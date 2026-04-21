# Documentazione libreria Visual dBsee

## Adattamenti PostgreSQL (PGDBE)

| Documento | Contenuto |
|-----------|-----------|
| [PGDBE-interventi-libreria.md](./PGDBE-interventi-libreria.md) | Indice, riepilogo, dettaglio per file (§2.6.x `DFSKIP`/`dfTop`/`dfSkip`, browse 1:n, `TBSKIP.PRG`), DIPE, cache, **§6 diagnostica** (sintomi, mermaid, prestazioni) |
| [PGDBE-dfSet-riferimento-rapido.md](./PGDBE-dfSet-riferimento-rapido.md) | Tabella + **sezione per chiave** (default PG, `YES`/`NO`, rischi, interazioni), esempi `dbstart.ini` |
| [PGDBE-checklist-riapplicazione.md](./PGDBE-checklist-riapplicazione.md) | Checklist 0→13; **§6** esteso su `DFSKIP` (LOCAL, LastRec, cammino break, fallback scan, DBGOTO, test) |

Ordine di lettura consigliato: **interventi** (perché) → **dfSet** (cosa impostare) → **checklist** (come portare il codice).

Sorgenti di riferimento: `libreria\src\` (branch base, xpp, s2).
