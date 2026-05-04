/*
  Console launcher (VIO) for pgupsize flow.
  Configurazione via environment, senza parsing argomenti CLI.
*/

#INCLUDE "Common.ch"

#define DF_PG_UPSIZE_RC_OK            0
#define DF_PG_UPSIZE_RC_CFG_ERROR     1
#define DF_PG_UPSIZE_RC_LICENSE_ERROR 2
#define DF_PG_UPSIZE_RC_UPSIZE_ERROR  3

STATIC PROCEDURE dfPgCliPrintLogHints()
LOCAL cTrace

   cTrace := dfPgUpsizeLastTraceLogPath()
   ? ""
   ? "Log completo:"
   ? "  trace : " + cTrace
   ? "  detail: " + StrTran( cTrace, ".pgtrace.log", ".log" )
RETURN

PROCEDURE MAIN()
LOCAL cCfg, nRc, lForce, lDryRun

   cCfg    := dfPgUpsizeCliEnvText( "VDB_UPSIZE_CFG", "VDB_UPSIZE_CONFIG" )
   lForce  := dfPgUpsizeCliEnvFlag( "VDB_PG_UPSIZE_FORCE", "VDB_UPSIZE_FORZA" )
   lDryRun := dfPgUpsizeCliEnvFlag( "VDB_PG_UPSIZE_DRY_RUN", "VDB_UPSIZE_SIMULA" )

   dfPgUpsizeCliPrintEffectiveConfig( "pgupsize-console.exe", cCfg, lForce, lDryRun, .F. )

   nRc := dfPgUpsizeRunMigration( cCfg, lForce, lDryRun, .T., .T. )

   ? dfPgUpsizeCliRcMessage( nRc )
   dfPgCliPrintLogHints()

   IF nRc != DF_PG_UPSIZE_RC_OK .AND. ;
      nRc != DF_PG_UPSIZE_RC_CFG_ERROR .AND. ;
      nRc != DF_PG_UPSIZE_RC_LICENSE_ERROR .AND. ;
      nRc != DF_PG_UPSIZE_RC_UPSIZE_ERROR
      nRc := DF_PG_UPSIZE_RC_UPSIZE_ERROR
   ENDIF

   ErrorLevel( nRc )
   dfPgUpsizeCliHoldWindow( "pgupsize-console.exe", .F. )
   QUIT
RETURN
