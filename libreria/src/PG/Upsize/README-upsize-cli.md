# PGUpsize CLI (uso cliente)

Questo documento descrive come usare `pgupsize.exe` per la migrazione DBF -> PostgreSQL in ambiente cliente.

## Obiettivo

- Eseguire la migrazione con tool standalone.
- Non incorporare nel binario `pgupsize.exe` la licenza PGDBE (chiave e intestatario).

## Dove si trova l'eseguibile

Output build:

- `libreria/output/lib200-2598/rel/pgupsize.exe`

In ambiente cliente puoi distribuirlo nella cartella `EXE` dell'applicazione.

## Prerequisiti

- `pgupsize.exe`
- `pgdbe.dll` raggiungibile (tipicamente nella stessa cartella `EXE` o nel `PATH`)
- configurazione PostgreSQL (`PgUpsize.ini` e/o `dbstart.ini`, vedi sotto)
- file DBF da migrare presenti in `EXE`, elencati in `path.ini` oppure disponibili in una cartella extra configurata

## Licenza PGDBE: esterna (non nel codice)

`pgupsize.exe` non deve contenere hardcoded licenza/nome licenza.
Passa i dati licenza dall'esterno con una delle seguenti opzioni (in ordine pratico consigliato).

### Opzione A (consigliata): file sidecar

File: `pgdbe_license.txt` (accanto a `dbstart.ini`) oppure path esplicito via `VDB_PG_LICENSE_FILE`.

Formato file (2 righe):

1. `license key`
2. `licensee`

Esempio:

```text
ABCD-1234-....
Ragione Sociale Cliente
```

### Opzione B: variabili ambiente

- `VDB_PG_LICENSE_KEY`
- `VDB_PG_LICENSEE`

### Opzione C: ini (sezione UPSIZE)

In `PgUpsize.ini` oppure `dbstart.ini`:

- `[UPSIZE] PgDbeLicenseKey=...`
- `[UPSIZE] PgDbeLicensee=...`

## Connessione PostgreSQL

Puoi configurarla in 3 modi. L'ordine di priorita' e':

1. **Variabili ambiente** (precedenza massima)
2. Se mancanti, chiavi in sezione **`[apps]`**
3. Se ancora mancanti, chiavi in sezione **`[UPSIZE]`**

### A) Variabili ambiente (consigliato per test/script)

- `VDB_PG_SERVER` -> host PostgreSQL (es. `localhost`)
- `VDB_PG_DATABASE` -> nome database (es. `presenze`)
- `VDB_PG_UID` -> utente (es. `postgres`)
- `VDB_PG_PWD` -> password

### B) `dbstart.ini` / `PgUpsize.ini` sezione `[apps]`

- `XbasePgServer`
- `XbasePgDatabase`
- `XbasePgUid`
- `XbasePgPwd`

### C) `dbstart.ini` / `PgUpsize.ini` sezione `[UPSIZE]`

- `ServerName`
- `Database`
- `UserID`
- `Password`

Esempio consigliato lato cliente (`EXE\pgupsize.ini`):

```ini
[UPSIZE]
ServerName=localhost
Database=presenze
UserID=postgres
Password=la_tua_password
PgDbeLicenseKey=...
PgDbeLicensee=...
```

### Esempio pratico di priorita'

Se imposti:

- `VDB_PG_SERVER=db-server-01` (env)
- `XbasePgServer=localhost` in `[apps]`
- `ServerName=127.0.0.1` in `[UPSIZE]`

il tool usera' **`db-server-01`** (valore env), perche' ha precedenza sugli ini.

## Configurazione file `.upsize`

Il tool accetta il template con:

- `VDB_UPSIZE_CFG=<path .upsize>`
- alias italiano: `VDB_UPSIZE_CONFIG=<path .upsize>`

Se non valorizzato, prova a risolvere automaticamente i path standard (`UPSIZE.upsize`, `SOURCE\pg\UPSIZE.upsize`, ecc.) e genera `UPSIZE.runtime.upsize`.

Se non esiste un template, il tool puo lavorare in modalita no-template: genera un XML runtime minimale partendo da `PgUpsize.ini`/`dbstart.ini` per la connessione e da `path.ini` o dalla cartella `EXE` per l'elenco DBF.

## Parametri per sezioni

### 1) Parametri essenziali (quelli che usi davvero)

| Nome semplice (consigliato) | Nome tecnico equivalente | A cosa serve |
| --- | --- | --- |
| `VDB_UPSIZE_FORZA=1` | `VDB_PG_UPSIZE_FORCE=1` | Forza esecuzione migrazione |
| `VDB_UPSIZE_LOG_CONSOLE=1` | `VDB_PG_UPSIZE_STDOUT=1` | Mostra log in console |
| `VDB_UPSIZE_CONFIG=<path>` | `VDB_UPSIZE_CFG=<path>` | Template `.upsize` esplicito (opzionale) |
| `VDB_UPSIZE_NON_ATTENDERE=1` | `VDB_PG_UPSIZE_NOHOLD=1` | Non aspettare INVIO a fine run |
| `VDB_UPSIZE_SIMULA=1` | `VDB_PG_UPSIZE_DRY_RUN=1` | Genera solo `UPSIZE.runtime.upsize` |

### 2) Connessione PostgreSQL

| Variabile | Significato | Fallback |
| --- | --- | --- |
| `VDB_PG_SERVER` | Host PostgreSQL | `[apps]` / `[UPSIZE]` |
| `VDB_PG_DATABASE` | Database PostgreSQL | `[apps]` / `[UPSIZE]` |
| `VDB_PG_UID` | Utente PostgreSQL | `[apps]` / `[UPSIZE]` |
| `VDB_PG_PWD` | Password PostgreSQL | `[apps]` / `[UPSIZE]` |

### 3) Licenza PGDBE

| Variabile | Significato | Note |
| --- | --- | --- |
| `VDB_PG_LICENSE_KEY` | Chiave licenza | Prioritaria rispetto a ini |
| `VDB_PG_LICENSEE` | Nome licenziatario | Deve combaciare con registrazione |
| `VDB_PG_LICENSE_FILE` | File `pgdbe_license.txt` | 2 righe: key, licensee |

### 4) File di configurazione (override path)

| Variabile | Significato |
| --- | --- |
| `VDB_PGUPSIZE_INI` | Path esplicito `PgUpsize.ini` |
| `VDB_DBSTART_INI` | Path esplicito `dbstart.ini` |
| `VDB_PG_PATH_INI` | Path esplicito `path.ini` |

### 5) Avanzati / debug

| Variabile | Uso |
| --- | --- |
| `VDB_PG_UPSIZE_TABLE_SOURCE` | Origine tabelle (`EXE` / `DBDD`) |
| `VDB_PG_UPSIZE_EXTRA_DBF_DIR` | Cartella aggiuntiva DBF da includere |
| `VDB_PG_UPSIZE_BYPASS_LICENSE_PRECHECK` | Bypass precheck licenza (solo test) |
| `VDB_SKIP_PG_UPSIZE` | Salta upsize in flusso integrato |
| `VDB_PG_UPSIZE_EXE` | Path custom `pgupsize.exe` per caller esterni |
| `VDB_PG_ACTIVATE_DBESYS` | Attivazione runtime PG in `dbeSys` |

### 6) Chiavi `[UPSIZE]` avanzate in `PgUpsize.ini`

| Chiave | Uso |
| --- | --- |
| `PgUpsizeTableSource=EXE|DBDD` | Sceglie se leggere le tabelle dai DBF presenti in `EXE`/`path.ini` o dal dizionario `DBDD`. |
| `PgUpsizeExtraDbfDir=<cartella>` | Include una cartella DBF aggiuntiva. |
| `PgUpsizeExcludeTables=nome1,nome2` | Esclude tabelle specifiche dalla migrazione. |
| `PgUpsizeExcludeOrders=file1.cdx,file2.cdx` | Esclude indici specifici; accetta path, nome file, stem e wildcard `*`. |
| `PgUpsizeDisableOrders=YES` | Non genera ordini nel runtime XML; usarlo solo per diagnosi o migrazioni controllate. |
| `PgActivateDbeSys=YES` | Attiva il runtime PG in `dbeSys`. |

## Comandi d'uso (cliente)

Apri `cmd.exe` nella cartella `EXE` del progetto.

Log su console: per `pgupsize.exe` i messaggi vengono stampati direttamente su `stdout`.
Se vuoi forzare il comportamento:

```bat
set VDB_PG_UPSIZE_STDOUT=1
```

La finestra di `pgupsize.exe` resta aperta a fine esecuzione (attende INVIO).
Per uso batch/CI puoi disattivare l'attesa:

```bat
set VDB_PG_UPSIZE_NOHOLD=1
```

Se vuoi passare un template esplicito, usa un path lato `EXE` (non `SOURCE`), ad esempio:

```bat
set VDB_UPSIZE_CFG=C:\Percorso\Progetto\EXE\UPSIZE.upsize
```

Per progetti senza template ma con `path.ini`:

```bat
set VDB_PG_PATH_INI=C:\Percorso\Progetto\EXE\path.ini
set VDB_PG_UPSIZE_TABLE_SOURCE=EXE
```

## Migrazione reale

```bat
set VDB_UPSIZE_FORZA=1
set VDB_UPSIZE_LOG_CONSOLE=1
pgupsize.exe
echo RC:%errorlevel%
```

## Generare solo `UPSIZE.runtime.upsize`

Se vuoi solo rigenerare il file runtime (`UPSIZE.runtime.upsize`) senza eseguire il trasferimento dati su PostgreSQL:

```bat
set VDB_UPSIZE_SIMULA=1
set VDB_UPSIZE_LOG_CONSOLE=1
pgupsize.exe
echo RC:%errorlevel%
```

Output atteso:

- file `UPSIZE.runtime.upsize` (oppure fallback in `%TEMP%` se il file in `EXE` e' bloccato)
- `ErrorLevel` `0` in caso di generazione corretta

## Gestione indici e retry

Durante la migrazione `DbfUpsize` puo fallire su un `OrdListAdd` di un CDX danneggiato o non compatibile.

Il runner legge `UPSIZE.runtime.upsize.pgtrace.log`, individua l'ultimo bag CDX problematico, lo esclude solo per il run corrente e rigenera `UPSIZE.runtime.upsize` per ritentare. L'esclusione temporanea non modifica `PgUpsize.ini`.

Se vuoi rendere persistente l'esclusione di un indice noto:

```ini
[UPSIZE]
PgUpsizeExcludeOrders=ARTICOLI.CDX,CLIENTI*.CDX
```

Se invece l'errore riguarda una tabella non apribile in esclusiva, il tool non la salta automaticamente: fallisce esplicitamente per evitare una migrazione parziale non dichiarata. Usa `PgUpsizeExcludeTables` solo quando hai deciso consapevolmente che quella tabella non deve essere migrata.

## Nomi tabella nel runtime XML

I nomi target PostgreSQL vengono normalizzati automaticamente:

- caratteri non validi diventano `_`
- spazi e simboli vengono ripuliti
- nomi che iniziano con cifra ricevono prefisso `T_`
- duplicati nello stesso runtime diventano `NOME_2`, `NOME_3`, ...

Il path del DBF sorgente non viene cambiato.

## Exit code (`ErrorLevel`)

- `0` = OK
- `1` = errore configurazione/template
- `2` = errore licenza PGDBE
- `3` = errore esecuzione `DbfUpsize`

## Log utili

- `UPSIZE.runtime.upsize.pgtrace.log`
- `UPSIZE.runtime.upsize.log`

Usali per diagnosi lato cliente in caso di `ErrorLevel` diverso da `0`.

## Note operative

- Evita di inserire chiavi licenza nel sorgente o nel binario distribuito.
- Preferisci `pgdbe_license.txt` o variabili ambiente per gestire rotazione/sicurezza credenziali.
- Se usi variabili ambiente, impostale nello script di lancio cliente e non nel codice applicativo.
