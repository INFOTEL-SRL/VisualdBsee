//*****************************************************************************
//Progetto       : dBsee 4.0
//Descrizione    : Funzioni di utilita' per FILE
//Programmatore  : Baccan Matteo
//*****************************************************************************
#include "Common.ch"
#include "dfmsg.ch"
#include "dfstd.ch"
#include "dfset.ch"
#include "Fileio.ch"

STATIC _cDdDbddNdxFieldChk := ""

// Debug finestre ricerca (solo file ddwin_dbg.log): dbstart.ini XbaseDdWinDebug=YES o VDB_DDWIN_DEBUG=YES
FUNCTION _ddWinDbgOn()
LOCAL cV := ""

   IF GetEnv( "VDB_DDWIN_DEBUG" ) == "YES"
      RETURN .T.
   ENDIF

   cV := dfSet( "XbaseDdWinDebug" )
   IF VALTYPE( cV ) != "C"
      cV := ""
   ENDIF
   IF UPPER( ALLTRIM( cV ) ) == "YES"
      RETURN .T.
   ENDIF

   // Lettura diretta dbstart.ini (non dipende da dfSet gia' popolato)
   IF TYPE( "dfVdbIniAppsString" ) != "U"
      cV := dfVdbIniAppsString( "XbaseDdWinDebug", "" )
   ELSE
      cV := ""
   ENDIF
   IF UPPER( ALLTRIM( cV ) ) == "YES"
      RETURN .T.
   ENDIF

RETURN .F.

STATIC FUNCTION _ddWinDbgPaths()
LOCAL aRet := {}, cIni, cBase, n, cDir, cPg

   IF TYPE( "dfInitName" ) != "U"
      cBase := RTRIM( dfInitName() )
      IF ! EMPTY( cBase )
         n := RAT( "\", cBase )
         IF n < 1
            n := RAT( "/", cBase )
         ENDIF
         IF n > 0
            AADD( aRet, LEFT( cBase, n ) + "ddwin_dbg.log" )
         ENDIF
      ENDIF
   ENDIF

   IF TYPE( "dfVdbIniFullPath" ) != "U"
      cIni := dfVdbIniFullPath()
      IF ! EMPTY( cIni )
         n := RAT( "\", cIni )
         IF n < 1
            n := RAT( "/", cIni )
         ENDIF
         IF n > 0
            AADD( aRet, LEFT( cIni, n ) + "ddwin_dbg.log" )
         ENDIF
      ENDIF
   ENDIF

   IF TYPE( "dfPgExeDirectory" ) != "U"
      cPg := RTRIM( dfPgExeDirectory() )
      IF ! EMPTY( cPg )
         IF RIGHT( cPg, 1 ) != "\"
            cPg += "\"
         ENDIF
         AADD( aRet, cPg + "ddwin_dbg.log" )
      ENDIF
   ENDIF

   cDir := RTRIM( CurDir() )
   IF ! EMPTY( cDir )
      IF RIGHT( cDir, 1 ) != "\"
         cDir += "\"
      ENDIF
      AADD( aRet, cDir + "ddwin_dbg.log" )
   ENDIF

   AADD( aRet, "ddwin_dbg.log" )

RETURN aRet

PROCEDURE _ddWinDbgLog( cMsg )
LOCAL aPath, nH, cPath, cLine, bSav, i

   cLine := DTOC( DATE() ) + " " + TIME() + " " + cMsg + Chr( 13 ) + Chr( 10 )
   aPath := _ddWinDbgPaths()
   bSav  := ErrorBlock( {|| .T. } )

   FOR i := 1 TO LEN( aPath )
      cPath := aPath[i]
      BEGIN SEQUENCE
         nH := FOPEN( cPath, FO_READWRITE + FO_SHARED )
         IF nH < 0
            nH := FCREATE( cPath )
         ELSE
            FSEEK( nH, 0, 2 )
         ENDIF
         IF nH >= 0
            FWRITE( nH, cLine )
            FCLOSE( nH )
         ENDIF
      RECOVER
      END SEQUENCE
   NEXT

   ErrorBlock( bSav )

RETURN

PROCEDURE _ddWinDbgMsg( cMsg )

   IF ! _ddWinDbgOn()
      RETURN
   ENDIF

   _ddWinDbgLog( cMsg )

RETURN

STATIC FUNCTION _ddDbddNdxBlockIsAlias( cAlias )
LOCAL cStem, cBlk

   cStem := UPPER( RTRIM( cAlias ) )
   cBlk  := UPPER( RTRIM( dbdd->RecTyp + dbdd->file_name ) )

   IF EMPTY( cStem )
      RETURN .F.
   ENDIF

   IF cBlk == "NDX" + PADR( cStem, 8 )
      RETURN .T.
   ENDIF

   IF "NDX" + cStem $ cBlk
      RETURN .T.
   ENDIF

RETURN .F.

* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION ddFilePos( cFile, lErrMsg )
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
LOCAL lRet := .T.

DEFAULT lErrMsg TO .T.

cFile:=UPPER(PADR(cFile,8))    // Normalizza il FILE
dbdd->(DBSEEK( "DBF"+cFile ))  // Posiziono il file su dBdd
IF !dbdd->(FOUND())
   IF lErrMsg
      dbMsgErr( dfStdMsg(MSG_DDUSE01)+cFile)
   ENDIF
   lRet := .F.
ENDIF
RETURN lRet

* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION ddFileDriver()
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
LOCAL cDriver := UPPER(ALLTRIM(dbdd->Field_Name))
IF EMPTY(cDriver) .OR. ASCAN( RDDLIST(), {|cSubDriver|cSubDriver==cDriver} )==0
   cDriver := RDDSETDEFAULT()
ENDIF
RETURN cDriver        // Driver

* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION ddFileName()
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
LOCAL cFile := "", cVarName
DO CASE
   CASE EMPTY(dbdd->file_ali)                  // alias non impostato in dBsee
        cFile := dbdd->file_name               // prendo il NOME

   CASE LEFT(dbdd->file_ali,1) == "@"          // nome da variabile
        cVarName := SUBSTR(dbdd->File_Ali,2)   // la prendo
        IF TYPE( cVarName ) # "C"              // controllo il tipo
           dbMsgErr( dfStdMsg(MSG_DDUSE02) +TRIM(dbdd->file_name)+"//"+;
                     dfStdMsg(MSG_DDUSE03) +cVarName       )
        ELSE
           cFile := &cVarName                  // NOME
        ENDIF

   OTHERWISE
        cFile := dbdd->file_ali                // NOME
ENDCASE
RETURN UPPER(ALLTRIM(cFile))                   // Nome del File

* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION ddFileIsTab()
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
RETURN dbdd->FILE_TYP=="1"                     // E' tabella

* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION ddFilePath()
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
LOCAL cPath 

// simone 13/11/06 
// mantis 0001165: aggiungere possibilitï¿½ di mappare un singolo dbf in un path specifico
cPath := dfSet("UserPath_"+ALLTRIM(dbdd->file_name))
IF EMPTY(cPath)
   cPath := dbDbfPath(VAL(dbdd->File_Path)) // Path del file da dbstart.ini
ELSEIF LEFT(cPath, 1)=="@"
   cPath := dbDbfPath(VAL(SUBSTR(cPath, 2))) // Path del file formato UserPath_NOMEDBF=@12 = 12ï¿½path da dbstart.ini
ELSE
   cPath := dfPathChk(cPath)                 // Path del file formato UserPath_NOMEDBF=c:\pippo
ENDIF
IF dfASDriver( ddFileDriver() )                // Se e' un file su AS400
   cPath := LEFT( cPath, LEN(cPath)-1 )           // Rimuovo lo slash \ finale
   IF RIGHT(cPath,1)#":" .AND. LEN(cPath)>1       // Se ho un path
      cPath += ":"                                   // Aggiungo i : finali
   ENDIF
ENDIF
RETURN cPath

* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION ddFilePathNum()
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
  LOCAL xRet := dbdd->File_Path
  IF dfIsDigit(Alltrim(xRet)) 
     xRet := VAL(Alltrim(xRet))
  ELSE 
     xRet := 0
  ENDIF 
RETURN xRet

* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION ddFileDACConnID()
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
LOCAL cPath
LOCAL cID
LOCAL nPath

// simone 13/11/06
// mantis 0001165: aggiungere possibilitï¿½ di mappare un singolo dbf in un path specifico
cPath := dfSet("UserPath_"+ALLTRIM(dbdd->file_name))
IF EMPTY(cPath)
   nPath := VAL(dbdd->File_Path)
ELSEIF LEFT(cPath, 1)=="@"
   nPath := (VAL(SUBSTR(cPath, 2))) // Path del file formato UserPath_NOMEDBF=@12 = 12ï¿½path da dbstart.ini
ENDIF
IF nPath == NIL
   RETURN NIL
ENDIF
RETURN dfDACConnIDBuild(nPath)



* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION ddFileDesc()
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
LOCAL cName := dbdd->Field_des
IF EMPTY(cName)
   cName := dbdd->File_Name
ENDIF
RETURN ALLTRIM(cName)

* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION ddIndexExp()                          // Espressione di Indice
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
   LOCAL cNdxExp
   LOCAL cKey

   IF ! dfSet(AI_INDEXSTRUCTDYN) // funzionamento standard?
      // Simone 29/3/07
      // mantis 0001215: se la struttura di un indice ï¿½ troppo lunga in creazione indice si possono avere errori runtime o indici errati
      RETURN ALLTRIM(dbdd->Field_Pic) +ALLTRIM(dbdd->Field_Pico)
   ENDIF


   // Simone 29/3/07
   // mantis 0001215: se la struttura di un indice ï¿½ troppo lunga in creazione indice si possono avere errori runtime o indici errati
   // ricalcolo la chiave dai singoli campi
   cNdxExp := ""

   dbdd->(dfPushArea())
   cKey := UPPER("key"+dbdd->FILE_NAME+STR(dbdd->NDXINCN, 3, 0))

   dbdd->(dfS(1, cKey ))
   DO WHILE ! dbdd->(EOF()) .AND. ;
            UPPER(dbdd->RECTYP+dbdd->FILE_NAME+STR(dbdd->NDXINCN, 3, 0)) == cKey
            //Mantis 1665. Luca 29/11/2007
            //UPPER("key"+dbdd->FILE_NAME+STR(dbdd->NDXINCN, 3, 0)) == cKey

      IF ! EMPTY(dbdd->SLOT)
         cNdxExp += "+"+ALLTRIM(dbdd->SLOT)
      ENDIF

      dbdd->(dbSkip())
   ENDDO
   dbdd->(dfPopArea())

   cNdxExp := SUBSTR(cNdxExp, 2) // salto "+" iniziale

   IF ! EMPTY(dbdd->FIELD_MSG)
      cNdxExp  := tStrTran(Alltrim(dbdd->FIELD_MSG) ,;
                           Alltrim(cNdxExp) )
   ENDIF
RETURN cNdxExp

// funzione tStrTran()
// presa da sorgenti Visual dBsee file TF.PRG
*******************************************************************************
STATIC FUNCTION tStrTran(      ; // SOSTITUISCE NELLA STRINGA1 IL % CON LA STRINGA2
                   cS1 ,; // Stringa 1
                   cS2 ,; // Stringa 2
                   cS3 ,; // Stringa 3  (Opzionale)
                   cS4  ) // Stringa 4  (Opzionale)

// esempio nr. 1:
//          cExp := tStrTran( cKeyExp ,alltrim(dd_sym->SYM_NAM) )
//  con  ckeyExp = "upper(%)"

// esempio nr. 2:
//          cExp := tStrTran( cKeyExp, alltrim(dd_sym->SYM_NAM), alltrim(str(dd_sym->SYM_LEN)), alltrim(str(dd_sym->SYM_DEC)) )
//  con  ckeyExp = "str(%N, %L, %D)"

*******************************************************************************
LOCAL cRet := ""

IF EMPTY( cS1 ); RETURN cS2; ENDIF
//## 12/12/96 Matteo ottimizzato
IF !("%"$cS1)  ; RETURN cS1; ENDIF

DEFAULT cS3 TO ""
DEFAULT cS4 TO ""

IF "%N" $ cS1 
   cS1 := StrTran( cS1 ,"%N" ,cS2 )
ENDIF
IF "%L" $ cS1
   cS1 := StrTran( cS1 ,"%L" ,cS3 )
ENDIF
IF "%D" $ cS1
   cS1 := StrTran( cS1 ,"%D" ,cS4 )
ENDIF
IF "%n" $ cS1 
   cS1 := StrTran( cS1 ,"%n" ,cS2 )
ENDIF
IF "%l" $ cS1
   cS1 := StrTran( cS1 ,"%l" ,cS3 )
ENDIF
IF "%d" $ cS1
   cS1 := StrTran( cS1 ,"%d" ,cS4 )
ENDIF
IF "%" $ cS1
   cS1 := StrTran( cS1 ,"%" ,cS2 )
ENDIF
RETURN cS1



* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION _ddDbddSeekRecTyp( cPrefix, cAlias )
LOCAL cKey, nSavDbddOrd, lRet := .F.

   IF SELECT( "dbdd" ) == 0
      RETURN .F.
   ENDIF

   nSavDbddOrd := 0
   IF dbdd->( ORDCOUNT() ) > 0
      nSavDbddOrd := dbdd->( INDEXORD() )
      dbdd->( ORDSETFOCUS( 1 ) )
   ENDIF

   cAlias := UPPER( PADR( cAlias, 8 ) )
   cKey   := UPPER( PADR( cPrefix, 3 ) ) + cAlias

   IF dbdd->( ORDCOUNT() ) > 0
      IF dbdd->( DBSEEK( cKey ) )
         lRet := .T.
      ENDIF
   ENDIF

   IF ! lRet
      dbdd->( DBGOTOP() )
      DO WHILE ! dbdd->( EOF() )
         IF UPPER( dbdd->RecTyp + dbdd->file_name ) == cKey
            lRet := .T.
            EXIT
         ENDIF
         dbdd->( DBSKIP() )
      ENDDO
   ENDIF

   IF nSavDbddOrd > 0
      dbdd->( ORDSETFOCUS( nSavDbddOrd ) )
   ENDIF

RETURN lRet

// NdxIncN vuoto in DBDD legacy: slot in FILE_ALI (es. "1CLIFOR1", "2CLIFOR2", "ARTIC2")
FUNCTION _ddDbddNdxSlotFromRow( cAlias )
LOCAL n, cFA, cStem, cTail

   n := VAL( STR( dbdd->NdxIncN ) )
   IF n > 0
      RETURN n
   ENDIF

   cFA := ALLTRIM( dbdd->FILE_ALI )
   IF EMPTY( cFA ) .OR. LEFT( cFA, 1 ) == "@"
      RETURN 0
   ENDIF

   IF dfIsDigit( LEFT( cFA, 1 ) )
      n := VAL( LEFT( cFA, 1 ) )
      IF n > 0
         RETURN n
      ENDIF
   ENDIF

   n := VAL( cFA )
   IF n > 0
      RETURN n
   ENDIF

   cStem := UPPER( RTRIM( cAlias ) )
   IF LEN( cFA ) > LEN( cStem )
      cTail := SUBSTR( cFA, LEN( cStem ) + 1 )
      n := VAL( cTail )
      IF n > 0
         RETURN n
      ENDIF
   ENDIF

   n := VAL( STRTRAN( UPPER( cFA ), cStem, "" ) )
   IF n > 0
      RETURN n
   ENDIF

RETURN 0

// Riga KEY: FILE_ALI spesso "1"/"2" (NdxIncN vuoto)
FUNCTION _ddDbddKeyRowSlot( cAlias )
LOCAL n

   n := VAL( ALLTRIM( dbdd->FILE_ALI ) )
   IF n > 0
      RETURN n
   ENDIF

RETURN _ddDbddNdxSlotFromRow( cAlias )

STATIC FUNCTION _ddDbddFieldValU( cWa, cField )
LOCAL nPos, xVal

   IF SELECT( cWa ) < 1 .OR. EMPTY( cField )
      RETURN ""
   ENDIF

   IF dfPgRddIs( ( cWa )->( RDDNAME() ) )
      RETURN dfPgSeekFieldValU( PADR( cWa, 8 ), cField )
   ENDIF

   nPos := ( cWa )->( FIELDPOS( cField ) )
   IF nPos < 1
      RETURN ""
   ENDIF

   xVal := ( cWa )->( FIELDGET( nPos ) )
   IF VALTYPE( xVal ) == "C" .OR. VALTYPE( xVal ) == "M"
      RETURN UPPER( RTRIM( xVal ) )
   ENDIF

RETURN UPPER( RTRIM( dfAny2Str( xVal, "" ) ) )

STATIC FUNCTION _ddDbddFieldHasNeedle( cWa, cField, cNeedle )
LOCAL cU, cV

   cU := UPPER( RTRIM( cNeedle ) )
   IF EMPTY( cU )
      RETURN .F.
   ENDIF

   cV := _ddDbddFieldValU( cWa, cField )
   RETURN cU $ cV .OR. AT( cU, cV ) > 0

STATIC FUNCTION _ddDbddRowPassFilter( bFilter, bBreak )

   IF VALTYPE( bBreak ) == "B" .AND. EVAL( bBreak )
      RETURN .F.
   ENDIF

   IF VALTYPE( bFilter ) == "B" .AND. ! EVAL( bFilter )
      RETURN .F.
   ENDIF

RETURN .T.

// ddKey campo C: soft seek poi prima riga che contiene la stringa (non solo uguale)
FUNCTION _ddDbddKeySeekContains( cAlias, nSlot, cNeedle, cField, bFilter, bBreak )
LOCAL cWa, nSav, lOk := .F.

   cWa := UPPER( ALLTRIM( cAlias ) )
   IF SELECT( cWa ) == 0 .OR. EMPTY( RTRIM( cNeedle ) ) .OR. EMPTY( cField )
      RETURN .F.
   ENDIF

   nSav := ( cWa )->( RECNO() )
   _ddDbddOrdSetFocus( cWa, nSlot )
   ( cWa )->( dfS( nSlot, cNeedle, .T. ) )

   DO WHILE ! ( cWa )->( EOF() )
      IF _ddDbddRowPassFilter( bFilter, bBreak ) .AND. ;
         _ddDbddFieldHasNeedle( cWa, cField, cNeedle )
         lOk := .T.
         EXIT
      ENDIF
      ( cWa )->( DBSKIP() )
   ENDDO

   IF ! lOk
      ( cWa )->( DBGOTOP() )
      DO WHILE ! ( cWa )->( EOF() )
         IF _ddDbddRowPassFilter( bFilter, bBreak ) .AND. ;
            _ddDbddFieldHasNeedle( cWa, cField, cNeedle )
            lOk := .T.
            EXIT
         ENDIF
         ( cWa )->( DBSKIP() )
      ENDDO
   ENDIF

   IF ! lOk
      ( cWa )->( DBGOTO( nSav ) )
   ENDIF

RETURN lOk

// ddKey: seek riuscita e record coerente (PG: verifica campo, non macro NDX_PIC)
FUNCTION _ddDbddKeySeekOk( cAlias, nSlot, uKeyVal, cKeyExp, lFound )
LOCAL cWa, cFld, cKeyU, uFld

   IF ! lFound .OR. ( cAlias )->( EOF() )
      RETURN .F.
   ENDIF

   IF EMPTY( uKeyVal )
      RETURN .T.
   ENDIF

   cWa := UPPER( ALLTRIM( cAlias ) )
   IF dfPgRddIs( ( cWa )->( RDDNAME() ) )
      cFld := dfPgOrdResolveField( UPPER( ALLTRIM( ( cWa )->( ORDKEY() ) ) ), nSlot, uKeyVal )
      IF ! EMPTY( cFld )
         RETURN dfPgSeekVerifyRow( PADR( cWa, 8 ), cFld, uKeyVal )
      ENDIF
      RETURN .T.
   ENDIF

   cKeyU := UPPER( RTRIM( dfAny2Str( uKeyVal, "" ) ) )
   IF VALTYPE( cKeyExp ) == "C" .AND. ! ( "+" $ cKeyExp .OR. "-" $ cKeyExp )
      uFld := ( cWa )->( &cKeyExp )
      RETURN UPPER( RTRIM( dfAny2Str( uFld, "" ) ) ) == cKeyU
   ENDIF

RETURN .T.

STATIC FUNCTION _ddDbddFileAliU()
LOCAL cFA

   cFA := ALLTRIM( dbdd->FILE_ALI )
   IF LEFT( cFA, 1 ) == "@"
      IF TYPE( SUBSTR( cFA, 2 ) ) == "C"
         RETURN UPPER( ALLTRIM( &SUBSTR( cFA, 2 ) ) )
      ENDIF
   ENDIF

RETURN UPPER( cFA )

STATIC FUNCTION _ddDbddNdxFieldChkTake()
LOCAL cRet := _cDdDbddNdxFieldChk

   _cDdDbddNdxFieldChk := ""
RETURN cRet

STATIC FUNCTION _ddPgOrdIsSystem( cOrdName )
LOCAL cU

   IF VALTYPE( cOrdName ) != "C"
      RETURN .F.
   ENDIF

   cU := UPPER( ALLTRIM( cOrdName ) )

   IF EMPTY( cU )
      RETURN .F.
   ENDIF

   * Indici utente upsize: tabella_campo_4seek / _4like — non sono di sistema
   * (INDEXKEY puo' contenere la parola __record nell'espressione: non usare "__" $ cU)
   IF "_4SEEK" $ cU .OR. "_4LIKE" $ cU
      RETURN .F.
   ENDIF

   IF "__RECORD" $ cU .OR. "__DELETED" $ cU
      RETURN .T.
   ENDIF

   IF RIGHT( cU, 5 ) == "_PKEY"
      RETURN .T.
   ENDIF

RETURN .F.

STATIC FUNCTION _ddDbddKeyFirstField( cAlias, nNdxInc, cFileName )
LOCAL cKey, cFld := "", nSavRec, nNdx, cFn

   DEFAULT cFileName TO ""

   IF SELECT( "dbdd" ) == 0 .OR. nNdxInc < 1
      RETURN ""
   ENDIF

   nNdx := nNdxInc
   cFn  := UPPER( RTRIM( cFileName ) )
   IF EMPTY( cFn )
      cFn := UPPER( PADR( cAlias, 8 ) )
   ENDIF
   cKey := "KEY" + UPPER( RTRIM( cFn ) ) + STR( nNdx, 3, 0 )

   nSavRec := dbdd->( RECNO() )
   IF dbdd->( DBSEEK( cKey ) )
      cFld := ALLTRIM( dbdd->field_name )
   ELSE
      cKey := "KEY" + cFn + STR( nNdx, 3 )
      IF dbdd->( DBSEEK( cKey ) )
         cFld := ALLTRIM( dbdd->field_name )
      ENDIF
   ENDIF

   IF nSavRec > 0
      dbdd->( DBGOTO( nSavRec ) )
   ENDIF

RETURN UPPER( cFld )

STATIC FUNCTION _ddPgFieldFromOrdTag( cTag )
LOCAL cU, n

   cU := LOWER( ALLTRIM( cTag ) )
   IF RIGHT( cU, 6 ) == "_4seek"
      cU := LEFT( cU, LEN( cU ) - 6 )
   ELSEIF RIGHT( cU, 6 ) == "_4like"
      cU := LEFT( cU, LEN( cU ) - 6 )
   ENDIF

   n := AT( "_", cU )
   IF n > 0
      RETURN SUBSTR( cU, n + 1 )
   ENDIF

RETURN ""

//* Slot utente DBDD (W_ORDER 1,2,…) -> nome campo PG per ORDER BY (non KEY001 grezzo)
FUNCTION _ddDbddFieldForUserSlot( cAlias, nUserSlot )
LOCAL cFld := "", cTag

   IF SELECT( "dbdd" ) == 0 .OR. nUserSlot < 1
      RETURN ""
   ENDIF

   IF _ddDbddSeekNdxScanSlot( cAlias, nUserSlot )
      cFld := ALLTRIM( dbdd->field_name )
      IF EMPTY( cFld )
         cTag := _ddDbddFileAliU()
         cFld := _ddPgFieldFromOrdTag( cTag )
      ENDIF
   ENDIF

   IF EMPTY( cFld )
      cFld := _ddDbddKeyFirstField( cAlias, nUserSlot )
   ENDIF

RETURN UPPER( ALLTRIM( cFld ) )

FUNCTION tbPgSqlOrdField( cAlias, nUserSlot )
   IF nUserSlot < 1
      RETURN ""
   ENDIF
   IF SELECT( "dbdd" ) == 0
      IF ! dbCfgOpen( "dbdd" ) .AND. ! dbCfgOpen( "dbDD" )
         RETURN ""
      ENDIF
   ENDIF
RETURN _ddDbddFieldForUserSlot( cAlias, nUserSlot )

STATIC FUNCTION _ddDbddTagForSlot( cAlias, nSlot )
LOCAL nNdx, nSav, cFA

   IF SELECT( "dbdd" ) == 0 .OR. nSlot < 1
      RETURN ""
   ENDIF

   nSav := dbdd->( RECNO() )
   IF ! _ddDbddSeekRecTyp( "NDX", cAlias )
      IF nSav > 0
         dbdd->( DBGOTO( nSav ) )
      ENDIF
      RETURN ""
   ENDIF

   DO WHILE _ddDbddNdxBlockIsAlias( cAlias ) .AND. ! dbdd->( EOF() )
      IF _ddDbddNdxSlotFromRow( cAlias ) == nSlot
         cFA := _ddDbddFileAliU()
         IF nSav > 0
            dbdd->( DBGOTO( nSav ) )
         ENDIF
         RETURN cFA
      ENDIF
      dbdd->( DBSKIP() )
   ENDDO

   IF nSav > 0
      dbdd->( DBGOTO( nSav ) )
   ENDIF

RETURN ""

STATIC FUNCTION _ddDbddPgFileAliFromOrdName( cAlias, cOrdName )
LOCAL cFNdx, cFA, cFld, cOrdU, cPat, nNdx, nSavRec, cRet := ""

   IF EMPTY( cOrdName ) .OR. _ddPgOrdIsSystem( cOrdName )
      RETURN ""
   ENDIF

   cOrdU := UPPER( ALLTRIM( cOrdName ) )
   cAlias := UPPER( PADR( cAlias, 8 ) )
   cFNdx  := "NDX" + cAlias
   nSavRec := dbdd->( RECNO() )

   IF dbdd->( DBSEEK( cFNdx ) )
      DO WHILE ! dbdd->( EOF() ) .AND. _ddDbddNdxBlockIsAlias( cAlias )
         cFA := _ddDbddFileAliU()
         IF ! EMPTY( cFA ) .AND. cFA $ cOrdU
            cRet := cFA
            EXIT
         ENDIF
         nNdx := _ddDbddNdxSlotFromRow( cAlias )
         cFld := _ddDbddKeyFirstField( cAlias, nNdx )
         IF ! EMPTY( cFld )
            cPat := "_" + cFld + "_"
            IF cPat $ cOrdU
               cRet := cFA
               EXIT
            ENDIF
         ENDIF
         dbdd->( DBSKIP() )
      ENDDO
   ENDIF

   IF nSavRec > 0
      dbdd->( DBGOTO( nSavRec ) )
   ENDIF

RETURN cRet

STATIC FUNCTION _ddDbddPgUserNdxSlot( cWa, nIndexOrd )
LOCAL n, nSlot, nSav, nFocus

   IF SELECT( cWa ) == 0 .OR. nIndexOrd < 1
      RETURN 0
   ENDIF

   nSav := ( cWa )->( INDEXORD() )
   nSlot := 0

   FOR n := 1 TO ( cWa )->( ORDCOUNT() )
      IF ! _dfPgOrdSetFocusN( cWa, n )
         LOOP
      ENDIF
      IF _ddPgOrdIsSystem( _ddPgOrdReadLabel( cWa ) )
         LOOP
      ENDIF
      nSlot++
      nFocus := ( cWa )->( INDEXORD() )
      IF nFocus == nIndexOrd
         _dfPgOrdRestoreFocus( cWa, nSav )
         RETURN nSlot
      ENDIF
   NEXT

   _dfPgOrdRestoreFocus( cWa, nSav )

RETURN 0

// PG upsize: nome tag indice (es. clifor + rag_soc -> clifor_rag_soc_4seek)
STATIC FUNCTION _ddDbddPgTagFromField( cWa, cFld )
LOCAL cTbl, cTag

   IF SELECT( cWa ) == 0 .OR. EMPTY( cFld )
      RETURN ""
   ENDIF

   cTbl := Lower( AllTrim( cWa ) )
   cTag := cTbl + "_" + Lower( AllTrim( cFld ) ) + "_4seek"

RETURN cTag

//* PGDBE: ORDSETFOCUS(n) protetto (evita BASE/2311 su indici non attivabili).
STATIC FUNCTION _dfPgOrdSetFocusN( cWa, nOrd )
LOCAL nCnt, nWant, nGot

   IF SELECT( cWa ) == 0 .OR. VALTYPE( nOrd ) != "N" .OR. nOrd < 1
      RETURN .F.
   ENDIF

   nWant := Int( nOrd )
   nCnt  := ( cWa )->( ORDCOUNT() )
   IF nCnt < 1 .OR. nWant > nCnt
      RETURN .F.
   ENDIF

   * PGDBE: ORDSETFOCUS ritorna C (nome indice precedente), non L — non usare come .T./.F.
   BEGIN SEQUENCE
      ( cWa )->( ORDSETFOCUS( nWant ) )
   RECOVER
      RETURN .F.
   END SEQUENCE

   nGot := ( cWa )->( INDEXORD() )

RETURN ( nGot == nWant )

STATIC FUNCTION _dfPgOrdRestoreFocus( cWa, nSav )
   IF SELECT( cWa ) == 0 .OR. VALTYPE( nSav ) != "N" .OR. nSav < 1
      RETURN NIL
   ENDIF
   _dfPgOrdSetFocusN( cWa, nSav )
RETURN NIL

STATIC FUNCTION _ddPgOrdReadLabel( cWa )
LOCAL cOn, cKey

   IF SELECT( cWa ) == 0
      RETURN ""
   ENDIF

   cOn := ( cWa )->( ORDNAME() )
   IF VALTYPE( cOn ) != "C" .OR. EMPTY( cOn )
      cKey := ( cWa )->( INDEXKEY() )
      IF VALTYPE( cKey ) == "C"
         cOn := ALLTRIM( cKey )
      ELSE
         cOn := ""
      ENDIF
   ENDIF

RETURN cOn

// PGDBE: ORDSETFOCUS accetta solo ORDNUMBER (N), non nome tag (C) — scan per trovare n fisico
STATIC FUNCTION _ddDbddPgPhysOrdFromPgTag( cWa, cPgTag )
LOCAL n, nSav, cOn, cNeed, cNm

   IF EMPTY( cPgTag ) .OR. SELECT( cWa ) == 0
      RETURN 0
   ENDIF

   cNeed := UPPER( ALLTRIM( cPgTag ) )
   nSav  := ( cWa )->( INDEXORD() )

   FOR n := 1 TO ( cWa )->( ORDCOUNT() )
      IF ! _dfPgOrdSetFocusN( cWa, n )
         LOOP
      ENDIF
      cOn := _ddPgOrdReadLabel( cWa )
      IF _ddPgOrdIsSystem( cOn )
         LOOP
      ENDIF
      cNm := ""
      IF ValType( ( cWa )->( ORDNAME() ) ) == "C"
         cNm := UPPER( ALLTRIM( ( cWa )->( ORDNAME() ) ) )
      ENDIF
      IF EMPTY( cNm )
         cNm := UPPER( ALLTRIM( cOn ) )
      ENDIF
      IF cNm == cNeed .OR. cNeed $ cNm
         _dfPgOrdRestoreFocus( cWa, nSav )
         RETURN n
      ENDIF
   NEXT

   _dfPgOrdRestoreFocus( cWa, nSav )

RETURN 0

// ORDSETFOCUS su indice PG upsize (via ORDNUMBER fisico)
STATIC FUNCTION _ddDbddOrdSetFocusPgTag( cWa, cFld )
LOCAL cPgTag, nPhys

   IF ValType( cFld ) != "C"
      RETURN .F.
   ENDIF

   cPgTag := _ddDbddPgTagFromField( cWa, cFld )
   nPhys  := _ddDbddPgPhysOrdFromPgTag( cWa, cPgTag )
   IF _ddWinDbgOn()
      _ddWinDbgMsg( "_ddDbddOrdSetFocus PG pgTag=[" + cPgTag + "] physOrd=" + dfAny2Str( nPhys ) )
   ENDIF
   IF nPhys > 0
      RETURN _ddDbddOrdSetFocusPhys( cWa, nPhys )
   ENDIF

RETURN .F.

// PGDBE: trova ORDNUMBER fisico il cui INDEXKEY/ORDNAME contiene il campo DBDD (es. rag_soc -> *_rag_soc_4seek)
STATIC FUNCTION _ddDbddPgPhysOrdFromField( cWa, cFld )
LOCAL n, nSav, cOn, cFldU, cNeed, cPgTag, nOrd

   cFldU := UPPER( ALLTRIM( cFld ) )
   IF EMPTY( cFldU ) .OR. SELECT( cWa ) == 0
      RETURN 0
   ENDIF

   cNeed := "_" + cFldU + "_"
   nSav  := ( cWa )->( INDEXORD() )

   cPgTag := _ddDbddPgTagFromField( cWa, cFld )
   IF ! EMPTY( cPgTag )
      nOrd := _ddDbddPgPhysOrdFromPgTag( cWa, cPgTag )
      IF _ddWinDbgOn()
         _ddWinDbgMsg( "  PhysOrdPgTag [" + cPgTag + "] physOrd=" + dfAny2Str( nOrd ) + ;
                " ordcnt=" + dfAny2Str( ( cWa )->( ORDCOUNT() ) ) )
      ENDIF
      IF nOrd > 0
         RETURN nOrd
      ENDIF
   ENDIF

   FOR n := 1 TO ( cWa )->( ORDCOUNT() )
      IF ! _dfPgOrdSetFocusN( cWa, n )
         LOOP
      ENDIF
      cOn := UPPER( _ddPgOrdReadLabel( cWa ) )
      IF _ddPgOrdIsSystem( cOn )
         LOOP
      ENDIF
      IF cNeed $ cOn .OR. cFldU $ cOn .OR. RIGHT( cOn, 6 ) == "_4SEEK" .AND. cFldU $ cOn
         _dfPgOrdRestoreFocus( cWa, nSav )
         RETURN n
      ENDIF
   NEXT

   _dfPgOrdRestoreFocus( cWa, nSav )

RETURN 0

STATIC FUNCTION _ddDbddOrdSetFocusPhys( cWa, nPhys )
LOCAL lOk := .F., cOrd

   IF nPhys < 1
      RETURN .F.
   ENDIF

   IF ( cWa )->( INDEXORD() ) == nPhys
      RETURN .T.
   ENDIF

   lOk := _dfPgOrdSetFocusN( cWa, nPhys )
   IF lOk
      cOrd := _ddPgOrdReadLabel( cWa )
   ELSE
      cOrd := ""
   ENDIF
   _ddWinDbgMsg( "_ddDbddOrdSetFocusPhys n=" + dfAny2Str( nPhys ) + " ok=" + dfAny2Str( lOk ) + ;
          " INDEXORD=" + dfAny2Str( (cWa)->(INDEXORD()) ) + " label=[" + LEFT( cOrd, 60 ) + "]" )
RETURN ( lOk .AND. ( cWa )->( INDEXORD() ) > 0 )

// PGDBE: slot utente DBDD (1,2,...) -> ORDNUMBER fisico (salta __record/__deleted/pkey)
FUNCTION _ddDbddPgPhysOrdFromUserSlot( cWa, nUserSlot )
LOCAL n, nSlot, nSav, cOn

   IF SELECT( cWa ) == 0 .OR. nUserSlot < 1
      RETURN 0
   ENDIF

   nSav  := ( cWa )->( INDEXORD() )
   nSlot := 0

   FOR n := 1 TO ( cWa )->( ORDCOUNT() )
      IF ! _dfPgOrdSetFocusN( cWa, n )
         LOOP
      ENDIF
      cOn := _ddPgOrdReadLabel( cWa )
      IF _ddWinDbgOn()
         _ddWinDbgMsg( "  PhysOrd n=" + dfAny2Str(n) + " label=[" + cOn + "] sys=" + ;
                dfAny2Str( _ddPgOrdIsSystem( cOn ) ) )
      ENDIF
      IF _ddPgOrdIsSystem( cOn )
         LOOP
      ENDIF
      nSlot++
      IF nSlot == nUserSlot
         _dfPgOrdRestoreFocus( cWa, nSav )
         RETURN n
      ENDIF
   NEXT

   _dfPgOrdRestoreFocus( cWa, nSav )

RETURN 0

//* ORDLISTADD su PGDBE: ignora errori e tag gia' presenti.
STATIC FUNCTION _dfPgOrdListAddSafe( cWa, cBag )
LOCAL n, bErr, cNeed, cOn

   IF SELECT( cWa ) == 0 .OR. EMPTY( cBag )
      RETURN .F.
   ENDIF

   cNeed := UPPER( ALLTRIM( cBag ) )
   FOR n := 1 TO ( cWa )->( ORDCOUNT() )
      cOn := ""
      IF ValType( ( cWa )->( ORDNAME() ) ) == "C"
         cOn := UPPER( ALLTRIM( ( cWa )->( ORDNAME() ) ) )
      ENDIF
      IF EMPTY( cOn )
         cOn := UPPER( ALLTRIM( _ddPgOrdLabel( cWa, n ) ) )
      ENDIF
      IF cNeed == cOn .OR. cNeed $ cOn
         RETURN .T.
      ENDIF
   NEXT

   bErr := ERRORBLOCK( {|e| Break( e )} )
   BEGIN SEQUENCE
      DBSELECTAREA( cWa )
      ORDLISTADD( cBag )
   RECOVER
      ERRORBLOCK( bErr )
      RETURN .F.
   END SEQUENCE
   ERRORBLOCK( bErr )

RETURN .T.

//* PGDBE: dopo dbfopen con DacSession ORDCOUNT() e' spesso 0 — aggancia indici upsize (*_4seek).
FUNCTION dfPgEnsureWorkareaIndexes( cAlias, cStem, aNdx )
LOCAL cWa, nSav, n, nMax, cTag, cFld, cStemL, lAny

   cWa := UPPER( ALLTRIM( cAlias ) )
   IF SELECT( cWa ) == 0
      RETURN .F.
   ENDIF
   IF ! dfPgRddIs( ( cWa )->( RDDNAME() ) )
      RETURN .T.
   ENDIF
   IF ( cWa )->( ORDCOUNT() ) > 0
      RETURN .T.
   ENDIF

   nSav   := ( cWa )->( INDEXORD() )
   cStemL := Lower( AllTrim( cStem ) )
   IF EMPTY( cStemL )
      cStemL := Lower( AllTrim( cWa ) )
   ENDIF
   lAny   := .F.

   DBSELECTAREA( cWa )

   IF _dfPgOrdListAddSafe( cWa, cStemL )
      lAny := .T.
   ENDIF
   IF cStemL != Lower( AllTrim( cWa ) )
      IF _dfPgOrdListAddSafe( cWa, Lower( AllTrim( cWa ) ) )
         lAny := .T.
      ENDIF
   ENDIF

   nMax := 15
   IF ValType( aNdx ) == "A"
      nMax := Max( nMax, Len( aNdx ) )
   ENDIF

   FOR n := 1 TO nMax
      cFld := _ddDbddFieldForUserSlot( cAlias, n )
      IF EMPTY( cFld ) .AND. n > IIF( ValType( aNdx ) == "A", Len( aNdx ), 0 )
         EXIT
      ENDIF
      IF ! EMPTY( cFld )
         cTag := cStemL + "_" + Lower( AllTrim( cFld ) ) + "_4seek"
         IF _dfPgOrdListAddSafe( cWa, cTag )
            lAny := .T.
         ENDIF
         cTag := cStemL + "_" + Lower( AllTrim( cFld ) ) + "_4like"
         IF _dfPgOrdListAddSafe( cWa, cTag )
            lAny := .T.
         ENDIF
      ENDIF
      IF ValType( aNdx ) == "A" .AND. n <= Len( aNdx ) .AND. ! EMPTY( aNdx[n] )
         IF _dfPgOrdListAddSafe( cWa, Lower( AllTrim( aNdx[n] ) ) )
            lAny := .T.
         ENDIF
      ENDIF
   NEXT

   _dfPgOrdRestoreFocus( cWa, nSav )

   IF _ddWinDbgOn()
      _ddWinDbgMsg( "dfPgEnsureWorkareaIndexes wa=" + cWa + " stem=" + cStemL + ;
             " ordcnt=" + dfAny2Str( ( cWa )->( ORDCOUNT() ) ) + " added=" + dfAny2Str( lAny ) )
   ENDIF

RETURN ( cWa )->( ORDCOUNT() ) > 0

// ORDSETFOCUS: su PGDBE nUserOrd e' slot dizionario, non ORDNUMBER grezzo
FUNCTION _ddDbddOrdSetFocus( cAlias, nUserOrd )
LOCAL cWa, nPhys, cTag, cFld

   cWa := UPPER( ALLTRIM( cAlias ) )
   IF SELECT( cWa ) == 0
      RETURN .F.
   ENDIF

   IF dfPgRddIs( ( cWa )->( RDDNAME() ) )
      IF _ddDbddPgUserNdxSlot( cWa, ( cWa )->( INDEXORD() ) ) == nUserOrd
         RETURN .T.
      ENDIF
      IF ( cWa )->( ORDCOUNT() ) == 0
         dfPgEnsureWorkareaIndexes( cAlias, cWa, {} )
      ENDIF
      cFld := _ddDbddFieldForUserSlot( cAlias, nUserOrd )
      cTag := _ddDbddTagForSlot( cAlias, nUserOrd )
      IF _ddWinDbgOn()
         _ddWinDbgMsg( "_ddDbddOrdSetFocus PG slot=" + dfAny2Str( nUserOrd ) + ;
                " field=" + dfAny2Str( cFld ) + " tag=" + dfAny2Str( cTag ) + ;
                " ordcnt=" + dfAny2Str( ( cWa )->( ORDCOUNT() ) ) )
      ENDIF
      IF ! EMPTY( cTag )
         nPhys := _ddDbddPgPhysOrdFromPgTag( cWa, cTag )
         IF _ddWinDbgOn()
            _ddWinDbgMsg( "_ddDbddOrdSetFocus PG legacyTag=" + cTag + " physOrd=" + dfAny2Str( nPhys ) )
         ENDIF
         IF nPhys > 0
            RETURN _ddDbddOrdSetFocusPhys( cWa, nPhys )
         ENDIF
      ENDIF
      IF ! EMPTY( cFld )
         nPhys := _ddDbddPgPhysOrdFromField( cWa, cFld )
         _ddWinDbgMsg( "_ddDbddOrdSetFocus PG field=" + cFld + " physOrd=" + dfAny2Str( nPhys ) )
         IF nPhys > 0
            RETURN _ddDbddOrdSetFocusPhys( cWa, nPhys )
         ENDIF
         IF _ddDbddOrdSetFocusPgTag( cWa, cFld )
            RETURN .T.
         ENDIF
      ENDIF
      nPhys := _ddDbddPgPhysOrdFromUserSlot( cWa, nUserOrd )
      IF nPhys > 0
         _ddWinDbgMsg( "_ddDbddOrdSetFocus PG slot=" + dfAny2Str( nUserOrd ) + " physOrd=" + dfAny2Str( nPhys ) )
         RETURN _ddDbddOrdSetFocusPhys( cWa, nPhys )
      ENDIF
      IF ! EMPTY( cFld ) .AND. _ddDbddOrdSetFocusPgTag( cWa, cFld )
         RETURN .T.
      ENDIF
      IF ! EMPTY( cTag ) .AND. ! EMPTY( cFld )
         nPhys := _ddDbddPgPhysOrdFromPgTag( cWa, Lower( AllTrim( cWa ) ) + "_" + ;
                Lower( AllTrim( cFld ) ) + "_4seek" )
         IF nPhys > 0
            RETURN _ddDbddOrdSetFocusPhys( cWa, nPhys )
         ENDIF
      ENDIF
      _ddWinDbgMsg( "_ddDbddOrdSetFocus PG: nessun indice per slot=" + dfAny2Str( nUserOrd ) )
      RETURN .F.
   ENDIF

RETURN ( cWa )->( ORDSETFOCUS( nUserOrd ) )

//* PGDBE: prima di DBGOTOP/skip filtro, riallinea indice utente (non __record/pkey).
PROCEDURE dfPgOrdSyncBeforeTop( nAlias )
LOCAL cWa, nPhys, nSav, cOn

   IF VALTYPE( nAlias ) != "N" .OR. nAlias < 1
      nAlias := SELECT()
   ENDIF
   IF nAlias < 1 .OR. ! dfPgRddIs( ( nAlias )->( RDDNAME() ) )
      RETURN
   ENDIF

   cWa  := ( nAlias )->( ALIAS() )
   nSav := ( nAlias )->( INDEXORD() )
   IF nSav > 0
      IF _dfPgOrdSetFocusN( cWa, nSav )
         cOn := _ddPgOrdReadLabel( cWa )
         IF ! _ddPgOrdIsSystem( cOn )
            RETURN
         ENDIF
      ENDIF
   ENDIF

   nPhys := _ddDbddPgPhysOrdFromUserSlot( cWa, 1 )
   IF nPhys > 0
      _dfPgOrdSetFocusN( cWa, nPhys )
   ENDIF
RETURN

//* PGDBE: DBGOTOP/DbGoTop = ordine fisico; dfS(slot,"") = primo record nell'indice attivo.
PROCEDURE dfPgGoTopInIndex( nAlias )
LOCAL cWa, nSlot, nSav

   IF VALTYPE( nAlias ) != "N" .OR. nAlias < 1
      nAlias := SELECT()
   ENDIF
   IF nAlias < 1 .OR. ! dfPgRddIs( ( nAlias )->( RDDNAME() ) )
      IF nAlias > 0
         ( nAlias )->( DBGOTOP() )
      ENDIF
      RETURN
   ENDIF

   dfPgOrdSyncBeforeTop( nAlias )

   cWa   := ( nAlias )->( ALIAS() )
   nSav  := ( nAlias )->( INDEXORD() )
   nSlot := _ddDbddPgUserNdxSlot( cWa, nSav )
   IF nSlot < 1
      nSlot := 1
   ENDIF

   dfS( nSlot, "", .T. )
   IF ( nAlias )->( EOF() )
      ( nAlias )->( DbGoTop() )
   ENDIF
RETURN

// PGDBE: ORDNAME spesso vuoto; usa INDEXKEY come etichetta indice
STATIC FUNCTION _ddPgOrdLabel( cWa, nOrd )
LOCAL cOn, cKey, nSav

   IF SELECT( cWa ) == 0 .OR. nOrd < 1
      RETURN ""
   ENDIF

   nSav := ( cWa )->( INDEXORD() )
   IF ! _dfPgOrdSetFocusN( cWa, nOrd )
      RETURN ""
   ENDIF
   cOn := _ddPgOrdReadLabel( cWa )
   _dfPgOrdRestoreFocus( cWa, nSav )

RETURN cOn

// PG: INDEXORD su indice utente (salta __record/__deleted/pkey)
// Ritorna { nPhysOrd, cOrdName, cTag, nSlot }
STATIC FUNCTION _ddDbddPgResolveOrd( cAlias, cWa, nOrd )
LOCAL nSav, n, cOn, cStem, cOrdName, cTag, nSlot, nRet, nPgPhys

   cOrdName := ""
   cTag     := ""
   nSlot    := 0
   nRet     := 0

   IF SELECT( cWa ) == 0
      RETURN { nRet, cOrdName, cTag, nSlot }
   ENDIF

   cStem := UPPER( PADR( cAlias, 8 ) )
   nSav  := ( cWa )->( INDEXORD() )

   IF VALTYPE( nOrd ) == "N" .AND. nOrd >= 1
      nPgPhys := _ddDbddPgPhysOrdFromUserSlot( cWa, nOrd )
      IF nPgPhys > 0
         nOrd := nPgPhys
      ENDIF
      cOn := _ddPgOrdLabel( cWa, nOrd )
      IF ! EMPTY( cOn ) .AND. ! _ddPgOrdIsSystem( cOn )
         cOrdName := cOn
         cTag     := _ddDbddPgFileAliFromOrdName( cStem, cOrdName )
         nSlot    := _ddDbddPgUserNdxSlot( cWa, nOrd )
         _dfPgOrdRestoreFocus( cWa, nSav )
         RETURN { nOrd, cOrdName, cTag, nSlot }
      ENDIF
   ENDIF

   FOR n := 1 TO ( cWa )->( ORDCOUNT() )
      IF ! _dfPgOrdSetFocusN( cWa, n )
         LOOP
      ENDIF
      cOn := _ddPgOrdReadLabel( cWa )
      IF EMPTY( cOn ) .OR. _ddPgOrdIsSystem( cOn )
         LOOP
      ENDIF
      cOrdName := cOn
      cTag     := _ddDbddPgFileAliFromOrdName( cStem, cOrdName )
      nSlot    := _ddDbddPgUserNdxSlot( cWa, n )
      _dfPgOrdRestoreFocus( cWa, nSav )
      RETURN { n, cOrdName, cTag, nSlot }
   NEXT

   _dfPgOrdRestoreFocus( cWa, nSav )

RETURN { nRet, cOrdName, cTag, nSlot }

// Seek riga NDX con NdxIncN esatto (evita match su chiave legacy errata)
STATIC FUNCTION _ddDbddSeekNdxSlotOnly( cAlias, nSlot )
LOCAL nNdx, nSav

   IF SELECT( "dbdd" ) == 0 .OR. nSlot < 1
      RETURN .F.
   ENDIF

   nSav := dbdd->( RECNO() )
   IF ! _ddDbddSeekRecTyp( "NDX", cAlias )
      IF nSav > 0
         dbdd->( DBGOTO( nSav ) )
      ENDIF
      RETURN .F.
   ENDIF

   DO WHILE _ddDbddNdxBlockIsAlias( cAlias ) .AND. ! dbdd->( EOF() )
      IF _ddDbddNdxSlotFromRow( cAlias ) == nSlot
         RETURN .T.
      ENDIF
      dbdd->( DBSKIP() )
   ENDDO

   IF nSav > 0
      dbdd->( DBGOTO( nSav ) )
   ENDIF

RETURN .F.

// PG: match DBDD solo da dizionario (ORDNAME/ORDCOUNT assenti o inaffidabili)
STATIC FUNCTION _ddDbddSeekNdxPgDbddOnly( cAlias, xOrd )
LOCAL nNdx

   dbdd->( DBGOTOP() )
   DO WHILE ! dbdd->( EOF() )
      IF _ddDbddNdxBlockIsAlias( cAlias )
         IF _ddDbddNdxRowMatch( xOrd, "" )
            RETURN .T.
         ENDIF
         IF VALTYPE( xOrd ) == "N" .AND. xOrd > 0 .AND. ;
            _ddDbddNdxSlotFromRow( cAlias ) == xOrd
            RETURN .T.
         ENDIF
      ENDIF
      dbdd->( DBSKIP() )
   ENDDO

RETURN .F.

STATIC FUNCTION _ddDbddNdxRowMatch( xOrd, cTag )
LOCAL cFA, nNdx, cAlias

   cAlias := UPPER( RTRIM( dbdd->file_name ) )

   // Ordine numerico: solo slot (NdxIncN / FILE_ALI). Mai tag $ FILE_ALI (CLIFOR in 1CLIFOR1).
   IF VALTYPE( xOrd ) == "N" .AND. xOrd > 0
      nNdx := _ddDbddNdxSlotFromRow( cAlias )
      RETURN ( nNdx > 0 .AND. nNdx == xOrd )
   ENDIF

   IF ! EMPTY( cTag )
      cFA := _ddDbddFileAliU()
      IF cFA == cTag
         RETURN .T.
      ENDIF
   ENDIF

   IF VALTYPE( xOrd ) == "C"
      cFA := _ddDbddFileAliU()
      IF ! EMPTY( cFA ) .AND. cFA == UPPER( ALLTRIM( xOrd ) )
         RETURN .T.
      ENDIF
   ENDIF

RETURN .F.

// Scan blocco NDX: solo riga con slot utente = nSlot (no match tag parziale)
STATIC FUNCTION _ddDbddSeekNdxScanSlot( cAlias, nSlot )
LOCAL nSav

   IF nSlot < 1 .OR. ! _ddDbddSeekRecTyp( "NDX", cAlias )
      RETURN .F.
   ENDIF

   nSav := dbdd->( RECNO() )
   DO WHILE _ddDbddNdxBlockIsAlias( cAlias ) .AND. ! dbdd->( EOF() )
      IF _ddDbddNdxSlotFromRow( cAlias ) == nSlot
         RETURN .T.
      ENDIF
      dbdd->( DBSKIP() )
   ENDDO

   IF nSav > 0
      dbdd->( DBGOTO( nSav ) )
   ENDIF

RETURN .F.

FUNCTION _ddDbddSeekNdx( cAlias, xOrd )
LOCAL cFNdx, cLegacy, cTag, cWaSel, nSavOrd, nSavDbddOrd, lRet, nRecNdx
LOCAL nSlot, cOrdName, lPgData, cDbg, cBlkSample, nSavWa, nPgOrd, aPg

   lRet := .F.

   IF SELECT( "dbdd" ) == 0
      _ddWinDbgMsg( "dbdd non aperto" )
      RETURN .F.
   ENDIF

   _cDdDbddNdxFieldChk := ""
   nRecNdx    := 0
   cBlkSample := ""
   nSavDbddOrd := 0
   IF dbdd->( ORDCOUNT() ) > 0
      nSavDbddOrd := dbdd->( INDEXORD() )
      dbdd->( ORDSETFOCUS( 1 ) )
   ENDIF

   DEFAULT xOrd TO 1
   IF VALTYPE( xOrd ) == "N" .AND. xOrd < 1
      xOrd := 1
   ENDIF
   cAlias := UPPER( PADR( cAlias, 8 ) )
   cFNdx  := "NDX" + cAlias
   cTag   := ""
   cWaSel := ALLTRIM( cAlias )
   lPgData := SELECT( cWaSel ) > 0 .AND. dfPgRddIs( ( cWaSel )->( RDDNAME() ) )

   IF VALTYPE( xOrd ) == "N" .AND. xOrd > 0
      cTag := _ddDbddTagForSlot( cAlias, xOrd )
   ENDIF

   IF _ddWinDbgOn()
      cDbg := "seekNdx alias=" + RTRIM( cAlias ) + " xOrd=" + dfAny2Str( xOrd )
      cDbg += " pg=" + dfAny2Str( lPgData )
      IF SELECT( cWaSel ) > 0
         nSavWa := ( cWaSel )->( INDEXORD() )
         cDbg += " idx=" + dfAny2Str( nSavWa ) + " ord#=" + dfAny2Str( ( cWaSel )->( ORDNUMBER() ) )
         cDbg += " ordCnt=" + dfAny2Str( ( cWaSel )->( ORDCOUNT() ) )
         cDbg += " ordNm=" + dfAny2Str( ( cWaSel )->( ORDNAME() ) )
         cDbg += " rdd=" + ( cWaSel )->( RDDNAME() )
      ENDIF
      _ddWinDbgMsg( cDbg )
   ENDIF

   IF VALTYPE( xOrd ) == "C"
      cTag := UPPER( ALLTRIM( xOrd ) )
      IF lPgData
         nSavOrd := ( cWaSel )->( INDEXORD() )
         ( cWaSel )->( ORDSETFOCUS( xOrd ) )
         cOrdName := ( cWaSel )->( ORDNAME() )
         ( cWaSel )->( ORDSETFOCUS( nSavOrd ) )
         cTag := _ddDbddPgFileAliFromOrdName( cAlias, cOrdName )
         IF EMPTY( cTag )
            cTag := UPPER( ALLTRIM( xOrd ) )
         ENDIF
      ENDIF
   ELSEIF VALTYPE( xOrd ) == "N"
      IF lPgData
         aPg      := _ddDbddPgResolveOrd( cAlias, cWaSel, xOrd )
         nPgOrd   := aPg[1]
         cOrdName := IIF( VALTYPE( aPg[2] ) == "C", aPg[2], "" )
         cTag     := IIF( VALTYPE( aPg[3] ) == "C", aPg[3], "" )
         nSlot    := aPg[4]
         IF EMPTY( cTag ) .AND. ! EMPTY( cOrdName )
            cTag := _ddDbddPgFileAliFromOrdName( cAlias, cOrdName )
         ENDIF
         IF nSlot > 0
            xOrd := nSlot
         ELSEIF nPgOrd > 0
            xOrd := nPgOrd
         ENDIF
         IF _ddWinDbgOn()
            _ddWinDbgMsg( "PG ord=" + dfAny2Str( cOrdName ) + " tag=" + dfAny2Str( cTag ) + ;
                   " slot=" + dfAny2Str( nSlot ) + " xOrd=" + dfAny2Str( xOrd ) )
         ENDIF
      ELSE
         nSavOrd := ( cWaSel )->( INDEXORD() )
         ( cWaSel )->( ORDSETFOCUS( xOrd ) )
         cTag := UPPER( ALLTRIM( ( cWaSel )->( ORDNAME() ) ) )
         ( cWaSel )->( ORDSETFOCUS( nSavOrd ) )
      ENDIF
   ENDIF

   IF VALTYPE( xOrd ) == "N" .AND. xOrd > 0
      IF _ddDbddSeekNdxSlotOnly( cAlias, xOrd )
         lRet := .T.
      ENDIF
      IF lRet != .T.
         cLegacy := cFNdx + STR( xOrd, 3 )
         IF dbdd->( DBSEEK( cLegacy ) ) .AND. _ddDbddNdxSlotFromRow( cAlias ) == xOrd
            lRet := .T.
         ENDIF
      ENDIF
      IF lRet != .T.
         cLegacy := cFNdx + STR( xOrd, 3, 0 )
         IF dbdd->( DBSEEK( cLegacy ) ) .AND. _ddDbddNdxSlotFromRow( cAlias ) == xOrd
            lRet := .T.
         ENDIF
      ENDIF
      IF lRet != .T.
         lRet := _ddDbddSeekNdxScanSlot( cAlias, xOrd )
      ENDIF
   ELSE
      IF lRet != .T. .AND. _ddDbddSeekRecTyp( "NDX", cAlias )
         DO WHILE _ddDbddNdxBlockIsAlias( cAlias ) .AND. ! dbdd->( EOF() )
            IF _ddDbddNdxRowMatch( xOrd, cTag )
               lRet := .T.
               EXIT
            ENDIF
            dbdd->( DBSKIP() )
         ENDDO
      ENDIF

      IF lRet != .T.
         dbdd->( DBGOTOP() )
         DO WHILE ! dbdd->( EOF() )
            IF _ddDbddNdxBlockIsAlias( cAlias )
               IF EMPTY( cBlkSample )
                  cBlkSample := RTRIM( dbdd->RecTyp + dbdd->file_name )
               ENDIF
               IF _ddDbddNdxRowMatch( xOrd, cTag )
                  lRet := .T.
                  EXIT
               ENDIF
            ENDIF
            dbdd->( DBSKIP() )
         ENDDO
      ENDIF
   ENDIF

   IF lRet != .T. .AND. lPgData
      IF _ddDbddSeekNdxPgDbddOnly( cAlias, xOrd )
         lRet := .T.
      ENDIF
   ENDIF

   IF lRet == .T.
      _cDdDbddNdxFieldChk := ALLTRIM( dbdd->Field_Chk )
      nRecNdx := dbdd->( RECNO() )
   ENDIF

   IF _ddWinDbgOn()
      cDbg := "seekNdx esito=" + dfAny2Str( lRet ) + " Field_Chk=" + dfAny2Str( _cDdDbddNdxFieldChk )
      cDbg += " tag=" + dfAny2Str( cTag ) + " blk=" + dfAny2Str( cBlkSample ) + " seek=" + cFNdx
      IF lRet
         cDbg += " FILE_ALI=" + _ddDbddFileAliU() + " NdxIncN=" + RTRIM( STR( dbdd->NdxIncN ) )
      ENDIF
      _ddWinDbgMsg( cDbg )
   ENDIF

   IF nSavDbddOrd > 0
      dbdd->( ORDSETFOCUS( nSavDbddOrd ) )
   ENDIF

   IF lRet .AND. nRecNdx > 0
      dbdd->( DBGOTO( nRecNdx ) )
   ENDIF

RETURN lRet

STATIC FUNCTION _ddWinNormalizeStem( cWin )
LOCAL cB := ALLTRIM( cWin )

   IF EMPTY( cB )
      RETURN ""
   ENDIF

   IF RIGHT( UPPER( cB ), 4 ) == ".PRG"
      cB := LEFT( cB, LEN( cB ) - 4 )
   ENDIF

   IF RIGHT( UPPER( cB ), 3 ) == "EXE"
      cB := LEFT( cB, LEN( cB ) - 3 )
   ENDIF

RETURN ALLTRIM( cB )

STATIC FUNCTION _ddWinStemVariants( cB )
RETURN { cB, ;
         UPPER( cB ), ;
         LOWER( cB ), ;
         UPPER( LEFT( cB, 1 ) ) + LOWER( SUBSTR( cB, 2 ) ) }

STATIC FUNCTION _ddWinSymbolCallable( cSym )
LOCAL cU := ALLTRIM( cSym )

   IF EMPTY( cU )
      RETURN .F.
   ENDIF

   IF TYPE( cU ) $ "UB"
      RETURN .T.
   ENDIF

   IF IsFunction( cU )
      RETURN .T.
   ENDIF

   IF TYPE( "dfIsFun" ) $ "UB"
      IF dfIsFun( cU ) .OR. dfIsFun( cU + "()" )
         RETURN .T.
      ENDIF
   ENDIF

RETURN .F.

// GET con focus (es. rag_soc) ï¿½ anche scan objCtrl se focus perso su F7
STATIC FUNCTION _ddDbddActiveFieldName()
LOCAL oGet, oDlg, n, oCtrl, aCtrl, nPos

   IF TYPE( "dfGetActive" ) != "U"
      oGet := dfGetActive()
      IF VALTYPE( oGet ) == "O" .AND. ! EMPTY( oGet:varname )
         RETURN UPPER( ALLTRIM( oGet:varname ) )
      ENDIF
   ENDIF

   IF TYPE( "S2FormCurr" ) != "U"
      oDlg := S2FormCurr()
      IF VALTYPE( oDlg ) == "O" .AND. oDlg:isDerivedFrom( "S2Form" )
         IF isMethod( oDlg, "UpdateCurrentGet" )
            nPos := oDlg:UpdateCurrentGet()
         ELSE
            nPos := oDlg:W_CURRENTGET
         ENDIF
         IF VALTYPE( nPos ) == "N" .AND. nPos >= 1 .AND. nPos <= LEN( oDlg:objCtrl )
            oCtrl := oDlg:objCtrl[nPos]
            IF VALTYPE( oCtrl ) == "O" .AND. oCtrl:isDerivedFrom( "S2Get" ) .AND. ! EMPTY( oCtrl:varname )
               RETURN UPPER( ALLTRIM( oCtrl:varname ) )
            ENDIF
         ENDIF
         oCtrl := oDlg:getActiveCtrl()
         IF VALTYPE( oCtrl ) == "O" .AND. ! EMPTY( oCtrl:varname )
            RETURN UPPER( ALLTRIM( oCtrl:varname ) )
         ENDIF
         IF isMethod( oDlg, "getObjCtrl" )
            aCtrl := oDlg:getObjCtrl()
            n := LEN( aCtrl )
            DO WHILE n >= 1
               oCtrl := aCtrl[n]
               IF VALTYPE( oCtrl ) == "O" .AND. oCtrl:isDerivedFrom( "S2Get" )
                  IF oCtrl:hasFocus() .OR. ( isMethod( oCtrl, "IsActive" ) .AND. oCtrl:IsActive() )
                     IF ! EMPTY( oCtrl:varname )
                        RETURN UPPER( ALLTRIM( oCtrl:varname ) )
                     ENDIF
                  ENDIF
               ENDIF
               n--
            ENDDO
         ENDIF
      ENDIF
   ENDIF

RETURN ""

// Indice utente la cui ORDKEY contiene il campo (es. rag_soc -> ordine 2)
STATIC FUNCTION _ddDbddOrdForFieldFromWa( cWa, cField )
LOCAL n, nSav, cKey, cFld, nUser, cOn, lPg

   cFld := UPPER( ALLTRIM( cField ) )
   IF SELECT( cWa ) == 0 .OR. EMPTY( cFld )
      RETURN 0
   ENDIF

   lPg  := dfPgRddIs( ( cWa )->( RDDNAME() ) )
   nSav := ( cWa )->( INDEXORD() )
   nUser := 0

   FOR n := 1 TO ( cWa )->( ORDCOUNT() )
      IF lPg
         IF ! _dfPgOrdSetFocusN( cWa, n )
            LOOP
         ENDIF
         cOn := _ddPgOrdReadLabel( cWa )
      ELSE
         IF ! _dfPgOrdSetFocusN( cWa, n )
            LOOP
         ENDIF
         cOn := _ddPgOrdReadLabel( cWa )
      ENDIF
      IF lPg .AND. _ddPgOrdIsSystem( cOn )
         LOOP
      ENDIF
      nUser++
      cKey := UPPER( ALLTRIM( ( cWa )->( ORDKEY() ) ) )
      IF ! EMPTY( cKey ) .AND. cFld $ cKey
         _dfPgOrdRestoreFocus( cWa, nSav )
         IF lPg
            RETURN _ddDbddPgUserNdxSlot( cWa, n )
         ENDIF
         RETURN nUser
      ENDIF
   NEXT

   _dfPgOrdRestoreFocus( cWa, nSav )

RETURN 0

STATIC FUNCTION _ddDbddNdxSlotForField( cAlias, cField )
LOCAL nNdx, nSav, cFld, cKey, cFn, cBlk, nSav2, cWaSel

   cField := UPPER( ALLTRIM( cField ) )
   IF EMPTY( cField )
      RETURN 0
   ENDIF

   cAlias := UPPER( PADR( cAlias, 8 ) )
   cWaSel := ALLTRIM( cAlias )
   IF SELECT( cWaSel ) > 0
      nNdx := _ddDbddOrdForFieldFromWa( cWaSel, cField )
      IF nNdx > 0
         RETURN nNdx
      ENDIF
   ENDIF

   IF SELECT( "dbdd" ) == 0
      RETURN 0
   ENDIF

   nSav := dbdd->( RECNO() )

   IF ! _ddDbddSeekRecTyp( "NDX", cAlias )
      IF nSav > 0
         dbdd->( DBGOTO( nSav ) )
      ENDIF
      RETURN 0
   ENDIF

   DO WHILE _ddDbddNdxBlockIsAlias( cAlias ) .AND. ! dbdd->( EOF() )
      nNdx := _ddDbddNdxSlotFromRow( cAlias )
      IF nNdx < 1
         dbdd->( DBSKIP() )
         LOOP
      ENDIF
      cFn := UPPER( RTRIM( dbdd->file_name ) )
      cFld := _ddDbddKeyFirstField( cAlias, nNdx, cFn )
      IF cFld == cField
         IF nSav > 0
            dbdd->( DBGOTO( nSav ) )
         ENDIF
         RETURN nNdx
      ENDIF
      nSav2 := dbdd->( RECNO() )
      cBlk  := "KEY" + UPPER( RTRIM( cFn ) ) + STR( nNdx, 3, 0 )
      IF dbdd->( DBSEEK( cBlk ) )
         DO WHILE ! dbdd->( EOF() ) .AND. ;
                UPPER( dbdd->RecTyp + dbdd->file_name + STR( nNdx, 3, 0 ) ) == cBlk
            IF UPPER( ALLTRIM( dbdd->field_name ) ) == cField
               IF nSav > 0
                  dbdd->( DBGOTO( nSav ) )
               ENDIF
               RETURN nNdx
            ENDIF
            dbdd->( DBSKIP() )
         ENDDO
         dbdd->( DBGOTO( nSav2 ) )
      ENDIF
      cKey := UPPER( ALLTRIM( dbdd->Field_Pic ) + ALLTRIM( dbdd->Field_Pico ) )
      IF cField $ cKey
         IF nSav > 0
            dbdd->( DBGOTO( nSav ) )
         ENDIF
         RETURN nNdx
      ENDIF
      dbdd->( DBSKIP() )
   ENDDO

   IF nSav > 0
      dbdd->( DBGOTO( nSav ) )
   ENDIF

RETURN 0

// Campo GET / ORDKEY / DBDD -> NdxIncN (rag_soc -> 2 -> fini2)
// xOrd passato != INDEXORD() (es. ddKey(,,2,)) non sovrascritto dal campo attivo
FUNCTION _ddDbddOrdFromContext( cAlias, xOrd )
LOCAL nSlot, cFld, cWaSel, nCurOrd, lKeepPassed

   cWaSel := UPPER( ALLTRIM( cAlias ) )
   IF SELECT( cWaSel ) > 0 .AND. VALTYPE( xOrd ) == "N" .AND. xOrd > 0
      nCurOrd := ( cWaSel )->( INDEXORD() )
      // indice esplicito (menu ddKey ,,2,) o diverso da INDEXORD: non mappare dal GET
      IF ( nCurOrd > 0 .AND. xOrd != nCurOrd ) .OR. xOrd > 1
         lKeepPassed := .T.
      ENDIF
   ENDIF

   cFld := _ddDbddActiveFieldName()
   IF ! EMPTY( cFld ) .AND. ! lKeepPassed
      nSlot := _ddDbddNdxSlotForField( cAlias, cFld )
      IF nSlot > 0
         RETURN nSlot
      ENDIF
   ENDIF

RETURN _ddDbddOrdFromData( cAlias, xOrd )

// PGDBE: mappa INDEXORD/ORDNUMBER su slot indice utente per _ddDbddSeekNdx
STATIC FUNCTION _ddDbddOrdFromData( cAlias, xOrd )
LOCAL cWaSel, aPg, nSav

   DEFAULT xOrd TO 1
   IF VALTYPE( xOrd ) == "C"
      RETURN xOrd
   ENDIF
   IF VALTYPE( xOrd ) != "N"
      RETURN xOrd
   ENDIF

   cWaSel := UPPER( ALLTRIM( cAlias ) )
   IF SELECT( cWaSel ) > 0 .AND. dfPgRddIs( ( cWaSel )->( RDDNAME() ) )
      nSav := ( cWaSel )->( INDEXORD() )
      IF xOrd < 1 .OR. nSav < 1
         aPg := _ddDbddPgResolveOrd( cAlias, cWaSel, 0 )
         IF aPg[4] > 0
            ( cWaSel )->( ORDSETFOCUS( nSav ) )
            RETURN aPg[4]
         ENDIF
      ELSE
         aPg := _ddDbddPgResolveOrd( cAlias, cWaSel, xOrd )
         IF aPg[4] > 0
            ( cWaSel )->( ORDSETFOCUS( nSav ) )
            RETURN aPg[4]
         ENDIF
      ENDIF
      ( cWaSel )->( ORDSETFOCUS( nSav ) )
   ENDIF

   IF xOrd < 1
      xOrd := 1
   ENDIF

RETURN xOrd

// Seek DBDD (CDX legacy + scan NdxIncN/FILE_ALI) poi Field_Chk -> stem finNExe in EXE host.
FUNCTION ddWinCustomStem( cAlias, xOrd )
LOCAL cStem, cResolved

   IF SELECT( "dbdd" ) == 0
      _ddWinDbgMsg( "customStem: dbdd assente" )
      RETURN ""
   ENDIF

   xOrd := _ddDbddOrdFromContext( cAlias, xOrd )

   IF VALTYPE( xOrd ) == "N" .AND. xOrd > 0 .AND. _ddDbddSeekNdxSlotOnly( cAlias, xOrd )
      cStem := ALLTRIM( dbdd->Field_Chk )
   ELSEIF ! _ddDbddSeekNdx( cAlias, xOrd )
      _ddWinDbgMsg( "customStem: seekNdx fallito -> ddWin generica" )
      RETURN ""
   ELSE
      cStem := ddIndexWin()
   ENDIF
   IF EMPTY( cStem )
      _ddWinDbgMsg( "customStem: Field_Chk vuoto su riga NDX" )
      RETURN ""
   ENDIF

   cResolved := ddResolveWinExeName( cStem )
   IF _ddWinDbgOn()
      _ddWinDbgMsg( "customStem: alias=" + cAlias + " xOrd=" + dfAny2Str( xOrd ) + ;
             " Field_Chk=" + cStem + " -> " + cResolved + ;
             " FILE_ALI=" + _ddDbddFileAliU() )
   ENDIF

RETURN cResolved

// Field_Chk (DBDD) -> stem per NNNExe() in EXE host (fini2 -> fini2Exe in app, non fini1)
FUNCTION ddResolveWinExeName( cWin )
LOCAL cB

   cB := _ddWinNormalizeStem( cWin )
   IF EMPTY( cB )
      RETURN ""
   ENDIF

   // Non risolvere simboli da DLL: evita stem sbagliato; EVAL NNNExe() e' nell'EXE applicativo.
RETURN cB

FUNCTION _ddDbddSeekFieField( cAlias, cField )
LOCAL cFldU, cBlock

   IF SELECT( "dbdd" ) == 0 .OR. EMPTY( cField )
      RETURN .F.
   ENDIF

   cAlias := UPPER( PADR( cAlias, 8 ) )
   cFldU  := UPPER( ALLTRIM( cField ) )
   cBlock := "FIE" + cAlias

   IF dbdd->( ORDCOUNT() ) > 0
      IF dbdd->( DBSEEK( cBlock + cFldU ) )
         RETURN .T.
      ENDIF
   ENDIF

   IF ! _ddDbddSeekRecTyp( "FIE", cAlias )
      RETURN .F.
   ENDIF

   DO WHILE ! dbdd->( EOF() ) .AND. UPPER( dbdd->RecTyp + dbdd->file_name ) == cBlock
      IF UPPER( ALLTRIM( dbdd->field_name ) ) == cFldU
         RETURN .T.
      ENDIF
      dbdd->( DBSKIP() )
   ENDDO

RETURN .F.

FUNCTION ddIndexWin()                          // Finestra sull'indice
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
LOCAL cRet := _ddDbddNdxFieldChkTake()

   IF EMPTY( cRet )
      cRet := ALLTRIM( dbdd->Field_Chk )
   ENDIF

RETURN cRet

* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION ddIndexName( cFileName )              // Nome dell'indice
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
LOCAL cRet

DEFAULT cFileName TO ""

IF LEFT(dbdd->FILE_ALI,1) = "@"  // nome file variabile
   cRet := SUBSTR(dbdd->file_ali,2)
   IF TYPE( cRet ) # "C"
      dbMsgErr( dfStdMsg(MSG_DDINDEX13) +cFileName +"//" +;
                dfStdMsg(MSG_DDINDEX14) +cRet             )
   ENDIF
   cRet := UPPER(&cRet)
ELSE
   cRet := ALLTRIM(dbdd->FILE_ALI)
ENDIF

RETURN cRet

* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION ddFldLOOK()                           // LookUp sul campo
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
RETURN ddGetSlot( dbdd->SLOT, "ï¿½ï¿½", 1)

* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION ddFldFLLOOK()                         // Destinazione del Lookup
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
RETURN UPPER(ddGetSlot( dbdd->SLOT, "ï¿½ï¿½", 3))

* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
FUNCTION ddFldFLInh()                          // Campo da ereditare
* ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½
RETURN UPPER(ddGetSlot( dbdd->SLOT, "ï¿½ï¿½", 6))