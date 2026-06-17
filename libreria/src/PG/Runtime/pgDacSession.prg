/******************************************************************************
  Runtime PostgreSQL: DacSession PGDBE (post-upsize / post-ddIndex).
  dfPgSessionInit / dfPgGetDacSession / dfPgSessionShutdown / dfPgCloseDbfWorkareas.
  Licenza e stringa DAC: pgUpsizeConn.prg; link dopo pgUpsizeConn, prima di ddUsePg.
******************************************************************************/
#INCLUDE "pgdbe.ch"

#ifdef __XPP__
REQUEST DacSession
#endif

#INCLUDE "Common.ch"
#INCLUDE "DFCLPSUP.CH"
#INCLUDE "dfGenMsg.ch"

STATIC s_oPgDacSession := NIL

*******************************************************************************
//* Attiva PGDBE come compound default. Chiamare DOPO che il framework ha aperto i file di sistema (dfInitScreenOff / ddUpdDbf / ddIndex).
FUNCTION dfPgDbeActivateDefault()
*******************************************************************************

   IF ValType( s_oPgDacSession ) == "O" .AND. s_oPgDacSession:isConnected()
      DbeSetDefault( "PGDBE" )
      RETURN .T.
   ENDIF

RETURN .F.

*******************************************************************************
FUNCTION dfPgDacSession()
*******************************************************************************

   IF ValType( s_oPgDacSession ) == "O"
      RETURN s_oPgDacSession
   ENDIF

RETURN NIL

*******************************************************************************
FUNCTION dfPgDbeRuntimeInit()
*******************************************************************************
LOCAL oS, cStr, cLic

   IF ValType( s_oPgDacSession ) == "O"
      IF s_oPgDacSession:isConnected()
         RETURN .T.
      ENDIF
   ENDIF

   IF ! dfPgDbeConfigurePgdbeLicense( .F. )
      RETURN .F.
   ENDIF

   cLic := dfPgLicenseInfoString()

   cStr := dfPgBuildDacConnectionString()
   oS   := DacSession():new( cStr )

   IF oS == NIL
      dbMsgErr( "PostgreSQL: DacSession non creato." )
      RETURN .F.
   ENDIF

   IF ! oS:isConnected()
      IF Empty( cLic )
         dbMsgErr( "PostgreSQL: connessione fallita (spesso manca licenza PGDBE client). Impostare XbasePgLicenseKey e XbasePgLicensee in [apps] o env, oppure VDB_DBSTART_INI verso EXE\dbstart.ini. Poi server/db/uid/pwd." )
      ELSE
         dbMsgErr( "PostgreSQL: connessione fallita. Verificare server/db/uid/pwd (dbstart.ini [apps] o env VDB_PG_*)." )
      ENDIF
      RETURN .F.
   ENDIF

   s_oPgDacSession := oS

RETURN .T.

*******************************************************************************
FUNCTION dfPgSessionInit( cConnStr )
*******************************************************************************
LOCAL lLoaded, bPrevErr, oS, cStr

   IF ValType( s_oPgDacSession ) == "O"
      IF s_oPgDacSession:isConnected()
         RETURN .T.
      ENDIF
   ENDIF

   lLoaded := AScan( DbeList(), {|x| Upper(x[1]) == "PGDBE"} ) > 0

   IF ! lLoaded
      bPrevErr := ErrorBlock( {|e| Break(e)} )
      BEGIN SEQUENCE
         lLoaded := DbeLoad( "PGDBE" )
      RECOVER
         lLoaded := .F.
      END SEQUENCE
      ErrorBlock( bPrevErr )
   ENDIF

   IF ! lLoaded
      dbMsgErr( "dfPgSessionInit: DbeLoad(PGDBE) fallito. pgdbe.dll non trovata." )
      RETURN .F.
   ENDIF

   IF ! dfPgDbeConfigurePgdbeLicense( .F. )
      RETURN .F.
   ENDIF

   IF ! Empty( cConnStr )
      cStr := cConnStr
   ELSE
      cStr := dfPgBuildDacConnectionString()
   ENDIF

   oS := DacSession():new( cStr )

   IF oS == NIL
      dbMsgErr( "dfPgSessionInit: DacSession non creato." )
      RETURN .F.
   ENDIF

   IF ! oS:isConnected()
      dbMsgErr( "dfPgSessionInit: connessione fallita. Verifica server/db/uid/pwd." )
      RETURN .F.
   ENDIF

   s_oPgDacSession := oS

RETURN .T.

*******************************************************************************
FUNCTION dfPgGetDacSession()
*******************************************************************************
   IF ValType( s_oPgDacSession ) == "O" .AND. s_oPgDacSession:isConnected()
      RETURN s_oPgDacSession
   ENDIF
RETURN NIL

*******************************************************************************
FUNCTION dfPgIsActive()   // .T. se l'applicazione gira in modalita' PostgreSQL
*******************************************************************************
// Unico punto di verita' per distinguere PG da DBF: basato sulla sessione
// PostgreSQL, quindi globale e indipendente dal workarea corrente.
// Per il driver di una SINGOLA tabella usare invece: alias->( dfPgRddIs( RDDNAME() ) )
RETURN ( dfPgGetDacSession() != NIL )

//************************************************************************
//* Chiusura applicazione (doc Alaska DacSession / MDIDEMO): :disconnect()
//* prima dell'uscita. Chiudere le aree PGDBE applicative, poi disconnect.
FUNCTION dfPgSessionShutdown()
//************************************************************************
LOCAL nArea, nPrev, cAlias, cRdd, cUp, oS

   IF ValType( s_oPgDacSession ) != "O"
      RETURN NIL
   ENDIF

   oS := s_oPgDacSession

   IF ! oS:isConnected()
      s_oPgDacSession := NIL
      RETURN NIL
   ENDIF

   nPrev := SELECT()

   FOR nArea := 1 TO 250
      IF !EMPTY( ALIAS( nArea ) )
         cAlias := ALIAS( nArea )
         cUp    := UPPER( TRIM( cAlias ) )
         IF dfPgIsSystemDictionaryStem( cUp )
            LOOP
         ENDIF
         cRdd := ( cAlias )->( RDDNAME() )
         IF UPPER( cRdd ) == "PGDBE"
            ( cAlias )->( DBCLOSEAREA() )
         ENDIF
      ENDIF
   NEXT

   IF nPrev > 0 .AND. nPrev <= 250
      IF !EMPTY( ALIAS( nPrev ) )
         DBSELECTAREA( nPrev )
      ENDIF
   ENDIF

   IF oS:isConnected()
      oS:disconnect()
   ENDIF
   s_oPgDacSession := NIL

RETURN NIL

*******************************************************************************
FUNCTION dfPgCloseDbfWorkareas()
*******************************************************************************
LOCAL nArea, nPrev, cAlias, cRdd, cUp

   IF dfPgGetDacSession() == NIL
      RETURN NIL
   ENDIF

   nPrev := SELECT()

   FOR nArea := 1 TO 250
      IF !EMPTY( ALIAS( nArea ) )
         cAlias := ALIAS( nArea )
         cUp    := UPPER( TRIM( cAlias ) )
         IF dfPgIsSystemDictionaryStem( cUp )
            LOOP
         ENDIF
         cRdd := ( cAlias )->( RDDNAME() )
         IF UPPER( cRdd ) != "PGDBE"
            ( cAlias )->( DBCLOSEAREA() )
         ENDIF
      ENDIF
   NEXT

   IF nPrev > 0 .AND. nPrev <= 250
      IF !EMPTY( ALIAS( nPrev ) )
         DBSELECTAREA( nPrev )
      ENDIF
   ENDIF

RETURN NIL
