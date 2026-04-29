/*
  Compat shim per pgupsize standalone.
  Fornisce fallback minimi delle funzioni framework usate dal core PG.
*/

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
   UNUSED( cAlias )
RETURN .F.

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
