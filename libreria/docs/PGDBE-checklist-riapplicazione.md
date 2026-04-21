# Checklist: riapplicare gli interventi PGDBE (ordine consigliato)

Percorso base sorgenti: `libreria\src\`.  
Ordine suggerito: prima le **primitive condivise**, poi **dfS/cache**, poi **stampe/query**, **UI**, **config**.

---

## 0. Prerequisito

- Assicurarsi che il progetto di compilazione della libreria **includa** `base\PGSEEK.PRG` (se il fork vanilla non lo ha, va **aggiunto** al progetto oltre che al filesystem).
- `DFS.PRG` e `DBLOOK.PRG` devono risolvere le chiamate a `dfPgRddIs`, `dfPgOrdKeySingleField`, `dfPgSeek*` definite in `PGSEEK.PRG` (stessa static lib / stesso link).

---

## 1. `base\PGSEEK.PRG` (intero modulo)

**Ruolo:** funzioni PG condivise da `DFS.PRG` e `DBLOOK.PRG` (e `DFSKIP.PRG`).

**Contenuto da avere:**

| Simbolo | Cosa fa |
|---------|---------|
| `dfPgRddIs( cRdd )` | `.T.` se la stringa RDD contiene `"PGDBE"`. |
| `dfPgOrdKeySingleField( cKeyExp )` | Da `ORDKEY()`: estrae un **solo nome campo** per le verify post-seek. Ciclo che rimuove **`PADR(...,)`** (primo argomento), poi **`UPPER(` / `LOWER(` / `RTRIM(` / `LTRIM(`** con argomento interno **senza** `(` né `,`. Rifiuta chiavi **composte** (`+` nell’espressione). |
| `dfPgSeekFieldValU` | Valore campo carattere normalizzato `UPPER(RTRIM(...))`. |
| `dfPgSeekIsPartialChr` | Seek “corto” vs larghezza campo `C` in `DbStruct()`. |
| `dfPgSeekVerifyRow` | Confronto seek vs campo corrente; skip verify se non PG / seek vuoto / parziale. |
| `dfPgSeekFallbackScan` | `DbSeek(PADR)` + scan lineare se serve. |
| `dfPgSeekAfterDbSeek` | Dopo `DBSEEK` soft/hard su PG, allinea il record se la chiave campo non coincide; chiama fallback. |

---

## 2. `base\DFS.PRG`

### 2a. Variabili STATIC e commento (in cima, prima di `FUNCTION dfS`)

- `STATIC sDfSSel, sDfSOrd, sDfSNam, sDfSWa` — contesto cache **dfS** per PG (alias numerico, ordine, **nome campo** dedotto da `ORDKEY`, alias 8 char).
- Commento: cache tra chiamate ma non tra stampe/sessioni diverse.

### 2b. Ramo PG all’inizio di `dfS( uOrd, uSeek, lSoft )`

Subito dopo i commenti storici, **prima** del ramo `IF ORDNUMBER() != uOrd` classico:

- `IF SELECT() > 0 .AND. dfPgRddIs( RDDNAME() )`
  - `ORDSETFOCUS( uOrd )` se necessario; `cWa := PADR(UPPER(ALIAS()),8)`.
  - Se `uSeek` è `C` e non vuoto dopo `RTRIM`:
    - Cache hit: stesso `nSel`, `uOrd`, `sDfSNam` non vuoto, stesso `cWa` → `cFld := sDfSNam`.
    - Altrimenti: `cFld := dfPgOrdKeySingleField( ALLTRIM( ORDKEY() ) )`.
    - **Fallback `codice`:** solo se `EMPTY(cFld)` e `FIELDPOS("codice")>0` e **`FIELDPOS("nome")<1`** (tabella tipo **CODICI**). Con campo **nome** (es. **DIPE**) non si usa il fallback.
    - Con `cSeekUse` non vuoto ma **`cFld` ancora vuoto**, il `DBSEEK` finale nel ramo PG usa **`cSeekUse`** (stringa da `dfAny2Str`), non **`uSeek`** (tipi PG / NIL).
    - Aggiorna `sDfSSel`, `sDfSOrd`, `sDfSWa`; se `!EMPTY(cFld)` → `sDfSNam := cFld`, **altrimenti** `sDfSNam := ""` (non lasciare cache campo stale).
    - Se `!EMPTY(cFld)`: hash key `_dfSPgHtKey`, `_dfSPgHtTryGoto`, shortcut se già sul record, `DBSEEK`, `dfPgSeekVerifyRow`, `_dfSPgHtPut`, eventuale secondo `ORDSETFOCUS`+`DBSEEK`, `dfPgSeekAfterDbSeek`, `RETURN lRet`.
  - Se ramo `cFld` vuoto o non entrato: `DBSEEK(uSeek,lSoft)` e `RETURN`.
- `ENDIF` del ramo PG, poi il codice **originale** `ORDSETFOCUS` + `RETURN DBSEEK(...)` per non-PG.

### 2c. `PROCEDURE dfSPgSeekCacheFlush()`

- `_dfSPgHtTable( .T. )` — flush tabella hash seek.
- `sDfSSel := NIL`, `sDfSOrd := NIL`, `sDfSNam := ""`, `sDfSWa := ""`.

### 2d. Funzioni STATIC/hash (stesso file, dopo `dfS`)

- `_dfSPgHtKey`, `_dfSPgHtTable`, `_dfSPgHtTryGoto`, `_dfSPgHtPut` — cache **RECNO** per combinazione alias+ordine+seek (con verify riga).

---

## 3. `base\dfprncon.prg` — `PROCEDURE dfPrnConfig`

All’inizio del corpo (subito dopo `PROCEDURE` / commento blocco):

- Chiamata **`dfSPgSeekCacheFlush()`** prima di azzerare `REP_QRY_BLOCK` / compilare `REP_QRY_EXP`.

---

## 4. `base\DFANY2ST.PRG` — `FUNCTION dfAny2Str`

Dopo `LOCAL` e prima di `cTip := VALTYPE( uPar )`:

- Se **`uPar == NIL`** → **`RETURN ""`** (commento: NULL PG / filtri e totali).

---

## 5. `base\DFQRYFLT.PRG` — `STATIC FUNCTION dfQryFlt` / helper

### 5a. Nuova helper `_dfQryFltOmitDate( u, cType )`

- Se tipo non `D` → `.F.`.
- Se non data / `EMPTY` / anno o mese o giorno `< 1` → `.T.` (campo data “vuoto” da escludere come empty field).

### 5b. Condizione “campo vuoto” su `QRY_FIELD`

- Da solo `EMPTY(aQuery[nField][3])` a:  
  `EMPTY(...) .OR. _dfQryFltOmitDate( aQuery[nField][3], aQuery[nField][5] )`  
  così le date “a zero” non rompono il filtro.

### 5c. Ramo `OTHERWISE` dei confronti (dopo `CASE` `$` / `C`)

- **`cType == "D"`:** espressione filtro con **`DTOS(campo)`** e **`DTOS(valore)`** invece di confronto diretto via `CTOD` sul campo (commento PGDBE/ODBC).
- **`cType == "C"`:**  
  - se condizione **`==`**: `UPPER(ALLTRIM(STRTRAN(dfAny2Str(...),CHR(160),' '))))` su entrambi i lati;  
  - altrimenti: per **`=`** su stringa, mappare comparatore a **`==`** dopo `UPPER(RTRIM(STRTRAN(dfAny2Str(...),CHR(160),' '))))`;  
  - usare `dfAny2Str` su campo e letterale dove serve (NULL, NBSP).

---

## 6. `base\DFSKIP.PRG`

### 6a. `FUNCTION dfSkip` — `LOCAL` e primo `DO CASE`

- Aggiungere **`LOCAL nPgBrW`** (contatore cammino PG nel ramo `n2Skip > 0`).

**`CASE (n2Skip == 0) .OR. (LastRec() == 0 …)`**

- Estendere la condizione con  
  **`!( dfPgRddIs( (nAlias)->( RDDNAME() ) ) .AND. n2Skip != 0 )`**  
  così su PG, con `LastRec()==0` ma righe presenti e `n2Skip <> 0`, lo skip dei report non si ferma.

**`CASE (n2Skip > 0)` — dopo ogni `dbSkip(1)`**

1. Se **`(nAlias)->(Eof())`**: `dbGoto(nActRec)`, fix `EOF()` ADS se necessario, `EXIT`.
2. Se **`EVAL(bBreak)`**: con PG e **`dfSet("XbasePgDfSkipWalkPastBreak") != "NO"`**, ciclo **`DbSkip(1)`** mentre `break` e non EOF, max **100000**; poi se ancora `Eof()` o `break`, ripristino `nActRec` e `EXIT`.
3. Se **`!EVAL(bFilter)`**: `LOOP`.
4. Aggiornare `nActRec` e `nSkipped`.

*(Ramo `n2Skip < 0`: invariato salvo esigenze future di simmetria col cammino PG.)*

### 6b. `PROCEDURE dfTop` — `LOCAL` e blocco `bKey`

- Aggiungere **`LOCAL nPgTopW`**.
- Nel ramo **`ELSE`** di `bKey`: `uSeekVal`, `DBSEEK` soft, ramo PG con `dfPgOrdKeySingleField`, `dfPgSeekAfterDbSeek` o `DbGoTop()` se composto / seek fallito (come sorgente).

### 6c. `PROCEDURE dfTop` — fallback dopo `ENDIF` del blocco `bKey`

- Se **`bKey != NIL`**, PG, **`Eof() .OR. lEof`**, `uSeekVal` tipo `C` non vuoto, campo singolo da `ORDKEY()` non vuoto: **`dfPgSeekFallbackScan`**; se trova riga: **`lSeekOk := .T.`**, **`lEof := .F.`** (rientro in `IF !lEof` dopo cambio master / seek incompleto).

### 6d. `PROCEDURE dfTop` — dentro `IF !lEof`

- `dfSkip(1,…)` se filtro non passa (storico).
- Cammino break PG (stesso **`dfSet`** di `dfSkip`) prima del ramo finale `DBGOTO(0)`.
- Chiusura: **`DBGOTO(0)`** se break o filtro non passano; opt-in **`XbasePgDfTopDeferDbgoto0OnBreak=YES`** per guard legacy su stampa.

### 6e. Test post-merge

- Listbox 1:n: cambi master ripetuti; nessuna griglia vuota né righe altrui.
- `dfReportSKIP` / stampe con query: nessuna regressione; altrimenti rivedere §7–8 e `dfSet` stampa.

---

## 7. `base\DFSTA.PRG` — `PROCEDURE dfReportTOP`

Nel ramo `ELSE` (non `VR_SKIPARRAY`):

- Variabili locali `lPgQryTop`, `cW`.
- Se master ha alias, select > 0, **`dfPgRddIs`**, **`dfPrnArr()[REP_QRY_BLOCK] != NIL`**, e **`dfSet("XbasePgReportTopUseKeyWithQry") != "YES"`** → `lPgQryTop := .T.`.
- Se `lPgQryTop`: **`dfTop( NIL, aVR[VR_FILTER], aVR[VR_BREAK] )`** altrimenti **`dfTop( aVR[VR_KEY], ...)`** come originale.

---

## 8. `base\dfupdqry.prg` — `FUNCTION dfUpdQryRep` (blocco `#ifdef` / fine logica opt)

Prima di `dfUpdVR(...)`:

- Commento PG: KEY/BREAK da ottimizzazione mirano a `DBSEEK` sul master; su PG possono lasciare EOF pur con dati che soddisfano `REP_QRY_*`.
- Salva `SELECT()`, alias master `cMs := RTRIM(aVRec[1][VR_NAME])`.
- Se alias valido, PG, e **`dfSet("XbasePgReportKeepQueryKeyOpt") != "YES"`**:  
  `bNewKey := NIL`, `bNewBreak := {|| .F. }`.
- Ripristina `SELECT(nSv)`.

---

## 9. `xpp\DFCRWOUT.prg` — `METHOD dfCRWOut:output`

Subito dopo `LOCAL nPos, xVal, cFieTyp` (o equivalente):

- Se `aFie` è array con almeno 2 elementi e `( uVar == NIL .OR. VALTYPE(uVar)=="U" )`:
  - tipo da `ALLTRIM(aFie[2])`, primo carattere in `UPPER`;
  - `N` → `0`; `D` → `CTOD(SPACE(8))`; `L` → `.F.`; altrimenti `""`.
- Poi il flusso esistente (CONVTOANSI, `AADD`/`::aRecord`, ecc.).

*(Usa le `#define` `DBS_TYPE_*` già presenti nello stesso file.)*

---

## 10. `base\DBLOOK.PRG` — `FUNCTION dbLook`

Interventi **incrementali** (molti punti nello stesso file):

| # | Cosa |
|---|------|
| 10.1 | Include / dipendenze: serve **`#include "dfSet.CH"`** se non già presente (per `dfSet("XbaseDbLookEofOnEmptyFreeSeek")`). |
| 10.2 | **`LOCAL nPgSavRec := 0`**, **`lPickSync := .F.`**, **`lEmptySeekFree := .F.`** con commenti. |
| 10.3 | Dopo primo **`ORDSETFOCUS( aLook[LK_ORDER] )`**: calcolo **`lEmptySeekFree`** := `LT_FREE` e seek `C` vuoto (`EMPTY(RTRIM(aLook[LK_SEEK]))`). |
| 10.4 | Blocco **pick/browse**: se **`lPickSync .AND. !lEsc`** → **`_dbLookSyncSeekAfterPick( cAlias, aLook )`** (allinea `LK_SEEK` al record corrente prima del `DBSEEK` successivo). |
| 10.5 | Ramo **`IF (!EMPTY(LK_SEEK) .OR. !lFound) .AND. !lEsc`**: su PG **`DBSEEK` senza soft** (`DBSEEK(aLook[LK_SEEK])`), altrimenti soft come originale; ramo `ELSEIF !lFound` invariato nella logica ma coerente con i tipi. |
| 10.6 | Dopo seek: **`_dbLookPgSeekVerify`** e se fallisce **`_dbLookPgSeekFallback`**. |
| 10.7 | Prima di **`ORDSETFOCUS(nInd)`** (ripristino indice): se PG e record valido → **`nPgSavRec := RECNO()`**. |
| 10.8 | Dopo **`ORDSETFOCUS(nInd)`**: se **`nPgSavRec > 0`** e PG → **`DBGOTO(nPgSavRec)`**. |
| 10.9 | Dopo restore indice: se **`lEmptySeekFree .AND. !lPickSync .AND. !lEsc`** e `dfSet("XbaseDbLookEofOnEmptyFreeSeek") != "NO"` → **`DBGOTO(0)`**. |
| 10.10 | Impostare **`lPickSync := .T.`** nei rami dove l’utente sceglie da browse/ddKey/dfTop (cercare `lPickSync` nel file per tutti i punti). |
| 10.11 | **STATIC** ausiliarie: `_dbLookPgFieldFromAlook`, `_dbLookSyncSeekAfterPick`, `_dbLookPgSeekField` (usa `dfPgOrdKeySingleField` + fallback campo da `aLook`), `_dbLookPgSeekVerify`, `_dbLookPgSeekFallback`, **`_dbLookSeekOnOrder`** (PG: `DBSEEK` + verify/fallback). |

*(Riferimento: sorgente attuale con commenti `PGDBE` e `LK_SEEK`.)*

---

## 11. `s2\S2BRW.prg` — `METHOD S2XbpBrowser:dfTotalInc`

- Sostituire il corpo che faceva **`AEVAL(..., {|oSub| oSub:WC_FOOTERTOTALBLOCK += EVAL(oSub:WC_TOTALVALUE)})`** (o equivalente con doppio lavoro) con **`AEVAL( ::aTotal, {|oSub| oSub:WC_FOOTERTOTALBLOCK += EVAL(oSub:WC_TOTALVALUE)})`** **senza** seconda `EVAL` del block totale per riga (commento: `tbEval` ha già posizionato il record; PG/lookup costoso).
- **`dfTAGTotalInc` / `dfTAGTotalDec`** restano con la logica `COLUMN_TAG_COUNT` + `WC_TOTALVALUE` se presente nel tuo sorgente.

---

## 12. `s2\S2BROWSE.prg` — `METHOD S2Browse:tbReset`

- **Sempre** **`::Browser:tbReset(lFreeze)`** dopo `::W_OBJREFRESH := .T.` (non saltare su PG: altrimenti colonne con lookup/decodifica si comportano male).

## 12bis. `s2\S2BRW.prg` — `METHOD S2XbpBrowser:tbTotal`

- In **`tbTotal`**, se **`SELECT()>0`**, **`dfPgRddIs(RDDNAME())`** e **`dfSet("XbaseBrowseFooterTotalsOnPG") != "YES"`**: non eseguire **`EVAL(::bEval, {|| ::dfTotalInc() })`** (evita scan intera tabella per i soli totali footer); eseguire comunque **`dfColZero`** e **`tbColPut`**. Altrimenti comportamento originale.

---

## 13. `base\DBCFGOPE.PRG` — `FUNCTION dbCfgOpen`

Dopo `cDriver := RDDSETDEFAULT()` e check `cFile`:

- Se **`dfPgRddIs( cDriver )`** → **`cDriver := "DBFCDX"`** per aprire i file dizionario **DBDD / DBHLP / DBTABD / DBLOGIN / DBLKINF** su DBF locale (commento: `dfUseFile` con PG fallisce).

---

## Riepilogo file toccati (13)

1. `src\base\PGSEEK.PRG`  
2. `src\base\DFS.PRG`  
3. `src\base\dfprncon.prg`  
4. `src\base\DFANY2ST.PRG`  
5. `src\base\DFQRYFLT.PRG`  
6. `src\base\DFSKIP.PRG`  
7. `src\base\DFSTA.PRG`  
8. `src\base\dfupdqry.prg`  
9. `src\xpp\DFCRWOUT.prg`  
10. `src\base\DBLOOK.PRG`  
11. `src\s2\S2BRW.prg`  
12. `src\s2\S2BROWSE.prg`  
13. `src\base\DBCFGOPE.PRG`  

**Non** sono elencate qui modifiche all’applicazione **PRESENZE** (`SOURCE\`, `EXE\dbstart.ini`, ecc.): solo libreria Visual dBsee.

**`dfSet` opzionali** documentati in `PGDBE-dfSet-riferimento-rapido.md`.

---

*Generato per allineare un fork pulito: applicare nell’ordine 1→13 e ricompilare la libreria dopo ogni gruppo logico (minimo: dopo 1–2, poi build completa).*
