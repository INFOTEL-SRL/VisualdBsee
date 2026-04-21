# Checklist PGDBE - riapplicazione e verifica

Questa checklist serve a riapplicare o verificare gli interventi PostgreSQL nel giusto ordine, seguendo i commit del fork.

## Uso consigliato

- Seguire i blocchi nell'ordine indicato.
- Considerare ogni blocco come una milestone tecnica autonoma.
- Ricompilare la libreria almeno alla fine di ogni blocco principale.

## 1. Commit `3a0e5ef` - runtime PostgreSQL

### Verifiche

- Esistono i file:
  - `src/PG/pgDacSession.prg`
  - `src/PG/pgUpsize.prg`
  - `src/PG/pgUpsizeConn.prg`
  - `src/PG/pgUpsizeXml.prg`
  - `src/PG/pgVdbIni.prg`
- Il progetto di build include i moduli PG in `static.base`, `dynamic.base` o file equivalenti.
- `src/base/PGSEEK.PRG` e' presente e compilato.
- `src/base/DDUSE.PRG` contiene il passaggio condizionale alla sessione PG runtime.
- `src/base/DBCFGOPE.PRG` forza `DBFCDX` per i file dizionario quando il default driver e' PG.

### Controlli funzionali

- A runtime, senza attivazione PG, il codice non deve interrogare inutilmente la DacSession.
- Con PG attivo, i moduli runtime devono risultare raggiungibili e linkati.

## 2. Commit `ce3cfc2` - seek e lookup

### Verifiche su `DFS.PRG`

- `dfS()` contiene un ramo PG separato dal flusso storico.
- Vengono usati:
  - `dfPgRddIs()`
  - `dfPgOrdKeySingleField()`
  - verifica record post-seek
  - cache seek per alias/ordine/valore
- Il fallback sul campo `codice` non viene usato indiscriminatamente.
- Il nome campo in cache viene azzerato quando non deducibile.

### Verifiche su `DBLOOK.PRG`

- Il seek PG usa verifica e fallback dedicati.
- Il record corrente viene preservato quando si cambia ordine.
- Il seek libero vuoto e' gestito in modo esplicito.

### Controlli funzionali

- Un lookup ripetuto sullo stesso valore deve tornare sul record corretto.
- Un ordine con `ORDKEY()` semplice deve permettere il riallineamento record dopo `DBSEEK`.

## 3. Commit `0fe8fe6` - report, query e Crystal output

### Verifiche su query e report

- `dfPrnConfig()` svuota la cache seek PG prima del nuovo contesto stampa.
- `dfAny2Str()` restituisce stringa vuota per input `NIL`.
- `dfQryFlt()` gestisce meglio:
  - date
  - stringhe
  - `NULL`
  - normalizzazione spazi
- `dfReportTOP()` non forza sempre `VR_KEY` quando e' attiva una query PG.
- `dfUpdQryRep()` puo neutralizzare KEY/BREAK legacy su master PG.
- `DFCRWOUT.prg` sostituisce i `NIL` con valori vuoti tipizzati.

### Controlli funzionali

- Un report con query PG non deve andare in EOF senza motivo.
- I campi `NULL` non devono produrre errori nei record temporanei o nei confronti filtro.
- Le date vuote o incomplete non devono far fallire il filtro in modo errato.

## 4. Commit `cda7aec` - browse e listbox

### Verifiche su `DFSKIP.PRG`

- `dfSkip()` non blocca la navigazione solo per `LastRec()==0` quando l'RDD e' PG.
- Esiste il cammino PG che prova a superare i record ancora in `break`.
- `dfTop()` usa verify/fallback PG e puo recuperare da EOF apparente.
- Il comportamento finale su `DBGOTO(0)` e' coerente con il default PG documentato.

### Verifiche su `S2BROWSE.prg` e `S2BRW.prg`

- `tbReset()` richiama ancora il reset del browser.
- `tbTotal()` puo saltare la scansione totale su PG.
- `dfTotalInc()` non rivaluta inutilmente i blocchi totale.

### Controlli funzionali

- Una listbox 1:n deve continuare a mostrare tutte le righe corrette dopo cambio master.
- Un browse non deve fermarsi alla prima riga valida se ne esistono altre nello stesso gruppo.
- L'apertura di browse con footer totals non deve degradare inutilmente.

## 5. Commit `4e37315` - documentazione

### Verifiche

- Esistono i file:
  - `docs/README.md`
  - `docs/PGDBE-interventi-libreria.md`
  - `docs/PGDBE-dfSet-riferimento-rapido.md`
  - `docs/PGDBE-checklist-riapplicazione.md`
- La documentazione riflette i commit realmente presenti nel fork.
- La documentazione separa chiaramente:
  - quadro generale per commit
  - chiavi `dfSet`
  - checklist di porting/verifica

## 6. Sanity check finale

- `git log --oneline` mostra i 5 commit PG nel fork.
- La working tree e' pulita dopo l'eventuale riordino documentale.
- Le chiavi `dfSet` usate dall'applicazione sono coerenti con il comportamento desiderato su PG.

## 7. Ordine minimo di collaudo

1. Verifica runtime e link dei moduli PG.
2. Verifica seek e lookup su una tabella PG con ordine reale.
3. Verifica report/query con dati che contengono `NULL` e date vuote.
4. Verifica browse/listbox 1:n con cambio master ripetuto.
5. Verifica eventuali override `dfSet` in `dbstart.ini`.
