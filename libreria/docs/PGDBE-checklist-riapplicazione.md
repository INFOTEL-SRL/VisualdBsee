# Checklist PGDBE - Riapplicazione/Verifica

Usa questa checklist quando riallinei il fork PG o dopo merge importanti sulla libreria.

## 1) Runtime PG (base)

- presenti i moduli `src/PG/*.prg` principali (`pgDacSession`, `pgUpsize*`, `pgVdbIni`)
- `src/base/PGSEEK.PRG` incluso in build
- file build (`static.base`, `dynamic.base`, `_gotutto.base`) coerenti
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
- test master/dettaglio 1:n: niente righe perse

## 5) Configurazione `dfSet`

- verificare chiavi PG rilevanti in `dbstart.ini`
- validare eventuali override legacy contro regressioni funzionali
- riferimento: `PGDBE-dfSet-riferimento-rapido.md`

## 6) Sanity finale

- build libreria completata senza errori
- test smoke su seek, report, browse
- documentazione `libreria/docs` aggiornata e coerente con lo stato codice
