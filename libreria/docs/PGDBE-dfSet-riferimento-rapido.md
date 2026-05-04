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

## Chiavi INI correlate a PGUpsize

Queste non sono chiavi `dfSet`, ma sono rilevanti per il runner DBF -> PostgreSQL e per il runtime PG.

Sezione `[apps]` in `dbstart.ini`:

- `XbaseRunPgUpsizeOnUpd=YES|NO`
  Abilita o disabilita l'esecuzione della migrazione quando viene invocato il flusso applicativo `/UPD`.
- `XbasePgServer`, `XbasePgDatabase`, `XbasePgUid`, `XbasePgPwd`
  Parametri connessione PostgreSQL letti dal runtime quando non sono presenti override via environment.
- `XbasePgLicenseKey`, `XbasePgLicensee`
  Dati licenza PGDBE, alternativi a `PgUpsize.ini`, sidecar o environment.

Sezione `[UPSIZE]` in `PgUpsize.ini`:

- `ServerName`, `Database`, `UserID`, `Password`
  Connessione usata da `DbfUpsize`.
- `PgDbeLicenseKey`, `PgDbeLicensee`
  Licenza PGDBE esterna al binario.
- `PgActivateDbeSys=YES|NO`
  Attiva il runtime PG in `dbeSys`.
- `PgUpsizeTableSource=EXE|DBDD`
  Origine elenco tabelle per il runtime XML.
- `PgUpsizeExtraDbfDir=<cartella>`
  Cartella DBF aggiuntiva da includere nella migrazione.
- `PgUpsizeExcludeTables=nome1,nome2`
  Tabelle da escludere in modo esplicito.
- `PgUpsizeExcludeOrders=file1.cdx,file2.cdx`
  Indici CDX da escludere; accetta path, nome file, stem e wildcard `*`.
- `PgUpsizeDisableOrders=YES`
  Disattiva la generazione degli ordini nel runtime XML; usare solo per diagnosi o migrazioni controllate.

Variabili ambiente equivalenti o prioritarie:

- `VDB_PG_SERVER`, `VDB_PG_DATABASE`, `VDB_PG_UID`, `VDB_PG_PWD`
- `VDB_PG_LICENSE_KEY`, `VDB_PG_LICENSEE`, `VDB_PG_LICENSE_FILE`
- `VDB_UPSIZE_CFG` / `VDB_UPSIZE_CONFIG`
- `VDB_PG_UPSIZE_FORCE` / `VDB_UPSIZE_FORZA`
- `VDB_PG_UPSIZE_DRY_RUN` / `VDB_UPSIZE_SIMULA`
- `VDB_PG_UPSIZE_TABLE_SOURCE`
- `VDB_PG_UPSIZE_EXTRA_DBF_DIR`
- `VDB_PGUPSIZE_INI`, `VDB_DBSTART_INI`, `VDB_PG_PATH_INI`
