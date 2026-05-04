# Documentazione Libreria Visual dBsee

Questa cartella raccoglie la documentazione tecnica degli interventi PostgreSQL/PGDBE applicati alla libreria in `libreria/src`.

La struttura PG corrente e' divisa in due aree:

- `libreria/src/PG/Runtime/`: sessione PostgreSQL, lettura INI e bootstrap DBE.
- `libreria/src/PG/Upsize/`: migrazione DBF -> PostgreSQL, generazione `UPSIZE.runtime.upsize`, runner CLI `pgupsize.exe`.

## Contenuto

- [PGDBE-interventi-libreria.md](./PGDBE-interventi-libreria.md)  
  Panoramica per commit: obiettivi, file toccati, effetti runtime.
- [PGDBE-dfSet-riferimento-rapido.md](./PGDBE-dfSet-riferimento-rapido.md)  
  Riferimento sintetico delle chiavi `dfSet` legate al comportamento PG.
- [PGDBE-checklist-riapplicazione.md](./PGDBE-checklist-riapplicazione.md)  
  Checklist operativa per verifica/porting su fork pulito.
- [../src/PG/Upsize/README-upsize-cli.md](../src/PG/Upsize/README-upsize-cli.md)
  Guida cliente/operativa per `pgupsize.exe`, variabili ambiente, INI e log.

## Ordine consigliato

1. `PGDBE-interventi-libreria.md`
2. `PGDBE-dfSet-riferimento-rapido.md`
3. `PGDBE-checklist-riapplicazione.md`
4. `../src/PG/Upsize/README-upsize-cli.md`

## Perimetro

- Ambito principale: codice libreria in `libreria/src`.
- Ambito operativo PGUpsize: `libreria/src/PG/Upsize/` e output `libreria/output/lib200-2598/rel/pgupsize.exe`.
- Fuori perimetro: dettagli applicativi locali e configurazioni macchina.
- I riferimenti commit usano gli hash presenti nel repository corrente.

## Note rapide

- Per build Xbase++ 2.00.2598 usare output dedicato `libreria/output/lib200-2598/`.
- Script principali di build/copia artefatti:
  - `build200-2598.bat`
  - `libreria/src/PG/Upsize/build-pgupsize-exe.bat`
  - `libreria/src/gotutto200-2598.bat`
  - `scripts/copy-build-artifacts.bat`
- Il runner standalone `pgupsize.exe` e' documentato vicino ai sorgenti per tenerlo allineato alle variabili e agli INI supportati.
