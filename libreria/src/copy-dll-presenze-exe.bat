@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

:: Output build 2.00-832 (stesso rel usato da gotutto200-832.bat)
set "SRC=%~dp0..\output\lib200-832\rel"
:: Import .lib COFF in rel\omf\ (_gotutto.base: aimplib ... /coff /o...\omf\...)
set "SRCOMF=%SRC%\omf"
:: Cartella EXE del progetto PRESENZE (tre livelli sopra src: libreria, VisualdBsee, PRESENZE)
for %%I in ("%~dp0..\..\..\EXE") do set "DST=%%~fI"
:: Librerie gotutto -> lib\ (copia locale; link Menu: nomi corti + LIB=...Lib200 vedi BuildAfterRegen.bat)
for %%I in ("%~dp0..\..\..\lib") do set "LIBDST=%%~fI"

if not exist "%SRC%\." (
   echo ERRORE: cartella build non trovata:
   echo   %SRC%
   echo Esegui prima gotutto200-832.bat
   exit /b 1
)
if not exist "%DST%\." (
   echo ERRORE: cartella EXE non trovata:
   echo   %DST%
   exit /b 1
)

if not exist "%LIBDST%\." mkdir "%LIBDST%"

echo Copia DLL da:
echo   %SRC%
echo verso EXE:
echo   %DST%
echo Copia LIB da:
echo   %SRCOMF% ^(e fallback %SRC%^)
echo verso:
echo   %LIBDST%
echo.
echo NOTA: copiare DLL/LIB non rilink Menu.exe. Dopo questa copia: ricompilare/linkare Menu.exe ^(Make.xpj^).
echo.

set "ERR=0"
for %%F in (DBLANG.DLL DBLANGBR.DLL DBLANGEN.DLL DBLANGES.DLL DBLANGIT.DLL VDBSEE1O.DLL VDBSEE1S.DLL) do (
   if exist "%SRC%\%%F" (
      copy /Y "%SRC%\%%F" "%DST%\%%F" >nul
      if errorlevel 1 (
         echo ERRORE copia %%F
         set "ERR=1"
      ) else (
         echo OK DLL %%F
      )
   ) else (
      echo MANCANTE in build: %%F
      set "ERR=1"
   )
)

echo.
for %%L in (dblang vdbsee1o vdbsee1s) do (
   set "SRCFILE="
   if exist "%SRCOMF%\%%L.lib" set "SRCFILE=%SRCOMF%\%%L.lib"
   if not defined SRCFILE if exist "%SRCOMF%\%%L.LIB" set "SRCFILE=%SRCOMF%\%%L.LIB"
   if not defined SRCFILE if exist "%SRC%\%%L.lib" set "SRCFILE=%SRC%\%%L.lib"
   if not defined SRCFILE if exist "%SRC%\%%L.LIB" set "SRCFILE=%SRC%\%%L.LIB"
   if defined SRCFILE (
      copy /Y "!SRCFILE!" "%LIBDST%\%%L.lib" >nul
      if errorlevel 1 (
         echo ERRORE copia %%L.lib
         set "ERR=1"
      ) else (
         echo OK LIB %%L.lib ^(!SRCFILE!^)
      )
      set "SRCFILE="
   ) else (
      echo MANCANTE %%L.lib in %SRCOMF% o %SRC%
      set "ERR=1"
   )
)

echo.
if "!ERR!"=="0" (echo Completato.) else (echo Completato con errori.)
exit /b !ERR!
