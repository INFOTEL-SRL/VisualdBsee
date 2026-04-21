/******************************************************************************
  Connessione PostgreSQL (INI/env), licenza PGDBE, DbeLoad/DbeInfo PGDBE (`dfPgDbeConfigurePgdbeLicense`),
  risoluzione PgUpsize.ini, stringa DacSession, precarico PGDBE. Stato template per INI accanto al .upsize.
  Link dopo pgVdbIni, prima di pgUpsize.prg.
******************************************************************************/
#INCLUDE "pgdbe.ch"
#INCLUDE "Common.ch"
#INCLUDE "DFCLPSUP.CH"
#INCLUDE "Fileio.ch"
#INCLUDE "dfGenMsg.ch"
#INCLUDE "dfSet.ch"

STATIC s_cPgUpsizeTemplateForIni := ""

//* Priorita: env non vuoto -> INI [apps] -> cDefault (dfVdbIniAppsString definita sotto).
STATIC FUNCTION dfPgConnParam( cEnvVar, cIniKey, cDefault )
LOCAL c

   IF ValType( cEnvVar ) != "C" .OR. Empty( cEnvVar )
      RETURN IIF( ValType( cDefault ) == "C", cDefault, "" )
   ENDIF

   c := AllTrim( GetEnv( cEnvVar ) )
   IF ValType( c ) == "C" .AND. !Empty( c )
      RETURN c
   ENDIF

   c := AllTrim( dfVdbIniAppsString( cIniKey, "" ) )
   IF ValType( c ) == "C" .AND. !Empty( c )
      RETURN c
   ENDIF

RETURN IIF( ValType( cDefault ) == "C", cDefault, "" )

//* Connessione DbfUpsize: [apps] poi sezione [UPSIZE] (ServerName, UserID, Password, Database) in dbstart.ini o PgUpsize.ini (stile Donnay).
//* PgUpsize.ini (di solito EXE\PgUpsize.ini) ha priorita' su dbstart [UPSIZE]: dfVdbIniFullPath() puo' puntare a un altro dbstart senza Password.
FUNCTION dfPgUpsizeIniUpsizeOnly( cKey )
LOCAL c, cPath

   IF ValType( cKey ) != "C" .OR. Empty( cKey )
      RETURN ""
   ENDIF

   cPath := dfPgPgUpsizeIniPath()
   IF ValType( cPath ) == "C" .AND. !Empty( cPath )
      c := AllTrim( dfVdbIniSectionStringInFile( cPath, "UPSIZE", cKey, "" ) )
      IF !Empty( c )
         RETURN c
      ENDIF
   ENDIF

   c := AllTrim( dfVdbIniSectionString( "UPSIZE", cKey, "" ) )
   IF !Empty( c )
      RETURN c
   ENDIF

RETURN ""

FUNCTION dfPgUpsizeConnSrv()
LOCAL c

   c := AllTrim( GetEnv( "VDB_PG_SERVER" ) )
   IF !Empty( c )
      RETURN c
   ENDIF

   c := AllTrim( dfVdbIniAppsString( "XbasePgServer", "" ) )
   IF !Empty( c )
      RETURN c
   ENDIF

   c := dfPgUpsizeIniUpsizeOnly( "ServerName" )
   IF !Empty( c )
      RETURN c
   ENDIF

RETURN "localhost"

FUNCTION dfPgUpsizeConnUid()
LOCAL c

   c := AllTrim( GetEnv( "VDB_PG_UID" ) )
   IF !Empty( c )
      RETURN c
   ENDIF

   c := AllTrim( dfVdbIniAppsString( "XbasePgUid", "" ) )
   IF !Empty( c )
      RETURN c
   ENDIF

   c := dfPgUpsizeIniUpsizeOnly( "UserID" )
   IF !Empty( c )
      RETURN c
   ENDIF

RETURN "postgres"

FUNCTION dfPgUpsizeConnPwd()
LOCAL c

   c := AllTrim( GetEnv( "VDB_PG_PWD" ) )
   IF !Empty( c )
      RETURN c
   ENDIF

   c := AllTrim( dfVdbIniAppsString( "XbasePgPwd", "" ) )
   IF !Empty( c )
      RETURN c
   ENDIF

   c := dfPgUpsizeIniUpsizeOnly( "Password" )
   IF !Empty( c )
      RETURN c
   ENDIF

RETURN ""

FUNCTION dfPgUpsizeConnDatabase()
LOCAL c

   c := AllTrim( GetEnv( "VDB_PG_DATABASE" ) )
   IF !Empty( c )
      RETURN c
   ENDIF

   c := AllTrim( dfVdbIniAppsString( "XbasePgDatabase", "" ) )
   IF !Empty( c )
      RETURN c
   ENDIF

   c := dfPgUpsizeIniUpsizeOnly( "Database" )
   IF !Empty( c )
      RETURN c
   ENDIF

RETURN "vdb_test"

//* Licenza PGDBE: [apps] XbasePg*; sezione [UPSIZE] PgDbeLicense* (stile PgUpsize.ini / rdonnay forum); opz. file PgUpsize.ini accanto a dbstart.ini.
STATIC FUNCTION dfPgLicenseKey()
LOCAL c

   c := dfPgConnParam( "VDB_PG_LICENSE_KEY", "XbasePgLicenseKey", "" )
   IF ValType( c ) == "C" .AND. !Empty( AllTrim( c ) )
      RETURN AllTrim( c )
   ENDIF

   c := dfPgLicenseKeyFromPgUpsizeIni()
   IF ValType( c ) == "C" .AND. !Empty( AllTrim( c ) )
      RETURN AllTrim( c )
   ENDIF

   c := dfVdbIniSectionString( "UPSIZE", "PgDbeLicenseKey", "" )
   IF ValType( c ) == "C" .AND. !Empty( AllTrim( c ) )
      RETURN AllTrim( c )
   ENDIF

RETURN ""

STATIC FUNCTION dfPgLicenseeName()
LOCAL c

   c := dfPgConnParam( "VDB_PG_LICENSEE", "XbasePgLicensee", "" )
   IF ValType( c ) == "C" .AND. !Empty( AllTrim( c ) )
      RETURN AllTrim( c )
   ENDIF

   c := dfPgLicenseeFromPgUpsizeIni()
   IF ValType( c ) == "C" .AND. !Empty( AllTrim( c ) )
      RETURN AllTrim( c )
   ENDIF

   c := dfVdbIniSectionString( "UPSIZE", "PgDbeLicensee", "" )
   IF ValType( c ) == "C" .AND. !Empty( AllTrim( c ) )
      RETURN AllTrim( c )
   ENDIF

RETURN ""

//* PgUpsize.ini nella stessa cartella dell'applicazione (dfInitName): spesso coincide con EXE\ ma dfVdbIniFullPath() puo' puntare altrove (env, roaming).
STATIC FUNCTION dfPgPgUpsizeIniBesideAppIni()
LOCAL cApp, cDir, cTry

   cApp := dfInitName()
   IF ValType( cApp ) != "C" .OR. Empty( cApp )
      RETURN ""
   ENDIF

   cDir := dfPgUpsizeCfgDirectory( cApp )
   IF Empty( cDir )
      RETURN ""
   ENDIF

   cTry := cDir + "\PgUpsize.ini"
   IF File( cTry )
      RETURN cTry
   ENDIF

RETURN ""

//* Durante dfPgUpsizeBuildRuntimeCfg, CurDir/dfInitName spesso non sono EXE: risalire da SOURCE\\*.upsize a ..\\EXE\\PgUpsize.ini.
STATIC FUNCTION dfPgPgUpsizeIniBesideTemplateAncestor()
LOCAL cTpl, cDir, aRel, i, cTry

   cTpl := s_cPgUpsizeTemplateForIni
   IF ValType( cTpl ) != "C" .OR. Empty( cTpl )
      RETURN ""
   ENDIF

   cDir := dfPgUpsizeCfgDirectory( cTpl )
   IF Empty( cDir )
      RETURN ""
   ENDIF

   aRel := { ;
      "..\EXE\PgUpsize.ini", ;
      "..\..\EXE\PgUpsize.ini", ;
      "..\..\..\EXE\PgUpsize.ini", ;
      "EXE\PgUpsize.ini" ;
      }

   FOR i := 1 TO Len( aRel )
      cTry := cDir + "\" + aRel[i]
      IF File( cTry )
         RETURN cTry
      ENDIF
   NEXT

RETURN ""

STATIC FUNCTION dfPgPgUpsizeIniPath()
LOCAL cDb, cTry, cDir, aRel, i, cEnv

//* Ordine: override esplicito -> accanto all'EXE (AppName) -> accanto all'INI (dfInitName) -> dbstart -> ricerca CurDir.
   cEnv := AllTrim( GetEnv( "VDB_PGUPSIZE_INI" ) )
   IF ValType( cEnv ) == "C" .AND. !Empty( cEnv ) .AND. File( cEnv )
      RETURN cEnv
   ENDIF

   //* Check basato su AppName(.T.) — funziona anche in dbeSys() prima del framework.
   cTry := dfPgFindPgUpsizeIniEarly()
   IF !Empty( cTry )
      RETURN cTry
   ENDIF

   cTry := dfPgPgUpsizeIniBesideAppIni()
   IF !Empty( cTry )
      RETURN cTry
   ENDIF

   cTry := dfPgPgUpsizeIniBesideTemplateAncestor()
   IF !Empty( cTry )
      RETURN cTry
   ENDIF

   cDb := dfVdbIniFullPath()
   IF ValType( cDb ) == "C" .AND. !Empty( cDb )
      cTry := dfPgUpsizeCfgDirectory( cDb ) + "\PgUpsize.ini"
      IF File( cTry )
         RETURN cTry
      ENDIF
   ENDIF

   cDb := dfVdbIniWalkUpForExeDbstart()
   IF ValType( cDb ) == "C" .AND. !Empty( cDb )
      cTry := dfPgUpsizeCfgDirectory( cDb ) + "\PgUpsize.ini"
      IF File( cTry )
         RETURN cTry
      ENDIF
   ENDIF

   cDb := dfVdbIniBesideSourceFolder()
   IF ValType( cDb ) == "C" .AND. !Empty( cDb )
      cTry := dfPgUpsizeCfgDirectory( cDb ) + "\PgUpsize.ini"
      IF File( cTry )
         RETURN cTry
      ENDIF
   ENDIF

   cDir := RTrim( CurDir() )
   IF ValType( cDir ) == "C" .AND. !Empty( cDir )
      IF !( Right( cDir, 1 ) == "\" .OR. Right( cDir, 1 ) == "/" )
         cDir += "\"
      ENDIF
      aRel := { "PgUpsize.ini", "EXE\PgUpsize.ini", "..\EXE\PgUpsize.ini", "..\..\EXE\PgUpsize.ini" }
      FOR i := 1 TO Len( aRel )
         cTry := cDir + aRel[i]
         IF File( cTry )
            RETURN cTry
         ENDIF
      NEXT
   ENDIF

RETURN ""

STATIC FUNCTION dfPgLicenseKeyFromPgUpsizeIni()
LOCAL cIni

   cIni := dfPgPgUpsizeIniPath()
   IF ValType( cIni ) != "C" .OR. Empty( cIni ) .OR. !File( cIni )
      RETURN ""
   ENDIF

RETURN dfVdbIniSectionStringInFile( cIni, "UPSIZE", "PgDbeLicenseKey", "" )

STATIC FUNCTION dfPgLicenseeFromPgUpsizeIni()
LOCAL cIni

   cIni := dfPgPgUpsizeIniPath()
   IF ValType( cIni ) != "C" .OR. Empty( cIni ) .OR. !File( cIni )
      RETURN ""
   ENDIF

RETURN dfVdbIniSectionStringInFile( cIni, "UPSIZE", "PgDbeLicensee", "" )

//* Due righe: (1) license key ASI (2) licensee esattamente come sul portale. Opzionale env VDB_PG_LICENSE_FILE=path.
STATIC FUNCTION dfPgLicenseFromSidecarFile()
LOCAL cEnv, cDir, cIni, cFile, cAll, aL, i, cLine, cKey, cLic, n

   cKey := ""
   cLic := ""

   cEnv := AllTrim( GetEnv( "VDB_PG_LICENSE_FILE" ) )
   IF ValType( cEnv ) == "C" .AND. !Empty( cEnv ) .AND. File( cEnv )
      cFile := cEnv
   ELSE
      cIni := dfVdbIniWalkUpForExeDbstart()
      IF Empty( cIni )
         cIni := dfVdbIniBesideSourceFolder()
      ENDIF
      IF Empty( cIni )
         RETURN ""
      ENDIF
      cDir := dfPgUpsizeCfgDirectory( cIni )
      IF Empty( cDir )
         RETURN ""
      ENDIF
      cFile := dfPgUpsizeEnsureTrailSlash( cDir ) + "pgdbe_license.txt"
   ENDIF

   IF !File( cFile )
      RETURN ""
   ENDIF

   cAll := dfVdbReadWholeFile( cFile )
   IF ValType( cAll ) != "C" .OR. Empty( cAll )
      RETURN ""
   ENDIF

   IF Len( cAll ) >= 3 .AND. Left( cAll, 3 ) == Chr( 239 ) + Chr( 187 ) + Chr( 191 )
      cAll := SubStr( cAll, 4 )
   ENDIF

   cAll := StrTran( cAll, Chr( 13 ), Chr( 10 ) )
   aL  := {}

   DO WHILE Len( cAll ) > 0
      n := At( Chr( 10 ), cAll )
      IF n < 1
         AAdd( aL, AllTrim( cAll ) )
         cAll := ""
      ELSE
         AAdd( aL, AllTrim( Left( cAll, n - 1 ) ) )
         cAll := SubStr( cAll, n + 1 )
      ENDIF
   ENDDO

   FOR i := 1 TO Len( aL )
      cLine := aL[i]
      IF ValType( cLine ) != "C" .OR. Empty( cLine )
         LOOP
      ENDIF
      IF Left( cLine, 1 ) == ";"
         LOOP
      ENDIF
      IF Empty( cKey )
         cKey := cLine
      ELSEIF Empty( cLic )
         cLic := cLine
      ELSE
         EXIT
      ENDIF
   NEXT

   IF ValType( cKey ) != "C" .OR. ValType( cLic ) != "C"
      RETURN ""
   ENDIF
   IF Empty( cKey ) .OR. Empty( cLic )
      RETURN ""
   ENDIF

RETURN "licensekey=" + cKey + ";licensee=" + cLic + ";"

FUNCTION dfPgLicenseInfoString()
LOCAL cK, cN, cSide

   cK := dfPgLicenseKey()
   cN := dfPgLicenseeName()

   IF ValType( cK ) != "C"
      cK := ""
   ENDIF
   IF ValType( cN ) != "C"
      cN := ""
   ENDIF

   cK := AllTrim( cK )
   cN := AllTrim( cN )

   IF Empty( cK ) .OR. Empty( cN )
      cSide := dfPgLicenseFromSidecarFile()
      IF !Empty( cSide )
         RETURN cSide
      ENDIF
   ENDIF

   IF Empty( cK ) .OR. Empty( cN )
      RETURN ""
   ENDIF

RETURN "licensekey=" + cK + ";licensee=" + cN + ";"

*******************************************************************************
//* DbeLoad + DbeSetDefault(PGDBE) + DbeInfo licenza. lRequire=.T.: obbligatorio per DbfUpsize (client license). .F.: come runtime (licenza opzionale se assente).
FUNCTION dfPgDbeConfigurePgdbeLicense( lRequire )
*******************************************************************************
LOCAL cLic, xLicState, lLoaded, bPrevErr, cPrevDefault

   IF ValType( lRequire ) != "L"
      lRequire := .F.
   ENDIF

   //* Controlla se PGDBE e' gia' caricato (es. da DBE.INI via dfDBESet in dbeSys).
   lLoaded := AScan( DbeList(), {|x| Upper(x[1]) == "PGDBE"} ) > 0

   IF ! lLoaded
      bPrevErr := ErrorBlock( {|e| Break(e)} )
      BEGIN SEQUENCE
         lLoaded := DbeLoad( "PGDBE" )
      RECOVER
         lLoaded := .F.
      END SEQUENCE
      ErrorBlock( bPrevErr )
   ENDIF

   IF ! lLoaded
      dbMsgErr( "PostgreSQL: DbeLoad(PGDBE) fallito. Verificare che pgdbe.dll sia nella cartella EXE o nel PATH, e che DbeLoad sia chiamato in dbeSys() o DBE.INI." )
      RETURN .F.
   ENDIF

//* DbeInfo() configura il DBE *corrente*: salvare e ripristinare il default per non alterare il driver attivo.
   cPrevDefault := DbeSetDefault()
   DbeSetDefault( "PGDBE" )

   cLic := dfPgLicenseInfoString()
   IF Empty( cLic )
      DbeSetDefault( cPrevDefault )
      IF lRequire
         dbMsgErr( "PostgreSQL: licenza PGDBE richiesta per DbfUpsize. Impostare PgDbeLicenseKey e PgDbeLicensee in EXE\PgUpsize.ini [UPSIZE] o XbasePgLicenseKey/XbasePgLicensee in [apps], oppure env VDB_PG_LICENSE_KEY e VDB_PG_LICENSEE." )
         RETURN .F.
      ENDIF
      RETURN .T.
   ENDIF

   DbeInfo( COMPONENT_DICTIONARY, PGDIC_LICENSE, cLic )
//* Lettura stato licenza: in alcuni runtime il tipo non e' logico; non bloccare se dubbia.
   xLicState := DbeInfo( COMPONENT_DICTIONARY, PGDIC_LICENSE )
   DbeSetDefault( cPrevDefault )
   IF ValType( xLicState ) == "L" .AND. ! xLicState
      dbMsgErr( "PostgreSQL: licenza PGDBE non valida. Verificare XbasePgLicenseKey e XbasePgLicensee (come su ASI Portal)." )
      RETURN .F.
   ENDIF

RETURN .T.

//* DbfUpsize (verify connection) e DacSession: pwd assente o stringa vuota -> messaggio "requires ... PWD ...".
//* Valore non vuoto obbligatorio; con trust su pg_hba la password e' ignorata. Impostare XbasePgPwd se SCRAM rifiuta lo spazio.
FUNCTION dfPgPwdForDacAndUpsize( cPwd )
   IF ValType( cPwd ) != "C" .OR. Len( cPwd ) < 1
      RETURN " "
   ENDIF
RETURN cPwd

*******************************************************************************
FUNCTION dfPgBuildDacConnectionString()
*******************************************************************************
//* PGDBE (doc Alaska DacSession): DBE=PGDBE;SERVER=...;DB=...;UID=...;PWD=...
RETURN "DBE=PGDBE;SERVER=" + dfPgUpsizeConnSrv() + ";DB=" + dfPgUpsizeConnDatabase() + ";UID=" + dfPgUpsizeConnUid() + ;
       ";PWD=" + dfPgPwdForDacAndUpsize( dfPgUpsizeConnPwd() )

*******************************************************************************
//* Precaricare PGDBE in dbeSys(). DllLoad con path completo prima di DbeLoad (che non cerca nella cartella EXE).
FUNCTION dfPgPreloadDbe()
*******************************************************************************
LOCAL bPrevErr, cFull, nPos, cDir

   cFull := AppName( .T. )
   IF ValType( cFull ) == "C" .AND. !Empty( cFull )
      nPos := RAt( "\", cFull )
      IF nPos > 0
         cDir := Left( cFull, nPos )
         IF File( cDir + "pgdbe.dll" )
            DllLoad( cDir + "pgdbe.dll" )
         ENDIF
      ENDIF
   ENDIF

   bPrevErr := ErrorBlock( {|e| Break(e)} )
   BEGIN SEQUENCE
      DbeLoad( "PGDBE" )
   RECOVER
   END SEQUENCE
   ErrorBlock( bPrevErr )

RETURN NIL

*******************************************************************************
//* Configurare licenza PGDBE prima di dfPgSessionInit() in dbeSys().
FUNCTION dfPgConfigureLicenseEarly()
*******************************************************************************
LOCAL cLic, bPrevErr, lLoaded

   lLoaded := .F.
   bPrevErr := ErrorBlock( {|e| Break(e)} )
   BEGIN SEQUENCE
      lLoaded := DbeLoad( "PGDBE" )
   RECOVER
      lLoaded := .F.
   END SEQUENCE
   ErrorBlock( bPrevErr )

   IF ! lLoaded
      RETURN .F.
   ENDIF

   DbeSetDefault( "PGDBE" )

   cLic := dfPgLicenseInfoString()
   IF !Empty( cLic )
      DbeInfo( COMPONENT_DICTIONARY, PGDIC_LICENSE, cLic )
   ENDIF

   DbeSetDefault( "DBFNTX" )

RETURN .T.

*******************************************************************************
FUNCTION dfPgRuntimeUsePostgres()
*******************************************************************************
LOCAL cEnv, cAct

//* PG runtime: opt-in tramite PgActivateDbeSys=YES in PgUpsize.ini [UPSIZE], dbstart.ini [apps], o env VDB_PG_ACTIVATE_DBESYS.
//* NON richiede piu' XbaseReplaceDatabaseDriver=PGDBE in dbstart.ini (l'IDE rigenera quel file e rimuove le chiavi custom;
//* inoltre ddUpdDbf() legge quella chiave e prova ad usare PGDBE per DBDD, che fallisce con BASE/8015).
//* dfPgUpsizeIniUpsizeOnly -> dfPgPgUpsizeIniPath -> dfPgFindPgUpsizeIniEarly (AppName) funziona anche in dbeSys().

   cAct := Upper( AllTrim( dfPgUpsizeIniUpsizeOnly( "PgActivateDbeSys" ) ) )
   IF cAct == "YES" .OR. cAct == "1" .OR. cAct == "TRUE"
      RETURN .T.
   ENDIF

   cAct := Upper( AllTrim( dfVdbIniAppsString( "XbasePgActivateDbeSys", "" ) ) )
   IF cAct == "YES" .OR. cAct == "1" .OR. cAct == "TRUE"
      RETURN .T.
   ENDIF

   cEnv := Upper( AllTrim( GetEnv( "VDB_PG_ACTIVATE_DBESYS" ) ) )
   IF cEnv == "1" .OR. cEnv == "YES" .OR. cEnv == "TRUE"
      RETURN .T.
   ENDIF

RETURN .F.

*******************************************************************************
//* Trova PgUpsize.ini senza dipendere dal framework (File() funziona in dbeSys).
STATIC FUNCTION dfPgFindPgUpsizeIniEarly()
*******************************************************************************
LOCAL aPaths, i, cExeDir, cTry

   cExeDir := dfPgExeDirectory()
   IF !Empty( cExeDir )
      cTry := cExeDir + "PgUpsize.ini"
      IF File( cTry )
         RETURN cTry
      ENDIF
   ENDIF

   aPaths := { "PgUpsize.ini", "EXE\PgUpsize.ini", "..\EXE\PgUpsize.ini" }
   FOR i := 1 TO Len( aPaths )
      IF File( aPaths[i] )
         RETURN aPaths[i]
      ENDIF
   NEXT

RETURN ""

*******************************************************************************
//* Directory dell'eseguibile (con trailing backslash) — disponibile subito, anche in dbeSys().
FUNCTION dfPgExeDirectory()
*******************************************************************************
LOCAL cFull, nPos

   cFull := AppName( .T. )
   IF ValType( cFull ) != "C" .OR. Empty( cFull )
      RETURN ""
   ENDIF

   nPos := RAt( "\", cFull )
   IF nPos == 0
      nPos := RAt( "/", cFull )
   ENDIF
   IF nPos > 0
      RETURN Left( cFull, nPos )
   ENDIF

RETURN ""

*******************************************************************************
//* Imposta il path del template upsize per la risoluzione di PgUpsize.ini (solo durante BuildRuntimeCfg / AfterUpd).
PROCEDURE dfPgUpsizeSetTemplateForIni( cPath )
*******************************************************************************

   IF ValType( cPath ) == "C"
      s_cPgUpsizeTemplateForIni := cPath
   ELSE
      s_cPgUpsizeTemplateForIni := ""
   ENDIF

RETURN
