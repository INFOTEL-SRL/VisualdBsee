# PGDBE - Riferimento rapido `dfSet`

Questo documento riassume le chiavi `dfSet` che influenzano i comportamenti PostgreSQL introdotti nel fork.

## Chiavi principali

- `XbasePgReportTopUseKeyWithQry`  
  Area report (`DFSTA.PRG`): evita/ripristina `dfTop(VR_KEY,...)` quando c'e una query.
- `XbasePgReportKeepQueryKeyOpt`  
  Area report/query (`dfupdqry.prg`): mantiene o disattiva ottimizzazioni KEY/BREAK legacy.
- `XbaseDbLookEofOnEmptyFreeSeek`  
  Area lookup (`DBLOOK.PRG`): gestisce EOF su seek libero vuoto.
- `XbaseBrowseFooterTotalsOnPG`  
  Area browse (`S2BRW.prg`): abilita/disabilita scansione completa footer totals.
- `XbasePgDfTopDeferDbgoto0OnBreak`  
  Area navigazione (`DFSKIP.PRG`): modula il `DBGOTO(0)` nei rami break/filtro.
- `XbasePgDfSkipWalkPastBreak`  
  Area navigazione (`DFSKIP.PRG`): abilita/disabilita cammino PG oltre break.

## Default consigliato nel fork PG

I default introdotti dai commit PG privilegiano:

- stabilita di seek/lookup su PG
- prevenzione di EOF anomali su report/query
- navigazione browse/listbox piu robusta in scenari 1:n
- riduzione costi non necessari nei footer totals

Eventuali override vanno applicati solo se richiesti da compatibilita legacy specifiche.

## Esempio configurazione

```ini
dfSet=XbasePgReportTopUseKeyWithQry=YES
dfSet=XbasePgReportKeepQueryKeyOpt=YES
dfSet=XbaseDbLookEofOnEmptyFreeSeek=NO
dfSet=XbaseBrowseFooterTotalsOnPG=YES
dfSet=XbasePgDfTopDeferDbgoto0OnBreak=YES
dfSet=XbasePgDfSkipWalkPastBreak=NO
```

## Quando usarlo

- report PG vuoti/incompleti
- lookup `dbLook` incoerenti rispetto ai dati
- browse/listbox che si fermano presto o saltano righe
- verifica rapida di regressioni dopo merge/cherry-pick
