//*****************************************************************************
//Progetto       : dBsee 4.0
//Descrizione    : Funzioni di utilita' per BROWSE
//Programmatore  : Baccan Matteo
//*****************************************************************************
#INCLUDE "dfWin.ch"
#INCLUDE "dfmsg.ch"

* ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
FUNCTION _TbFSkip( oTbr, n2Skip ) // dbSkip
* ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
LOCAL nSkip := (oTbr:W_ALIAS)->(dfSkip( n2Skip, oTbr:W_FILTER, oTbr:W_BREAK ))
IF nSkip == 0
   DO CASE
      CASE oTbr:WOBJ_TYPE # W_OBJ_FRM

      CASE (oTbr:W_ALIAS)->(RECCOUNT())==0
           dbMsgErr( dfAliasDesc(oTbr:W_ALIAS) +dfStdMsg( MSG_TBSKIP01 ))

      CASE (oTbr:W_ALIAS)->(DELETED()) .OR. (oTbr:W_ALIAS)->(EOF())
           * Evito i messaggi in caso di file vuoto con record cancellati

      CASE n2Skip<0
           dbMsgErr( dfStdMsg( MSG_TBSKIP02 ) +dfAliasDesc(oTbr:W_ALIAS))

      CASE n2Skip>0
           dbMsgErr( dfStdMsg( MSG_TBSKIP03 ) +dfAliasDesc(oTbr:W_ALIAS))
   ENDCASE
ENDIF
RETURN nSkip

* ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
// PGDBE: W_ORDER = slot DBDD; ORDNUMBER = ordine fisico (__record, pkey, …).
FUNCTION tbWaOrdSetFocus( cAlias, nOrd )
LOCAL cWa, lRet

   cWa := UPPER( ALLTRIM( cAlias ) )
   IF SELECT( cWa ) == 0 .OR. VALTYPE( nOrd ) != "N" .OR. nOrd < 1
      RETURN .F.
   ENDIF

   IF dfPgRddIs( ( cWa )->( RDDNAME() ) )
      lRet := .F.
      BEGIN SEQUENCE
         lRet := _ddDbddOrdSetFocus( cWa, nOrd )
      RECOVER
         lRet := .F.
      END SEQUENCE
      RETURN lRet
   ENDIF

   IF ( cWa )->( ORDNUMBER() ) != nOrd
      ( cWa )->( ORDSETFOCUS( nOrd ) )
   ENDIF

RETURN .T.

* ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
PROCEDURE _TbBTop( oTbr ) // GoTop
* ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
tbWaOrdSetFocus( oTbr:W_ALIAS, oTbr:W_ORDER )
IF dfPgRddIs( ( oTbr:W_ALIAS )->( RDDNAME() ) )
   dfPgGoTopInIndex( SELECT( oTbr:W_ALIAS ) )
ELSE
   ( oTbr:W_ALIAS )->( dfTop( oTbr:W_KEY, oTbr:W_FILTER, oTbr:W_BREAK ) )
ENDIF
RETURN

* ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
PROCEDURE _TbBBottom( oTbr ) // GoBottom
* ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
tbWaOrdSetFocus( oTbr:W_ALIAS, oTbr:W_ORDER )
(oTbr:W_ALIAS)->(dfBottom( oTbr:W_KEY, oTbr:W_FILTER, oTbr:W_BREAK ))
RETURN

* ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
STATIC FUNCTION dfAliasDesc( cAlias )
* ±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
LOCAL cName := cAlias
IF ddFilePos( cAlias )
   cName := ddFileDesc()
ENDIF
RETURN cName