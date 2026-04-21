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
  VDB_PG_ACTIVATE_DBESYS, VDB_DBSTART_INI, VDB_PG_UPSIZE_TABLE_SOURCE (EXE|DBDD), VDB_PG_UPSIZE_EXTRA_DBF_DIR.

  Elenco tabelle in UPSIZE.runtime: default = scan EXE\\*.DBF (esclusi i DBF di sistema del dizionario: DBDD, DBHLP,
  DBLOGIN, DBTABD, DBTAB — altrimenti DbfUpsize tenterebbe l'esclusiva su file gia' in USE). Con PgUpsize.ini [UPSIZE]
  PgUpsizeTableSource=DBDD (o env DBDD) si usano le tabelle RecTyp DBF dal dizionario, con le stesse esclusioni.
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
      cU == "DBTAB"
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

   IF Empty( s_cPgUpsizeTrace ) .OR. ValType( cLine ) != "C"
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
LOCAL cEnv, cTry

   cEnv := AllTrim( GetEnv( "VDB_UPSIZE_CFG" ) )
   IF !Empty( cEnv ) .AND. File( cEnv )
      RETURN cEnv
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
LOCAL oLog, cTpl, cCfg, lOk, cPrevDbe

//* ddIndex() dopo /UPD usa DbInfo su DBF: il compound default deve essere DBFCDX (o come da INI), non PGDBE lasciato da DbfUpsize.
   cPrevDbe := dfPgDbeCaptureCompoundDefault()

   IF !dfPgUpsizeShouldRunAfterUpd()
      dfPgUpsizeLogSkip( "dfPgUpsizeShouldRunAfterUpd()=.F. (XbaseRunPgUpsizeOnUpd=NO/0/FALSE oppure VDB_SKIP_PG_UPSIZE=1)" )
      RETURN NIL
   ENDIF

   cTpl := dfPgUpsizeResolveCfg()
   IF Empty( cTpl )
      dbMsgErr( "PostgreSQL upsize: file UPSIZE.upsize non trovato. Imposta VDB_UPSIZE_CFG o posiziona SOURCE\pg\UPSIZE.upsize (legacy: SOURCE\UPSIZE.upsize)." )
      RETURN NIL
   ENDIF

   dfPgUpsizeTraceBuildMsg( dfPgUpsizeCfgDirectory( cTpl ) + "UPSIZE.runtime.upsize", "dfPgUpsizeAfterUpd: template=" + cTpl )

   cCfg := dfPgUpsizeBuildRuntimeCfg( cTpl )
   IF Empty( cCfg )
      dbMsgErr( "PostgreSQL upsize: impossibile generare UPSIZE.runtime.upsize (connection, oppure nessun .DBF in EXE relativo al template)." )
      RETURN NIL
   ENDIF

//* Dopo BuildRuntimeCfg il template INI e' vuoto: serve di nuovo per ..\EXE\PgUpsize.ini (PgDbeLicense* come la Password).
   dfPgUpsizeSetTemplateForIni( cTpl )
   IF ! dfPgDbeConfigurePgdbeLicense( .T. )
      dfPgUpsizeSetTemplateForIni( "" )
      dfPgDbeRestoreCompoundDefault( cPrevDbe )
      RETURN NIL
   ENDIF
   dfPgUpsizeSetTemplateForIni( "" )

   dfPgUpsizeTraceOpen( cCfg )
   dfPgUpsizeTraceLine( "=== template " + cTpl )
   dfPgUpsizeTraceLine( "=== start DbfUpsize " + cCfg + " srv=" + dfPgUpsizeConnSrv() + " db=" + dfPgUpsizeConnDatabase() + " uid=" + dfPgUpsizeConnUid() )

   oLog := PgUpsizeLogger():new()
   lOk  := DbfUpsize( cCfg, oLog )

   dfPgUpsizeTraceLine( IIF( lOk, "=== DbfUpsize OK", "=== DbfUpsize FAILED" ) )

   IF !lOk
      dbMsgErr( "PostgreSQL upsize non completato. Vedi " + cCfg + ".pgtrace.log e " + cCfg + ".log" )
   ENDIF

   dfPgDbeRestoreCompoundDefault( cPrevDbe )
   dfPgEnsureExeCurDir()
   dfPgEnsureLocalDbeForDictionary()

RETURN NIL

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

