// *****************************************************************************
// Copyright (C) Albalog s.r.l.
// Description : Centralised Automatic Lookup function
// *****************************************************************************
#include "Common.ch"
#include "dfWin.ch"
#include "dfLook.ch"
#include "dfMsg.CH"
#include "dfSet.CH"

#ifdef __XPP__
   // 04-nov-05 Correct DBGOTO(0) problem
   #xtranslate DBGOTO(<x>) => DBGOTO_XPP(<x>)
#endif

* ???????????????????????????????????????????????????????????????????????????
FUNCTION dbLook(        ; // Auto-LookUp function
                 aLook  ) // Parameters array
* ???????????????????????????????????????????????????????????????????????????
// LK_ORDER  aLook[1]  := Order                 (Number)
// LK_SEEK   aLook[2]  := Prim.Position.Key     (CODEBLOCK)
// LK_VAL    aLook[3]  := Inherited fields      (Array)
// LK_FIELD  aLook[4]  := Key for DBDD          (Seek on DBDD)
// LK_WIN    aLook[5]  := Window
// LK_KEY    aLook[6]  := Key for Window
// LK_FILTER aLook[7]  := Filter on Window
// LK_BREAK  aLook[8]  := Break on Window
// LK_TYPE   aLook[9]  := Type of LookUp
//                           LT_NOTMANDATORY
//                           LT_MANDATORY
//                           LT_FREE         (Query)
// LK_EDIT   aLook[10] := Edit LookUp object. If empty, read from ddde
// LK_INS    aLook[11] := Allow adding from LookUp           (CODEBLOCK)
// LK_KBD    aLook[12] := Skip to next control
// LK_KEYORDER
// LK_WINDOWORDER

MEMVAR Act

LOCAL cFieDes, cFieTyp, cCode, cFleDes
LOCAL lFound    := .T.
LOCAL lEsc      := .F.
LOCAL nInd      := INDEXORD()
LOCAL cAct      := Act
LOCAL cAlias    := PADR(UPPER(ALIAS()),8)
LOCAL cOldState := ""
LOCAL lCase2    := .F.
LOCAL cKey
LOCAL nPgSavRec := 0
LOCAL lPickSync := .F.   // scelta da browse/ddKey/dfTop: LK_SEEK va allineato al record corrente
LOCAL lEmptySeekFree := .F. // LT_FREE + seek C vuoto: niente record "implicito" per !eof() lato chiamante

IF Act $ "uar-esc-Stb"         // These actions transform a LookUp
   RETURN .T.                  // to a free LookUp
ENDIF                          // Save the mask ALWAYS
                               // checks the data

DEFAULT aLook[LK_KEYORDER]     TO aLook[LK_ORDER]
DEFAULT aLook[LK_WINDOWORDER]  TO aLook[LK_ORDER]

// Simone 14/6/06 mantis 0001082: abilitare impostazione generale per disabilitare inserimento da lookup
DEFAULT aLook[LK_INS]          TO dfSet(AI_LOOKINSERTCB)  

cOldState := dfUsrState()      // Save current state
(cAlias)->( ORDSETFOCUS( aLook[LK_ORDER] ) )

lEmptySeekFree := ( aLook[LK_TYPE] == LT_FREE ) .AND. ;
                  VALTYPE( aLook[LK_SEEK] ) == "C" .AND. ;
                  EMPTY( RTRIM( aLook[LK_SEEK] ) )

// ------------------------------------------------------
// simone 9/6/2006 
// mantis 0001085: La dblook() per GET con lookup non funziona correttamente nel caso di settaggio NOT Mandatory per chiave con prefisso
// Fix per lookup NOT MANDATORY su tabelle con pre-codice (es "C"+CODANA)
//
// simula la seguente
// modifica al template VALIDSTD.TMP
/*
   // Aggiunto S2000 Standard per LookUp con chiave vuota
   IF Empty(?AllTrim(dd_sym->SYM_NAM)?)
      aDbl[LK_SEEK] := Space(Len(aDbl[LK_SEEK]))
   ENDIF

*/
IF ! EMPTY(aLook[LK_KEY]) .AND. ! EMPTY(aLook[LK_SEEK]) .AND. ;
   dfSet("XbaseDbLookFix_EmptyKey") != "NO"

   cKey := NIL
   IF VALTYPE(aLook[LK_KEY]) == "B"
      cKey := EVAL(aLook[LK_KEY])
   ELSEIF VALTYPE(aLook[LK_KEY]) $ "CM"
      cKey := aLook[LK_KEY]
   ENDIF

   //////////////////////////////////////////////////////////////
   //Luca and Simone
   //Modifica Fix per lookup su variaible del 9/03/2007
   //Accade che il wizard di creazione lookup su variaible non imposta correttamente la chiave di relazione
   //quindi permette in ogni caso di selezioanre il campo del record voluto ma si ottiene 
   //alla fine un fenomeno di sbiancamnto della variabile quando perde il Focus.
   //IF PADR(cKey, LEN(aLook[LK_SEEK])) == aLook[LK_SEEK]
   //   aLook[LK_SEEK] := SPACE(LEN(aLook[LK_SEEK]))
   //ENDIF
   IF VALTYPE(cKey) $ "CM"            .AND. ;
      VALTYPE(aLook[LK_SEEK]) $ "CM"  .AND. ;
      LEN(aLook[LK_SEEK]) > LEN(cKey) .AND. ;
      PADR(cKey, LEN(aLook[LK_SEEK])) == aLook[LK_SEEK]

      aLook[LK_SEEK] := SPACE(LEN(aLook[LK_SEEK]))
   ENDIF
   //////////////////////////////////////////////////////////////
ENDIF
// FINE
// ------------------------------------------------------


DO CASE
   CASE Act=="Cho"
        dfTop(    , aLook[LK_FILTER], aLook[LK_BREAK] )
        Act := "rep"
        lPickSync := .T.

   CASE Act=="Cen"
        dfBottom( , aLook[LK_FILTER], aLook[LK_BREAK] )
        Act := "rep"
        lPickSync := .T.

   CASE Act=="Cra"
        dfSkip( 1 , aLook[LK_FILTER], aLook[LK_BREAK] )
        Act := "rep"
        lPickSync := .T.

   CASE Act=="Cla"
        dfSkip( -1, aLook[LK_FILTER], aLook[LK_BREAK] )
        Act := "rep"
        lPickSync := .T.

        // Window
   CASE Act == "Ada" .OR.;
        ( dfSet(AI_LOOKAUTOWIN)  .AND.;
          Act=="ret"             .AND.;
          EMPTY(aLook[LK_SEEK])  .AND.;
          aLook[LK_TYPE]==LT_MANDATORY )

        // tbSetKey imposta LK_WINDOWORDER: se differisce da LK_ORDER, seek solo su LK_ORDER lascia PGDBE fuori chiave.
        IF !EMPTY(aLook[LK_SEEK])
           _dbLookSeekOnOrder( cAlias, aLook, aLook[LK_ORDER] )
           IF aLook[LK_WINDOWORDER] != aLook[LK_ORDER]
              _dbLookSeekOnOrder( cAlias, aLook, aLook[LK_WINDOWORDER] )
           ENDIF
        ENDIF
        IF aLook[LK_WIN] # NIL     // Window name
           // Generated window
           EVAL( aLook[LK_WIN]          ,; // Window name
                 aLook[LK_WINDOWORDER]  ,; // Order
                 aLook[LK_KEY]          ,; // Key
                 aLook[LK_FILTER]       ,; // Filter
                 aLook[LK_BREAK]         ) // Break

        ELSE
           // Run-time Window
           ddWin( aLook[LK_WINDOWORDER] ,; // Order
                  aLook[LK_KEY]         ,; // Key
                  aLook[LK_FILTER]      ,; // Filter
                  aLook[LK_BREAK]        ) // Break
        ENDIF
        IF (lEsc:=Act=="esc")
           lFound := .F.
        ELSE
           lPickSync := .T.
        ENDIF

   CASE Act == "Cda"               // Keys
        lEsc := !ddKey( 2                  ,; // Starter row
                        3                  ,; // Starter column
                        aLook[LK_KEYORDER] ,; // Current index order
                        aLook[LK_KEY]      ,; // Key    on Window
                        aLook[LK_FILTER]   ,; // Filter on Window
                        aLook[LK_BREAK]    )  // Break  on Window
        IF lEsc
           lFound := .F.
        ELSE
           lPickSync := .T.
        ENDIF

   OTHERWISE
        lFound := .F.
ENDCASE

// Dopo browse/ddKey/dfTop il record su cAlias e' quello scelto, ma aLook[LK_SEEK] e' ancora
// il valore del GET (es. inserimento: dopo la 1a scelta non e' vuoto). DBSEEK sotto riporterebbe
// al codice precedente e PG/VERIFY fallirebbero; in modifica il form non si aggiorna.
IF lPickSync .AND. !lEsc
   _dbLookSyncSeekAfterPick( cAlias, aLook )
ENDIF

IF (!EMPTY(aLook[LK_SEEK]) .OR. !lFound) .AND. !lEsc  // Positioning
   // CHKGET/ret con lFound=.T.: senza DBSEEK esplicito PGDBE puo' restare fuori chiave -> messaggio "codice non esiste".
   (cAlias)->( ORDSETFOCUS( aLook[LK_ORDER] ) )
   IF !EMPTY( aLook[LK_SEEK] )
      IF dfPgRddIs( (cAlias)->( RDDNAME() ) )
         lFound := (cAlias)->( DBSEEK( aLook[LK_SEEK] ) )
      ELSE
         lFound := (cAlias)->( DBSEEK( aLook[LK_SEEK], .T. ) )
      ENDIF
   ELSEIF !lFound
      lFound := (cAlias)->( DBSEEK( aLook[LK_SEEK] ) )
   ENDIF
   IF (cAlias)->(EOF())
      lFound := .F.
   ENDIF
   IF lFound .AND. !lEsc
      IF !_dbLookPgSeekVerify( cAlias, aLook )
         lFound := .F.
      ENDIF
   ENDIF
   IF !lFound .AND. !lEsc
      IF _dbLookPgSeekFallback( cAlias, aLook )
         lFound := .T.
      ENDIF
   ENDIF
ENDIF

lCase2 := LEN(aLook[LK_VAL])==1             .AND.; // Only one value
          VALTYPE(EVAL(aLook[LK_VAL][1][2]))=="N".AND.; // Numeric
          VALTYPE(aLook[LK_SEEK])=="C"           .AND.; // Seeked like character
          VAL(aLook[LK_SEEK])==0                 .AND.;
          aLook[LK_TYPE]==LT_NOTMANDATORY        .AND.; // Not Mandatory
          !lFound                                .AND.;
          !lEsc

DO CASE
   CASE aLook[LK_TYPE] == LT_FREE           // Free
        IF !lEsc
           lFound := .T.                       // Returns always .T.
        ENDIF

   CASE EMPTY( aLook[LK_SEEK] ) .AND.;
        !lFound                 .AND.;
        !lEsc                               // Seeked value

        DO CASE
           CASE aLook[LK_TYPE] == LT_MANDATORY    // Mandatory field

                dbdd->(ORDSETFOCUS(2))
                dbdd->(dbSeek("FIE"+ cAlias+ UPPER(aLook[LK_FIELD])))
                dbdd->(ORDSETFOCUS(1))

                cFieDes := TRIM(dbdd->field_des)
                dbMsgErr( dfStdMsg(MSG_DBLOOK01)+ cFieDes +" " +dfStdMsg(MSG_DBLOOK02) )

           CASE aLook[LK_TYPE] == LT_NOTMANDATORY // Empty field ok
                (cAlias)->(DBGOTO(0))             // Force EOF()
                lFound := .T.
        ENDCASE

   CASE lCase2
//   CASE LEN(aLook[LK_VAL])==1                  .AND.; // Only one value
//        VALTYPE(EVAL(aLook[LK_VAL][1][2]))=="N".AND.; // Numeric
//        VALTYPE(aLook[LK_SEEK])=="C"           .AND.; // Seeked like character
//        VAL(aLook[LK_SEEK])==0                 .AND.;
//        aLook[LK_TYPE]==LT_NOTMANDATORY        .AND.; // Not Mandatory
//        !lFound                                .AND.;
//        !lEsc

        // Value numeric, seeked like a character

        (cAlias)->(DBGOTO(0))             // Force EOF()
        lFound := .T.

   CASE !lFound .AND. !lEsc                 // May continue with data entry

        dbdd->(ORDSETFOCUS(2))
        dbdd->(DBSEEK("DBF"+ cAlias))
        cFleDes := strtran(TRIM(dbdd->Field_Des),":","")

        dbdd->(ORDSETFOCUS(1))
        dbdd->(DBSEEK("NDX"+ cAlias+str(aLook[LK_WINDOWORDER],3)))
        cFleDes += ":" +strtran(TRIM(dbdd->Field_Des),":","")

        dbdd->(ORDSETFOCUS(2))
        dbdd->(dbSeek("FIE"+ cAlias+ UPPER(aLook[LK_FIELD])))
        dbdd->(ORDSETFOCUS(1))
        cFieDes := TRIM(dbdd->Field_Des)
        cFieTyp := dbdd->Field_Type
        cCode   := TRIM(PADR( aLook[LK_SEEK], 45))

        IF cFieTyp=="D" .AND. LEN(aLook[LK_VAL])==1  // Date type field
           cCode := DTOC(EVAL(aLook[LK_VAL][1][2]))
        ENDIF

        IF !EVAL( aLook[LK_INS] ) .OR. ;             // Insertion Not allowed
           !EVAL( dfSet( AI_FILEINSERTCB ), ALLTRIM(cAlias) )
           dbMsgErr( dfStdMsg(MSG_DBLOOK03)+;
                     strtran(cFieDes,":","")+": (" +cCode +")" +;
                     dfStdMsg(MSG_DBLOOK04) )
        ELSE                                         // Insertion allowed
           IF dfYesNo( dfStdMsg(MSG_DBLOOK05)               +;
                       strtran(cFieDes,":","") +": (" +cCode +")"           +;
                       dfStdMsg(MSG_DBLOOK06) +" " +cFleDes +;
                       dfStdMsg(MSG_DBLOOK07), .F. )

              dfPushAct()   // Avoiding F10
              IF aLook[LK_EDIT] # NIL      // If a data entry frame
                 EVAL( aLook[LK_EDIT] )    // has been activated
                 IF Act # "esc"
                    lFound := .T.
                 ENDIF
              ELSE                 // Otherwise automatic data entry form
                 lFound := ddDe( DE_STATE_ADD, aLook[LK_VAL] )
              ENDIF
              dfPopAct()

           ENDIF
        ENDIF
ENDCASE

IF !EVAL( aLook[LK_FILTER] ) .AND. !EOF() .AND.; // Record is not within filter range
   !(aLook[LK_TYPE]==LT_FREE)             .AND.; // Key NOT free
   !(aLook[LK_TYPE]==LT_NOTMANDATORY.AND.EMPTY(aLook[LK_SEEK]))  // Key NOT
                                                 // Empty
   lFound := .F.
ENDIF

IF (cAct == "Cda" .OR. cAct == "Ada") .AND. lFound
   Act := "rep"
   IF aLook[LK_KBD]
      dbAct2Kbd( "tab" )  // Simulate pressing "Tab"
   ENDIF
ENDIF

// PGDBE: ORDSETFOCUS(nInd) puo' spostare il record corrente; il codice chiamante
// legge ancora alias->campo (es. codici->codice). Salva RECNO() e DBGOTO dopo restore.
IF lFound .AND. !lEsc .AND. dfPgRddIs( ( cAlias )->( RDDNAME() ) ) .AND. ;
      !( cAlias )->( EOF() ) .AND. !( cAlias )->( BOF() )
   nPgSavRec := ( cAlias )->( RECNO() )
ENDIF

( cAlias )->( ORDSETFOCUS( nInd ) )  // Restoring index

IF nPgSavRec > 0 .AND. dfPgRddIs( ( cAlias )->( RDDNAME() ) )
   ( cAlias )->( DBGOTO( nPgSavRec ) )
ENDIF

// LT_FREE + seek vuoto senza browse/ddKey: evita che il chiamante veda un record
// corrente "casuale" (es. primo CODICI) dopo dbLook -> query/stampe con codici fantasma.
// Disabilita: dfSet("XbaseDbLookEofOnEmptyFreeSeek","NO")
IF lEmptySeekFree .AND. !lPickSync .AND. !lEsc .AND. dfSet( "XbaseDbLookEofOnEmptyFreeSeek" ) != "NO"
   ( cAlias )->( DBGOTO( 0 ) )
ENDIF

dfUsrState( cOldState  )         // Restore old state

RETURN lFound

*******************************************************************************
STATIC FUNCTION _dbLookPgFieldFromAlook( aLook )
//*******************************************************************************
LOCAL cF, aSub

   IF VALTYPE( aLook ) != "A" .OR. LEN( aLook ) < LK_FIELD
      RETURN ""
   ENDIF

   cF := aLook[LK_FIELD]
   IF VALTYPE( cF ) == "C" .AND. !EMPTY( RTRIM( cF ) )
      RETURN RTRIM( cF )
   ENDIF

   IF LEN( aLook ) >= LK_VAL .AND. VALTYPE( aLook[LK_VAL] ) == "A" .AND. LEN( aLook[LK_VAL] ) >= 1
      aSub := aLook[LK_VAL][1]
      IF VALTYPE( aSub ) == "A" .AND. LEN( aSub ) >= 1 .AND. VALTYPE( aSub[1] ) == "C" .AND. !EMPTY( RTRIM( aSub[1] ) )
         RETURN RTRIM( aSub[1] )
      ENDIF
   ENDIF

RETURN ""

*******************************************************************************
STATIC PROCEDURE _dbLookSyncSeekAfterPick( cAliasPad, aLook )
//*******************************************************************************
// Allinea LK_SEEK al valore chiave del record corrente su cAlias (browse/ddKey).
LOCAL cWa, cFld, nPos, uVal, vtSeek, nPad

cWa := RTRIM( cAliasPad )
IF SELECT( cWa ) < 1 .OR. VALTYPE( aLook ) != "A" .OR. LEN( aLook ) < LK_FIELD
   RETURN
ENDIF

vtSeek := VALTYPE( aLook[LK_SEEK] )
IF vtSeek == "B"
   RETURN
ENDIF

cFld := ""
IF VALTYPE( aLook[LK_FIELD] ) == "C" .AND. !EMPTY( RTRIM( aLook[LK_FIELD] ) )
   cFld := RTRIM( aLook[LK_FIELD] )
ENDIF
IF EMPTY( cFld )
   cFld := _dbLookPgFieldFromAlook( aLook )
ENDIF
IF EMPTY( cFld )
   RETURN
ENDIF

IF ( cWa )->( EOF() ) .OR. ( cWa )->( BOF() )
   RETURN
ENDIF

nPos := ( cWa )->( FIELDPOS( cFld ) )
IF nPos < 1
   RETURN
ENDIF

uVal := ( cWa )->( FIELDGET( nPos ) )

IF vtSeek == "C"
   IF VALTYPE( uVal ) == "C"
      nPad := MAX( LEN( aLook[LK_SEEK] ), LEN( RTRIM( uVal ) ) )
      aLook[LK_SEEK] := PADR( RTRIM( uVal ), nPad )
   ELSE
      nPad := MAX( LEN( aLook[LK_SEEK] ), LEN( RTRIM( dfAny2Str( uVal, "" ) ) ) )
      aLook[LK_SEEK] := PADR( RTRIM( dfAny2Str( uVal, "" ) ), MAX( nPad, 1 ) )
   ENDIF
ELSEIF vtSeek == "N"
   IF VALTYPE( uVal ) == "N"
      aLook[LK_SEEK] := uVal
   ELSEIF VALTYPE( uVal ) == "C"
      aLook[LK_SEEK] := VAL( ALLTRIM( uVal ) )
   ELSE
      aLook[LK_SEEK] := VAL( ALLTRIM( dfAny2Str( uVal, "" ) ) )
   ENDIF
ELSE
   aLook[LK_SEEK] := uVal
ENDIF

RETURN

*******************************************************************************
STATIC FUNCTION _dbLookPgSeekField( cAliasPad, aLook )
//*******************************************************************************
LOCAL cWa, cF

   cWa := RTRIM( cAliasPad )
   cF  := _dbLookPgFieldFromAlook( aLook )
   IF EMPTY( cF ) .AND. SELECT( cWa ) >= 1
      cF := ( cWa )->( dfPgOrdResolveField( ALLTRIM( ORDKEY() ), aLook[LK_ORDER], aLook[LK_SEEK] ) )
   ENDIF

RETURN cF

*******************************************************************************
STATIC FUNCTION _dbLookPgSeekVerify( cAliasPad, aLook )
//*******************************************************************************
LOCAL cWa, cField

   cWa := RTRIM( cAliasPad )
   IF SELECT( cWa ) < 1
      RETURN .T.
   ENDIF

   IF !dfPgRddIs( ( cWa )->( RDDNAME() ) )
      RETURN .T.
   ENDIF

   IF VALTYPE( aLook ) != "A" .OR. LEN( aLook ) < LK_ORDER
      RETURN .T.
   ENDIF

   IF VALTYPE( aLook[LK_SEEK] ) != "C" .OR. EMPTY( RTRIM( aLook[LK_SEEK] ) )
      RETURN .T.
   ENDIF

   cField := _dbLookPgSeekField( cAliasPad, aLook )
   IF EMPTY( cField )
      RETURN .T.
   ENDIF

RETURN dfPgSeekVerifyRow( cWa, cField, aLook[LK_SEEK] )

*******************************************************************************
STATIC FUNCTION _dbLookPgSeekFallback( cAliasPad, aLook )
//*******************************************************************************
LOCAL cWa, cField

   cWa := RTRIM( cAliasPad )
   IF SELECT( cWa ) < 1
      RETURN .F.
   ENDIF

   IF !dfPgRddIs( ( cWa )->( RDDNAME() ) )
      RETURN .F.
   ENDIF

   IF VALTYPE( aLook ) != "A" .OR. LEN( aLook ) < LK_ORDER
      RETURN .F.
   ENDIF

   IF VALTYPE( aLook[LK_SEEK] ) != "C" .OR. EMPTY( RTRIM( aLook[LK_SEEK] ) )
      RETURN .F.
   ENDIF

   cField := _dbLookPgSeekField( cAliasPad, aLook )
   IF EMPTY( cField )
      RETURN .F.
   ENDIF

RETURN dfPgSeekFallbackScan( cWa, cField, aLook[LK_SEEK] )

*******************************************************************************
STATIC PROCEDURE _dbLookSeekOnOrder( cAliasPad, aLook, nOrd )
//*******************************************************************************
LOCAL cWa, lPg, xSeek

   cWa := RTRIM( cAliasPad )
   IF SELECT( cWa ) < 1 .OR. VALTYPE( nOrd ) != "N"
      RETURN
   ENDIF

   (cWa)->( ORDSETFOCUS( nOrd ) )

   xSeek := aLook[LK_SEEK]
   IF EMPTY( xSeek )
      RETURN
   ENDIF

   lPg := dfPgRddIs( (cWa)->( RDDNAME() ) )
   IF lPg
      (cWa)->( DBSEEK( xSeek ) )
      IF VALTYPE( xSeek ) == "C" .AND. !EMPTY( RTRIM( xSeek ) )
         IF !_dbLookPgSeekVerify( cAliasPad, aLook )
            _dbLookPgSeekFallback( cAliasPad, aLook )
         ENDIF
      ENDIF
   ELSE
      (cWa)->( DBSEEK( xSeek, .T. ) )
   ENDIF

RETURN
