//*****************************************************************************
//Progetto       : dBsee 4.0
//Descrizione    : Funzioni di utilita' per FILE
//Programmatore  : Baccan Matteo
//*****************************************************************************
#INCLUDE "Common.CH"
#INCLUDE "set.ch"

#ifdef __XPP__
   // simone 5/11/04 per correzione problema DBGOTO(0)
   // vedi DBGOTO_XPP
   #xtranslate DBGOTO(<x>) => DBGOTO_XPP(<x>)
#endif

// Abiita il LOG
//#define __LOG__
//#define __LOG_SKIP__

* ����������������������������������������������������������������������������
// .T. se la riga corrente va esclusa dalla navigazione del browse:
//  - fuori dal filtro utente (bFilter), oppure
//  - record __deleted con SET DELETED ON. Su DBF dbSkip li salta gia' da solo,
//    quindi DELETED() qui e' sempre .F.; su PGDBE il salto non e' affidabile e
//    senza questo controllo le righe cancellate comparivano nei browse.
* ����������������������������������������������������������������������������
STATIC FUNCTION _dfRowExcluded( nAlias, bFilter )
   IF ! (nAlias)->( EVAL( bFilter ) )
      RETURN .T.
   ENDIF
   IF SET( _SET_DELETED ) .AND. (nAlias)->( DELETED() )
      RETURN .T.
   ENDIF
RETURN .F.

* ����������������������������������������������������������������������������
FUNCTION dfSkip( n2Skip, bFilter, bBreak ) // dbSkip
* ����������������������������������������������������������������������������
LOCAL nSkipped := 0, nActRec := IF(EOF(),0,RECNO())
LOCAL nAlias := SELECT()
LOCAL nPgBrW

DEFAULT n2Skip     TO 1
#ifdef __LOG_SKIP__
   __Log("skip10 "+alltrim(str(n2skip))+" "+alltrim(str(nSkipped))+" "+alltrim(str(nActRec)), NIL, bFilter, bBreak)
#endif
DO CASE
   // PGDBE: LastRec() puo' essere 0 anche con righe (nessun conteggio fisico); il ramo
   // sotto impediva dfReportSKIP di avanzare -> report vuoti ("nulla da stampare").
   CASE (n2Skip == 0) .OR. ;
        (LastRec() == 0 .AND. !( dfPgRddIs( (nAlias)->( RDDNAME() ) ) .AND. n2Skip != 0 ))
#ifdef __LOG_SKIP__
   __Log("skip20 "+alltrim(str(n2skip))+" "+alltrim(str(nSkipped))+" "+alltrim(str(nActRec)), NIL, bFilter, bBreak)
#endif
        dbSkip(0)
        DBGOTO(nActRec)

   CASE (n2Skip > 0)
#ifdef __LOG_SKIP__
   __Log("skip30 "+alltrim(str(n2skip))+" "+alltrim(str(nSkipped))+" "+alltrim(str(nActRec)), NIL, bFilter, bBreak)
#endif
        DO WHILE nSkipped<n2Skip

#ifdef __LOG_SKIP__
   __Log("skip33 "+alltrim(str(n2skip))+" "+alltrim(str(nSkipped))+" "+alltrim(str(nActRec)), NIL, bFilter, bBreak)
#endif
           dbSkip(1)
#ifdef __LOG_SKIP__
   __Log("skip35 "+alltrim(str(n2skip))+" "+alltrim(str(nSkipped))+" "+alltrim(str(nActRec)), NIL, bFilter, bBreak)
#endif

           // simone 21/1/2010
           // XL 1709
           // salvo e ripristino alias in caso il codeblock lo cambi
           IF (nAlias)->( Eof() )
              dbGoto( nActRec )
              // Simone 02/11/09
              // mantis 0002106: problema con ADS e set filter 
              // FIX perch� con ADS se c'� SET FILTER attivo
              // il dbgoto() non resetta il flag di EOF()
              IF EOF()
                 dbSkip(-1) // fa reset del EOF()
                 dbGoto( nActRec )
              ENDIF
              EXIT
           ENDIF

           // PGDBE: dopo dbSkip(1) il cursore puo' finire su record fuori relazione (W_BREAK)
           // pur esistendo altre righe valide; tbEval interrompe la listbox al primo dfSkip=0.
           // Cammino aggiuntivo finche' break o EOF. Opt-out: dfSet XbasePgDfSkipWalkPastBreak=NO
           IF (nAlias)->( EVAL( bBreak ) )
              IF dfPgRddIs( (nAlias)->( RDDNAME() ) ) .AND. ;
                    !( dfSet( "XbasePgDfSkipWalkPastBreak" ) == "NO" )
                 nPgBrW := 0
                 DO WHILE (nAlias)->( EVAL( bBreak ) ) .AND. ;
                       !(nAlias)->( Eof() ) .AND. nPgBrW < 100000
                    (nAlias)->( DbSkip( 1 ) )
                    nPgBrW++
                 ENDDO
              ENDIF
              IF (nAlias)->( Eof() ) .OR. (nAlias)->( EVAL( bBreak ) )
                 dbGoto( nActRec )
                 IF EOF()
                    dbSkip(-1) // fa reset del EOF()
                    dbGoto( nActRec )
                 ENDIF
                 EXIT
              ENDIF
           ENDIF

#ifdef __LOG_SKIP__
   __Log("skip37 "+alltrim(str(n2skip))+" "+alltrim(str(nSkipped))+" "+alltrim(str(nActRec)), NIL, bFilter, bBreak)
#endif

           // simone 21/1/2010
           // XL 1709
           // salvo e ripristino alias in caso il codeblock lo cambi
           IF _dfRowExcluded( nAlias, bFilter )
              LOOP
           ENDIF

#ifdef __LOG_SKIP__
   __Log("skip40 "+alltrim(str(n2skip))+" "+alltrim(str(nSkipped))+" "+alltrim(str(nActRec)), NIL, bFilter, bBreak)
#endif


           nActRec := Recno()
           nSkipped++

        ENDDO

   CASE (n2Skip < 0)
#ifdef __LOG_SKIP__
   __Log("skip60 "+alltrim(str(n2skip))+" "+alltrim(str(nActRec)), NIL, bFilter, bBreak)
#endif
        DO WHILE nSkipped>n2Skip
#ifdef __LOG_SKIP__
   __Log("skip63 "+alltrim(str(n2skip))+" "+alltrim(str(nSkipped))+" "+alltrim(str(nActRec)), NIL, bFilter, bBreak)
#endif
           dbSkip(-1)
#ifdef __LOG_SKIP__
   __Log("skip65 "+alltrim(str(n2skip))+" "+alltrim(str(nSkipped))+" "+alltrim(str(nActRec)), NIL, bFilter, bBreak)
#endif

           // simone 21/1/2010
           // XL 1709
           // salvo e ripristino alias in caso il codeblock lo cambi
           IF (nAlias)->(Eval( bBreak ))
              IF dfPgRddIs( (nAlias)->( RDDNAME() ) ) .AND. ;
                    !( dfSet( "XbasePgDfSkipWalkPastBreak" ) == "NO" )
                 nPgBrW := 0
                 DO WHILE (nAlias)->( Eval( bBreak ) ) .AND. ;
                       !(nAlias)->( Bof() ) .AND. nPgBrW < 100000
                    (nAlias)->( DbSkip( -1 ) )
                    nPgBrW++
                 ENDDO
              ENDIF
              IF (nAlias)->( Bof() ) .OR. (nAlias)->( Eval( bBreak ) )
                 dbGoto( nActRec )
                 // Simone 02/11/09
                 // mantis 0002106: problema con ADS e set filter 
                 // FIX perch� con ADS se c'� SET FILTER attivo
                 // il dbgoto() non resetta il flag di BOF()
                 IF BOF()
                    dbSkip(1) // fa reset del BOF()
                    dbGoto( nActRec )
                 ENDIF

                 EXIT
              ENDIF
           ELSEIF Bof()
              dbGoto( nActRec )
              // Simone 02/11/09
              // mantis 0002106: problema con ADS e set filter 
              // FIX perch� con ADS se c'� SET FILTER attivo
              // il dbgoto() non resetta il flag di BOF()
              IF BOF()
                 dbSkip(1) // fa reset del BOF()
                 dbGoto( nActRec )
              ENDIF

              EXIT
           ENDIF
#ifdef __LOG_SKIP__
   __Log("skip67 "+alltrim(str(n2skip))+" "+alltrim(str(nSkipped))+" "+alltrim(str(nActRec)), NIL, bFilter, bBreak)
#endif

           // simone 21/1/2010
           // XL 1709
           // salvo e ripristino alias in caso il codeblock lo cambi
           IF _dfRowExcluded( nAlias, bFilter )
              LOOP
           ENDIF

#ifdef __LOG_SKIP__
   __Log("skip70 "+alltrim(str(n2skip))+" "+alltrim(str(nSkipped))+" "+alltrim(str(nActRec)), NIL, bFilter, bBreak)
#endif
           nActRec := Recno()
           nSkipped--

        ENDDO

ENDCASE

#ifdef __LOG_SKIP__
   __Log("skip99 "+alltrim(str(n2skip))+" "+alltrim(str(nSkipped))+" "+alltrim(str(nActRec)), NIL, bFilter, bBreak)
#endif

RETURN nSkipped
* ����������������������������������������������������������������������������
PROCEDURE dfTop( bKey, bFilter, bBreak ) // GoTop
* ����������������������������������������������������������������������������
LOCAL lEof := .F.
LOCAL nAlias := SELECT()
LOCAL uSeekVal, lSeekOk, cFld, cWaPad, nPgTopW

#ifdef __LOG__
   __Log("top10", bKey, bFilter, bBreak)
#endif

IF bKey == NIL       // se row_key e' vuota
   IF nAlias > 0 .AND. dfPgRddIs( ( nAlias )->( RDDNAME() ) )
      dfPgGoTopInIndex( nAlias )
   ELSE
      DBGOTOP()            // vado al primo record
   ENDIF
ELSE
   // simone 21/1/2010
   // XL 1709
   // salvo e ripristino alias in caso il codeblock lo cambi
   uSeekVal := (nAlias)->( EVAL( bKey ) )
   lSeekOk  := (nAlias)->( DBSEEK( uSeekVal, .T. ) )
   lEof     := (nAlias)->( EOF() )

   // PGDBE: DBSEEK soft puo' lasciare fuori chiave / EOF (stampe: dfReportTOP -> dfTop).
   IF nAlias > 0 .AND. dfPgRddIs( (nAlias)->( RDDNAME() ) )
      IF VALTYPE( uSeekVal ) == "C" .AND. !EMPTY( RTRIM( uSeekVal ) )
         cFld := dfPgOrdKeySingleField( ALLTRIM( (nAlias)->( ORDKEY() ) ) )
         IF !EMPTY( cFld )
            cWaPad := PADR( UPPER( (nAlias)->( ALIAS() ) ), 8 )
            lSeekOk := dfPgSeekAfterDbSeek( cWaPad, cFld, uSeekVal, .T., lSeekOk )
            lEof    := (nAlias)->( EOF() )
         ELSEIF (nAlias)->( EOF() ) .OR. !lSeekOk
            // Ordine su chiave composta: niente campo singolo -> riparti da testa e filtra
            (nAlias)->( DbGoTop() )
            lEof := (nAlias)->( EOF() )
         ENDIF
      ELSEIF (nAlias)->( EOF() ) .OR. !lSeekOk
         (nAlias)->( DbGoTop() )
         lEof := (nAlias)->( EOF() )
      ENDIF
   ENDIF
ENDIF

// PGDBE: con bKey, DBSEEK + verify possono lasciare EOF pur esistendo righe (cambio master 1:n);
// senza questo lEof resta .T. e non si entra nel blocco !lEof -> listbox vuota.
IF bKey != NIL .AND. nAlias > 0 .AND. dfPgRddIs( (nAlias)->( RDDNAME() ) ) .AND. ;
      ( (nAlias)->( Eof() ) .OR. lEof )
   IF VALTYPE( uSeekVal ) == "C" .AND. !EMPTY( RTRIM( uSeekVal ) )
      cFld := dfPgOrdKeySingleField( ALLTRIM( (nAlias)->( ORDKEY() ) ) )
      IF !EMPTY( cFld )
         cWaPad := PADR( UPPER( (nAlias)->( ALIAS() ) ), 8 )
         IF dfPgSeekFallbackScan( cWaPad, cFld, uSeekVal )
            lSeekOk := .T.
            lEof    := .F.
         ENDIF
      ENDIF
   ENDIF
ENDIF

#ifdef __LOG__
   __Log("top20", bKey, bFilter, bBreak)
#endif

IF !lEof // Solo se non sono a EOF
#ifdef __LOG__
   __Log("top30", bKey, bFilter, bBreak)
#endif
   // simone 21/1/2010
   // XL 1709
   // salvo e ripristino alias in caso il codeblock lo cambi
   IF _dfRowExcluded( nAlias, bFilter )         // Se non sono in filtro (o riga __deleted su PG)
      * // PGDBE: scan filtro illimitato da DBGOTOP blocca UI (es. ddWin+F_FIL su FIL_DES).
      IF bKey == NIL .AND. nAlias > 0 .AND. dfPgRddIs( (nAlias)->( RDDNAME() ) ) .AND. ;
            !( dfSet( "XbasePgDfTopFilterWalk" ) == "NO" )
         _dfPgTopSeekFirstFilter( nAlias, bFilter, bBreak )
      ELSE
         dfSkip( 1, bFilter, bBreak )   // Skippo di 1
      ENDIF
   ENDIF

   // PGDBE: cambio master (bKey) puo' lasciare il cursore su riga ancora con break .T.
   // (es. record dipendente precedente); il ramo DBGOTO(0) sotto svuotava la listbox 1:n.
   // Stesso cammino di dfSkip. Opt-out: dfSet XbasePgDfSkipWalkPastBreak=NO
   IF bKey != NIL .AND. dfPgRddIs( (nAlias)->( RDDNAME() ) ) .AND. ;
         !( dfSet( "XbasePgDfSkipWalkPastBreak" ) == "NO" ) .AND. ;
         !(nAlias)->( Eof() ) .AND. ;
         (nAlias)->( EVAL( bFilter ) ) .AND. ;
         (nAlias)->( EVAL( bBreak ) )
      nPgTopW := 0
      DO WHILE (nAlias)->( EVAL( bBreak ) ) .AND. ;
            !(nAlias)->( Eof() ) .AND. nPgTopW < 100000
         (nAlias)->( DbSkip( 1 ) )
         nPgTopW++
      ENDDO
   ENDIF

#ifdef __LOG__
   __Log("top40", bKey, bFilter, bBreak)
#endif

   // simone 21/1/2010
   // XL 1709
   // salvo e ripristino alias in caso il codeblock lo cambi
   // Se Break o Filtro NON verificato (o riga __deleted su PG con SET DELETED ON)
   IF (nAlias)->(EVAL( bBreak )) .OR. _dfRowExcluded( nAlias, bFilter )
      // PGDBE: il guard storico (solo con dfSet) evitava DBGOTO(0) quando PG+!EOF+filtro+break
      // erano tutti .T. (VR_BREAK falso positivo su stampe); su filtro .T. e break 1:n, break .T.
      // indica fuori relazione e serve sempre DBGOTO(0) -> default senza dfSet.
      IF dfPgRddIs( (nAlias)->( RDDNAME() ) ) .AND. ;
            dfSet( "XbasePgDfTopDeferDbgoto0OnBreak" ) == "YES"
         IF !( !(nAlias)->( EOF() ) .AND. ;
               (nAlias)->( EVAL( bFilter ) ) .AND. ;
               (nAlias)->( EVAL( bBreak ) ) )
            DBGOTO(0)
         ENDIF
      ELSE
         DBGOTO(0)
      ENDIF
   ENDIF
ENDIF

#ifdef __LOG__
   __Log("top50", bKey, bFilter, bBreak)
#endif

RETURN

* ����������������������������������������������������������������������������

STATIC PROCEDURE _dfPgTopSeekFirstFilter( nAlias, bFilter, bBreak )
LOCAL nMax, nWalk := 0
LOCAL uMax

uMax := dfSet( "XbasePgDfTopFilterMax" )
DO CASE
   CASE ValType( uMax ) == "N"
      nMax := uMax
   CASE ValType( uMax ) == "C"
      nMax := Val( uMax )
   OTHERWISE
      nMax := 0
ENDCASE
IF nMax < 1
   nMax := 800
ENDIF
DO WHILE _dfRowExcluded( nAlias, bFilter ) .AND. !(nAlias)->( Eof() ) .AND. nWalk < nMax
   (nAlias)->( DbSkip( 1 ) )
   IF (nAlias)->( EVAL( bBreak ) )
      IF dfPgRddIs( (nAlias)->( RDDNAME() ) ) .AND. ;
            !( dfSet( "XbasePgDfSkipWalkPastBreak" ) == "NO" )
         DO WHILE (nAlias)->( EVAL( bBreak ) ) .AND. !(nAlias)->( Eof() ) .AND. nWalk < nMax
            (nAlias)->( DbSkip( 1 ) )
            nWalk++
         ENDDO
      ENDIF
   ENDIF
   nWalk++
ENDDO
IF (nAlias)->( ! EVAL( bFilter ) )
   (nAlias)->( DBGOTO( 0 ) )
ENDIF
RETURN

PROCEDURE dfBottom( bKey, bFilter, bBreak ) // GoBottom
* ����������������������������������������������������������������������������
LOCAL nActRec, uKey
LOCAL nAlias := SELECT()

#ifdef __LOG__
   __Log("bot10", bKey, bFilter, bBreak)
#endif

IF bKey == NIL                      // se row_key e' vuota
   dbGoBottom()                            // vado al primo record
ELSE                                // se ho passato row_key
   // simone 21/1/2010
   // XL 1709
   // salvo e ripristino alias in caso il codeblock lo cambi
   uKey := (nAlias)->(Eval( bKey ))
   DO CASE
      CASE ValType( uKey ) == [C]        // se e' di tipo Carattere
           // Simone 28/10/2009 
           // 0002105: problema DBGOTO(0) , DBSKIP(-1) con ADS
           // correzione parziale, risolve il pattern indicato nel mantis
           // ma il problema DBGOTO(0), DBSKIP(-1) rimane aperto
           IF uKey==""
              dbGoBottom()
           ELSE
           dbSeek( dfChrInc( uKey ), .T. )
           dbSkip(-1)
           ENDIF
      CASE ValType( uKey ) $ [DN]        // se e' di tipo Data/Numerico
           dbSeek( uKey+1          , .T. )
           dbSkip(-1)
      CASE ValType( uKey ) == [L]        // se e' di tipo Logico
           dbSeek( !uKey           , .T. )
           dbSkip(-1)
   ENDCASE
ENDIF
#ifdef __LOG__
   __Log("bot20", bKey, bFilter, bBreak)
#endif

// simone 21/1/2010
// XL 1709
// salvo e ripristino alias in caso il codeblock lo cambi
IF !(nAlias)->(Eval( bFilter ))                 // Se non sono in filtro
   dfSkip( -1, bFilter, bBreak )       // Skippo di -1
ENDIF

#ifdef __LOG__
   __Log("bot30", bKey, bFilter, bBreak)
#endif


// simone 21/1/2010
// XL 1709
// salvo e ripristino alias in caso il codeblock lo cambi
// Se Break o Filtro NON verificato
IF (nAlias)->(EVAL( bBreak )) .OR. !(nAlias)->(EVAL( bFilter ))
   DBGOTO(0)
ENDIF

#ifdef __LOG__
   __Log("bot40", bKey, bFilter, bBreak)
#endif

RETURN

#ifdef __LOG__
STATIC FUNCTION  __Log(x, bKey, bFilter, bBreak)
LOCAL cMsg
//cMsg := DTOS(DATE())+" "+TIME()+" "+x+" "
cMsg := x
//cMsg += " "+VAR2CHAR(bKey)+":"+EVAL(bKey)
cMsg += " flt:"+VAR2CHAR(EVAL(bFilter))
cMsg += " brk:"+VAR2CHAR(EVAL(bBreak))
cMsg += " "+ALIAS()+ " "+ALLTRIM(STR(RECNO()))+IIF(EOF(), " EOF", "")+IIF(BOF(), " BOF", "")
dfLogMsg(cMsg, .T.)
RETURN .T.
#endif
