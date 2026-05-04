PROCEDURE tbTotal( oTbr, lDisplay )                   // Totali di colonna
   IF !tbCanCalcBrowseTotals( oTbr )
      RETURN
   ENDIF
   BEGIN SEQUENCE
      oTbr:tbTotal( lDisplay )
   RECOVER
   END SEQUENCE
RETURN 

PROCEDURE tbIcv( oTbr )                     // Incremento totali di colonna
   oTbr:tbIcv()
RETURN 

PROCEDURE tbDcv( oTbr )                     // Cancella Totali di colonna
   oTbr:tbDcv()
RETURN 

FUNCTION tbGcv( oTbr, cId )                 // Get Totali di colonna
RETURN oTbr:tbGcv( cId )

STATIC FUNCTION tbCanCalcBrowseTotals( oTbr )
LOCAL cAlias

   IF ValType( oTbr ) != "O"
      RETURN .F.
   ENDIF

   cAlias := ""
   BEGIN SEQUENCE
      cAlias := AllTrim( IIF( ValType( oTbr:W_ALIAS ) == "C", oTbr:W_ALIAS, "" ) )
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
