@echo off
REM Ambiente minimo per gotutto200-2598 / build200-2598 (stesso setup di build200-2598.bat).
REM Richiede prompt "Alaska Xbase++" oppure xpp20\bin gia' nel PATH.

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"

set "VDBLIB_MAINDIR=%ROOT%\libreria"
set "PATH=%VDBLIB_MAINDIR%\uti;%PATH%"
set "INCLUDE=%VDBLIB_MAINDIR%\INCLUDE;%INCLUDE%"
set "INCLUDE=%VDBLIB_MAINDIR%\SRC\EXTRA_CH;%INCLUDE%"
set "LIB=%VDBLIB_MAINDIR%\output\lib200-2598\rel;%LIB%"

if not exist "%VDBLIB_MAINDIR%\uti\strtran.exe" (
   echo ERRORE: manca %VDBLIB_MAINDIR%\uti\strtran.exe
   exit /b 1
)

where xppload >nul 2>&1
if errorlevel 1 (
   echo ERRORE: xppload non nel PATH. Aprire il prompt "Alaska Xbase++ 2.00.2598" e ripetere.
   exit /b 1
)

exit /b 0
