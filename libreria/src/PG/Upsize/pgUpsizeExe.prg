/*
  CLI standalone per migrazione DBF -> PostgreSQL.
  Riusa dfPgUpsizeRunMigration() e restituisce codici uscita:
  0=OK, 1=config/template, 2=licenza, 3=DbfUpsize fallito.
*/

#INCLUDE "Common.ch"

#define DF_PG_UPSIZE_RC_OK            0
#define DF_PG_UPSIZE_RC_CFG_ERROR     1
#define DF_PG_UPSIZE_RC_LICENSE_ERROR 2
#define DF_PG_UPSIZE_RC_UPSIZE_ERROR  3

STATIC FUNCTION dfPgCliIsHelpArg( cArg )
LOCAL c

   IF ValType( cArg ) != "C"
      RETURN .F.
   ENDIF

   c := Lower( AllTrim( cArg ) )
RETURN ( c == "--help" .OR. c == "-h" .OR. c == "/?" .OR. c == "-?" .OR. c == "help" )

STATIC FUNCTION dfPgCliWantsHelp()
LOCAL n, cArg

   FOR n := 1 TO dfArgC() - 1
      cArg := dfArgV( n )
      IF dfPgCliIsHelpArg( cArg )
         RETURN .T.
      ENDIF
   NEXT

RETURN .F.

STATIC PROCEDURE dfPgCliPrintHelp()
   ? "pgupsize.exe - standalone DBF -> PostgreSQL"
   ? ""
   ? "Uso:"
   ? "  pgupsize.exe [--help]"
   ? ""
   ? "Parametri:"
   ? "  --help, -h, /?, -?   Mostra questo help ed esce"
   ? ""
   ? "Variabili principali:"
   ? "  VDB_PG_UPSIZE_FORCE=1     Esegue la migrazione"
   ? "  VDB_PG_UPSIZE_DRY_RUN=1   Genera solo UPSIZE.runtime.upsize"
   ? "  VDB_PG_UPSIZE_NOHOLD=1    Non attendere INVIO a fine run"
   ? "  VDB_UPSIZE_CFG=<path>     Template esplicito (opzionale)"
   ? ""
   ? "Nota: senza VDB_UPSIZE_CFG il runtime XML viene costruito automaticamente."
RETURN

PROCEDURE MAIN()
LOCAL cCfg, nRc, lForce, lDryRun

   IF dfPgCliWantsHelp()
      dfPgCliPrintHelp()
      ErrorLevel( DF_PG_UPSIZE_RC_OK )
      QUIT
      RETURN
   ENDIF

   cCfg    := dfPgUpsizeCliEnvText( "VDB_UPSIZE_CFG", "VDB_UPSIZE_CONFIG" )
   lForce  := dfPgUpsizeCliEnvFlag( "VDB_PG_UPSIZE_FORCE", "VDB_UPSIZE_FORZA" )
   lDryRun := dfPgUpsizeCliEnvFlag( "VDB_PG_UPSIZE_DRY_RUN", "VDB_UPSIZE_SIMULA" )

   dfPgUpsizeCliPrintEffectiveConfig( "pgupsize.exe", cCfg, lForce, lDryRun, .T. )

   nRc := dfPgUpsizeRunMigration( cCfg, ;
                                  lForce, ;
                                  lDryRun, ;
                                  .T., ;
                                  .T. )

   ? dfPgUpsizeCliRcMessage( nRc )

   IF nRc != DF_PG_UPSIZE_RC_OK .AND. ;
      nRc != DF_PG_UPSIZE_RC_CFG_ERROR .AND. ;
      nRc != DF_PG_UPSIZE_RC_LICENSE_ERROR .AND. ;
      nRc != DF_PG_UPSIZE_RC_UPSIZE_ERROR
      nRc := DF_PG_UPSIZE_RC_UPSIZE_ERROR
   ENDIF

   ErrorLevel( nRc )
   dfPgUpsizeCliHoldWindow( "pgupsize.exe", .T. )
   QUIT
RETURN
