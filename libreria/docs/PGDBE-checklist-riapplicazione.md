# Checklist PGDBE - Riapplicazione/Verifica

Usa questa checklist quando riallinei il fork PG o dopo merge importanti sulla libreria.

## 1) Runtime PG (base)

- presenti i moduli `src/PG/Runtime/*.prg` principali (`pgDacSession`, `pgVdbIni`)
- presenti i moduli `src/PG/Upsize/*.prg` principali (`pgUpsize*`, `pgUpsizeExe`, `pgUpsizeCliCompat`)
- `src/base/PGSEEK.PRG` incluso in build
- file build (`static.base`, `dynamic.base`, `_gotutto.base`) coerenti con `PG\Runtime` e `PG\Upsize`
- `DDUSE.PRG` e `DBCFGOPE.PRG` con logica PG/DBFCDX corretta

## 2) Seek/Lookup

- `DFS.PRG` con ramo PG dedicato (`dfPgRddIs`, verifica post-seek, cache)
- `DBLOOK.PRG` con fallback PG e gestione seek libero vuoto
- test lookup ripetuto su stessa chiave: risultato stabile

## 3) Report/Query/Output

- `dfprncon` resetta cache seek PG prima della stampa
- `dfAny2Str` gestisce `NIL`
- `dfQryFlt` robusto su date/stringhe/NULL
- `dfReportTOP` e `dfUpdQryRep` non forzano comportamento DBF legacy su PG
- `DFCRWOUT` normalizza valori vuoti/NIL

## 4) Browse/Listbox

- `DFSKIP.PRG`: no stop prematuro su `LastRec()==0` in PG
- `dfTop`/`dfSkip` con percorso PG oltre break quando necessario
- `S2BROWSE`/`S2BRW` coerenti su reset e totals
- `TBTOP.prg` non muove top/bottom se l'alias browse non e' selezionabile
- `TBTOTAL.prg` non calcola totali se l'alias browse non e' disponibile
- test master/dettaglio 1:n: niente righe perse

### 4b) Browse ricerca PG (`ddWin` / `ddKey` / `fini*`)

Riferimento dettagliato: [PGDBE-browse-ricerca-ordine-indice.md](./PGDBE-browse-ricerca-ordine-indice.md)

- [ ] `DDFILE.PRG`: `_ddPgOrdIsSystem` — indici `*_4seek` / `*_4like` **non** classificati come sistema
- [ ] `DDWIN.PRG`: su PG, `_ddDbddOrdSetFocus` al posto di `ORDSETFOCUS(slot)`; EXE custom riceve **slot** utente, non `INDEXORD()` fisico
- [ ] `DFS.PRG`: `dfS` mappa slot numerico con `_ddDbddPgPhysOrdFromUserSlot`
- [ ] `TBSKIP.PRG`: `tbWaOrdSetFocus`, `_TbBTop` + `dfPgGoTopInIndex`; **assente** codice `tbPgBrowse*`
- [ ] `S2BROWSE` / `S2BRW` / `S2BRWBOX`: `skipBlock` standard (`_TbFSkip`), nessun wire mouse/SQL PG
- [ ] `dbstart.ini` host: **senza** `XbasePgBrowseIndexOrder` / `XbasePgBrowseSqlOrder`
- [ ] Build: `gotutto200-2598.bat` o, se STALE, `scripts/rebuild-vdbsee1o-2598.bat` → `VDBSEE1O.DLL` ≥ data `VDBSEE1S.DLL`
- [ ] Copia: `scripts/copy-to-host.bat` (o `copy-build-artifacts` con path espliciti) senza errore STALE
- [ ] Test: ordine griglia, seek, scroll, click mouse (no `BASE/1012`)

## 5) Configurazione `dfSet`

- verificare chiavi PG rilevanti in `dbstart.ini`
- validare eventuali override legacy contro regressioni funzionali
- riferimento: `PGDBE-dfSet-riferimento-rapido.md`

## 6) PGUpsize standalone

- `libreria/src/PG/Upsize/pgUpsizeExe.xpj` punta a `libreria/output/lib200-2598/rel/pgupsize.exe`
- `libreria/src/PG/Upsize/build-pgupsize-exe.bat` compila senza errori con ambiente Xbase++ 2.00.2598
- `pgupsize.exe` risponde agli override env:
  - `VDB_UPSIZE_CFG` / `VDB_UPSIZE_CONFIG`
  - `VDB_PG_UPSIZE_FORCE` / `VDB_UPSIZE_FORZA`
  - `VDB_PG_UPSIZE_DRY_RUN` / `VDB_UPSIZE_SIMULA`
  - `VDB_PG_UPSIZE_NOHOLD` / `VDB_UPSIZE_NON_ATTENDERE`
- `PgUpsize.ini` e `dbstart.ini` risolvono correttamente connessione e licenza PGDBE
- `pgdbe_license.txt` o `VDB_PG_LICENSE_FILE` funzionano come alternativa esterna alla licenza in INI
- dry-run genera `UPSIZE.runtime.upsize` e `UPSIZE.runtime.upsize.pgtrace.log`
- il runtime file generato contiene connessione, tabelle, path DBF e ordini attesi prima di lanciare una migrazione reale
- con progetto senza `SOURCE`, la generazione runtime legge `EXE\path.ini` tramite `VDB_PG_PATH_INI`

## 7) Generazione runtime XML

- default `DBDD`: `UPSIZE.runtime.upsize` legge tabelle `RecTyp=DBF` e ordini `NDX` dal dizionario, risolvendo i DBF fisici da `File_Path`/`path.ini`/`EXE`
- `PgUpsizeTableSource=EXE` o `VDB_PG_UPSIZE_TABLE_SOURCE=EXE` abilitano solo lo scan fisico legacy/diagnostico
- `PgUpsizeExtraDbfDir` o `VDB_PG_UPSIZE_EXTRA_DBF_DIR` includono DBF aggiuntivi
- `PgUpsizeExcludeTables` salta solo le tabelle dichiarate
- `PgUpsizeExcludeOrders` salta solo i CDX dichiarati, inclusi stem o wildcard
- in caso di errore `OrdListAdd`, il retry esclude temporaneamente solo il bag rilevato dal trace
- dopo l'esclusione transitoria, `UPSIZE.runtime.upsize` viene rigenerato prima del nuovo tentativo `DbfUpsize`
- errori di apertura esclusiva tabella non producono migrazione parziale silenziosa
- nomi tabella target sono validi per PostgreSQL e univoci nel runtime XML

## 8) Distribuzione artefatti verso host

- [ ] presenti in repo: `scripts/copy-to-host.bat`, `scripts/copy-build-artifacts.bat`, `scripts/rebuild-vdbsee1o-2598.bat`, `scripts/host-paths.bat.example`
- [ ] `scripts/host-paths.bat` creato da `.example` con `VDB_HOST_EXE` e `VDB_HOST_LIB` corretti (file gitignored), **oppure** stesse variabili in ambiente
- [ ] `scripts/copy-to-host.bat` completa senza errore STALE (`VDBSEE1O.DLL` ≥ data `VDBSEE1S.DLL` in output build)
- [ ] progetto host: `EXE` con `VDBSEE1O.DLL` + `VDBSEE1S.DLL`; `lib` con import da `omf\` se cartelle separate

## 9) Sanity finale

- build libreria completata senza errori (`build200-2598.bat` o `gotutto200-2598.bat`)
- se copia fallisce per STALE: `scripts/rebuild-vdbsee1o-2598.bat` poi `scripts/copy-to-host.bat`
- build `pgupsize.exe` e/o `pgupsize-console.exe` completata quando il runner standalone e' richiesto
- test smoke su seek, report, browse
- test smoke su dry-run PGUpsize con log console (`VDB_PG_UPSIZE_STDOUT=1`)
- documentazione `libreria/docs` aggiornata e coerente con lo stato codice
