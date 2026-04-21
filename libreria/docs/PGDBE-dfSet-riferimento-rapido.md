# PGDBE — `dfSet` e comportamenti PG (riferimento rapido)

Valori tipici in **`dbstart.ini`** o dove l’applicazione imposta **`dfSet`**.

**Convenzione generale**

- **`"YES"`** (dove indicato) riattiva un comportamento **legacy / esplicito** rispetto al default ottimizzato per PG.
- **`"NO"`** (dove indicato) **disattiva** un comportamento introdotto per PG (cammino skip, EOF su dbLook, ecc.).
- **Assenza** della chiave o valore diverso da quelli citati per riga: resta il **default documentato** per PG.

La sintassi reale delle righe in `dbstart.ini` dipende dal loader dell’app (delimitatori, sezioni, maiuscole).

---

## 1. Tabella riepilogativa

| Chiave | File / entry point | Default tipico PG | `YES` / `NO` (come da tabella sotto) |
|--------|-------------------|-------------------|--------------------------------------|
| `XbasePgReportTopUseKeyWithQry` | `DFSTA.PRG` → `dfReportTOP` | Con query stampa attiva si usa **`dfTop(NIL, …)`** senza seek su `VR_KEY` | **`YES`** → di nuovo **`dfTop(VR_KEY, …)`** anche con `REP_QRY_BLOCK` |
| `XbasePgReportKeepQueryKeyOpt` | `dfupdqry.prg` → `dfUpdQryRep` | Su PG si azzerano `bNewKey` / `bNewBreak` verso `dfUpdVR` | **`YES`** → non si azzerano (KEY/BREAK da `dfQryOpt` come prima) |
| `XbaseBrowseFooterTotalsOnPG` | `S2BRW.prg` → `tbTotal` | Su PG **non** si esegue lo scan `tbEval` per i totali footer | **`YES`** → scan completo come DBF (più lento) |
| `XbaseDbLookEofOnEmptyFreeSeek` | `DBLOOK.PRG` | Dopo seek libero vuoto si può forzare **`DBGOTO(0)`** | **`NO`** → non forzare EOF |
| `XbasePgDfTopDeferDbgoto0OnBreak` | `DFSKIP.PRG` → `dfTop` | In coda, se break o filtro non passano: **`DBGOTO(0)`** sempre (salvo ramo PG+YES) | **`YES`** → su PG, se `!EOF` e `EVAL(bFilter)` e `EVAL(bBreak)` tutti veri, **non** eseguire `DBGOTO(0)` (legacy stampa) |
| `XbasePgDfSkipWalkPastBreak` | `DFSKIP.PRG` → `dfSkip` (solo `n2Skip > 0`) e `dfTop` (cammino pre-`DBGOTO`) | Cammino **attivo** (attraversa record ancora in `break` dopo un passo) | **`NO`** → **nessun** cammino: comportamento più vicino al solo `dbSkip` ripetuto |

---

## 2. Dettaglio per chiave

### 2.1 `XbasePgReportTopUseKeyWithQry` = `YES`

- **Contesto:** `dfReportTOP` con master PG e **`dfPrnArr()[REP_QRY_BLOCK] != NIL`**.
- **Senza YES:** viene chiamato **`dfTop(NIL, VR_FILTER, VR_BREAK)`** per evitare un `DBSEEK` sulla KEY che su PG può portare in EOF pur esistendo righe che soddisfano la query.
- **Con YES:** si torna a **`dfTop(aVR[VR_KEY], …)`** come con DBFCDX.
- **Rischio con YES:** report di nuovo sensibili al seek su KEY sotto PG (possibile “nulla da stampare” o righe mancanti se la KEY non è allineata al motore PG).

### 2.2 `XbasePgReportKeepQueryKeyOpt` = `YES`

- **Contesto:** `dfUpdQryRep` quando costruisce i block KEY/BREAK per il layout di stampa.
- **Senza YES (default PG):** `bNewKey := NIL`, `bNewBreak := {|| .F. }` sul master PG per non combinare KEY da query con seek PG in modo incoerente.
- **Con YES:** non si azzerano; resta l’ottimizzazione originale.
- **Rischio:** KEY/BREAK da `dfQryOpt` possono lasciare il master in stato non stampabile su PG se non gestiti altrove.

### 2.3 `XbaseBrowseFooterTotalsOnPG` = `YES`

- **Contesto:** `S2XbpBrowser:tbTotal` durante `tbReset` del browse/listbox.
- **Senza YES:** su PG si salta solo l’`EVAL(::bEval, …)` che scansiona tutta la tabella per i totali footer; restano `dfColZero` e `tbColPut` così `tbReset` non rompe colonne calcolate.
- **Con YES:** scan completo (tempi su tabelle grandi).

### 2.4 `XbaseDbLookEofOnEmptyFreeSeek` = `NO`

- **Contesto:** dbLook, seek “libero” con valore vuoto, dopo ripristino ordine.
- **Default:** se diverso da `NO`, dopo seek vuoto si può chiamare **`DBGOTO(0)`** per non lasciare un record “fantasma”.
- **Con NO:** non si forza EOF.

### 2.5 `XbasePgDfTopDeferDbgoto0OnBreak` = `YES`

- **Contesto:** **solo** ramo finale di **`dfTop`**: quando `EVAL(bBreak) .OR. !EVAL(bFilter)`.
- **Senza YES (default):** su PG come su altri RDD: **`DBGOTO(0)`** se la condizione è vera (corretto per listbox **1:n** con `W_FILTER {|| .T.}` e break su relazione master-dettaglio).
- **Con YES:** se PG **e** `!EOF` **e** filtro **e** break sono tutti `.T.`, **non** si esegue `DBGOTO(0)` (vecchio guard per **VR_BREAK** “falso positivo” in alcune stampe).
- **Rischio grave con YES sulle liste 1:n:** con filtro sempre vero e break che indica “fuori relazione”, sopprimere `DBGOTO(0)` lascia il cursore sul record sbagliato → righe di altri master in griglia.
- **Uso consigliato:** solo se un report specifico richiede il ripristino legacy; valutare di non impostarlo globalmente in `dbstart.ini`.

### 2.6 `XbasePgDfSkipWalkPastBreak` = `NO`

- **Contesto A — `dfSkip` con `n2Skip > 0`:** dopo ogni `dbSkip(1)` interno, se **non** EOF ma `EVAL(bBreak)` è vero, invece di subito `dbGoto(nActRec)` + `RETURN 0`, su PG (se non `NO`) si eseguono ulteriori **`DbSkip(1)`** finché `break` diventa falso o EOF (max **100000** passi).
- **Contesto B — `dfTop`:** dopo il blocco seek principale e **prima** del `DBGOTO(0)` finale, se `bKey != NIL`, PG, non EOF, filtro e break veri, stesso opt-out: cammino analogo per riallineare dopo **cambio master** quando il cursore resta sulla riga del dipendente precedente.
- **Con `NO`:** nessun cammino; un solo `dbSkip(1)` che cade in `break` torna subito indietro (`dfSkip` → 0), come logica originale stretta.
- **Rischio con default (cammino attivo):** su tabelle enormi, in casi limite (es. molti record “fuori break” consecutivi), più passi per ogni riga logica; impostare `NO` solo dove serve misurare o evitare scan.
- **Interazione:** indipendente da `XbasePgDfTopDeferDbgoto0OnBreak` (uno agisce sul cammino, l’altro solo sulla decisione di `DBGOTO(0)` in coda a `dfTop`).

---

## 3. Esempi `dbstart.ini` (righe concettuali)

```ini
; Stampe: seek con KEY anche sotto query PG
dfSet=XbasePgReportTopUseKeyWithQry=YES

; Stampe: mantieni KEY/BREAK da dfQryOpt sul master PG
dfSet=XbasePgReportKeepQueryKeyOpt=YES

; Browse: totali footer con scan completo su PG (lento)
dfSet=XbaseBrowseFooterTotalsOnPG=YES

; dbLook: non forzare EOF su seek libero vuoto
dfSet=XbaseDbLookEofOnEmptyFreeSeek=NO

; dfTop: legacy — evita DBGOTO(0) quando filtro e break sono entrambi .T. su PG
; Usare solo se necessario per un report; può rompere liste 1:n
dfSet=XbasePgDfTopDeferDbgoto0OnBreak=YES

; dfSkip/dfTop: disattiva cammino oltre record ancora in break (PG)
dfSet=XbasePgDfSkipWalkPastBreak=NO
```

---

## 4. Collegamenti

- **`PGDBE-interventi-libreria.md`** — logica tecnica, flussi `dfTop`/`dfSkip`, browse, limiti ordine composto.
- **`PGDBE-checklist-riapplicazione.md`** — elenco puntuale da riapplicare su fork.
