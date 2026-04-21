//*****************************************************************************
// PGDBE: allineamento seek campo-based (condiviso da DFS.PRG e DBLOOK.PRG).
// Nessuna macro su ORDKEY: solo nomi campo semplici o PADR(campo,n).
//*****************************************************************************

*******************************************************************************
FUNCTION dfPgRddIs( cRdd )
//*******************************************************************************
   IF VALTYPE( cRdd ) != "C"
      RETURN .F.
   ENDIF

RETURN ( "PGDBE" $ UPPER( RTRIM( cRdd ) ) )

*******************************************************************************
FUNCTION dfPgOrdKeySingleField( cKeyExp )
//*******************************************************************************
LOCAL cF, cU, cInner, lChg, cFld

   IF VALTYPE( cKeyExp ) != "C" .OR. EMPTY( ALLTRIM( cKeyExp ) )
      RETURN ""
   ENDIF

   cF := RTRIM( cKeyExp )

   IF ( "+" $ cF )
      cF := ""
   ENDIF

   // Sgancia PADR / UPPER / LOWER / RTRIM / LTRIM (un solo argomento) fino al nome campo.
   // Esempio reale: PADR(UPPER(nome),60) — prima restituiva "" e dfS(PG) usava fallback "codice".
   DO WHILE .T.
      lChg := .F.
      cF   := ALLTRIM( cF )
      cU   := UPPER( cF )

      IF _dfPgOrdKeyStartsFunc( cF, "PADR" )
         cInner := _dfPgOrdKeyPadArg( cF )
         IF EMPTY( cInner )
            EXIT
         ENDIF
         cF   := cInner
         lChg := .T.
      ELSEIF _dfPgOrdKeyStartsFunc( cF, "UPPER" ) .OR. ;
             _dfPgOrdKeyStartsFunc( cF, "LOWER" ) .OR. ;
             _dfPgOrdKeyStartsFunc( cF, "RTRIM" ) .OR. ;
             _dfPgOrdKeyStartsFunc( cF, "LTRIM" ) .OR. ;
             _dfPgOrdKeyStartsFunc( cF, "TRIM" )  .OR. ;
             _dfPgOrdKeyStartsFunc( cF, "ALLTRIM" )
         cInner := _dfPgOrdKeyFnArg( cF )
         IF EMPTY( cInner )
            EXIT
         ENDIF
         cF   := cInner
         lChg := .T.
      ELSE
         EXIT
      ENDIF

      IF !lChg
         EXIT
      ENDIF
   ENDDO

   IF ( "+" $ cF )
      cF := ""
   ENDIF

   cF := _dfPgOrdKeyStripAlias( cF )

   IF ( "(" $ cF ) .OR. ( " " $ cF )
      cF := ""
   ENDIF

   IF !EMPTY( cF )
      RETURN cF
   ENDIF

   cFld := _dfPgOrdKeyFieldFromExpr( cKeyExp )

RETURN cFld

*******************************************************************************
FUNCTION dfPgOrdResolveField( cKeyExp, uOrd, uSeek )
//*******************************************************************************
LOCAL cFld

   cFld := dfPgOrdKeySingleField( cKeyExp )
   IF !EMPTY( cFld )
      RETURN cFld
   ENDIF

   cFld := _dfPgOrdUniqueSeekField( uSeek )

RETURN cFld

*******************************************************************************
STATIC FUNCTION _dfPgOrdKeyStartsFunc( cExpr, cFunc )
//*******************************************************************************
LOCAL cU

   IF VALTYPE( cExpr ) != "C" .OR. VALTYPE( cFunc ) != "C"
      RETURN .F.
   ENDIF

   cU := UPPER( ALLTRIM( cExpr ) )
RETURN LEFT( cU, LEN( cFunc ) ) == cFunc .AND. SUBSTR( cU, LEN( cFunc ) + 1, 1 ) $ " ("

*******************************************************************************
STATIC FUNCTION _dfPgOrdKeyFnArg( cExpr )
//*******************************************************************************
LOCAL n1, n2

   IF VALTYPE( cExpr ) != "C"
      RETURN ""
   ENDIF

   n1 := AT( "(", cExpr )
   n2 := RAT( ")", cExpr )
   IF n1 < 1 .OR. n2 < n1 + 1
      RETURN ""
   ENDIF

RETURN ALLTRIM( SUBSTR( cExpr, n1 + 1, n2 - n1 - 1 ) )

*******************************************************************************
STATIC FUNCTION _dfPgOrdKeyStripAlias( cExpr )
//*******************************************************************************
LOCAL nAt

   IF VALTYPE( cExpr ) != "C"
      RETURN ""
   ENDIF

   cExpr := ALLTRIM( cExpr )
   nAt := AT( "->", cExpr )
   IF nAt > 0
      cExpr := ALLTRIM( SUBSTR( cExpr, nAt + 2 ) )
   ENDIF

RETURN cExpr

STATIC FUNCTION _dfPgOrdUniqueSeekField( uSeek )
//*******************************************************************************
LOCAL aStru, cSeek, cFld, cHitFld, i, nRec, nW, nBestW

   IF SELECT() < 1
      RETURN ""
   ENDIF

   IF !dfPgRddIs( RDDNAME() )
      RETURN ""
   ENDIF

   cSeek := RTRIM( dfAny2Str( uSeek, "" ) )
   IF EMPTY( cSeek )
      RETURN ""
   ENDIF

   aStru := DbStruct()
   IF VALTYPE( aStru ) != "A"
      RETURN ""
   ENDIF

   nRec := IF( EOF() .OR. BOF(), 0, RECNO() )
   cHitFld := ""
   nBestW := 0

   FOR i := 1 TO LEN( aStru )
      IF VALTYPE( aStru[i] ) == "A" .AND. LEN( aStru[i] ) >= 3
         IF VALTYPE( aStru[i,1] ) == "C" .AND. VALTYPE( aStru[i,2] ) == "C" .AND. ;
               UPPER( aStru[i,2] ) $ "CM"
            cFld := RTRIM( aStru[i,1] )
            IF _dfPgFieldHasSeekValue( cFld, cSeek )
               nW := 0
               IF VALTYPE( aStru[i,3] ) == "N"
                  nW := aStru[i,3]
               ENDIF
               IF EMPTY( cHitFld ) .OR. nBestW == 0 .OR. ( nW > 0 .AND. nW < nBestW )
                  cHitFld := cFld
                  nBestW := nW
               ENDIF
            ENDIF
         ENDIF
      ENDIF
   NEXT

   IF nRec > 0
      DBGOTO( nRec )
   ELSE
      DBGOTO( 0 )
   ENDIF

   IF !EMPTY( cHitFld )
      RETURN cHitFld
   ENDIF

RETURN ""

*******************************************************************************
STATIC FUNCTION _dfPgFieldHasSeekValue( cField, cSeek )
//*******************************************************************************
LOCAL cSeekU

   IF VALTYPE( cField ) != "C" .OR. EMPTY( cField )
      RETURN .F.
   ENDIF

   cSeekU := UPPER( RTRIM( cSeek ) )

   DBGOTOP()
   DO WHILE !EOF()
      IF dfPgSeekFieldValU( PADR( UPPER( ALIAS() ), 8 ), cField ) == cSeekU
         RETURN .T.
      ENDIF
      DBSKIP( 1 )
   ENDDO

RETURN .F.

*******************************************************************************
STATIC FUNCTION _dfPgOrdKeyFieldFromExpr( cExpr )
//*******************************************************************************
LOCAL aStru, cNorm, cFld, i, nPos, nBestPos

   IF VALTYPE( cExpr ) != "C" .OR. SELECT() < 1
      RETURN ""
   ENDIF

   aStru := DbStruct()
   IF VALTYPE( aStru ) != "A"
      RETURN ""
   ENDIF

   cNorm := _dfPgOrdKeyNormExpr( cExpr )
   cFld  := ""
   nBestPos := 0

   FOR i := 1 TO LEN( aStru )
      IF VALTYPE( aStru[i] ) == "A" .AND. LEN( aStru[i] ) >= 1 .AND. VALTYPE( aStru[i,1] ) == "C"
         nPos := _dfPgOrdKeyTokenPos( cNorm, UPPER( RTRIM( aStru[i,1] ) ) )
         IF nPos > 0
            IF nBestPos == 0 .OR. nPos < nBestPos
               nBestPos := nPos
               cFld := RTRIM( aStru[i,1] )
            ENDIF
         ENDIF
      ENDIF
   NEXT

RETURN cFld

*******************************************************************************
STATIC FUNCTION _dfPgOrdKeyNormExpr( cExpr )
//*******************************************************************************
LOCAL cNorm, i, cChr

   cNorm := " " + UPPER( cExpr ) + " "

   FOR i := 1 TO LEN( cNorm )
      cChr := SUBSTR( cNorm, i, 1 )
      IF !( cChr $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_" )
         cNorm := STUFF( cNorm, i, 1, " " )
      ENDIF
   NEXT

   DO WHILE "  " $ cNorm
      cNorm := STRTRAN( cNorm, "  ", " " )
   ENDDO

RETURN cNorm

*******************************************************************************
STATIC FUNCTION _dfPgOrdKeyHasToken( cNorm, cToken )
//*******************************************************************************
LOCAL cFind

   IF VALTYPE( cNorm ) != "C" .OR. VALTYPE( cToken ) != "C" .OR. EMPTY( cToken )
      RETURN .F.
   ENDIF

   cFind := " " + UPPER( RTRIM( cToken ) ) + " "

RETURN cFind $ cNorm

*******************************************************************************
STATIC FUNCTION _dfPgOrdKeyTokenPos( cNorm, cToken )
//*******************************************************************************
LOCAL cFind

   IF VALTYPE( cNorm ) != "C" .OR. VALTYPE( cToken ) != "C" .OR. EMPTY( cToken )
      RETURN 0
   ENDIF

   cFind := " " + UPPER( RTRIM( cToken ) ) + " "

RETURN AT( cFind, cNorm )

*******************************************************************************
STATIC FUNCTION _dfPgOrdKeyPadArg( cExpr )
//*******************************************************************************
LOCAL cInner, nLev, nPos, cChr

   cInner := _dfPgOrdKeyFnArg( cExpr )
   IF EMPTY( cInner )
      RETURN ""
   ENDIF

   nLev := 0
   FOR nPos := 1 TO LEN( cInner )
      cChr := SUBSTR( cInner, nPos, 1 )
      DO CASE
      CASE cChr == "("
         nLev++
      CASE cChr == ")"
         nLev--
      CASE cChr == "," .AND. nLev == 0
         RETURN ALLTRIM( LEFT( cInner, nPos - 1 ) )
      ENDCASE
   NEXT

RETURN ""

*******************************************************************************
FUNCTION dfPgSeekFieldValU( cWaPad, cField )
//*******************************************************************************
LOCAL cWa, nPos, xVal

   cWa := RTRIM( cWaPad )
   IF SELECT( cWa ) < 1
      RETURN ""
   ENDIF

   nPos := ( cWa )->( FIELDPOS( cField ) )
   IF nPos < 1
      RETURN ""
   ENDIF

   xVal := ( cWa )->( FIELDGET( nPos ) )
   IF VALTYPE( xVal ) == "C"
      RETURN UPPER( RTRIM( xVal ) )
   ENDIF
   IF VALTYPE( xVal ) == "M"
      RETURN UPPER( RTRIM( xVal ) )
   ENDIF
   IF VALTYPE( xVal ) == "N"
      RETURN ALLTRIM( STR( xVal ) )
   ENDIF
   IF xVal == NIL .OR. VALTYPE( xVal ) == "U"
      RETURN ""
   ENDIF

RETURN ""

*******************************************************************************
FUNCTION dfPgSeekIsPartialChr( cWaPad, cField, uSeek )
//*******************************************************************************
LOCAL cWa, aStru, i, nW

   cWa := RTRIM( cWaPad )
   IF SELECT( cWa ) < 1
      RETURN .F.
   ENDIF

   IF VALTYPE( uSeek ) != "C" .OR. EMPTY( RTRIM( uSeek ) )
      RETURN .F.
   ENDIF

   IF VALTYPE( cField ) != "C" .OR. EMPTY( cField )
      RETURN .F.
   ENDIF

   nW := 0
   aStru := ( cWa )->( DbStruct() )
   IF VALTYPE( aStru ) == "A"
      FOR i := 1 TO LEN( aStru )
         IF VALTYPE( aStru[i] ) == "A" .AND. LEN( aStru[i] ) >= 3
            IF UPPER( RTRIM( aStru[i,1] ) ) == UPPER( cField )
               IF VALTYPE( aStru[i,2] ) == "C" .AND. UPPER( aStru[i,2] ) == "C"
                  nW := MAX( aStru[i,3], 1 )
               ENDIF
               EXIT
            ENDIF
         ENDIF
      NEXT
   ENDIF

   IF nW > 0 .AND. LEN( RTRIM( uSeek ) ) > 0 .AND. LEN( RTRIM( uSeek ) ) < nW
      RETURN .T.
   ENDIF

RETURN .F.

*******************************************************************************
//* .T. = record corrente ok o nulla da verificare (non-PG, seek vuoto, ecc.)
FUNCTION dfPgSeekVerifyRow( cWaPad, cField, cSeekRaw )
//*******************************************************************************
LOCAL cWa, cSeekU

   cWa := RTRIM( cWaPad )
   IF SELECT( cWa ) < 1
      RETURN .T.
   ENDIF

   IF !dfPgRddIs( ( cWa )->( RDDNAME() ) )
      RETURN .T.
   ENDIF

   IF VALTYPE( cSeekRaw ) != "C" .OR. EMPTY( RTRIM( cSeekRaw ) )
      RETURN .T.
   ENDIF

   IF VALTYPE( cField ) != "C" .OR. EMPTY( cField )
      RETURN .T.
   ENDIF

   // Non saltare la verifica se dfPgSeekIsPartialChr: su PG il campo puo' essere
   // CHAR/VARCHAR piu' largo del codice (ex. C(2)->char(10)); LEN(seek)<nW
   // diventava "parziale" e si accettava il record corrente senza confronto -> stessa C_DES su tutte le righe browse.

   cSeekU := UPPER( RTRIM( cSeekRaw ) )

RETURN ( dfPgSeekFieldValU( cWa, cField ) == cSeekU )

*******************************************************************************
FUNCTION dfPgSeekFallbackScan( cWaPad, cField, cSeekRaw )
//*******************************************************************************
LOCAL cWa, cSeek, cU, aStru, i, nW, lHit

   cWa := RTRIM( cWaPad )
   IF SELECT( cWa ) < 1
      RETURN .F.
   ENDIF

   IF !dfPgRddIs( ( cWa )->( RDDNAME() ) )
      RETURN .F.
   ENDIF

   IF VALTYPE( cSeekRaw ) != "C" .OR. EMPTY( RTRIM( cSeekRaw ) )
      RETURN .F.
   ENDIF

   IF VALTYPE( cField ) != "C" .OR. EMPTY( cField )
      RETURN .F.
   ENDIF

   cSeek := RTRIM( cSeekRaw )
   cU    := UPPER( cSeek )

   nW := 0
   aStru := ( cWa )->( DbStruct() )
   IF VALTYPE( aStru ) == "A"
      FOR i := 1 TO LEN( aStru )
         IF VALTYPE( aStru[i] ) == "A" .AND. LEN( aStru[i] ) >= 3
            IF UPPER( RTRIM( aStru[i,1] ) ) == UPPER( cField )
               IF VALTYPE( aStru[i,2] ) == "C" .AND. UPPER( aStru[i,2] ) == "C"
                  nW := MAX( aStru[i,3], 1 )
               ENDIF
               EXIT
            ENDIF
         ENDIF
      NEXT
   ENDIF

   IF nW < 1
      nW := MAX( LEN( cSeek ), 1 )
   ENDIF

   lHit := .F.

   IF ( cWa )->( DbSeek( PADR( cSeek, nW ) ) )
      IF dfPgSeekFieldValU( cWa, cField ) == cU
         lHit := .T.
      ENDIF
   ENDIF

   IF ! lHit
      ( cWa )->( DbGoTop() )
      DO WHILE !( cWa )->( Eof() )
         IF dfPgSeekFieldValU( cWa, cField ) == cU
            lHit := .T.
            EXIT
         ENDIF
         ( cWa )->( DbSkip() )
      ENDDO
   ENDIF

RETURN lHit

*******************************************************************************
//* Dopo DBSEEK: allinea il record su PGDBE se la chiave campo non coincide.
//* Ripristina posizione/booleano iniziale se non c'e' match esatto.
FUNCTION dfPgSeekAfterDbSeek( cWaPad, cField, uSeek, lSeekSoft, lRet0 )
//*******************************************************************************
LOCAL cWa, cSeekU, lMatch

   cWa := RTRIM( cWaPad )
   IF SELECT( cWa ) < 1
      RETURN lRet0
   ENDIF

   IF !dfPgRddIs( ( cWa )->( RDDNAME() ) )
      RETURN lRet0
   ENDIF

   IF VALTYPE( uSeek ) != "C" .OR. EMPTY( RTRIM( uSeek ) )
      RETURN lRet0
   ENDIF

   IF VALTYPE( cField ) != "C" .OR. EMPTY( cField )
      RETURN lRet0
   ENDIF

   // Come dfPgSeekVerifyRow: non uscire solo per "parziale" con campo CHAR largo (codici).

   cSeekU := UPPER( RTRIM( uSeek ) )

   lMatch := lRet0 .AND. !( cWa )->( Eof() ) .AND. ;
             ( dfPgSeekFieldValU( cWa, cField ) == cSeekU )

   IF lMatch
      RETURN lRet0
   ENDIF

   IF dfPgSeekFallbackScan( cWa, cField, uSeek )
      RETURN .T.
   ENDIF

   lRet0 := ( cWa )->( DBSEEK( uSeek, lSeekSoft ) )
   IF !lRet0 .OR. ( cWa )->( EOF() )
      dfPgSeekGotoMiss( cWa )
   ENDIF

RETURN lRet0

*******************************************************************************
FUNCTION dfPgSeekGotoMiss( cWaPad )
//*******************************************************************************
LOCAL cWa

   cWa := RTRIM( cWaPad )
   IF SELECT( cWa ) < 1
      RETURN .F.
   ENDIF

   // Su PGDBE, dopo seek fallito il driver puo' lasciare il record corrente su una riga precedente.
   // Per i browse che fanno subito DIPE->campo dopo dfS(), questo produce "stesso valore su tutte le righe".
   // Allineiamo il miss a "nessun record" come atteso dai lookup di tipo DBF.
   BEGIN SEQUENCE
      ( cWa )->( DBGOTO( 0 ) )
   END SEQUENCE

RETURN .F.
