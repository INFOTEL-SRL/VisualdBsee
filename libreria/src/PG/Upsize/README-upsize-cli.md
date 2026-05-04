# PGUpsize CLI (nota rapida)

`pgupsize.exe` e `pgupsize-console.exe` condividono lo stesso core di migrazione DBF → PostgreSQL; differiscono per subsystem di link (`/PM:PM` vs `/PM:VIO`), help/argomenti solo sull’EXE, e default sull’attesa INVIO a fine run.

**Documentazione completa** (prerequisiti, licenza esterna, connessione, INI, variabili d’ambiente, template `.upsize`, fasi runtime, exit code, log, build): vedi il README alla radice del repository, sezione **Supporto PostgreSQL / PGDBE** — file `README.md` nella root del workspace (percorso relativo da questa cartella: `../../../../README.md`). Nella stessa sezione ci sono anche **diagrammi** (architettura runner → core e sequenza delle due fasi).
