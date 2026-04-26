# Documentazione libreria Visual dBsee

## Adattamenti PostgreSQL (PGDBE)

Questa cartella documenta gli interventi PostgreSQL applicati alla libreria `libreria\src\` nel branch `pg`.

La documentazione e' organizzata per rispecchiare i 5 commit applicati nel fork:

| Commit | Titolo | Documento principale |
|---|---|---|
| `3a0e5ef` | Add PostgreSQL runtime infrastructure | `PGDBE-interventi-libreria.md` |
| `ce3cfc2` | Fix PostgreSQL seek and lookup flow | `PGDBE-interventi-libreria.md` |
| `0fe8fe6` | Fix PostgreSQL report and query handling | `PGDBE-interventi-libreria.md`, `PGDBE-dfSet-riferimento-rapido.md` |
| `cda7aec` | Adjust PostgreSQL browse and list navigation | `PGDBE-interventi-libreria.md`, `PGDBE-dfSet-riferimento-rapido.md` |
| `4e37315` | Add PGDBE documentation | tutti i file di questa cartella |

## File disponibili

| Documento | Scopo |
|---|---|
| [PGDBE-interventi-libreria.md](./PGDBE-interventi-libreria.md) | Vista completa e ordinata per commit: obiettivi, file toccati, comportamento introdotto e note operative. |
| [PGDBE-dfSet-riferimento-rapido.md](./PGDBE-dfSet-riferimento-rapido.md) | Riferimento rapido delle chiavi `dfSet` che modulano il comportamento PG. |
| [PGDBE-checklist-riapplicazione.md](./PGDBE-checklist-riapplicazione.md) | Checklist per riapplicare o verificare gli interventi su un fork pulito, seguendo l'ordine dei commit. |

## Ordine di lettura consigliato

1. `PGDBE-interventi-libreria.md`
2. `PGDBE-dfSet-riferimento-rapido.md`
3. `PGDBE-checklist-riapplicazione.md`

## Ambito

- Questa documentazione copre il codice libreria in `libreria\src\`.
- Non descrive in dettaglio le personalizzazioni applicative esterne alla libreria.
- I riferimenti ai commit usano gli hash presenti nel fork `C:\src\VisualdBsee`.

## Nota build

Il fork supporta anche varianti di build separate per diverse versioni di Xbase++.

In particolare, oltre ai percorsi storici `lib190` e `lib200-832`, e' stato introdotto il percorso `libreria/output/lib200-2598/` con gli script:

- `build200-2598.bat`
- `libreria/src/gotutto200-2598.bat`

Questa separazione serve a evitare che una build locale con toolchain diversa sovrascriva gli artefatti storici gia presenti nel repository.

## Nota template IDE

Il supporto PostgreSQL nel fork non dipende solo dai file in `libreria/src/`.

Una parte dell'integrazione vive anche nei template IDE sotto `ide/tmp/xbase/`, in particolare:

- `INITPROC.TMP`
- `RMAKEX1.TMP`
- `RMAKEX2.TMP`
- `rmakex3.tmp`

Questi template influenzano l'inizializzazione del main e la generazione dei file di build del progetto host. Per questo sono stati riallineati alla variante funzionante di riferimento.

## Nota distribuzione artefatti

Per copiare DLL e LIB verso un progetto host non si usa piu uno script locale specifico di un singolo progetto.

Il fork usa invece lo script generico:

- `scripts/copy-build-artifacts.bat`

Lo script richiede la variante di build e una cartella destinazione esplicita, cosi resta riutilizzabile anche fuori da ambienti locali specifici.
