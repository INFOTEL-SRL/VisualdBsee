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

STATIC FUNCTION dfPgCliEnvText( cEnvName, cEnvAlias )
LOCAL cVal

   cVal := AllTrim( GetEnv( cEnvName ) )
   IF !Empty( cVal )
      RETURN cVal
   ENDIF

   IF ValType( cEnvAlias ) == "C" .AND. !Empty( cEnvAlias )
      cVal := AllTrim( GetEnv( cEnvAlias ) )
      IF !Empty( cVal )
         RETURN cVal
      ENDIF
   ENDIF

RETURN ""

STATIC FUNCTION dfPgCliEnvFlag( cEnvName, cEnvAlias )
LOCAL cVal

   cVal := Upper( dfPgCliEnvText( cEnvName, cEnvAlias ) )

RETURN ( cVal == "1" .OR. cVal == "YES" .OR. cVal == "TRUE" )

STATIC FUNCTION dfPgCliRcMessage( nRc )

   DO CASE
      CASE nRc == DF_PG_UPSIZE_RC_OK
         RETURN "PostgreSQL upsize completato."
      CASE nRc == DF_PG_UPSIZE_RC_CFG_ERROR
         RETURN "Errore configurazione/template."
      CASE nRc == DF_PG_UPSIZE_RC_LICENSE_ERROR
         RETURN "Errore licenza PGDBE."
      CASE nRc == DF_PG_UPSIZE_RC_UPSIZE_ERROR
         RETURN "DbfUpsize fallito."
   ENDCASE

RETURN "Errore non classificato: " + LTrim( Str( nRc ) )

STATIC FUNCTION dfPgCliHoldEnabled()
LOCAL cVal

   cVal := Upper( dfPgCliEnvText( "VDB_PG_UPSIZE_NOHOLD", "VDB_UPSIZE_NON_ATTENDERE" ) )

RETURN !( cVal == "1" .OR. cVal == "YES" .OR. cVal == "TRUE" )

STATIC PROCEDURE dfPgCliHoldWindow()
LOCAL cDummy

   IF !dfPgCliHoldEnabled()
      RETURN
   ENDIF

   ? ""
   ?? "Premi INVIO per chiudere pgupsize.exe..."
   ACCEPT TO cDummy
RETURN

STATIC PROCEDURE dfPgCliUsage()
   ? "pgupsize.exe (standalone)"
   ? "Configurazione via environment:"
   ? "  VDB_UPSIZE_CFG=<path template .upsize>"
   ? "  VDB_PG_UPSIZE_FORCE=1"
   ? "  VDB_PG_UPSIZE_DRY_RUN=1"
   ? "Alias in italiano:"
   ? "  VDB_UPSIZE_CONFIG=<path template .upsize>"
   ? "  VDB_UPSIZE_FORZA=1"
   ? "  VDB_UPSIZE_SIMULA=1"
   ? "  VDB_UPSIZE_NON_ATTENDERE=1"
RETURN

PROCEDURE MAIN()
LOCAL cCfg, nRc

   cCfg   := dfPgCliEnvText( "VDB_UPSIZE_CFG", "VDB_UPSIZE_CONFIG" )

   nRc := dfPgUpsizeRunMigration( cCfg, ;
                                  dfPgCliEnvFlag( "VDB_PG_UPSIZE_FORCE", "VDB_UPSIZE_FORZA" ), ;
                                  dfPgCliEnvFlag( "VDB_PG_UPSIZE_DRY_RUN", "VDB_UPSIZE_SIMULA" ), ;
                                  .T., ;
                                  .T. )

   ? dfPgCliRcMessage( nRc )

   IF nRc != DF_PG_UPSIZE_RC_OK .AND. ;
      nRc != DF_PG_UPSIZE_RC_CFG_ERROR .AND. ;
      nRc != DF_PG_UPSIZE_RC_LICENSE_ERROR .AND. ;
      nRc != DF_PG_UPSIZE_RC_UPSIZE_ERROR
      nRc := DF_PG_UPSIZE_RC_UPSIZE_ERROR
   ENDIF

   ErrorLevel( nRc )
   dfPgCliHoldWindow()
   QUIT
RETURN
