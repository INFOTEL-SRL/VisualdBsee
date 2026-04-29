/******************************************************************************
  Parser minimale dbstart.ini (path, [apps], sezioni) e I/O file testo.
  Anche path upsize: dfPgUpsizeCfgDirectory (parent dir) e dfPgUpsizeEnsureTrailSlash.
  Modulo separato da pgUpsize; linkare per primo nella coda PG.
******************************************************************************/
#INCLUDE "Common.ch"
#INCLUDE "DFCLPSUP.CH"
#INCLUDE "Fileio.ch"

STATIC FUNCTION dfVdbParentDirFromPath( cCfg )
LOCAL n
   IF ValType( cCfg ) != "C" .OR. Empty( cCfg )
      RETURN ""
   ENDIF
   n := RAt( "\", cCfg )
   IF n < 1
      n := RAt( "/", cCfg )
   ENDIF
   IF n < 1
      RETURN ""
   ENDIF
RETURN Left( cCfg, n )

*******************************************************************************
FUNCTION dfVdbReadWholeFile( cFile )
*******************************************************************************
LOCAL nH, nSz, cBuf

   IF ValType( cFile ) != "C" .OR. Empty( cFile ) .OR. !File( cFile )
      RETURN ""
   ENDIF

   nH := FOpen( cFile, FO_READ + FO_DENYNONE )
   IF nH < 0
      RETURN ""
   ENDIF

   nSz := FSeek( nH, 0, FS_END )
   FSeek( nH, 0, FS_SET )
   cBuf := Space( Max( nSz, 0 ) )

   IF nSz > 0
      FRead( nH, @cBuf, nSz )
   ENDIF

   FClose( nH )

RETURN cBuf

*******************************************************************************
FUNCTION dfVdbWriteWholeFile( cFile, cBody )
*******************************************************************************
LOCAL nH, nW, nLen

   IF ValType( cFile ) != "C" .OR. Empty( cFile ) .OR. ValType( cBody ) != "C"
      RETURN .F.
   ENDIF

   nLen := Len( cBody )
   nH   := FCreate( cFile, FC_NORMAL )
   IF nH < 0
      RETURN .F.
   ENDIF

   nW := FWrite( nH, cBody, nLen )
   FClose( nH )

RETURN ( nW == nLen )
//* Da una directory qualsiasi sotto il progetto, trova ...\EXE\dbstart.ini risalendo (CurDir spesso non e' piu' la cartella dell'EXE dopo dfSet e il framework).
FUNCTION dfVdbIniWalkUpForExeDbstart()
LOCAL c, n

   c := RTrim( CurDir() )
   IF ValType( c ) != "C" .OR. Empty( c )
      RETURN ""
   ENDIF

   DO WHILE .T.
      IF File( c + "\EXE\dbstart.ini" )
         RETURN c + "\EXE\dbstart.ini"
      ENDIF
      n := RAt( "\", c )
      IF n < 2
         EXIT
      ENDIF
      c := Left( c, n - 1 )
      IF Len( c ) < 4
         EXIT
      ENDIF
   ENDDO

RETURN ""

*******************************************************************************
FUNCTION dfVdbIniBesideSourceFolder()
LOCAL c

   c := RTrim( CurDir() )
   IF ValType( c ) != "C" .OR. Empty( c )
      RETURN ""
   ENDIF

   IF Upper( Right( c, 7 ) ) == "\SOURCE"
      IF File( Left( c, Len( c ) - 7 ) + "\EXE\dbstart.ini" )
         RETURN Left( c, Len( c ) - 7 ) + "\EXE\dbstart.ini"
      ENDIF
   ENDIF

   IF Upper( Right( c, 4 ) ) == "\EXE"
      IF File( c + "\dbstart.ini" )
         RETURN c + "\dbstart.ini"
      ENDIF
   ENDIF

RETURN ""

*******************************************************************************
//* dbstart.ini nella stessa cartella (o EXE\\) del file dfInitName(): CurDir puo' essere System32 o altro e la walk da CurDir non trova mai EXE\\dbstart.ini.
STATIC FUNCTION dfVdbIniBesideInitName()
*******************************************************************************
LOCAL cApp, cBase, n, cTry

   cApp := dfInitName()
   IF ValType( cApp ) != "C" .OR. Empty( cApp )
      RETURN ""
   ENDIF

   cBase := dfVdbParentDirFromPath( cApp )
   IF Empty( cBase )
      RETURN ""
   ENDIF

   cTry := cBase + "dbstart.ini"
   IF File( cTry )
      RETURN cTry
   ENDIF

   cTry := cBase + "EXE\dbstart.ini"
   IF File( cTry )
      RETURN cTry
   ENDIF

   n := RAt( "\SOURCE\", Lower( cBase ) )
   IF n > 1
      cTry := Left( cBase, n - 1 ) + "EXE\dbstart.ini"
      IF File( cTry )
         RETURN cTry
      ENDIF
   ENDIF

RETURN ""

*******************************************************************************
FUNCTION dfVdbIniFullPath()
*******************************************************************************
LOCAL cIni, cDir, aRel, i, cEnv, cWalk

   cEnv := AllTrim( GetEnv( "VDB_DBSTART_INI" ) )
   IF ValType( cEnv ) == "C" .AND. !Empty( cEnv ) .AND. File( cEnv )
      RETURN cEnv
   ENDIF

   cIni := dfVdbIniBesideInitName()
   IF !Empty( cIni )
      RETURN cIni
   ENDIF

   cWalk := dfVdbIniWalkUpForExeDbstart()
   IF !Empty( cWalk )
      RETURN cWalk
   ENDIF

   cWalk := dfVdbIniBesideSourceFolder()
   IF !Empty( cWalk )
      RETURN cWalk
   ENDIF

   cDir := CurDir()
   IF ValType( cDir ) != "C" .OR. Empty( cDir )
      cDir := ""
   ELSE
      cDir := RTrim( cDir )
      IF !( Right( cDir, 1 ) == "\" .OR. Right( cDir, 1 ) == "/" )
         cDir += "\"
      ENDIF
   ENDIF

   aRel := { ;
      "dbstart.ini", ;
      "EXE\dbstart.ini", ;
      "..\EXE\dbstart.ini", ;
      "..\..\EXE\dbstart.ini" ;
      }

   FOR i := 1 TO Len( aRel )
      IF !Empty( cDir ) .AND. File( cDir + aRel[i] )
         RETURN cDir + aRel[i]
      ENDIF
   NEXT

   cIni := dfInitName()
   IF ValType( cIni ) == "C" .AND. !Empty( cIni ) .AND. File( cIni )
      RETURN cIni
   ENDIF

RETURN ""

*******************************************************************************
FUNCTION dfVdbIniAppsString( cKey, cDefault )
*******************************************************************************
LOCAL cIni, cAll, cSeek, nPos, cLine, lApps := .F., nEq, cK

   IF ValType( cKey ) != "C" .OR. Empty( cKey )
      RETURN IIF( ValType( cDefault ) == "C", cDefault, "" )
   ENDIF

   cIni := dfVdbIniFullPath()
   IF Empty( cIni )
      RETURN IIF( ValType( cDefault ) == "C", cDefault, "" )
   ENDIF

   cAll := dfVdbReadWholeFile( cIni )
   IF Empty( cAll )
      RETURN IIF( ValType( cDefault ) == "C", cDefault, "" )
   ENDIF

   cSeek := cAll

   DO WHILE Len( cSeek ) > 0
      nPos := At( Chr( 10 ), cSeek )
      IF nPos < 1
         cLine := cSeek
         cSeek := ""
      ELSE
         cLine := Left( cSeek, nPos - 1 )
         cSeek := SubStr( cSeek, nPos + 1 )
      ENDIF

      cLine := StrTran( cLine, Chr( 13 ), "" )
      cLine := RTrim( LTrim( cLine ) )

      IF Empty( cLine )
         LOOP
      ENDIF

      IF Left( cLine, 1 ) == ";"
         LOOP
      ENDIF

      IF Left( cLine, 1 ) == "["
         lApps := Upper( cLine ) == "[APPS]"
         LOOP
      ENDIF

      IF !lApps
         LOOP
      ENDIF

      nEq := At( "=", cLine )
      IF nEq < 1
         LOOP
      ENDIF

      cK := Upper( AllTrim( Left( cLine, nEq - 1 ) ) )
      IF cK == Upper( AllTrim( cKey ) )
         RETURN AllTrim( SubStr( cLine, nEq + 1 ) )
      ENDIF
   ENDDO

RETURN IIF( ValType( cDefault ) == "C", cDefault, "" )

*******************************************************************************
FUNCTION dfVdbIniSectionStringInFile( cIniPath, cSection, cKey, cDefault )
*******************************************************************************
LOCAL cAll, cSeek, nPos, cLine, lIn := .F., nEq, cK, cSecU

   IF ValType( cIniPath ) != "C" .OR. Empty( cIniPath ) .OR. !File( cIniPath )
      RETURN IIF( ValType( cDefault ) == "C", cDefault, "" )
   ENDIF

   IF ValType( cSection ) != "C" .OR. Empty( cSection ) .OR. ValType( cKey ) != "C" .OR. Empty( cKey )
      RETURN IIF( ValType( cDefault ) == "C", cDefault, "" )
   ENDIF

   cSecU := "[" + Upper( AllTrim( cSection ) ) + "]"

   cAll := dfVdbReadWholeFile( cIniPath )
   IF Empty( cAll )
      RETURN IIF( ValType( cDefault ) == "C", cDefault, "" )
   ENDIF

   cSeek := cAll

   DO WHILE Len( cSeek ) > 0
      nPos := At( Chr( 10 ), cSeek )
      IF nPos < 1
         cLine := cSeek
         cSeek := ""
      ELSE
         cLine := Left( cSeek, nPos - 1 )
         cSeek := SubStr( cSeek, nPos + 1 )
      ENDIF

      cLine := StrTran( cLine, Chr( 13 ), "" )
      cLine := RTrim( LTrim( cLine ) )

      IF Empty( cLine )
         LOOP
      ENDIF

      IF Left( cLine, 1 ) == ";"
         LOOP
      ENDIF

      IF Left( cLine, 1 ) == "["
         lIn := Upper( AllTrim( cLine ) ) == cSecU
         LOOP
      ENDIF

      IF !lIn
         LOOP
      ENDIF

      nEq := At( "=", cLine )
      IF nEq < 1
         LOOP
      ENDIF

      cK := Upper( AllTrim( Left( cLine, nEq - 1 ) ) )
      IF cK == Upper( AllTrim( cKey ) )
         RETURN AllTrim( SubStr( cLine, nEq + 1 ) )
      ENDIF
   ENDDO

RETURN IIF( ValType( cDefault ) == "C", cDefault, "" )

*******************************************************************************
FUNCTION dfVdbIniSectionString( cSection, cKey, cDefault )
*******************************************************************************
LOCAL cIni

   cIni := dfVdbIniFullPath()
   IF Empty( cIni )
      RETURN IIF( ValType( cDefault ) == "C", cDefault, "" )
   ENDIF

RETURN dfVdbIniSectionStringInFile( cIni, cSection, cKey, cDefault )

*******************************************************************************
FUNCTION dfVdbReplaceDatabaseDriver()
*******************************************************************************
RETURN Upper( AllTrim( dfVdbIniAppsString( "XbaseReplaceDatabaseDriver", "DBFCDX" ) ) )

*******************************************************************************
FUNCTION dfPgUpsizeCfgDirectory( cCfg )
*******************************************************************************
RETURN dfVdbParentDirFromPath( cCfg )

*******************************************************************************
FUNCTION dfPgUpsizeEnsureTrailSlash( cPath )
*******************************************************************************

   IF ValType( cPath ) != "C" .OR. Empty( cPath )
      RETURN ""
   ENDIF

   cPath := RTrim( cPath )
   IF !( Right( cPath, 1 ) == "\" .OR. Right( cPath, 1 ) == "/" )
      cPath += "\"
   ENDIF

RETURN cPath

