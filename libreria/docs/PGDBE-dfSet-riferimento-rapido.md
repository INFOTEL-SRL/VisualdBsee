# PGDBE - riferimento rapido `dfSet`

Questo file raccoglie le chiavi `dfSet` collegate agli adattamenti PG introdotti nei commit del fork.

## Mappa commit -> chiavi

| Commit | Area | Chiavi principali |
|---|---|---|
| `0fe8fe6` | report e query | `XbasePgReportTopUseKeyWithQry`, `XbasePgReportKeepQueryKeyOpt` |
| `ce3cfc2` | lookup | `XbaseDbLookEofOnEmptyFreeSeek` |
| `cda7aec` | browse e navigazione | `XbaseBrowseFooterTotalsOnPG`, `XbasePgDfTopDeferDbgoto0OnBreak`, `XbasePgDfSkipWalkPastBreak` |

## Tabella sintetica

| Chiave | Punto di intervento | Default PG | Valore alternativo |
|---|---|---|---|
| `XbasePgReportTopUseKeyWithQry` | `DFSTA.PRG` -> `dfReportTOP` | con query attiva evita `dfTop(VR_KEY,...)` | `YES` ripristina il comportamento legacy |
| `XbasePgReportKeepQueryKeyOpt` | `dfupdqry.prg` -> `dfUpdQryRep` | disattiva KEY/BREAK ottimizzati per DBF sul master PG | `YES` li mantiene |
| `XbaseDbLookEofOnEmptyFreeSeek` | `DBLOOK.PRG` | seek libero vuoto puo forzare `DBGOTO(0)` | `NO` evita l'EOF forzato |
| `XbaseBrowseFooterTotalsOnPG` | `S2BRW.prg` -> `tbTotal` | salta la scansione completa footer totals | `YES` esegue la scansione completa |
| `XbasePgDfTopDeferDbgoto0OnBreak` | `DFSKIP.PRG` -> `dfTop` | su break/filtro chiude con `DBGOTO(0)` | `YES` mantiene il record in alcuni casi legacy |
| `XbasePgDfSkipWalkPastBreak` | `DFSKIP.PRG` -> `dfSkip`, `dfTop` | prova a camminare oltre record ancora in break | `NO` disattiva il cammino PG |

## Dettaglio operativo

### `XbasePgReportTopUseKeyWithQry=YES`

- Commit di riferimento: `0fe8fe6`
- Area: report
- Uso: ripristina il vecchio uso di `VR_KEY` anche quando e' attiva una query di stampa.
- Rischio: su PG il seek sulla key puo portare in EOF pur avendo righe stampabili.

### `XbasePgReportKeepQueryKeyOpt=YES`

- Commit di riferimento: `0fe8fe6`
- Area: report/query
- Uso: mantiene le ottimizzazioni KEY/BREAK generate per il flusso DBF.
- Rischio: su PG il master puo restare in uno stato non stampabile.

### `XbaseDbLookEofOnEmptyFreeSeek=NO`

- Commit di riferimento: `ce3cfc2`
- Area: lookup
- Uso: evita il `DBGOTO(0)` dopo seek libero vuoto.
- Rischio: si puo lasciare il cursore su un record visivamente non coerente con la ricerca vuota.

### `XbaseBrowseFooterTotalsOnPG=YES`

- Commit di riferimento: `cda7aec`
- Area: browse/footer totals
- Uso: forza il calcolo completo dei totali footer su PG.
- Rischio: apertura browse piu lenta su tabelle grandi.

### `XbasePgDfTopDeferDbgoto0OnBreak=YES`

- Commit di riferimento: `cda7aec`
- Area: browse/listbox 1:n
- Uso: evita `DBGOTO(0)` nel ramo finale di `dfTop` in alcuni casi legacy.
- Rischio: puo lasciare righe del master precedente in una listbox dettaglio.

### `XbasePgDfSkipWalkPastBreak=NO`

- Commit di riferimento: `cda7aec`
- Area: navigazione
- Uso: disattiva il cammino PG che prova a superare record temporaneamente fuori break.
- Rischio: browse o listbox possono fermarsi troppo presto, mostrando una sola riga o righe incomplete.

## Esempi concettuali

```ini
dfSet=XbasePgReportTopUseKeyWithQry=YES
dfSet=XbasePgReportKeepQueryKeyOpt=YES
dfSet=XbaseDbLookEofOnEmptyFreeSeek=NO
dfSet=XbaseBrowseFooterTotalsOnPG=YES
dfSet=XbasePgDfTopDeferDbgoto0OnBreak=YES
dfSet=XbasePgDfSkipWalkPastBreak=NO
```

## Quando consultare questo file

- Se un report PG torna vuoto o salta record.
- Se `dbLook` si comporta in modo diverso da DBF.
- Se browse o listbox 1:n hanno righe mancanti o navigazione troncata.
- Se vuoi capire quali comportamenti PG sono fissi e quali sono modulabili da configurazione.
