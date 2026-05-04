FUNCTION tbTop( oWin )
LOCAL uRet

   IF !tbCanMoveBrowse( oWin )
      RETURN NIL
   ENDIF
   uRet := NIL
   BEGIN SEQUENCE
      uRet := oWin:tbTop()
   RECOVER
   END SEQUENCE
RETURN uRet

FUNCTION tbBottom( oWin )
LOCAL uRet

   IF !tbCanMoveBrowse( oWin )
      RETURN NIL
   ENDIF
   uRet := NIL
   BEGIN SEQUENCE
      uRet := oWin:tbBottom()
   RECOVER
   END SEQUENCE
RETURN uRet

STATIC FUNCTION tbCanMoveBrowse( oWin )
LOCAL cAlias

   IF ValType( oWin ) != "O"
      RETURN .F.
   ENDIF

   cAlias := ""
   BEGIN SEQUENCE
      cAlias := AllTrim( IIF( ValType( oWin:W_ALIAS ) == "C", oWin:W_ALIAS, "" ) )
   RECOVER
      RETURN .F.
   END SEQUENCE

   IF Empty( cAlias )
      RETURN .F.
   ENDIF

   IF Select( cAlias ) <= 0
      RETURN .F.
   ENDIF

   BEGIN SEQUENCE
      DBSELECTAREA( cAlias )
   RECOVER
      RETURN .F.
   END SEQUENCE

RETURN .T.

// //*****************************************************************************
// //Progetto       : dBsee 4.0
// //Descrizione    : Funzioni di utilita' per tBrowse
// //Programmatore  : Baccan Matteo
// //*****************************************************************************
// #include "INKEY.CH"
// #include "dfwin.ch"
// #include "dfstd.ch"
// 
// * 北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
// PROCEDURE tbTop( oTbr ) //
// * 北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
// tbGenMove( oTbr, K_HOME )
// RETURN
// 
// * 北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
// PROCEDURE tbBottom( oTbr ) //
// * 北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
// tbGenMove( oTbr, K_END )
// RETURN
// 
// * 北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
// STATIC PROCEDURE tbGenMove( oTbr, nMove ) //
// * 北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
// LOCAL lStab
// 
// DFDISPBEGIN()
// IF oTbr:WOBJ_TYPE == W_OBJ_FRM
//    DO CASE
//       CASE nMove==K_HOME ;EVAL( oTbr:GoTopBlock )
//       CASE nMove==K_END  ;EVAL( oTbr:GoBottomBlock )
//    ENDCASE
//    tbRecCng( oTbr )
// ELSE
//    DO CASE
//       // CASE nMove==K_HOME ;IF( lStab:=oTbr:HITTOP()   ,,oTbr:GOTOP()   )
//       // CASE nMove==K_END  ;IF( lStab:=oTbr:HITBOTTOM(),,oTbr:GOBOTTOM())
// 
//       CASE nMove==K_HOME ;IF( lStab:=.F.             ,,oTbr:GOTOP()   )
//       CASE nMove==K_END  ;IF( lStab:=.F.             ,,oTbr:GOBOTTOM())
// 
//    ENDCASE
//  //  IF !oTbr:STABLE .OR. !lStab
//       IF nMove==K_HOME
//          tbTotal( oTbr )
//          tbStab( oTbr, .T. )
//       ELSE
//          tbStab( oTbr )
//       ENDIF
//       tbSysFooter( oTbr )
//  //  ENDIF
// ENDIF
// 
// // tbSayOpt( oTbr, W_MM_VSCROLLBAR )
// 
// IF nMove==K_END .AND. oTbr:W_KEY#NIL
//    oTbr:W_CURRENTKEY := EVAL( oTbr:W_KEY )
// ENDIF
// DFDISPEND()
// 
// RETURN

