@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"

if "%~1"=="" (
   echo Uso:
   echo   %~nx0 ^<variante-build^> ^<destinazione-dll^> [destinazione-lib]
   echo.
   echo Copia DLL runtime + LIB di link ^(import COFF da omf\^).
   echo.
   echo Progetto host tipico ^(cartelle EXE e lib separate^):
   echo   - Runtime: VDBSEE1O.DLL ^(BASE: ddWin, DDFILE, DBLOOK, PG...^) + VDBSEE1S.DLL
   echo   - Link:    omf\dblang.lib, omf\VDBSEE1O.lib, omf\VDBSEE1S.lib
   echo.
   echo Copia rapida ^(path in scripts\host-paths.bat, vedi host-paths.bat.example^):
   echo   copy-to-host.bat
   echo.
   echo Esempi con path espliciti:
   echo   %~nx0 lib200-2598 D:\mio-progetto\EXE D:\mio-progetto\lib
   echo   %~nx0 lib200-2598 D:\mio-progetto\EXE
   exit /b 1
)

if "%~2"=="" (
   echo Uso:
   echo   %~nx0 ^<variante-build^> ^<destinazione-dll^> [destinazione-lib]
   exit /b 1
)

set "VARIANT=%~1"
set "DST=%~f2"
set "LIBDST=%~f3"

if not defined LIBDST set "LIBDST=%DST%"

set "SRC=%ROOT%\libreria\output\%VARIANT%\rel"
set "SRCOMF=%SRC%\omf"

if not exist "%SRC%\." (
   echo ERRORE: cartella build non trovata:
   echo   %SRC%
   echo Verifica la variante o esegui build200-2598.bat fino a DYNAMIC OK.
   exit /b 1
)

if not exist "%DST%\." mkdir "%DST%"
if errorlevel 1 (
   echo ERRORE: impossibile creare destinazione DLL: %DST%
   exit /b 1
)

if not exist "%LIBDST%\." mkdir "%LIBDST%"
if errorlevel 1 (
   echo ERRORE: impossibile creare destinazione LIB: %LIBDST%
   exit /b 1
)

echo Copia artefatti build
echo   variante: %VARIANT%
echo   sorgente: %SRC%
echo   DLL  -^> %DST%
echo   LIB  -^> %LIBDST% ^(link: omf\ preferito^)
echo.

set "ERR=0"

REM --- DLL runtime obbligatorie (ddWin e' in VDBSEE1O lettera O, non in VDBSEE1S solo) ---
REM Token tra virgolette: in CMD "VDBSEE1O" senza quote puo' diventare VDBSEE10 / redirect 1>
for %%N in ("VDBSEE1O" "VDBSEE1S") do (
   set "DLLSTEM=%%~N"
   if not exist "%SRC%\!DLLSTEM!.DLL" (
      echo ERRORE: manca !DLLSTEM!.DLL in %SRC%
      echo   Serve build DYNAMIC completata ^(gotutto200-2598.bat in libreria\src^).
      set "ERR=1"
   ) else (
      copy /Y "%SRC%\!DLLSTEM!.DLL" "%DST%\!DLLSTEM!.DLL" >nul
      if errorlevel 1 (
         echo ERRORE copia DLL !DLLSTEM!.DLL
         set "ERR=1"
      ) else (
         echo OK DLL !DLLSTEM!.DLL
      )
   )
)

if exist "%SRC%\VDBSEE1O.DLL" if exist "%SRC%\VDBSEE1S.DLL" (
   set "STALE1O=0"
   for /f "delims=" %%A in ('powershell -NoProfile -Command ^
      "$o=(Get-Item -LiteralPath '%SRC%\VDBSEE1O.DLL').LastWriteTime; $s=(Get-Item -LiteralPath '%SRC%\VDBSEE1S.DLL').LastWriteTime; if ($o -lt $s) { 'STALE' }"') do if /I "%%A"=="STALE" set "STALE1O=1"
   if "!STALE1O!"=="1" (
      echo.
      echo ERRORE: VDBSEE1O.DLL in output e' PIU' VECCHIA di VDBSEE1S.DLL.
      echo   ddWin / DDFILE / DBLOOK stanno in VDBSEE1O — copiare ora non aggiorna il runtime.
      echo   Esegui: scripts\rebuild-vdbsee1o-2598.bat  poi rilancia questo script.
      echo.
      set "ERR=1"
   )
)

REM Altre DLL lingua / runtime
for %%F in ("%SRC%\DBLANG*.DLL") do (
   if exist "%%~fF" (
      copy /Y "%%~fF" "%DST%\%%~nxF" >nul
      if errorlevel 1 (
         echo ERRORE copia DLL %%~nxF
         set "ERR=1"
      ) else (
         echo OK DLL %%~nxF
      )
   )
)

if exist "%SRC%\pgupsize.exe" (
   copy /Y "%SRC%\pgupsize.exe" "%DST%\pgupsize.exe" >nul
   if errorlevel 1 ( echo ERRORE copia pgupsize.exe & set "ERR=1" ) else ( echo OK EXE pgupsize.exe )
) else (
   echo ATTENZIONE: pgupsize.exe non trovato in %SRC%
)

if exist "%SRC%\pgupsize-console.exe" (
   copy /Y "%SRC%\pgupsize-console.exe" "%DST%\pgupsize-console.exe" >nul
   if errorlevel 1 ( echo ERRORE copia pgupsize-console.exe & set "ERR=1" ) else ( echo OK EXE pgupsize-console.exe )
)

echo.

REM --- LIB di link progetto host: omf\ e' la sorgente corretta (COFF / ALINK) ---
for %%N in ("dblang" "DBLANG" "VDBSEE1O" "VDBSEE1S") do (
   set "LIBSTEM=%%~N"
   set "COPIED=0"
   if exist "%SRCOMF%\!LIBSTEM!.lib" (
      copy /Y "%SRCOMF%\!LIBSTEM!.lib" "%LIBDST%\!LIBSTEM!.lib" >nul
      if errorlevel 1 (
         echo ERRORE copia LIB !LIBSTEM!.lib da omf
         set "ERR=1"
      ) else (
         echo OK LIB !LIBSTEM!.lib ^(omf^)
         set "COPIED=1"
      )
   )
   if "!COPIED!"=="0" if exist "%SRC%\!LIBSTEM!.lib" (
      copy /Y "%SRC%\!LIBSTEM!.lib" "%LIBDST%\!LIBSTEM!.lib" >nul
      if errorlevel 1 (
         echo ERRORE copia LIB !LIBSTEM!.lib da rel
         set "ERR=1"
      ) else (
         echo OK LIB !LIBSTEM!.lib ^(rel^)
         set "COPIED=1"
      )
   )
   if "!COPIED!"=="0" (
      echo ERRORE: !LIBSTEM!.lib non trovato in %SRCOMF% ne' in %SRC%
      set "ERR=1"
   )
)

REM LIB aggiuntive in rel\ (non sostituiscono le core gia' copiate)
for %%F in ("%SRC%\*.lib") do (
   set "SKIP=0"
   for %%N in ("dblang" "DBLANG" "VDBSEE1O" "VDBSEE1S") do if /I "%%~nF"=="%%~N" set "SKIP=1"
   if "!SKIP!"=="0" if exist "%%~fF" (
      if not exist "%LIBDST%\%%~nxF" (
         copy /Y "%%~fF" "%LIBDST%\%%~nxF" >nul
         if errorlevel 1 (
            echo ERRORE copia LIB %%~nxF
            set "ERR=1"
         ) else (
            echo OK LIB %%~nxF ^(extra rel^)
         )
      )
   )
)

REM Se DLL e LIB sono la stessa cartella, duplica anche le core .lib li
if /I "%DST%"=="%LIBDST%" (
   for %%N in ("dblang" "DBLANG" "VDBSEE1O" "VDBSEE1S") do (
      if exist "%LIBDST%\%%~N.lib" (
         copy /Y "%LIBDST%\%%~N.lib" "%DST%\%%~N.lib" >nul
         if errorlevel 1 set "ERR=1"
      )
   )
)

echo.
if "%ERR%"=="0" (
   echo Completato. Verifica date:
   if exist "%DST%\VDBSEE1O.DLL" dir /T:W "%DST%\VDBSEE1O.DLL"
   if exist "%DST%\VDBSEE1S.DLL" dir /T:W "%DST%\VDBSEE1S.DLL"
   if not "%LIBDST%"=="%DST%" if exist "%LIBDST%\VDBSEE1O.lib" dir /T:W "%LIBDST%\VDBSEE1O.lib" "%LIBDST%\VDBSEE1S.lib" 2>nul
) else (
   echo Completato con errori.
)
exit /b %ERR%
