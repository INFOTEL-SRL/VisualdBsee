/******************************************************************************
  Modulo PostgreSQL / PGDBE (Visual dBsee + Alaska).

  Responsabilita' principali:
  - Upsize: DbfUpsize() (dbfupsize.lib), logger IUpsizeLogger; XML runtime in `pgUpsizeXml.prg` (`dfPgUpsizeBuildRuntimeCfg`).
  - Runtime DacSession: `pgDacSession.prg` (`dfPgSessionInit`, `dfPgGetDacSession`, `dfPgSessionShutdown`, …); licenza/`DbeLoad` PGDBE in `pgUpsizeConn.prg` (`dfPgDbeConfigurePgdbeLicense`).
  - INI/path: `pgVdbIni.prg` (I/O + `dfPgUpsizeCfgDirectory` / `dfPgUpsizeEnsureTrailSlash`); connessione stringa/`PgUpsize.ini` in `pgUpsizeConn.prg` (link prima di questo modulo).

  Flusso applicativo (vedi Menu.prg): con PG + /UPD, ddUpdDbf() prima di dfPgSessionInit (crea nuovi .dbf da DBDD),
  poi DbfUpsize in OIEXE4, poi ddIndex. Senza PG: solo ddUpdDbf. Prima di ddIndex: dfPgEnsureExeCurDir() (DbfUpsize/config in SOURCE\pg
  puo' lasciare CurDir li; con dbDDPath vuoto in dbstart il DD cerca DBDD.DBF sulla cwd -> fallisce se non e' EXE)
  e dfPgEnsureLocalDbeForDictionary() (default PGDBE -> DBFCDX per ddIndex).
  Dopo ddIndex, OIEXE6: dfPgSessionInit + dfPgCloseDbfWorkareas. In uscita: dfPgSessionShutdown() da ExitMenu (dbUdf.prg).
  NON usare XbaseReplaceDatabaseDriver=PGDBE in dbstart.ini per attivare PG (ddUpdDbf su DBDD fallisce).

  Riferimenti: Alaska PGDBE doc, Visual dBsee INCLUDE (DFCLPSUP.CH), Xbase++ xpp20 (pgdbe.ch).

  Env utili: VDB_SKIP_PG_UPSIZE, VDB_PG_UPSIZE_FORCE, VDB_UPSIZE_CFG, VDB_PGUPSIZE_INI, VDB_PG_*,
  VDB_PG_ACTIVATE_DBESYS, VDB_DBSTART_INI, VDB_PG_UPSIZE_TABLE_SOURCE (DBDD|EXE), VDB_PG_UPSIZE_EXTRA_DBF_DIR.

  Elenco tabelle in UPSIZE.runtime: default = DBDD; EXE resta solo scan fisico legacy (esclusi i DBF di sistema: DBDD, DBHLP,
  DBLOGIN, DBTABD, DBTAB — altrimenti DbfUpsize tenterebbe l'esclusiva su file gia' in USE). Con PgUpsize.ini [UPSIZE]
  PgUpsizeTableSource=DBDD (o env DBDD) si usano le tabelle RecTyp DBF dal dizionario, con le stesse esclusioni.
  Nota aggiornata: DBDD e' ora il default; EXE abilita solo lo scan fisico legacy/diagnostico.
  Cartella extra (opzionale): [UPSIZE] PgUpsizeExtraDbfDir=C:\\...\\ (o env VDB_PG_UPSIZE_EXTRA_DBF_DIR) unisce altri
  .DBF nell'elenco (stesso nome in EXE vince). I file creati dall'IDE vanno copiati in EXE oppure in quella cartella.

  Nota GUI: non usare ? / qOut nel logger (BASE/4402).
******************************************************************************/

#pragma library( "dbfupsize.lib" )
#INCLUDE "pgdbe.ch"

#INCLUDE "Common.ch"
#INCLUDE "DFCLPSUP.CH"
#INCLUDE "Fileio.ch"
#INCLUDE "dfGenMsg.ch"
#INCLUDE "dfSet.ch"

STATIC s_cPgUpsizeTrace := ""
STATIC s_cPgUpsizeLastCfg := ""
#define DF_PG_UPSIZE_RC_OK            0
#define DF_PG_UPSIZE_RC_CFG_ERROR     1
#define DF_PG_UPSIZE_RC_LICENSE_ERROR 2
#define DF_PG_UPSIZE_RC_UPSIZE_ERROR  3

*******************************************************************************
STATIC FUNCTION dfPgUpsizeBypassLicensePrecheck()
*******************************************************************************
LOCAL cEnv

   cEnv := Upper( AllTrim( GetEnv( "VDB_PG_UPSIZE_BYPASS_LICENSE_PRECHECK" ) ) )

RETURN ( cEnv == "1" .OR. cEnv == "YES" .OR. cEnv == "TRUE" )

*******************************************************************************
STATIC FUNCTION dfPgUpsizeStdoutEnabled()
*******************************************************************************
LOCAL cEnv, cExe

   cEnv := Upper( AllTrim( GetEnv( "VDB_PG_UPSIZE_STDOUT" ) ) )
   IF Empty( cEnv )
      cEnv := Upper( AllTrim( GetEnv( "VDB_UPSIZE_LOG_CONSOLE" ) ) )
   ENDIF
   IF cEnv == "1" .OR. cEnv == "YES" .OR. cEnv == "TRUE"
      RETURN .T.
   ENDIF
   IF cEnv == "0" .OR. cEnv == "NO" .OR. cEnv == "FALSE"
      RETURN .F.
   ENDIF

   cExe := Upper( AllTrim( AppName( .F. ) ) )
   IF cExe == "PGUPSIZE" .OR. cExe == "PGUPSIZE.EXE" .OR. ;
      ( "PGUPSIZE-CONSOLE" $ cExe )
      RETURN .T.
   ENDIF

RETURN .F.

*******************************************************************************
STATIC PROCEDURE dfPgUpsizeStdoutLine( cLine )
*******************************************************************************
   IF ValType( cLine ) == "C" .AND. !Empty( cLine ) .AND. dfPgUpsizeStdoutEnabled()
      ? cLine
   ENDIF
RETURN

*******************************************************************************
STATIC PROCEDURE dfPgUpsizeNotifyError( cMsg, lNoUi )
*******************************************************************************
   IF ValType( cMsg ) != "C" .OR. Empty( cMsg )
      RETURN
   ENDIF

   IF ValType( lNoUi ) == "L" .AND. lNoUi
      dfPgUpsizeTraceBuildMsg( "UPSIZE.runtime.upsize", "ERROR: " + cMsg )
      dfPgUpsizeStdoutLine( cMsg )
      RETURN
   ENDIF

   dbMsgErr( cMsg )
RETURN

//*******************************************************************************
FUNCTION dfPgIsSystemDictionaryStem( cStem )
//*******************************************************************************
//* True se cStem (nome tabella / file senza .dbf) e' un archivio del dizionario Visual dBsee: non va in upsize.
LOCAL cU

   IF ValType( cStem ) != "C" .OR. Empty( cStem )
      RETURN .F.
   ENDIF

   cU := Upper( RTrim( cStem ) )

   IF cU == "DBDD" .OR. cU == "DBHLP" .OR. ;
      cU == "DBLOGIN" .OR. cU == "DBTABD" .OR. ;
      cU == "DBTAB" .OR. cU == "DB3S" .OR. ;
      cU == "DB_TMP"
      RETURN .T.
   ENDIF

RETURN .F.

*******************************************************************************
STATIC FUNCTION dfPgDbeCaptureCompoundDefault()
*******************************************************************************
LOCAL x

   x := DbeSetDefault()
   IF ValType( x ) == "C" .AND. !Empty( AllTrim( x ) )
      RETURN AllTrim( x )
   ENDIF

   x := dfVdbReplaceDatabaseDriver()
   IF ValType( x ) == "C" .AND. !Empty( AllTrim( x ) )
      RETURN AllTrim( x )
   ENDIF

RETURN "DBFCDX"

*******************************************************************************
STATIC PROCEDURE dfPgDbeRestoreCompoundDefault( cPrevDbe )
*******************************************************************************

   IF ValType( cPrevDbe ) == "C" .AND. !Empty( AllTrim( cPrevDbe ) )
      DbeSetDefault( AllTrim( cPrevDbe ) )
   ENDIF

RETURN

*******************************************************************************
FUNCTION dfPgUpsizeDefaultDbeName()
*******************************************************************************
LOCAL x

   // DbeSetDefault() senza argomenti: nome del compound DBE corrente (Xbase++/Alaska).
   x := DbeSetDefault()
   IF ValType( x ) == "C"
      RETURN AllTrim( x )
   ENDIF

RETURN ""

*******************************************************************************
FUNCTION dfPgUpsizeShouldRunAfterUpd()
*******************************************************************************
LOCAL cDbe, cForce, cOnUpd

   IF Upper( AllTrim( GetEnv( "VDB_SKIP_PG_UPSIZE" ) ) ) == "1"
      RETURN .F.
   ENDIF

   cForce := Upper( AllTrim( GetEnv( "VDB_PG_UPSIZE_FORCE" ) ) )
   IF cForce == "1" .OR. cForce == "YES" .OR. cForce == "TRUE"
      RETURN .T.
   ENDIF

   cOnUpd := Upper( AllTrim( dfVdbIniAppsString( "XbaseRunPgUpsizeOnUpd", "YES" ) ) )
   IF cOnUpd == "NO" .OR. cOnUpd == "0" .OR. cOnUpd == "FALSE"
      RETURN .F.
   ENDIF

   IF dfVdbReplaceDatabaseDriver() == "PGDBE"
      RETURN .T.
   ENDIF

   cDbe := Upper( dfPgUpsizeDefaultDbeName() )
   IF cDbe == "PGDBE"
      RETURN .T.
   ENDIF

RETURN .T.

*******************************************************************************
STATIC PROCEDURE dfPgUpsizeLogSkip( cWhy )
*******************************************************************************
LOCAL cDir, cFile, nH, cBuf

   IF ValType( cWhy ) != "C"
      RETURN
   ENDIF

   cDir := CurDir()
   IF ValType( cDir ) == "C" .AND. !Empty( cDir ) .AND. !( Right( cDir, 1 ) == "\" )
      cDir += "\"
   ENDIF

   cFile := cDir + "pgUpsize.skip.log"
   cBuf  := DToC( Date() ) + " " + Time() + " DbfUpsize non eseguito: " + cWhy + Chr( 13 ) + Chr( 10 )

   nH := FOpen( cFile, FO_READWRITE + FO_DENYWRITE )
   IF nH == -1
      nH := FCreate( cFile, FC_NORMAL )
   ENDIF

   IF nH != -1
      FSeek( nH, 0, FS_END )
      FWrite( nH, cBuf, Len( cBuf ) )
      FClose( nH )
   ENDIF

RETURN

*******************************************************************************
STATIC PROCEDURE dfPgUpsizeTraceOpen( cCfg )
*******************************************************************************

   IF ValType( cCfg ) == "C" .AND. !Empty( cCfg )
      s_cPgUpsizeTrace := cCfg + ".pgtrace.log"
   ELSE
      s_cPgUpsizeTrace := ""
   ENDIF

RETURN

*******************************************************************************
//* Scrive una riga su <cfg>.pgtrace.log anche prima di dfPgUpsizeTraceOpen (rigenerazione runtime).
PROCEDURE dfPgUpsizeTraceRegenLine( cCfgPath, nBodyLen )
*******************************************************************************
LOCAL nHandle, cBuf, cPath

   IF ValType( cCfgPath ) != "C" .OR. Empty( cCfgPath ) .OR. ValType( nBodyLen ) != "N"
      RETURN
   ENDIF

   cPath := cCfgPath + ".pgtrace.log"
   cBuf  := DToC( Date() ) + " " + Time() + " === regenerated " + cCfgPath + " bytes=" + LTrim( Str( nBodyLen ) ) + Chr( 13 ) + Chr( 10 )

   nHandle := FOpen( cPath, FO_READWRITE + FO_DENYWRITE )

   IF nHandle == -1
      nHandle := FCreate( cPath, FC_NORMAL )
   ENDIF

   IF nHandle != -1
      FSeek( nHandle, 0, FS_END )
      FWrite( nHandle, cBuf, Len( cBuf ) )
      FClose( nHandle )
   ENDIF

RETURN

*******************************************************************************
//* Diagnostica rigenerazione runtime (stesso file di DbfUpsize: <cfg>.pgtrace.log).
PROCEDURE dfPgUpsizeTraceBuildMsg( cCfgPath, cMsg )
*******************************************************************************
LOCAL nHandle, cBuf, cPath

   IF ValType( cCfgPath ) != "C" .OR. Empty( cCfgPath ) .OR. ValType( cMsg ) != "C" .OR. Empty( cMsg )
      RETURN
   ENDIF
   dfPgUpsizeStdoutLine( cMsg )

   cPath := cCfgPath + ".pgtrace.log"
   cBuf  := DToC( Date() ) + " " + Time() + " " + cMsg + Chr( 13 ) + Chr( 10 )

   nHandle := FOpen( cPath, FO_READWRITE + FO_DENYWRITE )

   IF nHandle == -1
      nHandle := FCreate( cPath, FC_NORMAL )
   ENDIF

   IF nHandle != -1
      FSeek( nHandle, 0, FS_END )
      FWrite( nHandle, cBuf, Len( cBuf ) )
      FClose( nHandle )
   ENDIF

RETURN

*******************************************************************************
STATIC PROCEDURE dfPgUpsizeTraceLine( cLine )
*******************************************************************************
LOCAL nHandle, cBuf

   IF ValType( cLine ) != "C"
      RETURN
   ENDIF

   dfPgUpsizeStdoutLine( cLine )

   IF Empty( s_cPgUpsizeTrace )
      RETURN
   ENDIF

   cBuf := DToC( Date() ) + " " + Time() + " " + cLine + Chr( 13 ) + Chr( 10 )

   nHandle := FOpen( s_cPgUpsizeTrace, FO_READWRITE + FO_DENYWRITE )

   IF nHandle == -1
      nHandle := FCreate( s_cPgUpsizeTrace, FC_NORMAL )
   ENDIF

   IF nHandle != -1
      FSeek( nHandle, 0, FS_END )
      FWrite( nHandle, cBuf, Len( cBuf ) )
      FClose( nHandle )
   ENDIF

RETURN

//* IUpsizeLogger ha :alert differito (BASE/2261 se manca). DFCLPSUP.CH #xtranslate ALERT( => dfAlert( si applica
//* anche a sottostringhe tipo ":Alert("; METHOD alert IS pgUpsizeLogWarn mappa il messaggio :alert() all'implementazione :pgUpsizeLogWarn() evitando il match del preprocessore.

CLASS PgUpsizeLogger FROM IUpsizeLogger
   EXPORTED:
      METHOD start
      METHOD finish
      METHOD output
      METHOD progress
      METHOD stage
      METHOD setJobCount
      METHOD jobError
      METHOD jobFinished
      METHOD pgUpsizeLogWarn
      METHOD alert IS pgUpsizeLogWarn
ENDCLASS

METHOD PgUpsizeLogger:start()
RETURN Self

METHOD PgUpsizeLogger:finish()
   dfPgUpsizeTraceLine( "### finish" )
RETURN Self

METHOD PgUpsizeLogger:output( cTxt )
   IF ValType( cTxt ) == "C"
      dfPgUpsizeTraceLine( cTxt )
   ENDIF
RETURN Self

METHOD PgUpsizeLogger:progress( nJobId, nPercent )
   UNUSED( nJobId )
   UNUSED( nPercent )
RETURN Self

METHOD PgUpsizeLogger:stage( cTxt )
   IF ValType( cTxt ) == "C"
      dfPgUpsizeTraceLine( "### " + cTxt )
   ENDIF
RETURN Self

METHOD PgUpsizeLogger:setJobCount( nJobs )
   dfPgUpsizeTraceLine( "--- Jobs: " + Var2Char( nJobs ) )
RETURN Self

METHOD PgUpsizeLogger:jobError( nJobId )
   dfPgUpsizeTraceLine( "JOB ERROR id=" + Var2Char( nJobId ) )
   dbMsgErr( "Upsize job error ID: " + Var2Char( nJobId ) )
RETURN Self

METHOD PgUpsizeLogger:jobFinished( nJobId )
   dfPgUpsizeTraceLine( "--- Job finished " + Var2Char( nJobId ) )
RETURN Self

METHOD PgUpsizeLogger:pgUpsizeLogWarn( cMsg, cDetail )
   IF ValType( cMsg ) == "C" .AND. !Empty( cMsg )
      IF ValType( cDetail ) == "C" .AND. !Empty( cDetail )
         dfPgUpsizeTraceLine( "ALERT: " + cMsg + " | " + cDetail )
         dbMsgErr( cMsg + " " + cDetail )
      ELSE
         dfPgUpsizeTraceLine( "ALERT: " + cMsg )
         dbMsgErr( cMsg )
      ENDIF
   ENDIF
RETURN Self

*******************************************************************************
FUNCTION dfPgUpsizeResolveCfg()
*******************************************************************************
LOCAL cEnv, cTry, cExeDir, cCur

   cEnv := AllTrim( GetEnv( "VDB_UPSIZE_CFG" ) )
   IF !Empty( cEnv ) .AND. File( cEnv )
      RETURN cEnv
   ENDIF

   cExeDir := dfPgExeDirectory()
   IF ValType( cExeDir ) == "C" .AND. !Empty( cExeDir )
      cTry := cExeDir + "UPSIZE.upsize"
      IF File( cTry )
         RETURN cTry
      ENDIF

      cTry := cExeDir + "pg\UPSIZE.upsize"
      IF File( cTry )
         RETURN cTry
      ENDIF
   ENDIF

   cCur := CurDir()
   IF ValType( cCur ) == "C" .AND. !Empty( cCur )
      IF !( Right( cCur, 1 ) == "\" .OR. Right( cCur, 1 ) == "/" )
         cCur += "\"
      ENDIF

      cTry := cCur + "UPSIZE.upsize"
      IF File( cTry )
         RETURN cTry
      ENDIF

      cTry := cCur + "pg\UPSIZE.upsize"
      IF File( cTry )
         RETURN cTry
      ENDIF
   ENDIF

   cTry := "..\SOURCE\pg\UPSIZE.upsize"
   IF File( cTry )
      RETURN cTry
   ENDIF

   cTry := "SOURCE\pg\UPSIZE.upsize"
   IF File( cTry )
      RETURN cTry
   ENDIF

   cTry := "..\SOURCE\UPSIZE.upsize"
   IF File( cTry )
      RETURN cTry
   ENDIF

   cTry := "SOURCE\UPSIZE.upsize"
   IF File( cTry )
      RETURN cTry
   ENDIF

RETURN ""

*******************************************************************************
FUNCTION dfPgUpsizeCloseWorkareasBeforeUpsize()
*******************************************************************************
//* Chiamare prima di DbfUpsize: chiude i DBF in USE (dopo ddIndex o dopo sessione); altrimenti l'apertura esclusiva fallisce.
//* Non usare CLOSE DATABASES: chiuderebbe anche i DD di sistema (DBDD ecc.) e l'IDE non riapre piu' il dizionario.
LOCAL nArea, nPrev, cAlias, cUp

   nPrev := SELECT()

   FOR nArea := 1 TO 250
      IF !EMPTY( ALIAS( nArea ) )
         cAlias := ALIAS( nArea )
         cUp    := UPPER( TRIM( cAlias ) )
         IF cUp == "DBDD" .OR. cUp == "DBHLP" .OR. ;
            cUp == "DBLOGIN" .OR. cUp == "DBTABD" .OR. ;
            cUp == "DBTAB"
            LOOP
         ENDIF
         ( cAlias )->( DBCLOSEAREA() )
      ENDIF
   NEXT

   IF nPrev > 0 .AND. nPrev <= 250
      IF !EMPTY( ALIAS( nPrev ) )
         DBSELECTAREA( nPrev )
      ENDIF
   ENDIF

RETURN NIL

*******************************************************************************
FUNCTION dfPgUpsizeAfterUpd()
*******************************************************************************
LOCAL nRc

   nRc := dfPgUpsizeRunMigration( "", .F., .F., .T. )
   IF nRc != DF_PG_UPSIZE_RC_OK
      dfPgUpsizeTraceBuildMsg( "UPSIZE.runtime.upsize", "dfPgUpsizeAfterUpd: rc=" + LTrim( Str( nRc ) ) )
   ENDIF

RETURN NIL

*******************************************************************************
STATIC PROCEDURE dfPgUpsizeFinalizeRuntime( cPrevDbe )
*******************************************************************************
   dfPgDbeRestoreCompoundDefault( cPrevDbe )
   dfPgEnsureExeCurDir()
   dfPgEnsureLocalDbeForDictionary()
RETURN

*******************************************************************************
FUNCTION dfPgUpsizeRunMigration( cTplOrCfg, lForce, lDryRun, lLogSkip, lNoUi )
*******************************************************************************
LOCAL oLog, cTpl, cCfg, lOk, cPrevDbe
LOCAL nAttempt, cFailBag, cFailDbf

   s_cPgUpsizeLastCfg := ""

//* ddIndex() dopo /UPD usa DbInfo su DBF: il compound default deve essere DBFCDX (o come da INI), non PGDBE lasciato da DbfUpsize.
   cPrevDbe := dfPgDbeCaptureCompoundDefault()

   IF ValType( lForce ) != "L"
      lForce := .F.
   ENDIF
   IF ValType( lDryRun ) != "L"
      lDryRun := .F.
   ENDIF
   IF ValType( lLogSkip ) != "L"
      lLogSkip := .F.
   ENDIF
   IF ValType( lNoUi ) != "L"
      lNoUi := .F.
   ENDIF

   IF !lForce .AND. !dfPgUpsizeShouldRunAfterUpd()
      IF lLogSkip
         dfPgUpsizeLogSkip( "dfPgUpsizeShouldRunAfterUpd()=.F. (XbaseRunPgUpsizeOnUpd=NO/0/FALSE oppure VDB_SKIP_PG_UPSIZE=1)" )
      ENDIF
      dfPgUpsizeFinalizeRuntime( cPrevDbe )
      RETURN DF_PG_UPSIZE_RC_OK
   ENDIF

   dfPgUpsizeResetTransientExcludedOrders()
   dfPgUpsizeResetTransientExcludedTables()

   cTpl := ""
   IF ValType( cTplOrCfg ) == "C"
      cTpl := AllTrim( cTplOrCfg )
   ENDIF
   IF !Empty( cTpl ) .AND. !File( cTpl )
      dfPgUpsizeNotifyError( "PostgreSQL upsize: file configurazione non trovato: " + cTpl, lNoUi )
      dfPgUpsizeFinalizeRuntime( cPrevDbe )
      RETURN DF_PG_UPSIZE_RC_CFG_ERROR
   ENDIF

   IF Empty( cTpl )
      cTpl := dfPgUpsizeResolveCfg()
   ENDIF

   IF !Empty( cTpl )
      dfPgUpsizeTraceBuildMsg( dfPgUpsizeCfgDirectory( cTpl ) + "UPSIZE.runtime.upsize", "dfPgUpsizeRunMigration: template=" + cTpl )
   ELSE
      dfPgUpsizeTraceBuildMsg( "UPSIZE.runtime.upsize", "dfPgUpsizeRunMigration: no template, build from INI/path.ini" )
   ENDIF

   cCfg := dfPgUpsizeBuildRuntimeCfg( cTpl )
   IF Empty( cCfg )
      dfPgUpsizeNotifyError( "PostgreSQL upsize: impossibile generare UPSIZE.runtime.upsize (connection, oppure nessun .DBF in EXE relativo al template).", lNoUi )
      dfPgUpsizeFinalizeRuntime( cPrevDbe )
      RETURN DF_PG_UPSIZE_RC_CFG_ERROR
   ENDIF
   s_cPgUpsizeLastCfg := cCfg

//* Dopo BuildRuntimeCfg il template INI e' vuoto: serve di nuovo per ..\EXE\PgUpsize.ini (PgDbeLicense* come la Password).
   dfPgUpsizeSetTemplateForIni( cTpl )
   IF ! dfPgDbeConfigurePgdbeLicense( !dfPgUpsizeBypassLicensePrecheck() )
      dfPgUpsizeSetTemplateForIni( "" )
      dfPgUpsizeFinalizeRuntime( cPrevDbe )
      RETURN DF_PG_UPSIZE_RC_LICENSE_ERROR
   ENDIF
   dfPgUpsizeSetTemplateForIni( "" )

   IF lDryRun
      dfPgUpsizeTraceBuildMsg( cCfg, "dfPgUpsizeRunMigration: dry-run completed" )
      dfPgUpsizeFinalizeRuntime( cPrevDbe )
      RETURN DF_PG_UPSIZE_RC_OK
   ENDIF

   nAttempt := 1
   DO WHILE nAttempt <= 8
      dfPgUpsizeTraceOpen( cCfg )
      dfPgUpsizeTraceLine( "=== template " + cTpl )
      dfPgUpsizeTraceLine( "=== start DbfUpsize " + cCfg + " srv=" + dfPgUpsizeConnSrv() + " db=" + dfPgUpsizeConnDatabase() + " uid=" + dfPgUpsizeConnUid() + " attempt=" + LTrim( Str( nAttempt ) ) )

      oLog := PgUpsizeLogger():new()
      lOk  := DbfUpsize( cCfg, oLog )
      IF lOk
         EXIT
      ENDIF

      cFailBag := dfPgUpsizeLastOrdListAddBag( cCfg + ".pgtrace.log" )
      IF !Empty( cFailBag )
         IF !dfPgUpsizeAddTransientExcludedOrder( cFailBag )
            EXIT
         ENDIF
         dfPgUpsizeTraceBuildMsg( cCfg, "Retry after OrdListAdd bag exclude: " + cFailBag )
      ELSE
         cFailDbf := dfPgUpsizeLastExclusiveOpenTable( cCfg + ".pgtrace.log" )
         IF Empty( cFailDbf )
            EXIT
         ENDIF

         //* Non saltare tabelle su retry: meglio fallire esplicitamente
         //* che completare con migrazione parziale silenziosa.
         dfPgUpsizeTraceBuildMsg( cCfg, "Exclusive-open table detected, stop retry without table exclusion: " + cFailDbf )
         EXIT
      ENDIF

      cCfg := dfPgUpsizeBuildRuntimeCfg( cTpl )
      IF Empty( cCfg )
         EXIT
      ENDIF
      s_cPgUpsizeLastCfg := cCfg
      nAttempt++
   ENDDO

   dfPgUpsizeTraceLine( IIF( lOk, "=== DbfUpsize OK", "=== DbfUpsize FAILED" ) )

   IF !lOk
      dfPgUpsizeNotifyError( "PostgreSQL upsize non completato. Vedi " + cCfg + ".pgtrace.log e " + cCfg + ".log", lNoUi )
      dfPgUpsizeFinalizeRuntime( cPrevDbe )
      RETURN DF_PG_UPSIZE_RC_UPSIZE_ERROR
   ENDIF

   dfPgUpsizeFinalizeRuntime( cPrevDbe )

RETURN DF_PG_UPSIZE_RC_OK

*******************************************************************************
FUNCTION dfPgUpsizeLastTraceLogPath()
*******************************************************************************
LOCAL cCfg

   cCfg := s_cPgUpsizeLastCfg
   IF ValType( cCfg ) == "C" .AND. !Empty( cCfg )
      RETURN cCfg + ".pgtrace.log"
   ENDIF

RETURN "UPSIZE.runtime.upsize.pgtrace.log"

//*******************************************************************************
//* Estrae il bag che causa OrdListAdd dal trace (ultima occorrenza).
STATIC FUNCTION dfPgUpsizeLastOrdListAddBag( cTracePath )
//*******************************************************************************
LOCAL cAll, cNeedle, nPos, cTail, nClose, cBag

   IF ValType( cTracePath ) != "C" .OR. Empty( cTracePath ) .OR. !File( cTracePath )
      RETURN ""
   ENDIF

   cAll := dfVdbReadWholeFile( cTracePath )
   IF Empty( cAll )
      RETURN ""
   ENDIF

   cNeedle := "opening bag ("
   nPos := dfPgUpsizeLastPos( cNeedle, Lower( cAll ) )
   IF nPos < 1
      RETURN ""
   ENDIF

   cTail := SubStr( cAll, nPos + Len( cNeedle ) )
   nClose := At( ")", cTail )
   IF nClose < 1
      RETURN ""
   ENDIF

   cBag := AllTrim( Left( cTail, nClose - 1 ) )
RETURN cBag

//*******************************************************************************
//* Estrae l'ultimo DBF con errore "not able to open table exclusive:" dal trace.
STATIC FUNCTION dfPgUpsizeLastExclusiveOpenTable( cTracePath )
//*******************************************************************************
LOCAL cAll, cNeedle, nPos, cTail, nEol, cDbf

   IF ValType( cTracePath ) != "C" .OR. Empty( cTracePath ) .OR. !File( cTracePath )
      RETURN ""
   ENDIF

   cAll := dfVdbReadWholeFile( cTracePath )
   IF Empty( cAll )
      RETURN ""
   ENDIF

   cNeedle := "not able to open table exclusive:"
   nPos := dfPgUpsizeLastPos( cNeedle, Lower( cAll ) )
   IF nPos < 1
      RETURN ""
   ENDIF

   cTail := SubStr( cAll, nPos + Len( cNeedle ) )
   nEol := At( Chr( 10 ), cTail )
   IF nEol < 1
      cDbf := AllTrim( StrTran( cTail, Chr( 13 ), "" ) )
   ELSE
      cDbf := AllTrim( StrTran( Left( cTail, nEol - 1 ), Chr( 13 ), "" ) )
   ENDIF
RETURN cDbf

//*******************************************************************************
//* Posizione dell'ultima occorrenza (1-based), 0 se non trovata.
STATIC FUNCTION dfPgUpsizeLastPos( cNeedle, cHay )
//*******************************************************************************
LOCAL nPos, nFound, cRest

   IF ValType( cNeedle ) != "C" .OR. Empty( cNeedle ) .OR. ;
      ValType( cHay ) != "C" .OR. Empty( cHay )
      RETURN 0
   ENDIF

   nPos := 0
   cRest := cHay

   DO WHILE .T.
      nFound := At( cNeedle, cRest )
      IF nFound < 1
         EXIT
      ENDIF
      nPos += nFound
      cRest := SubStr( cRest, nFound + 1 )
   ENDDO

RETURN nPos

*******************************************************************************
FUNCTION dfPgUpsizeRunFromUpd()
*******************************************************************************
LOCAL cExeDir, cTool, cCmd, nShellRc, nRc, cUseExternal

   IF !dfPgUpsizeShouldRunAfterUpd()
      dfPgUpsizeLogSkip( "dfPgUpsizeRunFromUpd(): dfPgUpsizeShouldRunAfterUpd()=.F." )
      RETURN .T.
   ENDIF

   cUseExternal := Upper( AllTrim( GetEnv( "VDB_PG_UPSIZE_EXTERNAL" ) ) )
   IF cUseExternal == "1" .OR. cUseExternal == "YES" .OR. cUseExternal == "TRUE"
      cTool := AllTrim( GetEnv( "VDB_PG_UPSIZE_EXE" ) )
      IF Empty( cTool )
         cExeDir := dfPgExeDirectory()
         IF !Empty( cExeDir )
            cTool := cExeDir + "pgupsize.exe"
         ENDIF
      ENDIF

      IF ValType( cTool ) == "C" .AND. !Empty( cTool ) .AND. File( cTool )
         cCmd := '/C ""' + cTool + '"'
         nShellRc := dfRunShell( cCmd, NIL, .F., .F. )
         IF ValType( nShellRc ) == "N" .AND. nShellRc == 0
            RETURN .T.
         ENDIF
      ENDIF
   ENDIF

//* Fallback compatibile storico: esecuzione interna diretta se tool esterno assente o fallisce.
   nRc := dfPgUpsizeRunMigration( "", .F., .F., .T. )

RETURN ( nRc == DF_PG_UPSIZE_RC_OK )

*******************************************************************************
//* Ripristina la cwd sulla cartella dell'EXE (AppName): DbfUpsize lavora spesso da cartella template UPSIZE.
//* Con [Path] dbDDPath vuoto, Visual dBsee risolve DBDD.dbf rispetto a CurDir — se non e' EXE, errore apertura DD.
FUNCTION dfPgEnsureExeCurDir()
LOCAL cExe, bPrevErr

   cExe := dfPgExeDirectory()
   IF ValType( cExe ) != "C" .OR. Empty( cExe )
      RETURN NIL
   ENDIF

   cExe := RTrim( cExe )
   DO WHILE Len( cExe ) > 0 .AND. ( Right( cExe, 1 ) == "\" .OR. Right( cExe, 1 ) == "/" )
      cExe := Left( cExe, Len( cExe ) - 1 )
   ENDDO

   IF Empty( cExe )
      RETURN NIL
   ENDIF

   IF Upper( RTrim( CurDir() ) ) == Upper( cExe )
      RETURN NIL
   ENDIF

   bPrevErr := ErrorBlock( {|e| Break(e)} )
   BEGIN SEQUENCE
      CurDir( cExe )
   RECOVER
      // cwd invariata se path non valido
   END SEQUENCE
   ErrorBlock( bPrevErr )

RETURN NIL

*******************************************************************************
//* DbfUpsize / dfPgDbeCaptureCompoundDefault (fallback su INI) possono lasciare PGDBE come compound default.
//* ddIndex(), dbCfgOpen e USE del dizionario (DBDD ecc.) richiedono un DBE ISAM su file locale.
FUNCTION dfPgEnsureLocalDbeForDictionary()
LOCAL cD

   cD := Upper( AllTrim( DbeSetDefault() ) )
   IF cD == "PGDBE"
      DbeSetDefault( "DBFCDX" )
   ENDIF

RETURN NIL
