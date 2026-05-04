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
- con progetto senza `SOURCE`, la generazione runtime legge `EXE\path.ini` tramite `VDB_PG_PATH_INI`

## 7) Generazione runtime XML

- `PgUpsizeTableSource=EXE|DBDD` o `VDB_PG_UPSIZE_TABLE_SOURCE` selezionano l'origine tabelle attesa
- `PgUpsizeExtraDbfDir` o `VDB_PG_UPSIZE_EXTRA_DBF_DIR` includono DBF aggiuntivi
- `PgUpsizeExcludeTables` salta solo le tabelle dichiarate
- `PgUpsizeExcludeOrders` salta solo i CDX dichiarati, inclusi stem o wildcard
- in caso di errore `OrdListAdd`, il retry esclude temporaneamente solo il bag rilevato dal trace
- errori di apertura esclusiva tabella non producono migrazione parziale silenziosa
- nomi tabella target sono validi per PostgreSQL e univoci nel runtime XML

## 8) Sanity finale

- build libreria completata senza errori
- build `pgupsize.exe` completata quando il runner standalone e' richiesto
- test smoke su seek, report, browse
- test smoke su dry-run PGUpsize con log console (`VDB_PG_UPSIZE_STDOUT=1`)
- documentazione `libreria/docs` aggiornata e coerente con lo stato codice
