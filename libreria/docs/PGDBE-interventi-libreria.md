# PostgreSQL (PGDBE) - interventi sulla libreria Visual dBsee

Questo documento descrive gli adattamenti PostgreSQL introdotti nella libreria `libreria\src\`, organizzati secondo i commit applicati nel fork.

## Obiettivo

Portare la libreria Visual dBsee a lavorare in modo piu prevedibile con `PGDBE`, coprendo quattro aree principali:

- infrastruttura runtime PostgreSQL
- seek e lookup su ordini PG
- report, query e output temporanei
- navigazione browse e listbox 1:n

## Sequenza dei commit

| Commit | Titolo | Area principale |
|---|---|---|
| `3a0e5ef` | Add PostgreSQL runtime infrastructure | runtime, sessione, nuovi moduli PG |
| `ce3cfc2` | Fix PostgreSQL seek and lookup flow | `dfS`, `dbLook`, `dfSkip` |
| `0fe8fe6` | Fix PostgreSQL report and query handling | query, report, Crystal output |
| `cda7aec` | Adjust PostgreSQL browse and list navigation | browse, listbox, footer totals |
| `4e37315` | Add PGDBE documentation | documentazione e rifiniture |

## 1. Commit `3a0e5ef` - runtime PostgreSQL

### File toccati

- `libreria/src/PG/pgDacSession.prg`
- `libreria/src/PG/pgUpsize.prg`
- `libreria/src/PG/pgUpsizeConn.prg`
- `libreria/src/PG/pgUpsizeXml.prg`
- `libreria/src/PG/pgVdbIni.prg`
- `libreria/src/_gotutto.base`
- `libreria/src/base/DBCFGOPE.PRG`
- `libreria/src/base/DDUSE.PRG`
- `libreria/src/base/PGSEEK.PRG`
- `libreria/src/copy-dll-presenze-exe.bat`
- `libreria/src/dblang.base`
- `libreria/src/dynamic.base`
- `libreria/src/static.base`

### Cosa introduce

- Nuovi moduli sotto `src\PG\` per gestire bootstrap PG, configurazione, upsize e sessione runtime.
- Infrastruttura comune `PGSEEK.PRG` con helper per capire se l'RDD corrente e' PG, dedurre il campo da `ORDKEY()`, verificare il record dopo un `DBSEEK` e fare fallback scan quando serve.
- Aggiornamenti ai file base di build per includere i moduli PG nella compilazione della libreria.
- Adattamento di `DBCFGOPE.PRG` per aprire i dizionari locali con `DBFCDX` anche quando il driver di default e' PG.
- Adattamento di `DDUSE.PRG` per instradare la sessione solo quando il runtime PG e' davvero attivo.

### Effetto pratico

- La libreria puo riconoscere e gestire esplicitamente il contesto PostgreSQL.
- Le funzioni di seek PG non sono duplicate in piu punti ma centralizzate.
- I file dizionario restano apribili anche con driver PG attivo.

## 2. Commit `ce3cfc2` - seek e lookup PostgreSQL

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

## 3. Commit `0fe8fe6` - report, query e output

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

## 4. Commit `cda7aec` - browse e navigazione listbox

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

## 5. Commit `4e37315` - documentazione

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

## 6. Integrazione fuori da `libreria/src`

Nel confronto con `C:\src\PRESENZE\VisualdBsee` e' emerso che il supporto PostgreSQL funzionante non dipende solo dai sorgenti della libreria e dalle DLL prodotte.

Sono rilevanti anche questi template IDE:

- `ide/tmp/xbase/INITPROC.TMP`
- `ide/tmp/xbase/RMAKEX1.TMP`
- `ide/tmp/xbase/RMAKEX2.TMP`
- `ide/tmp/xbase/rmakex3.tmp`

Ruolo operativo:

- `INITPROC.TMP` contribuisce all'inizializzazione del progetto generato e puo contenere il bootstrap del runtime PG.
- `RMAKEX*.TMP` governano la generazione dei file di build/link del main.

Questi file sono stati riallineati alla variante `PRESENZE` per mantenere coerente l'integrazione PG anche lato progetto host, non solo lato libreria.

## 7. Chiavi `dfSet` collegate

Le modifiche PG introdotte dai commit `0fe8fe6` e `cda7aec` possono essere modulate tramite alcune chiavi `dfSet`.

Le principali sono:

- `XbasePgReportTopUseKeyWithQry`
- `XbasePgReportKeepQueryKeyOpt`
- `XbaseBrowseFooterTotalsOnPG`
- `XbaseDbLookEofOnEmptyFreeSeek`
- `XbasePgDfTopDeferDbgoto0OnBreak`
- `XbasePgDfSkipWalkPastBreak`

Il dettaglio operativo e' documentato in `PGDBE-dfSet-riferimento-rapido.md`.

## 8. Mappa rapida file -> commit

| File | Commit principale |
|---|---|
| `src/PG/*.prg` | `3a0e5ef` |
| `src/base/PGSEEK.PRG` | `3a0e5ef` |
| `src/base/DFS.PRG` | `3a0e5ef`, `ce3cfc2` |
| `src/base/DBLOOK.PRG` | `ce3cfc2` |
| `src/base/DFANY2ST.PRG` | `0fe8fe6` |
| `src/base/DFQRYFLT.PRG` | `0fe8fe6` |
| `src/base/DFSTA.PRG` | `0fe8fe6` |
| `src/base/dfprncon.prg` | `0fe8fe6` |
| `src/base/dfupdqry.prg` | `0fe8fe6` |
| `src/xpp/DFCRWOUT.prg` | `0fe8fe6` |
| `src/base/DFSKIP.PRG` | `cda7aec` |
| `src/s2/S2BROWSE.prg` | `cda7aec` |
| `src/s2/S2BRW.prg` | `cda7aec` |

## 9. Uso consigliato di questa documentazione

1. Leggere questo file per capire la storia tecnica dei commit.
2. Consultare `PGDBE-dfSet-riferimento-rapido.md` se serve modulare il comportamento runtime.
3. Usare `PGDBE-checklist-riapplicazione.md` per verificare il fork o rifare il porting in futuro.
