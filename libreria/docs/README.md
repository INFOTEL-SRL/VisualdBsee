# Documentazione Libreria Visual dBsee

Documentazione tecnica degli interventi PostgreSQL/PGDBE in `libreria/src`.

## Aree PG

- `libreria/src/PG/Runtime/` — sessione PostgreSQL, INI, bootstrap DBE
- `libreria/src/PG/Upsize/` — migrazione DBF→PG, `UPSIZE.runtime.upsize`, `pgupsize.exe`, `pgupsize-console.exe`

## Documenti

| Documento | Contenuto |
|-----------|-----------|
| [PGDBE-interventi-libreria.md](./PGDBE-interventi-libreria.md) | Cronologia per commit; §14 script `scripts/` |
| [PGDBE-browse-ricerca-ordine-indice.md](./PGDBE-browse-ricerca-ordine-indice.md) | Browse ricerca PG, ordine indice, build §7 |
| [PGDBE-dfSet-riferimento-rapido.md](./PGDBE-dfSet-riferimento-rapido.md) | Chiavi `dfSet` e flag runtime |
| [PGDBE-checklist-riapplicazione.md](./PGDBE-checklist-riapplicazione.md) | Checklist verifica / porting |
| [../src/PG/Upsize/README-upsize-cli.md](../src/PG/Upsize/README-upsize-cli.md) | CLI upsize: env, INI, log |
| [../../README.md](../../README.md) | Build 2598, copia artefatti, IDE |

## Ordine di lettura

1. `PGDBE-interventi-libreria.md`
2. `PGDBE-browse-ricerca-ordine-indice.md` (browse ricerca / ordine indice)
3. `PGDBE-dfSet-riferimento-rapido.md`
4. `PGDBE-checklist-riapplicazione.md`
5. `README-upsize-cli.md`
6. `README.md` (root repo)

## Script build e copia (`scripts/`)

Path del **progetto host** solo in `host-paths.bat` (locale, gitignored) o in variabili d’ambiente — mai nel repo.

| Script | Quando usarlo |
|--------|----------------|
| `build200-2598.bat` | Build completa libreria + copia in `ide/Lib200-2598` |
| `libreria/src/gotutto200-2598.bat` | Build da cartella `src` (STATIC/DYNAMIC) |
| `rebuild-vdbsee1o-2598.bat` | Solo `VDBSEE1O.DLL` stale rispetto a `VDBSEE1S` |
| **`copy-to-host.bat`** | **Copia rapida** dopo build (richiede `host-paths.bat`) |
| `copy-build-artifacts.bat` | Copia con path espliciti sulla riga di comando |
| `host-paths.bat.example` | Template → copiare in `host-paths.bat` |

**Setup copia rapida (una tantum):**

```bat
copy scripts\host-paths.bat.example scripts\host-paths.bat
REM Impostare VDB_HOST_EXE e VDB_HOST_LIB
```

**Dopo ogni build:** `scripts\copy-to-host.bat`

Alternativa senza file locale: variabili `VDB_HOST_EXE` e `VDB_HOST_LIB` (opz. `VDB_BUILD_VARIANT`) poi `copy-to-host.bat`.

`copy-build-artifacts.bat` rifiuta la copia se `VDBSEE1O.DLL` in output è più vecchia di `VDBSEE1S.DLL`.

Dettaglio errori build browse: [PGDBE-browse-ricerca-ordine-indice.md](./PGDBE-browse-ricerca-ordine-indice.md) §7.  
Dettaglio completo script: [PGDBE-interventi-libreria.md](./PGDBE-interventi-libreria.md) §14.

## Perimetro

| In perimetro | Fuori perimetro |
|--------------|-----------------|
| `libreria/src`, output `lib200-2598/rel/` | Logica `.prg` dei progetti host |
| Script repo in `scripts/` | Path macchina in git (`host-paths.bat` è locale) |
| Template IDE `ide/tmp/xbase/*.TMP` | Config PostgreSQL/licenze macchina |

Commit di riferimento browse PG: `fcb8937` (branch `pg`).
