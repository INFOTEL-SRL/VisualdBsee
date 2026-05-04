# VisualdBsee

Visual dBsee e' un ambiente e insieme di librerie per sviluppare applicazioni business con **Alaska Xbase++**.

Questo repository contiene sia il codice della libreria condivisa sia i componenti dell'IDE, oltre ai file di setup e agli script di build usati per ricompilare le versioni supportate.

## Panoramica del repository

Le aree principali del progetto sono:

- `libreria/`
  Contiene la libreria Visual dBsee vera e propria: sorgenti, include, output di compilazione, utilita e documentazione tecnica.
- `ide/`
  Contiene il codice e gli asset dell'IDE Visual dBsee: binari, sorgenti, librerie di supporto, template temporanei e risorse.
- `setup/`
  Contiene i pacchetti di installazione e le note legate al setup storico del prodotto.
- `build190.bat`
  Prepara l'ambiente e compila la libreria per la toolchain Xbase++ 1.90.
- `build200-832.bat`
  Prepara l'ambiente e compila la libreria per la toolchain Xbase++ 2.00 / build 832.
- `build200-2598.bat`
  Prepara l'ambiente e compila la libreria per la toolchain Xbase++ 2.00.2598 in un output separato.
- `scripts/`
  Utility di supporto per copia artefatti, import file locali IDE e manutenzione di progetto.

## Struttura principale

### `libreria/`

Cartella dedicata al core condiviso di Visual dBsee.

- `libreria/src/`
  Sorgenti della libreria, organizzati per area funzionale.
- `libreria/include/`
  Header e file `.ch` usati in compilazione.
- `libreria/output/`
  Output delle build della libreria, separati per variante di toolchain.
- `libreria/uti/`
  Utility usate durante build o manutenzione.
- `libreria/docs/`
  Documentazione tecnica del fork, inclusa la parte PGDBE/PostgreSQL.

Sottocartelle rilevanti di `libreria/src/`:

- `base/`
  Nucleo storico della libreria: gestione dati, report, query, configurazione e logica comune.
- `s2/`
  Componenti browse e UI collegati alla navigazione dati.
- `xpp/`
  Codice di integrazione con componenti Xbase++ e output report.
- `PG/`
  Moduli introdotti per supporto runtime PostgreSQL e infrastruttura PGDBE. La struttura corrente separa `Runtime/` (sessione PG, INI, bootstrap DBE) e `Upsize/` (migrazione DBF -> PostgreSQL, generazione XML runtime e runner `pgupsize.exe` / `pgupsize-console.exe`).
- `support/`
  File di supporto, stub e helper complementari.
- `vdb/`, `xml/`, `cfunc/`, `clipsupp/`, `c_obj/`, `extralib/`, `extraobj/`, `extra_ch/`, `messaggi/`
  Aree specialistiche usate dalla build della libreria e dai moduli accessori.

### `ide/`

Cartella dedicata all'ambiente Visual dBsee.

- `ide/SOURCE/`
  Sorgenti dell'IDE e di parte del codice applicativo collegato agli strumenti di sviluppo.
- `ide/INCLUDE/`
  Include usati dal progetto IDE.
- `ide/BIN/`
  Binari e materiali runtime dell'IDE.
- `ide/LIB/`, `ide/Lib190/`, `ide/Lib200/`, `ide/Lib200-519/`, `ide/Lib200-2598/`
  Librerie e varianti per diverse versioni del toolchain.
- `ide/resource/`
  Risorse dell'applicazione.
- `ide/tmp/`
  Template e file intermedi usati per generazione progetto o rigenerazione asset.
- `ide/SAMPLES/`
  Materiale di esempio.
- `ide/UTIL/`, `ide/DOC/`
  Utility e documentazione storica dell'IDE.

### `setup/`

Contiene gli installer storici disponibili nel repository:

- `VisualdBseeSetup168.exe`
- `VisualdBsee1611Update.exe`
- `readme.txt`

La nota in `setup/readme.txt` descrive la sequenza storica di installazione della versione `1.6.11`.

## Flusso di build

Gli script principali in root sono pensati per la compilazione della libreria:

### `build190.bat`

- imposta `PATH`, `INCLUDE` e `LIB` rispetto a `libreria/`
- richiama `libreria/src/gotutto190.bat`
- copia le librerie generate dentro `ide/Lib190`

### `build200-832.bat`

- imposta `PATH`, `INCLUDE` e `LIB` rispetto a `libreria/`
- richiama `libreria/src/gotutto200-832.bat`
- usa l'output `libreria/output/lib200-832/rel`

### `build200-2598.bat`

- imposta `PATH`, `INCLUDE` e `LIB` rispetto a `libreria/`
- richiama `libreria/src/gotutto200-2598.bat`
- usa l'output separato `libreria/output/lib200-2598/rel`
- copia le librerie generate dentro `ide/Lib200-2598`

## Varianti di output

Per evitare di mischiare artefatti prodotti da versioni diverse di Xbase++, il repository separa gli output per variante di build.

Percorsi attualmente presenti o supportati:

- `libreria/output/lib190/`
  Build storica Xbase++ 1.90.
- `libreria/output/lib200-832/`
  Build Xbase++ 2.00 / build 832.
- `libreria/output/lib200-2598/`
  Build Xbase++ 2.00.2598.

La variante `2.00.2598` e' stata introdotta per permettere build locali senza sporcare gli artefatti della vecchia `lib200-832`.

## Copia degli artefatti

Per copiare DLL, LIB e, se presenti, `pgupsize.exe` e `pgupsize-console.exe` verso un progetto host o una cartella di distribuzione, il repository include lo script:

- `scripts/copy-build-artifacts.bat`

Uso:

```bat
scripts\copy-build-artifacts.bat <variante-build> <destinazione-dll> [destinazione-lib]
```

Esempi:

```bat
scripts\copy-build-artifacts.bat lib200-2598 C:\dest\bin
scripts\copy-build-artifacts.bat lib200-2598 C:\dest\exe C:\dest\lib
```

Se la destinazione LIB non viene passata, DLL e LIB vengono copiate nella stessa cartella. Gli eseguibili `pgupsize.exe` e `pgupsize-console.exe` vengono copiati nella destinazione DLL quando esistono nell'output della variante scelta.

## Template IDE rilevanti

Oltre alla libreria, il comportamento del progetto generato dall'IDE dipende anche da alcuni template in `ide/tmp/xbase/`.

Per l'integrazione PostgreSQL/PGDBE sono rilevanti in particolare:

- `ide/tmp/xbase/INITPROC.TMP`
  Template di inizializzazione del progetto generato. Qui possono vivere i blocchi di bootstrap runtime PG.
- `ide/tmp/xbase/RMAKEX1.TMP`
- `ide/tmp/xbase/RMAKEX2.TMP`
- `ide/tmp/xbase/rmakex3.tmp`
  Template collegati alla generazione del progetto di build/link del main.

Nel fork questi file sono stati riallineati alla variante funzionante di riferimento, per evitare che il supporto PG resti limitato alla sola libreria o alle sole DLL copiate.

## Avvio dell'IDE

Per avviare correttamente `ide/BIN/vDbsee.exe` servono alcuni file locali che in genere arrivano da una propria installazione gia funzionante di Visual dBsee.

I file tipici da importare in `ide/BIN/` sono:

- `dbsee.ini`
- `dbseeusr.dbf`
- `VDBSEE.qos`
- `dbsee.bak`

Questi file contengono configurazioni macchina-specifiche e non vanno versionati.

Se mancano, l'IDE puo non partire oppure segnalare errori simili a:

- `File non trovato ...\BIN\DBSEEUSR`
- `Controllare le impostazioni del file dbsee.ini alla voce [Environment]`

Per copiarli dalla propria installazione locale al repository e' disponibile lo script:

- [import-ide-local-files.ps1](./scripts/import-ide-local-files.ps1)

Esempio:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\import-ide-local-files.ps1 "C:\Program Files (x86)\VisualdBsee"
```

Lo script:

- copia solo i file locali noti dell'IDE
- crea un backup `.bak` se nel repository esiste gia un file con lo stesso nome
- non tocca i file versionati del repository fuori da `ide/BIN`

### Profilo locale e parametri PostgreSQL nella property grid

I parametri PostgreSQL mostrati nella sidebar "Scheda Progetto" non dipendono solo dai template in `ide/tmp/xbase/` o dai DBF versionati.

In pratica entrano in gioco anche file locali di profilo IDE (in particolare `VDBSEE.qos` e `dbseeusr.dbf`) che arrivano da una installazione funzionante.

Se dopo una pulizia aggressiva (es. `git clean -fd`) la UI non mostra piu i campi PG attesi:

1. rieseguire `scripts/import-ide-local-files.ps1`
2. chiudere e riaprire `vDbsee.exe`
3. verificare che in `ide/BIN` siano presenti almeno `dbsee.ini`, `dbseeusr.dbf`, `VDBSEE.qos`, `dbsee.bak`

### Refresh indici property grid

Se dopo una modifica a `ide/BIN/dbseeopt.dbf` o `ide/BIN/dbseetab.dbf` l'IDE non mostra i nuovi campi nella sidebar, prima di riaprire `vDbsee.exe` e' necessario cancellare gli indici locali:

- `ide/BIN/dbseeOp1.ntx`
- `ide/BIN/dbseeOp2.ntx`
- `ide/BIN/dbseeTab.ntx`

Questo e' particolarmente importante per i campi PostgreSQL: senza la rigenerazione di questi `.ntx`, la property grid puo continuare a mostrare la versione vecchia e quindi non far vedere i campi aggiunti.

## Prerequisiti

Per usare gli script di build e' necessario avere gia impostato l'ambiente di **Alaska Xbase++** prima di eseguirli.

In particolare:

- il compilatore e gli strumenti Xbase++ devono essere installati
- le variabili d'ambiente del toolchain devono essere disponibili nella shell corrente
- il repository deve essere usato da un prompt Windows compatibile con i batch storici del progetto

## Supporto PostgreSQL / PGDBE

Questo fork contiene adattamenti specifici per PostgreSQL tramite `PGDBE`, concentrati soprattutto in:

- `libreria/src/PG/Runtime/`
- `libreria/src/PG/Upsize/`
- `libreria/src/base/PGSEEK.PRG`
- vari moduli in `libreria/src/base/`, `libreria/src/s2/` e `libreria/src/xpp/`

La documentazione dedicata si trova in [libreria/docs/README.md](./libreria/docs/README.md) e comprende:

- panoramica per commit degli interventi PG
- riferimento rapido delle chiavi `dfSet`
- checklist di verifica o riapplicazione
- guida operativa CLI: [libreria/src/PG/Upsize/README-upsize-cli.md](./libreria/src/PG/Upsize/README-upsize-cli.md)

### EXE migrazione PostgreSQL

Sono disponibili due entrypoint per eseguire la migrazione DBF -> PostgreSQL fuori dal main applicativo (stesso core, subsystem diverso):

| Eseguibile | Progetto | Script build | Uso tipico |
| --- | --- | --- | --- |
| `pgupsize.exe` | `libreria/src/PG/Upsize/pgUpsizeExe.xpj` | `libreria/src/PG/Upsize/build-pgupsize-exe.bat` | Link `/PM:PM` richiesto dalle librerie runtime: apre una finestra console separata. |
| `pgupsize-console.exe` | `libreria/src/PG/Upsize/pgUpsizeConsole.xpj` | `libreria/src/PG/Upsize/build-pgupsize-console.bat` | Link `/PM:VIO`: output nella **stessa** finestra terminale (IDE, `cmd`, PowerShell). |

Sorgenti principali:

- `libreria/src/PG/Upsize/pgUpsizeExe.prg` — `MAIN` per `pgupsize.exe` (help CLI, env, attesa INVIO opzionale).
- `libreria/src/PG/Upsize/pgUpsizeConsoleMain.prg` — `MAIN` per `pgupsize-console.exe` (stesso flusso via env; di default non attende INVIO a fine run).

Entrambi i runner riusano il core PGUpsize previsto anche per l'integrazione applicativa: generazione `UPSIZE.runtime.upsize`, configurazione licenza PGDBE, esecuzione `DbfUpsize`.

**Nota importante:** il binario `pgupsize.exe` non puo essere linkato come pura applicazione console (`/PM:VIO`): con le DLL attuali si ottiene `BASE/4314` (*Application was not linked using /PM:PM-switch*). Per uso da terminale integrato usare `pgupsize-console.exe`.

**Argomenti CLI:** `pgupsize.exe` riconosce `--help` / `-h` / `/?` ed esce senza migrare. `pgupsize-console.exe` e pensato per script/IDE: legge solo le variabili d'ambiente (nessun parsing degli argomenti).

**Log su stdout:** con nome eseguibile che contiene `PGUPSIZE-CONSOLE` (in pratica `pgupsize-console.exe`) il trace viene anche stampato su stdout, oltre al file `.pgtrace.log`. Si puo forzare con `VDB_PG_UPSIZE_STDOUT=1` o `VDB_UPSIZE_LOG_CONSOLE=1`. A fine run `pgupsize-console.exe` stampa i path del log completo (`*.pgtrace.log` e `*.log` senza suffisso trace).

**Flusso integrato (dopo `/UPD`):** `dfPgUpsizeRunFromUpd()` esegue l'upsize **nello stesso processo** dell'applicazione (nessuna nuova finestra). Per tornare al lancio esterno di `pgupsize.exe` impostare `VDB_PG_UPSIZE_EXTERNAL=1` (opzionale `VDB_PG_UPSIZE_EXE` per path custom).
Per i progetti legacy senza cartella `SOURCE`, il runtime viene costruito direttamente da:

- `EXE\pgupsize.ini` (connessione/licenza)
- `EXE\path.ini` (`UserPathXX` con le cartelle DBF reali)

La fase di upsize e' divisa in due passaggi:

1. creazione di `UPSIZE.runtime.upsize`, cioe' il file XML effettivamente passato a `DbfUpsize`
2. esecuzione di `DbfUpsize` usando quel runtime file

Il runtime file viene generato risolvendo connessione/licenza da environment o INI, poi ricostruendo l'elenco tabelle dal dizionario `DBDD`, che e' la sorgente predefinita e rappresenta lo stato esatto del database. I DBF dichiarati nel DBDD vengono risolti usando `File_Path` verso le cartelle reali di `path.ini` (`UserPathXX`), poi cercando negli altri `UserPathXX` e infine nella cartella `EXE`; gli ordini vengono presi dalle righe `NDX` del DBDD/`FILE_ALI`, senza dedurli dal nome della tabella o dallo scan dei `.CDX`. In dry-run il processo si ferma dopo la creazione del file, utile per verificare path DBF, nomi tabella e ordini CDX prima di trasferire dati.

Uso rapido (build entrambi gli exe):

```bat
cd libreria\src\PG\Upsize
build-pgupsize-exe.bat
build-pgupsize-console.bat
```

Esempio da terminale integrato (stessa finestra, log live):

```bat
cd /d C:\src\PRESENZE\EXE
set VDB_PG_UPSIZE_FORCE=1
set VDB_PG_UPSIZE_DRY_RUN=1
set VDB_PG_PATH_INI=C:\src\PRESENZE\EXE\path.ini
C:\src\VisualdBsee\libreria\output\lib200-2598\rel\pgupsize-console.exe
```

Esempio con runner classico (finestra separata):

```bat
C:\src\VisualdBsee\libreria\output\lib200-2598\rel\pgupsize.exe
```

Output build tipico (variante `lib200-2598`):

- `libreria/output/lib200-2598/rel/pgupsize.exe`
- `libreria/output/lib200-2598/rel/pgupsize-console.exe`

Configurazione supportata (env):

- `VDB_UPSIZE_CFG` (opzionale; se manca, usa modalita no-template)
- `VDB_PG_UPSIZE_FORCE=1`
- `VDB_PG_UPSIZE_DRY_RUN=1` (per dry-run)
- `VDB_PG_PATH_INI=<path a path.ini>` (opzionale ma consigliato)
- `VDB_PG_UPSIZE_TABLE_SOURCE=DBDD|EXE` (default `DBDD`; `EXE` abilita lo scan fisico legacy)
- `VDB_PGUPSIZE_INI=<path a PgUpsize.ini>` (override esplicito)
- `VDB_PG_UPSIZE_EXTRA_DBF_DIR=<cartella DBF extra>` (opzionale)
- `VDB_PG_UPSIZE_STDOUT=1` / `VDB_UPSIZE_LOG_CONSOLE=1` (forzare log su console)
- `VDB_PG_UPSIZE_EXTERNAL=1` (solo flusso integrato: rilancia `pgupsize.exe` esterno invece dell'esecuzione inline)
- `VDB_PG_UPSIZE_EXE=<path>` (path esplicito per `pgupsize.exe` quando `VDB_PG_UPSIZE_EXTERNAL=1`)

Configurazione supportata (`EXE\PgUpsize.ini`, sezione `[UPSIZE]`):

- `PgUpsizeTableSource=DBDD|EXE` (default `DBDD`; `EXE` abilita lo scan fisico legacy)
- `PgUpsizeExtraDbfDir=<cartella DBF extra>`
- `PgUpsizeExcludeTables=nome1,nome2`
- `PgUpsizeExcludeOrders=file1.cdx,file2.cdx` (supporta anche stem e wildcard `*`)
- `PgUpsizeDisableOrders=YES` (solo diagnosi o migrazioni senza indici)

Codici di uscita:

- `0`: successo
- `1`: errore configurazione/template
- `2`: errore licenza PGDBE
- `3`: `DbfUpsize` fallito

Note operative:

- `pgupsize.exe` e `pgupsize-console.exe` usano gli stessi moduli core PGUpsize della libreria; il progetto console aggiunge solo `pgUpsizeConsoleMain.prg` e riusa `pgUpsizeCliCompat.prg` per shim standalone.
- Se `DbfUpsize` fallisce su un `OrdListAdd`, il runtime puo rigenerare l'XML escludendo temporaneamente solo quel bag CDX e ritentare, senza rendere permanente l'esclusione.
- Le tabelle nel runtime XML vengono normalizzate a nomi PostgreSQL validi e rese univoche (`NOME`, `NOME_2`, ...), mentre il path DBF resta quello originale.

## Note sul contenuto del repository

- Il repository contiene materiale storico e varianti per piu versioni dell'ambiente Xbase++.
- Le build moderne possono usare output distinti per evitare di mischiare artefatti prodotti da toolchain diverse.
- Quando si usa la toolchain `2.00.2598`, il percorso consigliato e' `libreria/output/lib200-2598/` con copia finale in `ide/Lib200-2598/`.
- Alcune cartelle ospitano output di build o asset binari necessari al progetto.
- La struttura riflette un progetto legacy reale, quindi convivono codice libreria, strumenti IDE, setup e materiale di supporto.

## Punto di ingresso consigliato

Se devi orientarti nel progetto:

1. leggi questo `README.md`
2. esplora `libreria/src/` per il core applicativo
3. esplora `ide/SOURCE/` per il lato IDE
4. consulta `libreria/docs/` per la documentazione tecnica del fork, in particolare per PGDBE
