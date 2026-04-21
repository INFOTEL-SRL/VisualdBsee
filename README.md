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
  Moduli introdotti per supporto runtime PostgreSQL e infrastruttura PGDBE.
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

## Template IDE rilevanti

Oltre alla libreria, il comportamento del progetto generato dall'IDE dipende anche da alcuni template in `ide/tmp/xbase/`.

Per l'integrazione PostgreSQL/PGDBE sono rilevanti in particolare:

- `ide/tmp/xbase/INITPROC.TMP`
  Template di inizializzazione del progetto generato. Qui possono vivere i blocchi di bootstrap runtime PG.
- `ide/tmp/xbase/RMAKEX1.TMP`
- `ide/tmp/xbase/RMAKEX2.TMP`
- `ide/tmp/xbase/rmakex3.tmp`
  Template collegati alla generazione del progetto di build/link del main.

Nel fork questi file sono stati riallineati alla variante funzionante presente in `C:\src\PRESENZE\VisualdBsee`, per evitare che il supporto PG resti limitato alla sola libreria o alle sole DLL copiate.

## Prerequisiti

Per usare gli script di build e' necessario avere gia impostato l'ambiente di **Alaska Xbase++** prima di eseguirli.

In particolare:

- il compilatore e gli strumenti Xbase++ devono essere installati
- le variabili d'ambiente del toolchain devono essere disponibili nella shell corrente
- il repository deve essere usato da un prompt Windows compatibile con i batch storici del progetto

## Supporto PostgreSQL / PGDBE

Questo fork contiene adattamenti specifici per PostgreSQL tramite `PGDBE`, concentrati soprattutto in:

- `libreria/src/PG/`
- `libreria/src/base/PGSEEK.PRG`
- vari moduli in `libreria/src/base/`, `libreria/src/s2/` e `libreria/src/xpp/`

La documentazione dedicata si trova in [libreria/docs/README.md](./libreria/docs/README.md) e comprende:

- panoramica per commit degli interventi PG
- riferimento rapido delle chiavi `dfSet`
- checklist di verifica o riapplicazione

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
