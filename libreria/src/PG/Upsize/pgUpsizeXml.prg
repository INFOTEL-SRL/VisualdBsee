/******************************************************************************
  Generazione XML runtime per DbfUpsize (UPSIZE.runtime.upsize).
  Dipende da pgUpsize.prg (connessione, trace, template INI) e pgVdbIni (I/O file).
  Ordine link tipico: pgVdbIni, pgUpsize, pgUpsizeXml, pgDacSession, ddUsePg.

  Alaska ASXML (asxml.ch, XMLDocOpenFile / XMLDocSetAction / XMLDocProcess) e'
  pensato per il parsing a callback dei file XML, non per emettere o riscrivere
  documenti grandi; vedi
  https://doc.alaska-software.com/content/xml_h2_processing_xml_configuration_files.cxp
  Qui si costruisce ancora XML come testo: merge template, sostituzione
  <connection>, generazione blocchi <table> da scan EXE/DBDD — nessuna lib
  XML extra nel progetto, output allineato a quanto si aspetta DbfUpsize().
******************************************************************************/
#INCLUDE "Common.ch"
#INCLUDE "DFCLPSUP.CH"
#INCLUDE "Fileio.ch"
#INCLUDE "dfGenMsg.ch"
#INCLUDE "dfSet.ch"

*******************************************************************************
STATIC FUNCTION dfXmlAttrEscape( cVal )
*******************************************************************************

   IF ValType( cVal ) != "C"
      RETURN ""
   ENDIF

   cVal := StrTran( cVal, "&", "&amp;" )
   cVal := StrTran( cVal, '"', "&quot;" )
   cVal := StrTran( cVal, "<", "&lt;" )
   cVal := StrTran( cVal, ">", "&gt;" )

RETURN cVal

*******************************************************************************
STATIC FUNCTION dfPgUpsizeXmlLf()
*******************************************************************************
RETURN Chr( 13 ) + Chr( 10 )

*******************************************************************************
STATIC FUNCTION dfPgUpsizeXmlQuot()
*******************************************************************************
RETURN Chr( 34 )

*******************************************************************************
//* Cartella EXE + prefisso relativo (dbf= nel XML). Fallback se AppName() non fornisce ancora EXE con .dbf.
//* Con Menu.exe in EXE, dfPgUpsizeBuildTablesXml usa path assoluti da dfPgExeDirectory().
STATIC FUNCTION dfPgUpsizeExeDirAndRelFromTpl( cTplDir )
LOCAL cB, cA, cR

   cB := dfPgUpsizeEnsureTrailSlash( cTplDir )

   cR := "..\..\EXE\"
   cA := cB + cR
   IF File( cA + "Menu.exe" ) .OR. Len( Directory( cA + "*.DBF" ) ) > 0
      RETURN { cA, cR }
   ENDIF

   cR := "..\EXE\"
   cA := cB + cR
   IF File( cA + "Menu.exe" ) .OR. Len( Directory( cA + "*.DBF" ) ) > 0
      RETURN { cA, cR }
   ENDIF

RETURN { cB + "..\..\EXE\", "..\..\EXE\" }

*******************************************************************************
STATIC FUNCTION dfPgUpsizeDbfcdxNames()
*******************************************************************************
//* Nomi tabella (senza estensione) che usano dbe dbfcdx invece di foxcdx.
RETURN { "ANAGRA" }

*******************************************************************************
STATIC FUNCTION dfPgUpsizeDbfExcluded( cBaseUpper )
*******************************************************************************
LOCAL a, i

   IF ValType( cBaseUpper ) != "C" .OR. Empty( cBaseUpper )
      RETURN .F.
   ENDIF

   cBaseUpper := Upper( AllTrim( cBaseUpper ) )

   a := { "DESKTOP", "FOXUSER" }

   FOR i := 1 TO Len( a )
      IF cBaseUpper == a[i]
         RETURN .T.
      ENDIF
   NEXT

RETURN .F.

//* [UPSIZE] PgUpsizeExcludeTables=nome1,nome2 (senza .DBF) per saltare tabelle che non si aprono in esclusiva o non vanno migrate.
STATIC FUNCTION dfPgUpsizeIniExcludedTable( cBaseUpper )
LOCAL cList, cTok, nAt, cU

   IF ValType( cBaseUpper ) != "C" .OR. Empty( cBaseUpper )
      RETURN .F.
   ENDIF

   cU := Upper( AllTrim( cBaseUpper ) )

   cList := dfPgUpsizeIniUpsizeOnly( "PgUpsizeExcludeTables" )
   IF ValType( cList ) != "C" .OR. Empty( AllTrim( cList ) )
      RETURN .F.
   ENDIF

   cList := StrTran( cList, ";", "," )

   DO WHILE Len( cList ) > 0
      nAt := At( ",", cList )
      IF nAt < 1
         cTok := AllTrim( cList )
         cList := ""
      ELSE
         cTok := AllTrim( Left( cList, nAt - 1 ) )
         cList := SubStr( cList, nAt + 1 )
      ENDIF
      IF ValType( cTok ) == "C" .AND. Upper( AllTrim( cTok ) ) == cU
         RETURN .T.
      ENDIF
   ENDDO

RETURN .F.

*******************************************************************************
STATIC FUNCTION dfPgUpsizeTableDbe( cBase )
*******************************************************************************
LOCAL a, i

   IF ValType( cBase ) != "C" .OR. Empty( cBase )
      RETURN "foxcdx"
   ENDIF

   a := dfPgUpsizeDbfcdxNames()
   FOR i := 1 TO Len( a )
      IF Upper( AllTrim( cBase ) ) == Upper( AllTrim( a[i] ) )
         RETURN "dbfcdx"
      ENDIF
   NEXT

RETURN "foxcdx"

*******************************************************************************
STATIC FUNCTION dfPgUpsizeAllDigits( cRest )
*******************************************************************************
LOCAL j, n

   IF ValType( cRest ) != "C" .OR. Empty( cRest )
      RETURN .F.
   ENDIF

   n := Len( cRest )
   FOR j := 1 TO n
      IF !( SubStr( cRest, j, 1 ) >= "0" .AND. SubStr( cRest, j, 1 ) <= "9" )
         RETURN .F.
      ENDIF
   NEXT

RETURN .T.

*******************************************************************************
STATIC FUNCTION dfPgUpsizeCdxStemMatchesBase( cStem, cBase )
*******************************************************************************
LOCAL cUStem, cUBase, cRest, cBase7

   IF ValType( cStem ) != "C" .OR. ValType( cBase ) != "C" .OR. Empty( cBase )
      RETURN .F.
   ENDIF

   cUStem := Upper( AllTrim( cStem ) )
   cUBase := Upper( AllTrim( cBase ) )

   IF cUStem == cUBase
      RETURN .T.
   ENDIF

   IF Left( cUStem, Len( cUBase ) ) != cUBase
//* Compatibilita' con stem storici 8.3 (es. PRESENZE -> PRESENZ1.CDX).
//* In questo caso il base e' troncato di 1 carattere.
      IF Len( cUBase ) >= 8
         cBase7 := Left( cUBase, Len( cUBase ) - 1 )
         IF Left( cUStem, Len( cBase7 ) ) == cBase7
            IF Len( cUStem ) == Len( cBase7 )
               RETURN .T.
            ENDIF
            cRest := SubStr( cUStem, Len( cBase7 ) + 1 )
            IF dfPgUpsizeAllDigits( cRest )
               RETURN .T.
            ENDIF
            RETURN dfPgUpsizeCdxOrderSuffixOk( cRest )
         ENDIF
      ENDIF
      RETURN .F.
   ENDIF

   IF Len( cUStem ) <= Len( cUBase )
      RETURN .F.
   ENDIF

   cRest := SubStr( cUStem, Len( cUBase ) + 1 )

   IF dfPgUpsizeAllDigits( cRest )
      RETURN .T.
   ENDIF

//* Suffisso tipo _M, _P, _1, M1, ... (indici multipli Visual dBsee / FoxCDX oltre a presenze1, presenze2).
RETURN dfPgUpsizeCdxOrderSuffixOk( cRest )

*******************************************************************************
//* Suffisso dopo il nome tabella nello stem del .CDX: lettere, cifre, underscore (no spazi).
STATIC FUNCTION dfPgUpsizeCdxOrderSuffixOk( cSuff )
*******************************************************************************
LOCAL j, n, c

   IF ValType( cSuff ) != "C" .OR. Empty( cSuff )
      RETURN .F.
   ENDIF

   n := Len( cSuff )
   FOR j := 1 TO n
      c := SubStr( cSuff, j, 1 )
      IF ( c >= "0" .AND. c <= "9" ) .OR. ;
         ( c >= "A" .AND. c <= "Z" ) .OR. ;
         ( c >= "a" .AND. c <= "z" ) .OR. ;
         c == "_"
         LOOP
      ENDIF
      RETURN .F.
   NEXT

RETURN .T.

*******************************************************************************
STATIC PROCEDURE dfPgUpsizeSortStrAsc( aList )
*******************************************************************************
LOCAL i, j, n, cTmp

   IF ValType( aList ) != "A"
      RETURN
   ENDIF

   n := Len( aList )
   FOR i := 1 TO n - 1
      FOR j := i + 1 TO n
         IF Upper( aList[i] ) > Upper( aList[j] )
            cTmp    := aList[i]
            aList[i] := aList[j]
            aList[j] := cTmp
         ENDIF
      NEXT
   NEXT

RETURN

*******************************************************************************
STATIC PROCEDURE dfPgUpsizeSortDbfRows( aRows )
*******************************************************************************
LOCAL i, j, n, aTmp

   IF ValType( aRows ) != "A"
      RETURN
   ENDIF

   n := Len( aRows )
   FOR i := 1 TO n - 1
      FOR j := i + 1 TO n
         IF Upper( aRows[i][1] ) > Upper( aRows[j][1] )
            aTmp    := aRows[i]
            aRows[i] := aRows[j]
            aRows[j] := aTmp
         ENDIF
      NEXT
   NEXT

RETURN

*******************************************************************************
STATIC FUNCTION dfPgUpsizeTableSourceDbdd()
*******************************************************************************
LOCAL cEnv, cIni

   cEnv := Upper( RTrim( GetEnv( "VDB_PG_UPSIZE_TABLE_SOURCE" ) ) )
   IF cEnv == "DBDD"
      RETURN .T.
   ENDIF

   cIni := Upper( RTrim( dfPgUpsizeIniUpsizeOnly( "PgUpsizeTableSource" ) ) )
RETURN ( cIni == "DBDD" )

//*******************************************************************************
STATIC FUNCTION dfPgUpsizeExtraDbfDir()
//*******************************************************************************
//* Directory aggiuntiva da cui includere *.DBF nell'upsize (dopo EXE / DBDD). Env ha priorita' su INI.
LOCAL c

   c := RTrim( AllTrim( GetEnv( "VDB_PG_UPSIZE_EXTRA_DBF_DIR" ) ) )
   IF ValType( c ) == "C" .AND. !Empty( c )
      RETURN c
   ENDIF

RETURN RTrim( AllTrim( dfPgUpsizeIniUpsizeOnly( "PgUpsizeExtraDbfDir" ) ) )

//*******************************************************************************
STATIC FUNCTION dfPgUpsizeDirParentWithSlash( cFullPath )
//*******************************************************************************
//* Directory del file (con \ finale); stringa vuota se non ricavabile.
LOCAL n

   IF ValType( cFullPath ) != "C" .OR. Empty( cFullPath )
      RETURN ""
   ENDIF

   n := RAt( "\", cFullPath )
   IF n < 1
      n := RAt( "/", cFullPath )
   ENDIF
   IF n < 1
      RETURN ""
   ENDIF

RETURN Left( cFullPath, n )

//*******************************************************************************
//* Aggiunge righe { stem, pathDbfCompleto } da cExtraDir senza sovrascrivere stem gia' in aRows.
STATIC PROCEDURE dfPgUpsizeMergeExtraDbfDir( aRows, cExtraDir )
*******************************************************************************
LOCAL aDir, i, cF, cBase, nLen, cEx

   IF ValType( aRows ) != "A" .OR. ValType( cExtraDir ) != "C" .OR. Empty( RTrim( cExtraDir ) )
      RETURN
   ENDIF

   cEx := dfPgUpsizeEnsureTrailSlash( RTrim( cExtraDir ) )
   aDir := Directory( cEx + "*.DBF" )

   IF ValType( aDir ) != "A"
      RETURN
   ENDIF

   FOR i := 1 TO Len( aDir )
      cF := aDir[i][1]
      IF ValType( cF ) != "C" .OR. Empty( cF )
         LOOP
      ENDIF
      IF Upper( Right( cF, 4 ) ) != ".DBF"
         LOOP
      ENDIF
      nLen := Len( cF ) - 4
      IF nLen < 1
         LOOP
      ENDIF
      cBase := Left( cF, nLen )
      IF dfPgIsSystemDictionaryStem( cBase )
         LOOP
      ENDIF
      IF dfPgUpsizeDbfExcluded( Upper( cBase ) )
         LOOP
      ENDIF
      IF dfPgUpsizeIniExcludedTable( Upper( cBase ) )
         LOOP
      ENDIF
      IF AScan( aRows, {|x| ValType( x ) == "A" .AND. Len( x ) >= 1 .AND. Upper( RTrim( x[1] ) ) == Upper( RTrim( cBase ) ) } ) > 0
         LOOP
      ENDIF
      AAdd( aRows, { cBase, cEx + cF } )
   NEXT

RETURN

*******************************************************************************
//* Nome file .DBF in EXE (Directory) con stem case-insensitive = cStemUpper (senza .DBF).
STATIC FUNCTION dfPgUpsizeFindDbfFilenameInExe( cExeDir, cStemUpper )
*******************************************************************************
LOCAL aDir, i, nLen, cF, cB

   IF ValType( cExeDir ) != "C" .OR. Empty( cExeDir ) .OR. ValType( cStemUpper ) != "C" .OR. Empty( cStemUpper )
      RETURN ""
   ENDIF

   cStemUpper := Upper( RTrim( cStemUpper ) )
   cExeDir    := dfPgUpsizeEnsureTrailSlash( cExeDir )
   aDir       := Directory( cExeDir + "*.DBF" )

   IF ValType( aDir ) != "A"
      RETURN ""
   ENDIF

   FOR i := 1 TO Len( aDir )
      cF := aDir[i][1]
      IF ValType( cF ) != "C" .OR. Empty( cF )
         LOOP
      ENDIF
      IF Upper( Right( cF, 4 ) ) != ".DBF"
         LOOP
      ENDIF
      nLen := Len( cF ) - 4
      IF nLen < 1
         LOOP
      ENDIF
      cB := Upper( Left( cF, nLen ) )
      IF cB == cStemUpper
         RETURN cF
      ENDIF
   NEXT

RETURN ""

*******************************************************************************
//* Righe tabella come DirectoryDbfRows: { nomeDD, pathDbfCompleto } dal dizionario DBDD (RecTyp DBF).
STATIC FUNCTION dfPgUpsizeDbddDbfRows( cExeDir )
*******************************************************************************
LOCAL aOut, nSav, cRt, cStemU, cF

   aOut := {}

   IF ValType( cExeDir ) != "C" .OR. Empty( cExeDir )
      RETURN aOut
   ENDIF

   cExeDir := dfPgUpsizeEnsureTrailSlash( cExeDir )

//* Standalone one-shot: se il dizionario locale non esiste in EXE, evitare dbCfgOpen("dbDD")
//* (puo' mostrare errore "non riesco ad aprire DBDD.dbf") e usare fallback scan EXE.
   IF !File( cExeDir + "DBDD.DBF" ) .AND. !File( cExeDir + "dbdd.dbf" )
      RETURN aOut
   ENDIF

   nSav    := Select()

   IF Select( "dbdd" ) == 0
      IF !dbCfgOpen( "dbDD" )
         IF nSav > 0 .AND. nSav <= 250
            IF !Empty( Alias( nSav ) )
               DBSELECTAREA( nSav )
            ENDIF
         ENDIF
         RETURN aOut
      ENDIF
   ENDIF

   SELECT dbdd
   dbdd->( DbGoTop() )

   DO WHILE ! dbdd->( Eof() )

      cRt := Upper( RTrim( dbdd->RecTyp ) )

      IF cRt == "DBF"

         cStemU := Upper( RTrim( dbdd->file_name ) )

         IF !Empty( cStemU ) .AND. ;
            !dfPgIsSystemDictionaryStem( cStemU ) .AND. ;
            !dfPgUpsizeDbfExcluded( cStemU ) .AND. ;
            !dfPgUpsizeIniExcludedTable( cStemU )

            cF := dfPgUpsizeFindDbfFilenameInExe( cExeDir, cStemU )

            IF !Empty( cF ) .AND. AScan( aOut, {|x| Upper( x[1] ) == cStemU } ) == 0
               AAdd( aOut, { cStemU, cExeDir + cF } )
            ENDIF

         ENDIF

      ENDIF

      dbdd->( DbSkip() )

   ENDDO

   IF nSav > 0 .AND. nSav <= 250
      IF !Empty( Alias( nSav ) )
         DBSELECTAREA( nSav )
      ENDIF
   ENDIF

   IF Len( aOut ) > 0
      dfPgUpsizeSortDbfRows( aOut )
   ENDIF

RETURN aOut

*******************************************************************************
//* Ogni elemento: { nomeTabella, pathDbfCompleto }.
STATIC FUNCTION dfPgUpsizeDirectoryDbfRows( cExeDir )
*******************************************************************************
LOCAL aOut, aDir, i, cF, cBase, nLen

   aOut := {}

   IF ValType( cExeDir ) != "C" .OR. Empty( cExeDir )
      RETURN aOut
   ENDIF

   cExeDir := dfPgUpsizeEnsureTrailSlash( cExeDir )
   aDir    := Directory( cExeDir + "*.DBF" )

   IF ValType( aDir ) != "A"
      RETURN aOut
   ENDIF

   FOR i := 1 TO Len( aDir )
      cF := aDir[i][1]
      IF ValType( cF ) != "C" .OR. Empty( cF )
         LOOP
      ENDIF
      IF Upper( Right( cF, 4 ) ) != ".DBF"
         LOOP
      ENDIF
      nLen := Len( cF ) - 4
      IF nLen < 1
         LOOP
      ENDIF
      cBase := Left( cF, nLen )
      IF dfPgIsSystemDictionaryStem( cBase )
         LOOP
      ENDIF
      IF dfPgUpsizeDbfExcluded( Upper( cBase ) )
         LOOP
      ENDIF
      IF dfPgUpsizeIniExcludedTable( Upper( cBase ) )
         LOOP
      ENDIF
      AAdd( aOut, { cBase, cExeDir + cF } )
   NEXT

   dfPgUpsizeSortDbfRows( aOut )

RETURN aOut

*******************************************************************************
STATIC FUNCTION dfPgUpsizeDirectoryCdxStems( cExeDir )
*******************************************************************************
LOCAL aOut, aDir, i, cF, cStem, nLen

   aOut := {}

   IF ValType( cExeDir ) != "C" .OR. Empty( cExeDir )
      RETURN aOut
   ENDIF

   cExeDir := dfPgUpsizeEnsureTrailSlash( cExeDir )
   aDir    := Directory( cExeDir + "*.CDX" )

   IF ValType( aDir ) != "A"
      RETURN aOut
   ENDIF

   FOR i := 1 TO Len( aDir )
      cF := aDir[i][1]
      IF ValType( cF ) != "C" .OR. Empty( cF )
         LOOP
      ENDIF
      IF Upper( Right( cF, 4 ) ) != ".CDX"
         LOOP
      ENDIF
      nLen := Len( cF ) - 4
      IF nLen < 1
         LOOP
      ENDIF
      cStem := Left( cF, nLen )
      AAdd( aOut, cStem )
   NEXT

   dfPgUpsizeSortStrAsc( aOut )

RETURN aOut

*******************************************************************************
STATIC FUNCTION dfPgUpsizeOrdersXmlForBase( cBase, aCdxStems, cDbfRel, cLf )
*******************************************************************************
LOCAL k, cStem, cBlock

   cBlock := ""

   IF ValType( aCdxStems ) != "A"
      RETURN cBlock
   ENDIF

   FOR k := 1 TO Len( aCdxStems )
      cStem := aCdxStems[k]
      IF dfPgUpsizeCdxStemMatchesBase( cStem, cBase )
         cBlock += "        <order>" + dfXmlAttrEscape( cDbfRel + cStem + ".CDX" ) + "</order>" + cLf
      ENDIF
   NEXT

RETURN cBlock

*******************************************************************************
//* Normalizza FILE_ALI / stem in path ordine upsize: sempre file .CDX (Fox compound).
STATIC FUNCTION dfPgUpsizeOrderPathCdx( cDir, cStemRaw )
*******************************************************************************
LOCAL cStem, cU

   IF ValType( cDir ) != "C" .OR. ValType( cStemRaw ) != "C" .OR. Empty( RTrim( cStemRaw ) )
      RETURN ""
   ENDIF

   cStem := RTrim( cStemRaw )
   cU    := Upper( cStem )

   IF Right( cU, 4 ) == ".CDX"
      RETURN cDir + cStem
   ENDIF

   IF Right( cU, 4 ) == ".NTX" .OR. Right( cU, 4 ) == ".NDX"
      RETURN cDir + Left( cStem, Len( cStem ) - 4 ) + ".CDX"
   ENDIF

RETURN cDir + cStem + ".CDX"

*******************************************************************************
//* Blocco <order>: da DBDD (NDX+PADR(stem,8), FILE_ALI come ddUsePg.ddUse), poi
//* merge con *.CDX in directory tabella. Upsize = solo indici CDX.
STATIC FUNCTION dfPgUpsizeOrdersXmlFromDbddAndDir( cBase, cDirTbl, cLf )
*******************************************************************************
LOCAL cBlock, cDir, cFNdx, nSav, cAliRaw, cStem, nNdxNum, uPath, aSeen, k, cStemF, cFull, aCdxRow, cMacro

   cBlock := ""
   aSeen  := {}

   IF ValType( cBase ) != "C" .OR. Empty( cBase ) .OR. ValType( cDirTbl ) != "C" .OR. Empty( cDirTbl ) .OR. ValType( cLf ) != "C"
      RETURN cBlock
   ENDIF

   cDir := dfPgUpsizeEnsureTrailSlash( RTrim( cDirTbl ) )

   cFNdx := Upper( PADR( RTrim( cBase ), 8 ) )

   nSav := Select()

   IF Select( "dbdd" ) == 0
      IF !dbCfgOpen( "dbDD" )
         IF nSav > 0 .AND. nSav <= 250 .AND. !Empty( Alias( nSav ) )
            DBSELECTAREA( nSav )
         ENDIF
         aCdxRow := dfPgUpsizeDirectoryCdxStems( cDir )
         RETURN dfPgUpsizeOrdersXmlForBase( cBase, aCdxRow, cDir, cLf )
      ENDIF
   ENDIF

   SELECT dbdd
   dbdd->( DbSeek( "NDX" + cFNdx ) )

   nNdxNum := 0
   DO WHILE Upper( dbdd->RecTyp + dbdd->file_name ) == "NDX" + cFNdx .AND. ;
         nNdxNum <= 15 .AND. ;
         ! dbdd->( Eof() )

      nNdxNum++

      cAliRaw := dbdd->FILE_ALI

      IF ValType( cAliRaw ) != "C"
         dbdd->( DbSkip() )
         LOOP
      ENDIF

      cStem := ""

      IF Left( cAliRaw, 1 ) == "@"
         cMacro := SubStr( cAliRaw, 2 )
         IF Type( cMacro ) == "C"
            cStem := RTrim( &cMacro. )
         ENDIF
      ELSE
         cStem := RTrim( cAliRaw )
      ENDIF

      IF !Empty( cStem )
         cFull := dfPgUpsizeOrderPathCdx( cDir, cStem )
         IF !Empty( cFull )
            uPath := Upper( RTrim( cFull ) )
            IF AScan( aSeen, {|p| p == uPath} ) == 0
               AAdd( aSeen, uPath )
               cBlock += "        <order>" + dfXmlAttrEscape( cFull ) + "</order>" + cLf
            ENDIF
         ENDIF
      ENDIF

      dbdd->( DbSkip() )
   ENDDO

   IF nSav > 0 .AND. nSav <= 250 .AND. !Empty( Alias( nSav ) )
      DBSELECTAREA( nSav )
   ENDIF

   aCdxRow := dfPgUpsizeDirectoryCdxStems( cDir )
   FOR k := 1 TO Len( aCdxRow )
      cStemF := aCdxRow[k]
      IF dfPgUpsizeCdxStemMatchesBase( cStemF, cBase )
         cFull := dfPgUpsizeOrderPathCdx( cDir, cStemF )
         uPath := Upper( RTrim( cFull ) )
         IF AScan( aSeen, {|p| p == uPath} ) == 0
            AAdd( aSeen, uPath )
            cBlock += "        <order>" + dfXmlAttrEscape( cFull ) + "</order>" + cLf
         ENDIF
      ENDIF
   NEXT

RETURN cBlock

//*******************************************************************************
//* path.ini accanto a Menu.exe (EXE): chiavi UserPath01, UserPath02, ...
//* Valori = directory dei dati applicativi (es. APPDATA2024). Solo da li' si elencano i .DBF per UPSIZE.runtime.upsize.
STATIC FUNCTION dfPgUpsizePathIniFullPath( cTplDir )
//*******************************************************************************
LOCAL cExe, cTry, cEnv, aRel, i, cCur

   cEnv := AllTrim( GetEnv( "VDB_PG_PATH_INI" ) )
   IF ValType( cEnv ) == "C" .AND. !Empty( cEnv ) .AND. File( cEnv )
      RETURN cEnv
   ENDIF

   cExe := RTrim( dfPgExeDirectory() )
   IF ValType( cExe ) == "C" .AND. !Empty( cExe )
      cExe := dfPgUpsizeEnsureTrailSlash( cExe )
      IF File( cExe + "path.ini" )
         RETURN cExe + "path.ini"
      ENDIF
   ENDIF

//* Standalone: risolvi path.ini dal template progetto (SOURCE\pg\UPSIZE.upsize -> ..\..\EXE\path.ini).
   IF ValType( cTplDir ) == "C" .AND. !Empty( RTrim( cTplDir ) )
      cTplDir := dfPgUpsizeEnsureTrailSlash( RTrim( cTplDir ) )
      aRel := { "..\..\EXE\path.ini", "..\EXE\path.ini", "EXE\path.ini", "path.ini" }
      FOR i := 1 TO Len( aRel )
         cTry := cTplDir + aRel[i]
         IF File( cTry )
            RETURN cTry
         ENDIF
      NEXT
   ENDIF

//* Fallback cwd per casi ad-hoc da cartella EXE del progetto.
   cCur := CurDir()
   IF ValType( cCur ) == "C" .AND. !Empty( cCur )
      cCur := dfPgUpsizeEnsureTrailSlash( cCur )
      IF File( cCur + "path.ini" )
         RETURN cCur + "path.ini"
      ENDIF
      IF File( cCur + "..\EXE\path.ini" )
         RETURN cCur + "..\EXE\path.ini"
      ENDIF
   ENDIF

RETURN ""

//*******************************************************************************
//* Array di directory (con \ finale), deduplicate, da path.ini [UserPath*].
STATIC FUNCTION dfPgUpsizeReadUserPathDirsFromPathIni( cTplDir )
//*******************************************************************************
LOCAL cIni, cAll, cSeek, nPos, cLine, nEq, cKey, cVal, aOut, cNorm, nScan

   aOut := {}

   cIni := dfPgUpsizePathIniFullPath( cTplDir )
   IF Empty( cIni )
      RETURN aOut
   ENDIF

   cAll := dfVdbReadWholeFile( cIni )
   IF ValType( cAll ) != "C" .OR. Empty( cAll )
      RETURN aOut
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
         LOOP
      ENDIF

      nEq := At( "=", cLine )
      IF nEq < 1
         LOOP
      ENDIF

      cKey := Upper( AllTrim( Left( cLine, nEq - 1 ) ) )
      IF Left( cKey, 8 ) != "USERPATH"
         LOOP
      ENDIF

      cVal := AllTrim( SubStr( cLine, nEq + 1 ) )
      IF ValType( cVal ) != "C" .OR. Empty( cVal )
         LOOP
      ENDIF

      IF ( Left( cVal, 1 ) == Chr( 34 ) .OR. Left( cVal, 1 ) == "'" ) .AND. Len( cVal ) >= 2
         IF Right( cVal, 1 ) == Chr( 34 ) .OR. Right( cVal, 1 ) == "'"
            cVal := SubStr( cVal, 2, Len( cVal ) - 2 )
         ENDIF
      ENDIF

      cNorm := dfPgUpsizeEnsureTrailSlash( RTrim( cVal ) )
      IF Empty( cNorm )
         LOOP
      ENDIF

      nScan := AScan( aOut, {|p| ValType( p ) == "C" .AND. Upper( RTrim( p ) ) == Upper( RTrim( cNorm ) ) } )
      IF nScan > 0
         LOOP
      ENDIF

      AAdd( aOut, cNorm )
   ENDDO

RETURN aOut

//*******************************************************************************
//* Righe { stem, pathDbf } da una o piu' directory (merge come ExtraDbfDir).
STATIC FUNCTION dfPgUpsizeDbfRowsFromUserPathDirs( aDirs )
//*******************************************************************************
LOCAL aRows, i

   aRows := {}

   IF ValType( aDirs ) != "A" .OR. Len( aDirs ) < 1
      RETURN aRows
   ENDIF

   FOR i := 1 TO Len( aDirs )
      IF ValType( aDirs[i] ) == "C" .AND. !Empty( RTrim( aDirs[i] ) )
         dfPgUpsizeMergeExtraDbfDir( aRows, aDirs[i] )
      ENDIF
   NEXT

   IF Len( aRows ) > 0
      dfPgUpsizeSortDbfRows( aRows )
   ENDIF

RETURN aRows

*******************************************************************************
STATIC FUNCTION dfPgUpsizeBuildTablesXml( cTplDir, lNoTemplate )
*******************************************************************************
LOCAL cExeDir, cDbfRel, cLf, aRows, i, cBase, cDbe, cFname, cOrders, cBlock, cQ, aExe, cScan, cExtra, cDirTbl
LOCAL aUserDirs, lIgnorePathIni, lFromPathIni

   aUserDirs    := {}
   aRows        := {}
   lFromPathIni := .F.

   cLf     := dfPgUpsizeXmlLf()
   cQ      := dfPgUpsizeXmlQuot()
   cTplDir := dfPgUpsizeEnsureTrailSlash( cTplDir )
   IF ValType( lNoTemplate ) != "L"
      lNoTemplate := .F.
   ENDIF

//* Preferire EXE reale da AppName(): path assoluti in XML (evita DbUseArea su ..\..\EXE\*.dbf con CurDir in SOURCE\pg).
   IF lNoTemplate
      cScan := RTrim( CurDir() )
   ELSE
      cScan := RTrim( dfPgExeDirectory() )
   ENDIF
   IF ValType( cScan ) == "C" .AND. !Empty( cScan )
      IF !( Right( cScan, 1 ) == "\" .OR. Right( cScan, 1 ) == "/" )
         cScan += "\"
      ENDIF
   ENDIF

   IF ValType( cScan ) == "C" .AND. !Empty( cScan ) .AND. Len( Directory( cScan + "*.DBF" ) ) > 0
      cExeDir := cScan
      cDbfRel := cExeDir
   ELSE
      aExe    := dfPgUpsizeExeDirAndRelFromTpl( cTplDir )
      cExeDir := aExe[1]
      cDbfRel := aExe[2]
   ENDIF

   IF !( Right( cDbfRel, 1 ) == "\" .OR. Right( cDbfRel, 1 ) == "/" )
      cDbfRel := dfPgUpsizeEnsureTrailSlash( cDbfRel )
   ENDIF

   lIgnorePathIni := Upper( AllTrim( dfPgUpsizeIniUpsizeOnly( "PgUpsizeIgnorePathIni" ) ) )
   lIgnorePathIni := ( lIgnorePathIni == "YES" .OR. lIgnorePathIni == "1" .OR. lIgnorePathIni == "TRUE" )
   IF lNoTemplate
//* Standalone senza SOURCE: path.ini deve essere sempre considerato.
      lIgnorePathIni := .F.
   ENDIF

   IF !lIgnorePathIni
      aUserDirs := dfPgUpsizeReadUserPathDirsFromPathIni( cTplDir )
      dfPgUpsizeTraceBuildMsg( "UPSIZE.runtime.upsize", "BuildTablesXml: path.ini dirs=" + LTrim( Str( Len( aUserDirs ) ) ) )
      IF Len( aUserDirs ) > 0
         aRows := dfPgUpsizeDbfRowsFromUserPathDirs( aUserDirs )
         dfPgUpsizeTraceBuildMsg( "UPSIZE.runtime.upsize", "BuildTablesXml: rows from path.ini=" + LTrim( Str( Len( aRows ) ) ) )
         IF Len( aRows ) > 0
            lFromPathIni := .T.
         ENDIF
      ENDIF
   ENDIF

   IF !lFromPathIni
      IF dfPgUpsizeTableSourceDbdd()
         aRows := dfPgUpsizeDbddDbfRows( cExeDir )
         IF Len( aRows ) < 1
//* DBDD vuoto o non disponibile: fallback scan EXE (comportamento precedente).
            aRows := dfPgUpsizeDirectoryDbfRows( cExeDir )
         ENDIF
      ELSE
         aRows := dfPgUpsizeDirectoryDbfRows( cExeDir )
      ENDIF

      cExtra := dfPgUpsizeExtraDbfDir()
      IF ValType( cExtra ) == "C" .AND. !Empty( RTrim( cExtra ) )
         dfPgUpsizeMergeExtraDbfDir( aRows, cExtra )
         dfPgUpsizeSortDbfRows( aRows )
      ENDIF
   ENDIF

   IF Len( aRows ) < 1
      RETURN ""
   ENDIF

   cBlock := ""

   FOR i := 1 TO Len( aRows )
      cBase   := aRows[i][1]
      cDbe    := dfPgUpsizeTableDbe( cBase )
      cFname  := aRows[i][2]
      cDirTbl := dfPgUpsizeDirParentWithSlash( cFname )
      IF Empty( cDirTbl )
         cDirTbl := cDbfRel
      ENDIF
      cOrders := dfPgUpsizeOrdersXmlFromDbddAndDir( cBase, cDirTbl, cLf )

      cBlock += "    <table name = " + cQ + dfXmlAttrEscape( cBase ) + cQ + cLf
      cBlock += "           dbe  = " + cQ + dfXmlAttrEscape( cDbe ) + cQ + cLf
      cBlock += "           dbf  = " + cQ + dfXmlAttrEscape( cFname ) + cQ + ">" + cLf

      IF !Empty( cOrders )
         cBlock += cOrders
      ENDIF

      cBlock += "    </table>" + cLf
      cBlock += "    <upsize table=" + cQ + dfXmlAttrEscape( cBase ) + cQ + " connection=" + cQ + "connection" + cQ + " mode=" + cQ + "isam" + cQ + " />" + cLf
      cBlock += cLf
   NEXT

RETURN cBlock

*******************************************************************************
//* Rimuove commenti XML <!-- ... --> (es. esempio tabelle nel template) cosi' <table nell'esempio non confonde lo strip.
STATIC FUNCTION dfPgUpsizeRemoveXmlComments( cXml )
*******************************************************************************
LOCAL nO, nC, cRest, nGuard

   IF ValType( cXml ) != "C" .OR. Empty( cXml )
      RETURN ""
   ENDIF

   nGuard := 0

   DO WHILE .T.

      nGuard++
      IF nGuard > 200
         EXIT
      ENDIF

      nO := At( "<!--", Lower( cXml ) )

      IF nO < 1
         EXIT
      ENDIF

      cRest := SubStr( cXml, nO )
      nC    := At( "-->", cRest )

      IF nC < 1
         EXIT
      ENDIF

      cXml := Left( cXml, nO - 1 ) + LTrim( SubStr( cRest, nC + 3 ) )

   ENDDO

RETURN cXml

*******************************************************************************
//* Rimuove blocchi <table ... </table> + <upsize .../> gia' presenti (runtime vecchio o copia nel template).
//* Si assume l'ordine table poi upsize self-close come nel template generato; non e' un parser XML completo.
STATIC FUNCTION dfPgUpsizeStripLegacyTableBlocks( cXml )
*******************************************************************************
LOCAL nConf, cPre, cTail, nTab, nUps, nSlash, nAfter, nGuard, cLow, cTailPart, cUp

   IF ValType( cXml ) != "C" .OR. Empty( cXml )
      RETURN ""
   ENDIF

   cLow  := Lower( cXml )
   nConf := RAt( "</config>", cLow )

   IF nConf < 1
      RETURN cXml
   ENDIF

   cPre  := Left( cXml, nConf - 1 )
   cTail := SubStr( cXml, nConf )
   nGuard := 0

   DO WHILE .T.

      nGuard++
      IF nGuard > 500
         EXIT
      ENDIF

      nTab := RAt( "<table", Lower( cPre ) )

      IF nTab < 1
         EXIT
      ENDIF

      cTailPart := SubStr( cPre, nTab )
      nUps        := At( "<upsize", Lower( cTailPart ) )

      IF nUps < 1
         EXIT
      ENDIF

      cUp    := SubStr( cTailPart, nUps )
      nSlash := At( "/>", cUp )

      IF nSlash < 1
         EXIT
      ENDIF

//* Fine blocco `/>` dell'elemento <upsize .../> (nUps/nSlash sono indici 1-based in cTailPart / cUp).
      nAfter := nTab + nUps + nSlash
      cPre   := Left( cPre, nTab - 1 ) + LTrim( SubStr( cPre, nAfter + 1 ) )

   ENDDO

RETURN RTrim( cPre ) + cTail

*******************************************************************************
STATIC FUNCTION dfPgUpsizeInsertTablesBeforeClosingConfig( cXml, cTables )
*******************************************************************************
LOCAL n, cLf, cHead, cTail

   IF ValType( cXml ) != "C" .OR. Empty( cXml )
      RETURN ""
   ENDIF

   cLf := dfPgUpsizeXmlLf()
   n   := RAt( "</config>", Lower( cXml ) )

   IF n < 1
      RETURN ""
   ENDIF

   cHead := RTrim( Left( cXml, n - 1 ) )
   cTail := SubStr( cXml, n )

   IF ValType( cTables ) == "C" .AND. !Empty( cTables )
      RETURN cHead + cLf + cLf + cTables + cTail
   ENDIF

RETURN cHead + cTail

*******************************************************************************
STATIC FUNCTION dfPgUpsizeReplaceConnectionXml( cXml, cSrv, cUid, cPwd, cDatabase )
*******************************************************************************
LOCAL cScan, n1, cRest, nSlash, cNew, cLf, cQ, cPwdOut

   IF ValType( cXml ) != "C" .OR. Empty( cXml )
      RETURN ""
   ENDIF

   cScan := Upper( cXml )
   n1 := At( "<CONNECTION", cScan )
   IF n1 < 1
      RETURN cXml
   ENDIF

   cRest := SubStr( cXml, n1 )
   nSlash := At( "/>", cRest )
   IF nSlash < 1
      RETURN cXml
   ENDIF

   cLf := dfPgUpsizeXmlLf()
   cQ  := dfPgUpsizeXmlQuot()

   cPwdOut := dfPgPwdForDacAndUpsize( cPwd )
//* DbfUpsize tratta PWD vuoto dopo trim come assente: uno spazio solo non basta.
   IF ValType( cPwdOut ) != "C" .OR. Empty( AllTrim( cPwdOut ) )
      cPwdOut := "-"
   ENDIF

//* Attributi DBE, SRV, UID, PWD, DATABASE; valore DBE come motore registrato (PGDBE).
   cNew := "    <connection name     = " + cQ + "connection" + cQ + cLf
   cNew += "                DBE      = " + cQ + "PGDBE" + cQ + cLf
   cNew += "                SRV      = " + cQ + dfXmlAttrEscape( cSrv ) + cQ + cLf
   cNew += "                UID      = " + cQ + dfXmlAttrEscape( cUid ) + cQ + cLf
   cNew += "                PWD      = " + cQ + dfXmlAttrEscape( cPwdOut ) + cQ + cLf
   cNew += "                DATABASE = " + cQ + dfXmlAttrEscape( cDatabase ) + cQ + "/>" + cLf

RETURN Left( cXml, n1 - 1 ) + cNew + SubStr( cXml, n1 + nSlash + 1 )

*******************************************************************************
STATIC FUNCTION dfPgUpsizeDefaultRuntimeXml( cSrv, cUid, cPwd, cDatabase )
*******************************************************************************
LOCAL cLf, cQ, cPwdOut, cXml

   cLf := dfPgUpsizeXmlLf()
   cQ  := dfPgUpsizeXmlQuot()

   cPwdOut := dfPgPwdForDacAndUpsize( cPwd )
   IF ValType( cPwdOut ) != "C" .OR. Empty( AllTrim( cPwdOut ) )
      cPwdOut := "-"
   ENDIF

   cXml := '<?xml version="1.0" encoding="iso-8859-1" standalone="yes"?>' + cLf
   cXml += "<config>" + cLf
   cXml += "    <database_engines>" + cLf
   cXml += "        <dbebuild name=" + cQ + "DBFNTX" + cQ + ">" + cLf
   cXml += "            <storage name=" + cQ + "DBFDBE" + cQ + "/>" + cLf
   cXml += "            <order name=" + cQ + "NTXDBE" + cQ + "/>" + cLf
   cXml += "        </dbebuild>" + cLf
   cXml += "        <dbebuild name=" + cQ + "DBFCDX" + cQ + ">" + cLf
   cXml += "            <storage name=" + cQ + "DBFDBE" + cQ + "/>" + cLf
   cXml += "            <order name=" + cQ + "CDXDBE" + cQ + "/>" + cLf
   cXml += "        </dbebuild>" + cLf
   cXml += "        <dbebuild name=" + cQ + "FOXCDX" + cQ + ">" + cLf
   cXml += "            <storage name=" + cQ + "FOXDBE" + cQ + "/>" + cLf
   cXml += "            <order name=" + cQ + "CDXDBE" + cQ + "/>" + cLf
   cXml += "        </dbebuild>" + cLf
   cXml += '        <dbeload name="PGDBE"/>' + cLf
   cXml += "    </database_engines>" + cLf + cLf
   cXml += "    <connection name     = " + cQ + "connection" + cQ + cLf
   cXml += "                DBE      = " + cQ + "PGDBE" + cQ + cLf
   cXml += "                SRV      = " + cQ + dfXmlAttrEscape( cSrv ) + cQ + cLf
   cXml += "                UID      = " + cQ + dfXmlAttrEscape( cUid ) + cQ + cLf
   cXml += "                PWD      = " + cQ + dfXmlAttrEscape( cPwdOut ) + cQ + cLf
   cXml += "                DATABASE = " + cQ + dfXmlAttrEscape( cDatabase ) + cQ + "/>" + cLf + cLf
   cXml += "</config>" + cLf

RETURN cXml

*******************************************************************************
FUNCTION dfPgUpsizeBuildRuntimeCfg( cTplPath )
*******************************************************************************
LOCAL cDir, cOut, cBody, cMerged, cSrv, cUid, cPwd, cDb, cTables
LOCAL cTplUsed, cExe, cPathIniEnv
LOCAL lWritten, nTry, cOutTry, cStamp, cTmpDir

   cTplUsed := ""
   IF ValType( cTplPath ) == "C" .AND. !Empty( cTplPath ) .AND. File( cTplPath )
      cTplUsed := cTplPath
   ENDIF

   dfPgUpsizeSetTemplateForIni( cTplUsed )

   IF !Empty( cTplUsed )
      cDir := dfPgUpsizeCfgDirectory( cTplUsed )
   ELSE
      cPathIniEnv := AllTrim( GetEnv( "VDB_PG_PATH_INI" ) )
      IF ValType( cPathIniEnv ) == "C" .AND. !Empty( cPathIniEnv ) .AND. File( cPathIniEnv )
         cDir := dfPgUpsizeDirParentWithSlash( cPathIniEnv )
      ENDIF
      IF ValType( cDir ) != "C" .OR. Empty( cDir )
         cDir := CurDir()
      ENDIF
      IF ValType( cDir ) != "C" .OR. Empty( cDir )
         cExe := dfPgExeDirectory()
         IF ValType( cExe ) == "C" .AND. !Empty( cExe )
            cDir := cExe
         ELSE
            cDir := CurDir()
         ENDIF
      ENDIF
      cDir := dfPgUpsizeEnsureTrailSlash( cDir )
   ENDIF

   IF Empty( cDir )
      cDir := dfPgUpsizeEnsureTrailSlash( CurDir() )
   ENDIF

   cOut := cDir + "UPSIZE.runtime.upsize"

   IF !Empty( cTplUsed )
      dfPgUpsizeTraceBuildMsg( cOut, "BuildRuntimeCfg: start tpl=" + cTplUsed )
   ELSE
      dfPgUpsizeTraceBuildMsg( cOut, "BuildRuntimeCfg: start no-template (from INI/path.ini)" )
   ENDIF

   cSrv := dfPgUpsizeConnSrv()
   cUid := dfPgUpsizeConnUid()
   cPwd := dfPgUpsizeConnPwd()
   cDb  := dfPgUpsizeConnDatabase()

   IF !Empty( cTplUsed )
      cBody := dfVdbReadWholeFile( cTplUsed )
      IF Empty( cBody )
         dfPgUpsizeTraceBuildMsg( cOut, "BuildRuntimeCfg: abort template body vuoto" )
         dfPgUpsizeSetTemplateForIni( "" )
         RETURN ""
      ENDIF

      cBody := dfPgUpsizeRemoveXmlComments( cBody )
      cBody := dfPgUpsizeStripLegacyTableBlocks( cBody )

//* DbfUpsize: <connection DBE=...> deve coincidere con il nome registrato (PGDBE). Template legacy "pgdbe" -> fallisce verify ("requires ... attributes").
      cBody := StrTran( cBody, '<dbeload name="pgdbe"/>', '<dbeload name="PGDBE"/>' )
      cBody := StrTran( cBody, '<dbeload name="Pgdbe"/>', '<dbeload name="PGDBE"/>' )
   ELSE
      cBody := dfPgUpsizeDefaultRuntimeXml( cSrv, cUid, cPwd, cDb )
   ENDIF

   cMerged := dfPgUpsizeReplaceConnectionXml( cBody, cSrv, cUid, cPwd, cDb )
   IF !Empty( cMerged )
      cBody := cMerged
   ENDIF

   cTables := dfPgUpsizeBuildTablesXml( dfPgUpsizeEnsureTrailSlash( cDir ), Empty( cTplUsed ) )
   IF Empty( cTables )
      dfPgUpsizeTraceBuildMsg( cOut, "BuildRuntimeCfg: abort BuildTablesXml vuoto (nessun .DBF in EXE o DBDD senza file)" )
      dfPgUpsizeSetTemplateForIni( "" )
      RETURN ""
   ENDIF

   cBody := dfPgUpsizeInsertTablesBeforeClosingConfig( cBody, cTables )

   IF Empty( cBody )
      dfPgUpsizeTraceBuildMsg( cOut, "BuildRuntimeCfg: abort dopo InsertTables (XML vuoto)" )
      dfPgUpsizeSetTemplateForIni( "" )
      RETURN ""
   ENDIF

//* Alcuni lock (AV/indexer/editor) sono transitori: riprova brevemente prima di fallire.
   lWritten := .F.
   cOutTry  := cOut
   FOR nTry := 1 TO 5
      IF File( cOutTry )
         FERASE( cOutTry )
      ENDIF

      lWritten := dfVdbWriteWholeFile( cOutTry, cBody )
      IF lWritten
         cOut := cOutTry
         EXIT
      ENDIF

      Inkey( 0.2 )
   NEXT

//* Se il file standard resta bloccato, usa un runtime alternativo univoco nella stessa cartella.
   IF !lWritten
      cStamp := StrTran( DToS( Date() ) + "_" + StrTran( Time(), ":", "" ), " ", "" )
      cOutTry := cDir + "UPSIZE.runtime." + cStamp + ".upsize"
      lWritten := dfVdbWriteWholeFile( cOutTry, cBody )
      IF lWritten
         cOut := cOutTry
         dfPgUpsizeTraceBuildMsg( cOut, "BuildRuntimeCfg: fallback su file runtime alternativo: " + cOutTry )
      ENDIF
   ENDIF

//* Ultimo fallback: usa TEMP utente (evita lock/ACL su EXE monitorata da altri processi).
   IF !lWritten
      cTmpDir := AllTrim( GetEnv( "TEMP" ) )
      IF ValType( cTmpDir ) == "C" .AND. !Empty( cTmpDir )
         cTmpDir := dfPgUpsizeEnsureTrailSlash( cTmpDir )
         cOutTry := cTmpDir + "UPSIZE.runtime." + cStamp + ".upsize"
         lWritten := dfVdbWriteWholeFile( cOutTry, cBody )
         IF lWritten
            cOut := cOutTry
            dfPgUpsizeTraceBuildMsg( cOut, "BuildRuntimeCfg: fallback su TEMP: " + cOutTry )
         ENDIF
      ENDIF
   ENDIF

   IF !lWritten
      dfPgUpsizeTraceBuildMsg( cOut, "BuildRuntimeCfg: abort dfVdbWriteWholeFile fallito (file bloccato?)" )
      dfPgUpsizeSetTemplateForIni( "" )
      RETURN ""
   ENDIF

   dfPgUpsizeTraceRegenLine( cOut, Len( cBody ) )

   dfPgUpsizeSetTemplateForIni( "" )

RETURN cOut
