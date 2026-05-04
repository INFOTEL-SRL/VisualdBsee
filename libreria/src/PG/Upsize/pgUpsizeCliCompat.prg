/*
  Compat shim per pgupsize standalone.
  Fornisce fallback minimi delle funzioni framework usate dal core PG.
*/

#INCLUDE "Common.ch"

#define DF_PG_UPSIZE_RC_OK            0
#define DF_PG_UPSIZE_RC_CFG_ERROR     1
#define DF_PG_UPSIZE_RC_LICENSE_ERROR 2
#define DF_PG_UPSIZE_RC_UPSIZE_ERROR  3

// ---------------------------------------------------------------------------
// CLI condiviso (pgupsize.exe / pgupsize-console.exe)
// ---------------------------------------------------------------------------
FUNCTION dfPgUpsizeCliEnvText( cEnvName, cEnvAlias )
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

FUNCTION dfPgUpsizeCliEnvFlag( cEnvName, cEnvAlias )
LOCAL cVal

   cVal := Upper( dfPgUpsizeCliEnvText( cEnvName, cEnvAlias ) )

RETURN ( cVal == "1" .OR. cVal == "YES" .OR. cVal == "TRUE" )

FUNCTION dfPgUpsizeCliRcMessage( nRc )

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

//* lHoldWhenEnvUnset: .T. = attendi INVIO se env NOHOLD assente (pgupsize.exe); .F. = non attendere (console).
FUNCTION dfPgUpsizeCliHoldEnabled( lHoldWhenEnvUnset )
LOCAL cVal

   IF ValType( lHoldWhenEnvUnset ) != "L"
      lHoldWhenEnvUnset := .T.
   ENDIF

   cVal := Upper( AllTrim( dfPgUpsizeCliEnvText( "VDB_PG_UPSIZE_NOHOLD", "VDB_UPSIZE_NON_ATTENDERE" ) ) )
   IF Empty( cVal )
      RETURN lHoldWhenEnvUnset
   ENDIF

RETURN !( cVal == "1" .OR. cVal == "YES" .OR. cVal == "TRUE" )

PROCEDURE dfPgUpsizeCliHoldWindow( cExeLabel, lHoldWhenEnvUnset )
LOCAL cDummy

   IF ValType( cExeLabel ) != "C" .OR. Empty( cExeLabel )
      cExeLabel := "pgupsize.exe"
   ENDIF

   IF !dfPgUpsizeCliHoldEnabled( lHoldWhenEnvUnset )
      RETURN
   ENDIF

   ? ""
   ?? "Premi INVIO per chiudere " + cExeLabel + "..."
   ACCEPT TO cDummy
RETURN

PROCEDURE dfPgUpsizeCliPrintEffectiveConfig( cExeTitle, cCfg, lForce, lDryRun, lHoldWhenEnvUnset )
LOCAL cCfgOut

   IF ValType( cExeTitle ) != "C" .OR. Empty( cExeTitle )
      cExeTitle := "pgupsize.exe"
   ENDIF

   cCfgOut := cCfg
   IF Empty( cCfgOut )
      cCfgOut := "(auto)"
   ENDIF

   ? cExeTitle + " - parametri effettivi"
   ? "  cfg    : " + cCfgOut
   ? "  force  : " + IIF( lForce, "YES", "NO" )
   ? "  dryRun : " + IIF( lDryRun, "YES", "NO" )
   ? "  noHold : " + IIF( !dfPgUpsizeCliHoldEnabled( lHoldWhenEnvUnset ), "YES", "NO" )
   ? ""
   ? "Variabili canoniche consigliate:"
   ? "  VDB_UPSIZE_CFG, VDB_PG_UPSIZE_FORCE, VDB_PG_UPSIZE_DRY_RUN, VDB_PG_UPSIZE_NOHOLD"
   ? "Alias legacy supportati (compatibilita):"
   ? "  VDB_UPSIZE_CONFIG, VDB_UPSIZE_FORZA, VDB_UPSIZE_SIMULA, VDB_UPSIZE_NON_ATTENDERE"
   ? ""
RETURN

// ---------------------------------------------------------------------------
// Messaggistica / shell / config
// ---------------------------------------------------------------------------
FUNCTION dbMsgErr( cMsg )
   IF ValType( cMsg ) == "C" .AND. !Empty( cMsg )
      ? cMsg
   ENDIF
RETURN NIL

FUNCTION dfRunShell( cCmd, cPrg, lWin95, lBack )
   UNUSED( cCmd )
   UNUSED( cPrg )
   UNUSED( lWin95 )
   UNUSED( lBack )
RETURN -1

FUNCTION dbCfgOpen( cAlias )
LOCAL cAli, cIni, cPath, cDbf, cNdx1, cNdx2

   cAli := IIF( ValType( cAlias ) == "C" .AND. !Empty( AllTrim( cAlias ) ), Lower( AllTrim( cAlias ) ), "dbdd" )

   IF Select( cAli ) > 0
      RETURN .T.
   ENDIF

   cPath := ""
   cIni  := dfInitName()
   IF ValType( cIni ) == "C" .AND. !Empty( cIni ) .AND. File( cIni )
      cPath := dfVdbIniSectionStringInFile( cIni, "Path", "dbDDPath", "" )
   ENDIF

   IF Empty( cPath )
      cPath := CurDir()
   ENDIF

   cPath := dfPgUpsizeEnsureTrailSlash( cPath )

   cDbf  := cPath + "DBDD.DBF"
   IF !File( cDbf )
      cDbf := cPath + "dbdd.dbf"
   ENDIF
   IF !File( cDbf )
      RETURN .F.
   ENDIF

   BEGIN SEQUENCE
      dbUseArea( .T., "DBFCDX", cDbf, cAli, .T., .F. )
   RECOVER
      RETURN .F.
   END SEQUENCE

   IF Select( cAli ) <= 0
      RETURN .F.
   ENDIF

   cNdx1 := cPath + "DBDD1.CDX"
   cNdx2 := cPath + "DBDD2.CDX"

   BEGIN SEQUENCE
      IF File( cNdx1 )
         ORDLISTADD( Left( cNdx1, Len( cNdx1 ) - 4 ) )
      ENDIF
      IF File( cNdx2 )
         ORDLISTADD( Left( cNdx2, Len( cNdx2 ) - 4 ) )
      ENDIF
      SET ORDER TO 1
   RECOVER
   END SEQUENCE

RETURN .T.

// ---------------------------------------------------------------------------
// Risoluzione dbstart.ini in standalone:
// 1) env VDB_DBSTART_INI
// 2) dbstart.ini locale
// 3) ..\EXE\dbstart.ini
// ---------------------------------------------------------------------------
FUNCTION dfInitName()
LOCAL c

   c := AllTrim( GetEnv( "VDB_DBSTART_INI" ) )
   IF ValType( c ) == "C" .AND. !Empty( c )
      RETURN c
   ENDIF

   IF File( "dbstart.ini" )
      RETURN "dbstart.ini"
   ENDIF

   IF File( "..\EXE\dbstart.ini" )
      RETURN "..\EXE\dbstart.ini"
   ENDIF

RETURN ""
