# PostgreSQL (PGDBE) - Interventi sulla libreria Visual dBsee

Questo documento resta la vista completa degli interventi PG applicati in `libreria/src`, ordinata per commit e area funzionale.

Per uso rapido:

- panoramica chiavi runtime: `PGDBE-dfSet-riferimento-rapido.md`
- verifica operativa: `PGDBE-checklist-riapplicazione.md`

## Obiettivo

Portare la libreria Visual dBsee a lavorare in modo piu prevedibile con `PGDBE`, coprendo quattro aree principali:

- infrastruttura runtime PostgreSQL
- seek e lookup su ordini PG
- report, query e output temporanei
- navigazione browse e listbox 1:n

## Sequenza dei commit

| Commit | Data | Titolo | Area principale |
|---|---|---|---|
| `b77f497` | `2026-04-21` | aggiunta infrastruttura runtime PostgreSQL | runtime, sessione, nuovi moduli PG |
| `a4de29f` | `2026-04-21` | corretto il flusso di seek e lookup PostgreSQL | `dfS`, `dbLook`, `dfSkip` |
| `fc99184` | `2026-04-21` | corrette gestione report e query PostgreSQL | query, report, Crystal output |
| `8ea3bbd` | `2026-04-21` | corretta la navigazione browse e listbox PostgreSQL | browse, listbox, footer totals |
| `4cf939d` | `2026-04-21` | aggiunta documentazione PGDBE | documentazione e rifiniture |
| `0757028` | `2026-04-21` | aggiunta variante di build Xbase++ 2.00.2598 e aggiornamento documentazione | build/output/documentazione |
| `2ac44ba` | `2026-04-21` | riallineati i template ide xbase per l'integrazione PostgreSQL | template IDE |
| `9d305d5` | `2026-04-21` | sostituito lo script locale di copia artefatti con uno generico | distribuzione artefatti |
| `3012194` | `2026-04-24` | aggiunti campi postgresql al progetto e ide | metadati IDE/property grid |
| `e79c566` | `2026-04-26` | riordinati gli script di supporto e rimossi i riferimenti locali dalle build | script e manutenzione |
| `0e9244e` | `2026-04-26` | aggiornati i template del make | template build/make |
| `52cad31` | `2026-04-26` | aggiornate le librerie per la build 2.00.2598 | aggiornamento binari/lib |
| `79f6621` | `2026-04-26` | template per parametri postgres in vdb | template PG parameters |
| `1f3439e` | `2026-04-28` | aggiunto supporto a pg anche per i listbox | integrazioni listbox su casi PG |
| `7e0ffed` | `2026-05-04` | riordinata la struttura PGUpsize e semplificato il flusso CLI per uso cliente | `PG/Runtime`, `PG/Upsize`, CLI |
| `e55d174` | `2026-05-04` | upsize: gestisci retry ed esclusioni nella migrazione PG | retry `DbfUpsize`, esclusioni ordini/tabelle |
| `a7c31d1` | `2026-05-04` | browse: proteggi indici e alias non disponibili | `DDUSE`, browse totals/top-bottom |
| `f97114b` | `2026-05-04` | docs: aggiorna documentazione PGUpsize e PGDBE | README e docs PG |
| `5ca83c7` | `2026-05-04` | build: aggiorna artefatti 2.00.2598 e pgupsize | output build, `pgupsize.exe`, template |

## 1. Commit `b77f497` - runtime PostgreSQL

### File toccati

- `libreria/src/PG/Runtime/pgDacSession.prg`
- `libreria/src/PG/Runtime/pgVdbIni.prg`
- `libreria/src/PG/Upsize/pgUpsize.prg`
- `libreria/src/PG/Upsize/pgUpsizeConn.prg`
- `libreria/src/PG/Upsize/pgUpsizeXml.prg`
- `libreria/src/_gotutto.base`
- `libreria/src/base/DBCFGOPE.PRG`
- `libreria/src/base/DDUSE.PRG`
- `libreria/src/base/PGSEEK.PRG`
- `scripts/copy-build-artifacts.bat`
- `libreria/src/dblang.base`
- `libreria/src/dynamic.base`
- `libreria/src/static.base`

### Cosa introduce

- Nuovi moduli sotto `src\PG\` per gestire bootstrap PG, configurazione, upsize e sessione runtime. Nello stato corrente sono separati in `src\PG\Runtime\` e `src\PG\Upsize\`.
- Infrastruttura comune `PGSEEK.PRG` con helper per capire se l'RDD corrente e' PG, dedurre il campo da `ORDKEY()`, verificare il record dopo un `DBSEEK` e fare fallback scan quando serve.
- Aggiornamenti ai file base di build per includere i moduli PG nella compilazione della libreria.
- Adattamento di `DBCFGOPE.PRG` per aprire i dizionari locali con `DBFCDX` anche quando il driver di default e' PG.
- Adattamento di `DDUSE.PRG` per instradare la sessione solo quando il runtime PG e' davvero attivo.
- Presenza di uno script generico per copiare gli artefatti build verso una destinazione scelta esplicitamente, senza riferimenti rigidi a un progetto locale.

### Effetto pratico

- La libreria puo riconoscere e gestire esplicitamente il contesto PostgreSQL.
- Le funzioni di seek PG non sono duplicate in piu punti ma centralizzate.
- I file dizionario restano apribili anche con driver PG attivo.

## 2. Commit `a4de29f` - seek e lookup PostgreSQL

### File toccati

- `libreria/src/ide/SOURCE/DBLOOK.PRG`
- `libreria/src/base/DBLOOK.PRG`
- `libreria/src/base/DFS.PRG`

### Cosa corregge

Questo commit affronta i casi in cui `DBSEEK` su PG posiziona il cursore in modo non pienamente coerente con il record logico atteso, soprattutto con ordini su campi carattere e lookup ripetuti.

### Interventi principali

#### `DFS.PRG` - `dfS()`

- Ramificazione PG dedicata prima del flusso storico `ORDSETFOCUS + DBSEEK`.
- Cache statica del contesto seek per alias, ordine e nome campo dedotto da `ORDKEY()`.
- Cache hash del `RECNO()` per seek ripetuti.
- Uso di `dfPgOrdKeySingleField()` per verificare il record corrente dopo il seek.
- Fallback su campo `codice` limitato ai casi in cui la struttura tabella lo rende sensato.
- Azzeramento del nome campo in cache quando non si riesce a dedurre un campo valido dall'ordine.

#### `DBLOOK.PRG`

- Ramificazioni PG per evitare seek soft incoerenti.
- Verifica del record dopo `DBSEEK`.
- Fallback scan quando il record trovato non combacia davvero con il valore cercato.
- Salvataggio e ripristino della posizione record quando si cambia ordine.
- Gestione piu robusta del seek libero vuoto.

### Effetto pratico

- Minor rischio di usare il record sbagliato dopo `dfS()` o `dbLook()`.
- Lookup piu stabili su tabelle PG con ordini non banali.
- Base tecnica riutilizzabile nei commit successivi su report e browse.

## 3. Commit `fc99184` - report, query e output

### File toccati

- `libreria/src/base/DFANY2ST.PRG`
- `libreria/src/base/DFQRYFLT.PRG`
- `libreria/src/base/DFSTA.PRG`
- `libreria/src/base/dfprncon.prg`
- `libreria/src/base/dfupdqry.prg`
- `libreria/src/xpp/DFCRWOUT.prg`

### Problemi affrontati

- report che vanno in EOF pur avendo dati
- query con confronti data/stringa poco affidabili su PG
- valori `NIL` che propagano errori o record temporanei incompleti
- cache seek riutilizzata tra contesti di stampa diversi

### Interventi principali

#### `dfprncon.prg`

- Introduce il flush della cache seek PG all'inizio della configurazione stampa.

#### `DFANY2ST.PRG`

- `dfAny2Str()` restituisce `""` se riceve `NIL`, cosi i confronti e le espressioni non si rompono sui `NULL` SQL.

#### `DFQRYFLT.PRG`

- Migliora i confronti data usando `DTOS()` nei casi compatibili con PG.
- Normalizza meglio i confronti stringa, inclusi spazi non standard e differenze di padding.
- Gestisce meglio date vuote o non valide nei filtri.

#### `DFSTA.PRG`

- In `dfReportTOP()` evita di usare forzatamente `VR_KEY` quando una query di stampa PG e' gia attiva.

#### `dfupdqry.prg`

- Disinnesca la combinazione pericolosa KEY/BREAK ottimizzata per DBF quando il master e' PG.

#### `DFCRWOUT.prg`

- Converte i `NIL` in valori vuoti tipizzati prima dell'output verso il DBF temporaneo per Crystal Reports.

### Effetto pratico

- Report piu affidabili su dataset PG.
- Meno regressioni legate a `NULL`, date non valorizzate e confronti stringa.
- Stampa e query piu coerenti con il comportamento atteso dell'applicazione.

## 4. Commit `8ea3bbd` - browse e navigazione listbox

### File toccati

- `libreria/src/base/DFSKIP.PRG`
- `libreria/src/s2/S2BROWSE.prg`
- `libreria/src/s2/S2BRW.prg`

### Problemi affrontati

- browse 1:n che mostrano una sola riga
- listbox vuote dopo cambio master
- costi elevati nei footer totals su PG
- navigazione interrotta troppo presto per colpa di `break` o `LastRec()==0`

### Interventi principali

#### `DFSKIP.PRG`

- `dfSkip()` non considera automaticamente `LastRec()==0` come assenza righe quando l'RDD e' PG.
- Nei cammini PG con `break`, prova a camminare oltre i record temporaneamente fuori gruppo prima di arrendersi.
- `dfTop()` usa i nuovi helper PG per riallinearsi dopo il seek.
- In caso di EOF apparente, puo usare un fallback scan per rientrare su una riga valida.
- Mantiene `DBGOTO(0)` come comportamento di chiusura coerente, salvo opt-in legacy tramite `dfSet`.

#### `S2BROWSE.prg`

- `tbReset()` continua a invocare il reset del browser anche su PG, evitando browse incoerenti.

#### `S2BRW.prg`

- `tbTotal()` puo saltare la scansione completa dei footer totals su PG.
- `dfTotalInc()` evita lavoro ridondante durante il calcolo dei totali.

### Effetto pratico

- Browse e listbox piu stabili nei casi master/dettaglio.
- Meno rischio di schermate vuote o navigazione troncata.
- Riduzione del costo di apertura browse su tabelle grandi.

## 5. Commit `1f3439e` - supporto PG aggiuntivo sui listbox

Questo commit estende gli adattamenti su listbox in contesto PostgreSQL, consolidando la parte introdotta nei commit precedenti su browse/navigazione.

In termini pratici, e' il completamento recente della linea di lavoro "PG su listbox", quindi va considerato insieme a `8ea3bbd` durante il collaudo funzionale.

## 6. Commit `4cf939d` - documentazione

### File toccati

- `libreria/docs/PGDBE-checklist-riapplicazione.md`
- `libreria/docs/PGDBE-dfSet-riferimento-rapido.md`
- `libreria/docs/PGDBE-interventi-libreria.md`
- `libreria/docs/README.md`
- `libreria/src/base/DFLIBDAT.PRG`

### Scopo

- Formalizzare la logica introdotta dai commit precedenti.
- Rendere piu semplice riapplicare o verificare gli interventi PG in un altro fork.
- Tenere separati:
  - quadro generale
  - configurazioni `dfSet`
  - checklist di verifica o porting

## 7. Commit di integrazione (fuori da `libreria/src` ma rilevanti)

Questi commit non sono solo "core libreria", ma sono parte integrante della catena PG del branch:

- `0757028`  
  Introduce la variante build `2.00.2598` (script, output e docs).
- `2ac44ba`  
  Riallinea template IDE (`INITPROC.TMP`, `RMAKEX*.TMP`) necessari per coerenza runtime PG lato progetto host.
- `9d305d5`  
  Sostituisce script locale con `scripts/copy-build-artifacts.bat` generico.
- `3012194`  
  Aggiorna DBF/NTX IDE (`dbseeopt`, `dbseetab`) con campi PostgreSQL in proprieta' progetto.
- `e79c566`  
  Riordina script e rimuove riferimenti locali hardcoded nelle build.
- `0e9244e`  
  Aggiorna template make/build.
- `52cad31`  
  Aggiorna set librerie/binari per build `2.00.2598`.
- `79f6621`  
  Introduce template per parametri PostgreSQL in VDB.
- `7e0ffed`
  Riordina i moduli PG in `Runtime/` e `Upsize/`, aggiunge la guida cliente del runner `pgupsize.exe` e semplifica il flusso standalone tramite environment/INI.
- `e55d174`
  Aggiunge retry controllato della migrazione: se `DbfUpsize` fallisce su un `OrdListAdd`, il trace viene letto per individuare il bag CDX problematico, il file runtime viene rigenerato escludendo temporaneamente solo quell'ordine e la migrazione viene ritentata.
- `a7c31d1`
  Protegge l'apertura indici e le chiamate browse quando un alias non e' disponibile o non e' piu selezionabile.
- `f97114b`
  Riallinea README e documentazione PGDBE alla struttura `PG/Runtime` + `PG/Upsize` e alla CLI standalone.
- `5ca83c7`
  Aggiorna gli artefatti build `2.00.2598`, include `pgupsize.exe` negli output e riallinea `dfLibDate()`.

## 8. Integrazione fuori da `libreria/src`

Nel confronto con una variante funzionante di riferimento e' emerso che il supporto PostgreSQL non dipende solo dai sorgenti della libreria e dalle DLL prodotte.

Sono rilevanti anche questi template IDE:

- `ide/tmp/xbase/INITPROC.TMP`
- `ide/tmp/xbase/RMAKEX1.TMP`
- `ide/tmp/xbase/RMAKEX2.TMP`
- `ide/tmp/xbase/rmakex3.tmp`

Ruolo operativo:

- `INITPROC.TMP` contribuisce all'inizializzazione del progetto generato e puo contenere il bootstrap del runtime PG.
- `RMAKEX*.TMP` governano la generazione dei file di build/link del main.

Questi file sono stati riallineati alla variante funzionante di riferimento per mantenere coerente l'integrazione PG anche lato progetto host, non solo lato libreria.

## 9. Chiavi `dfSet` collegate

Le modifiche PG introdotte dai commit `fc99184` e `8ea3bbd` possono essere modulate tramite alcune chiavi `dfSet`.

Le principali sono:

- `XbasePgReportTopUseKeyWithQry`
- `XbasePgReportKeepQueryKeyOpt`
- `XbaseBrowseFooterTotalsOnPG`
- `XbaseDbLookEofOnEmptyFreeSeek`
- `XbasePgDfTopDeferDbgoto0OnBreak`
- `XbasePgDfSkipWalkPastBreak`

Il dettaglio operativo e' documentato in `PGDBE-dfSet-riferimento-rapido.md`.

## 10. Mappa rapida file -> commit

| File | Commit principale |
|---|---|
| `src/PG/Runtime/*.prg` | `b77f497`, `7e0ffed` |
| `src/PG/Upsize/*.prg` | `b77f497`, `7e0ffed`, `e55d174` |
| `src/base/PGSEEK.PRG` | `b77f497` |
| `src/base/DFS.PRG` | `b77f497`, `a4de29f` |
| `src/base/DBLOOK.PRG` | `a4de29f` |
| `src/base/DDUSE.PRG` | `b77f497`, `a7c31d1` |
| `src/base/DFANY2ST.PRG` | `fc99184` |
| `src/base/DFQRYFLT.PRG` | `fc99184` |
| `src/base/DFSTA.PRG` | `fc99184` |
| `src/base/dfprncon.prg` | `fc99184` |
| `src/base/dfupdqry.prg` | `fc99184` |
| `src/xpp/DFCRWOUT.prg` | `fc99184` |
| `src/base/DFSKIP.PRG` | `8ea3bbd` |
| `src/s2/S2BROWSE.prg` | `8ea3bbd` |
| `src/s2/S2BRW.prg` | `8ea3bbd`, `1f3439e` |
| `src/support/TBTOTAL.prg` | `a7c31d1` |
| `src/xpp/TBTOP.prg` | `a7c31d1` |

## 11. Uso consigliato di questa documentazione

1. Leggere questo file per la storia tecnica completa.
2. Usare `PGDBE-dfSet-riferimento-rapido.md` per tuning/configurazione.
3. Usare `PGDBE-checklist-riapplicazione.md` per audit e riallineamenti post-merge.

## 12. EXE standalone DBF->Postgres

Per coprire anche il caso "tool esterno", e' stato introdotto un runner CLI dedicato che riusa il core di migrazione PG della libreria.

- `libreria/src/PG/Upsize/pgUpsize.prg`
  - espone `dfPgUpsizeRunMigration(cTplOrCfg, lForce, lDryRun, lLogSkip, lNoUi)`
  - gestisce dry-run, codici uscita, precheck licenza, ripristino DBE locale dopo `DbfUpsize`
  - mantiene `dfPgUpsizeAfterUpd()` e `dfPgUpsizeRunFromUpd()` per eventuali integrazioni applicative
- `libreria/src/PG/Upsize/pgUpsizeExe.prg`
  - entrypoint `MAIN()` standalone
  - configurazione via environment (`VDB_UPSIZE_CFG`, `VDB_PG_UPSIZE_FORCE`, `VDB_PG_UPSIZE_DRY_RUN`) e alias in italiano (`VDB_UPSIZE_CONFIG`, `VDB_UPSIZE_FORZA`, `VDB_UPSIZE_SIMULA`)
  - mappa codici uscita espliciti (`0..3`) per script, supporto cliente e CI
- `libreria/src/PG/Upsize/pgUpsizeCliCompat.prg`
  - shim minimo per usare il core PG fuori dal framework completo
  - fornisce fallback per messaggi, shell, `dbCfgOpen()` e risoluzione `dbstart.ini`
- `libreria/src/PG/Upsize/pgUpsizeExe.xpj` + `libreria/src/PG/Upsize/build-pgupsize-exe.bat`
  - target build dedicato per produrre `pgupsize.exe` su output `libreria/output/lib200-2598/rel`
- `libreria/src/PG/Upsize/README-upsize-cli.md`
  - guida cliente per licenza PGDBE esterna, connessione, path INI, dry-run, log ed exit code

Il template `ide/tmp/xbase/INITPROC.TMP` resta responsabile dell'inizializzazione runtime PostgreSQL del progetto generato. La chiamata esplicita alla migrazione puo avvenire da tool standalone oppure da codice applicativo che invoca gli helper sopra.

### Fase di creazione `UPSIZE.runtime.upsize`

La migrazione non usa direttamente il template sorgente. Prima viene sempre costruito un file runtime:

1. `dfPgUpsizeRunMigration()` riceve un template esplicito (`VDB_UPSIZE_CFG` / `VDB_UPSIZE_CONFIG`) oppure chiede a `dfPgUpsizeResolveCfg()` di trovarne uno.
2. Se non esiste un template, il flusso entra in modalita no-template e crea una configurazione minima partendo dagli INI disponibili.
3. `dfPgUpsizeBuildRuntimeCfg()` determina la cartella di lavoro:
   - dalla directory del template, se il template esiste
   - da `VDB_PG_PATH_INI`, se si usa un `path.ini` esplicito
   - dalla directory corrente / cartella `EXE`, nei casi standalone
4. La connessione PostgreSQL viene scritta nel runtime prendendo i valori da environment, `[apps]` o `[UPSIZE]`.
5. L'elenco tabelle viene ricostruito dal dizionario `DBDD`, sorgente predefinita per rappresentare lo stato esatto del database:
   - vengono lette le righe `RecTyp=DBF`
   - i DBF di dizionario/sistema e le tabelle escluse vengono saltati
   - il file DBF fisico viene cercato usando `File_Path` verso il relativo `UserPathXX`, poi negli altri `UserPathXX` e infine in `EXE`
   - l'eventuale `PgUpsizeExtraDbfDir` viene aggiunto solo come inclusione esplicita
6. Ogni tabella viene emessa nel runtime XML con:
   - nome target PostgreSQL normalizzato e univoco
   - path DBF sorgente originale
   - DBE tabella `foxcdx`
   - ordini CDX presi dalle righe `NDX` del `DBDD`/`FILE_ALI`, se non disabilitati o esclusi
7. Il file generato e' `UPSIZE.runtime.upsize`; se non e' scrivibile nella destinazione prevista, il codice prova un fallback su path alternativo o `%TEMP%`.

La modalita `PgUpsizeTableSource=EXE` / `VDB_PG_UPSIZE_TABLE_SOURCE=EXE` resta disponibile solo come scan fisico legacy/diagnostico. In modalita predefinita non si deducono gli indici dal nome della tabella e non si fondono automaticamente i `.CDX` presenti nella cartella dati: se un ordine non e' nel `DBDD`, non entra nel runtime.

Questa fase e' eseguibile da sola con dry-run (`VDB_PG_UPSIZE_DRY_RUN=1` o `VDB_UPSIZE_SIMULA=1`) ed e' il primo controllo da fare quando una migrazione cliente non parte.

### Fase di esecuzione upsize

Dopo la creazione del runtime:

1. viene configurata la licenza PGDBE (`pgdbe_license.txt`, environment o INI)
2. se il run non e' dry-run, viene aperto il trace `<runtime>.pgtrace.log`
3. `DbfUpsize( cCfg, oLog )` trasferisce dati e strutture verso PostgreSQL
4. in caso di successo viene ripristinato il DBE locale precedente
5. in caso di errore:
   - se il trace segnala un CDX non apribile durante `OrdListAdd`, viene aggiunta un'esclusione transitoria e il runtime viene rigenerato per ritentare
   - se il trace segnala una tabella non apribile in esclusiva, il flusso fallisce esplicitamente per evitare migrazioni parziali silenziose
   - dopo il limite di retry, il runner ritorna codice `3`

## 13. Hardening corrente PGUpsize e browse

Lo stato corrente aggiunge protezioni operative non legate a un solo commit storico:

- `pgUpsizeXml.prg`
  - genera il runtime XML con DBE tabella `foxcdx`
  - normalizza i nomi target PostgreSQL e li rende univoci (`NOME`, `NOME_2`, ...)
  - supporta `[UPSIZE] PgUpsizeExcludeTables`
  - supporta `[UPSIZE] PgUpsizeExcludeOrders` con nomi file, stem e wildcard
  - supporta `[UPSIZE] PgUpsizeDisableOrders=YES` per diagnosi o migrazioni senza ordini
  - legge di default tabelle e ordini da `DBDD`; `PgUpsizeTableSource=EXE` / `VDB_PG_UPSIZE_TABLE_SOURCE=EXE` mantiene solo lo scan fisico legacy
  - puo includere una cartella DBF extra tramite `PgUpsizeExtraDbfDir` / `VDB_PG_UPSIZE_EXTRA_DBF_DIR`
- `pgUpsize.prg`
  - se `DbfUpsize` fallisce durante `OrdListAdd`, legge il trace, esclude temporaneamente il singolo bag CDX e rigenera il runtime XML per ritentare
  - limita i retry a un massimo controllato
  - non salta tabelle con errore di apertura esclusiva: in quel caso fallisce in modo esplicito per evitare migrazioni parziali silenziose
- `pgUpsizeConn.prg`
  - espone `dfPgUpsizeResolvedIniPath()` per diagnostica del `PgUpsize.ini` realmente usato
- `DDUSE.PRG`
  - protegge `ORDLISTADD()` e `SET ORDER TO` da indici non apribili, evitando che un bag rotto blocchi tutta l'apertura tabella quando e' possibile proseguire
- `TBTOTAL.prg` e `TBTOP.prg`
  - verificano che l'oggetto browse abbia un alias valido e selezionabile prima di calcolare totali o muovere top/bottom
  - racchiudono le chiamate browse in `BEGIN SEQUENCE`, cosi un alias gia chiuso non fa collassare la UI

Queste protezioni sono particolarmente utili durante migrazioni o smoke test su progetti legacy, dove indici locali, DBF e workarea possono non essere nello stato atteso.
