//*****************************************************************************

//Progetto       : dBsee 4.0

//Descrizione    : Funzioni di utilita' VARIE

//Programmatore  : Baccan Matteo

//*****************************************************************************

// Contesto seek PG in dfS: deve persistere tra chiamate ma NON tra stampe/sessioni
// diverse; altrimenti si riusa un campo indice o area sbagliati (zeri / EOF).
STATIC sDfSSel, sDfSOrd, sDfSNam, sDfSWa

* ?????????????????????????????????????????????????????????????????????????????
FUNCTION dfS( uOrd, uSeek, lSoft )

* ?????????????????????????????????????????????????????????????????????????????

LOCAL lRet, cFld, cWa, lDidOrd, cSeekT, cHkey, nSel, cSeekUse, cOrdKey

// simone 31/01/08

// ripristinato funzionamento originale perche' il PDR 2799 e' risolto da tempo

// (testato su 1.82 e 1.90)

// e il &(INDEXKEY()) sulla 1.82 da' un IDSC a bellanti GERR 5076

//

//#ifdef __XPP__

//   LOCAL lRet

//   ORDSETFOCUS(uOrd)

//   IF SET( _SET_EXACT) .OR. ! VALTYPE(uSeek) == "C"

//      lRet := DBSEEK(uSeek,lSoft)

//   ELSE

//      lRet := DBSEEK( LEFT( uSeek, LEN( &(INDEXKEY()) ) ), lSoft )

//   ENDIF

//   RETURN lRet

//#else

//   RETURN (ORDSETFOCUS(uOrd),DBSEEK(uSeek,lSoft))

//#endif

// Simone 28/10/09

// non uso ORDSETFOCUS_XPP perche' controllo prima (e' piu' veloce)

//

// PGDBE: cache Recno() hash (dfHT*); su hit DBGOTO+verify; dfHTMod dopo seek ok.

// Vedi dfSPgSeekCacheFlush. Prestazioni ISAM/SmartOrders: doc Alaska PGDBE

// https://doc.alaska-software.com/content/pgdbe_h2_navigational_support_isam.cxp

// (OrdInfo ordine virtuale vs ISAM, NO-SMART-ORDER sconsigliato).

//

IF SELECT() > 0 .AND. dfPgRddIs( RDDNAME() )

   lDidOrd := .F.

   IF VALTYPE(uOrd)=="C" .AND. UPPER(ORDNAME()) != UPPER(uOrd) .OR. ;
      VALTYPE(uOrd)=="N" .AND. ORDNUMBER() != uOrd

      ORDSETFOCUS( uOrd )

      lDidOrd := .T.

   ENDIF

   cWa := PADR( UPPER( ALIAS() ), 8 )

   // PGDBE: uSeek puo' non essere "C" (memo, numerico, NIL da NULL SQL) pur essendo una chiave testo in indice.
   // Il vecchio test escludeva il ramo PG -> solo DBSEEK(uSeek) e record codici sbagliato (stessa C_DES su tutte le righe browse).
   cSeekUse := RTRIM( dfAny2Str( uSeek, "" ) )

   IF !EMPTY( cSeekUse )

      nSel := SELECT()

      IF VALTYPE( sDfSSel ) == "N" .AND. nSel == sDfSSel .AND. uOrd == sDfSOrd .AND. ;
            !EMPTY( sDfSNam ) .AND. cWa == sDfSWa

         cFld := sDfSNam

      ELSE

         cOrdKey := UPPER( ALLTRIM( ORDKEY() ) )
         cFld := dfPgOrdResolveField( cOrdKey, uOrd, cSeekUse )

         sDfSSel := nSel

         sDfSOrd := uOrd

         sDfSWa := cWa

         IF !EMPTY( cFld )

            sDfSNam := cFld

         ELSE

            sDfSNam := ""

         ENDIF

      ENDIF

      IF !EMPTY( cFld )

         cSeekT := cSeekUse

         cHkey := _dfSPgHtKey( cWa, uOrd, cSeekT )

         IF _dfSPgHtTryGoto( cWa, cFld, cSeekT, cHkey )

            RETURN .T.

         ENDIF

         IF !EOF() .AND. dfPgSeekFieldValU( cWa, cFld ) == UPPER( cSeekT ) .AND. !dfPgSeekIsPartialChr( cWa, cFld, cSeekT )

            _dfSPgHtPut( cHkey )

            RETURN .T.

         ENDIF

         lRet := DBSEEK( cSeekUse, lSoft )

         IF lRet .AND. !EOF() .AND. dfPgSeekVerifyRow( cWa, cFld, cSeekT )

            _dfSPgHtPut( cHkey )

            RETURN lRet

         ENDIF

         IF !lDidOrd .AND. ORDNUMBER() == uOrd

            ORDSETFOCUS( uOrd )

            lRet := DBSEEK( cSeekUse, lSoft )

            IF lRet .AND. !EOF() .AND. dfPgSeekVerifyRow( cWa, cFld, cSeekT )

               _dfSPgHtPut( cHkey )

               RETURN lRet

            ENDIF

         ENDIF

         lRet := dfPgSeekAfterDbSeek( cWa, cFld, cSeekUse, lSoft, lRet )

         IF lRet .AND. !EOF() .AND. dfPgSeekVerifyRow( cWa, cFld, cSeekT )

            _dfSPgHtPut( cHkey )

         ELSE

            dfPgSeekGotoMiss( cWa )

         ENDIF

         RETURN lRet

      ENDIF

   ENDIF

   // Se cSeekUse valorizzato ma cFld vuoto (chiave indice non dedotta), DBSEEK deve usare
   // la stringa normalizzata, non uSeek (tipo / NIL PG), altrimenti resta lo stesso record codici.
   IF !EMPTY( cSeekUse )

      lRet := DBSEEK( cSeekUse, lSoft )

   ELSE

      lRet := DBSEEK( uSeek, lSoft )

   ENDIF

   IF !lRet .OR. EOF()
      dfPgSeekGotoMiss( cWa )
   ENDIF

   RETURN lRet

ENDIF

IF ORDNUMBER() != uOrd // simone 28/10/09 velocizza su ADS

ORDSETFOCUS(uOrd)

ENDIF

RETURN DBSEEK(uSeek, lSoft)

*******************************************************************************

PROCEDURE dfSPgSeekCacheFlush()

//*******************************************************************************

_dfSPgHtTable( .T. )
   sDfSSel := NIL
   sDfSOrd := NIL
   sDfSNam := ""
   sDfSWa := ""

RETURN



*******************************************************************************

FUNCTION _dfSPgHtKey( cWa8, nOrd, cSeekT )

//*******************************************************************************

RETURN RTRIM( cWa8 ) + "|" + STR( nOrd, 4, 0 ) + "|" + UPPER( cSeekT )



*******************************************************************************

FUNCTION _dfSPgHtTable( lFlush )
//*******************************************************************************
STATIC s_aHt
LOCAL lF
   lF := .F.
   IF PCOUNT() >= 1 .AND. VALTYPE( lFlush ) == "L"
      lF := lFlush
   ENDIF
   IF lF
      s_aHt := dfHTNew( 257 )
      RETURN s_aHt
   ENDIF
   IF VALTYPE( s_aHt ) != "A" .OR. LEN( s_aHt ) < 3 .OR. s_aHt[3] != 257
      s_aHt := dfHTNew( 257 )
   ENDIF
RETURN s_aHt



*******************************************************************************

FUNCTION _dfSPgHtTryGoto( cWa8, cFld, cSeekT, cHkey )

//*******************************************************************************

LOCAL lHit, xRec, cWr

   xRec := dfHTFind( _dfSPgHtTable(), cHkey, @lHit )

   IF !lHit .OR. VALTYPE( xRec ) != "N" .OR. xRec < 1

      RETURN .F.

   ENDIF

   cWr := RTRIM( cWa8 )

   IF SELECT( cWr ) < 1

      RETURN .F.

   ENDIF

   ( cWr )->( DBGOTO( xRec ) )

   IF ( cWr )->( EOF() ) .OR. !dfPgSeekVerifyRow( cWa8, cFld, cSeekT )

      RETURN .F.

   ENDIF

RETURN .T.



*******************************************************************************

STATIC PROCEDURE _dfSPgHtPut( cHkey )

//*******************************************************************************

LOCAL nRec

   nRec := RECNO()

   IF nRec > 0

      dfHTMod( _dfSPgHtTable(), nRec, cHkey, .T. )

   ENDIF

RETURN
