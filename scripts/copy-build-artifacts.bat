@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"

if "%~1"=="" (
   echo Uso:
   echo   %~nx0 ^<variante-build^> ^<destinazione-dll^> [destinazione-lib]
   echo.
   echo Esempi:
   echo   %~nx0 lib200-2598 C:\dest\bin
   echo   %~nx0 lib200-2598 C:\dest\exe C:\dest\lib
   exit /b 1
)

if "%~2"=="" (
   echo Uso:
   echo   %~nx0 ^<variante-build^> ^<destinazione-dll^> [destinazione-lib]
   echo.
   echo Esempi:
   echo   %~nx0 lib200-2598 C:\dest\bin
   echo   %~nx0 lib200-2598 C:\dest\exe C:\dest\lib
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
   echo Verifica la variante richiesta o esegui prima la build.
   exit /b 1
)

if not exist "%DST%\." mkdir "%DST%"
if errorlevel 1 (
   echo ERRORE: impossibile creare la cartella destinazione DLL:
   echo   %DST%
   exit /b 1
)

if not exist "%LIBDST%\." mkdir "%LIBDST%"
if errorlevel 1 (
   echo ERRORE: impossibile creare la cartella destinazione LIB:
   echo   %LIBDST%
   exit /b 1
)

echo Copia artefatti build
echo   variante: %VARIANT%
echo   sorgente DLL: %SRC%
echo   sorgente LIB primarie: %SRC%
echo   sorgente LIB OMF (fallback): %SRCOMF%
echo   destinazione DLL: %DST%
echo   destinazione LIB: %LIBDST%
echo.

set "ERR=0"

for %%F in ("%SRC%\*.DLL") do (
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

if not exist "%SRC%\*.DLL" (
   echo ATTENZIONE: nessuna DLL trovata in %SRC%
)

if exist "%SRC%\pgupsize.exe" (
   copy /Y "%SRC%\pgupsize.exe" "%DST%\pgupsize.exe" >nul
   if errorlevel 1 (
      echo ERRORE copia EXE pgupsize.exe
      set "ERR=1"
   ) else (
      echo OK EXE pgupsize.exe
   )
) else (
   echo ATTENZIONE: pgupsize.exe non trovato in %SRC%
)

echo.
set "COPIED_LIBS=;"
set "CORE_LIBS=;DBLANG;VDBSEE1O;VDBSEE1S;VDBSEE1X;"

for %%F in ("%SRC%\*.lib") do (
   if exist "%%~fF" (
      copy /Y "%%~fF" "%LIBDST%\%%~nxF" >nul
      if errorlevel 1 (
         echo ERRORE copia LIB %%~nxF
         set "ERR=1"
      ) else (
         echo OK LIB %%~nxF
         set "COPIED_LIBS=!COPIED_LIBS!%%~nF;"
      )
   )
)

for %%F in ("%SRCOMF%\*.lib") do (
   if exist "%%~fF" (
      if exist "%LIBDST%\%%~nxF" (
         echo SKIP LIB %%~nxF da OMF (gia' copiata da %SRC%^)
      ) else (
         echo !CORE_LIBS! | findstr /I /C:";%%~nF;" >nul
         if errorlevel 1 (
            copy /Y "%%~fF" "%LIBDST%\%%~nxF" >nul
            if errorlevel 1 (
               echo ERRORE copia LIB %%~nxF da OMF
               set "ERR=1"
            ) else (
               echo OK LIB %%~nxF da OMF
               set "COPIED_LIBS=!COPIED_LIBS!%%~nF;"
            )
         ) else (
            echo SKIP LIB %%~nxF da OMF (preferita versione in %SRC%^)
         )
      )
   )
)

echo.
for %%N in (DBLANG VDBSEE1O VDBSEE1S) do (
   if exist "%SRC%\%%N.lib" (
      copy /Y "%SRC%\%%N.lib" "%DST%\%%N.lib" >nul
      if errorlevel 1 (
         echo ERRORE copia LIB %%N.lib verso destinazione DLL
         set "ERR=1"
      ) else (
         echo OK LIB %%N.lib verso destinazione DLL
      )
   ) else (
      if exist "%LIBDST%\%%N.lib" (
         copy /Y "%LIBDST%\%%N.lib" "%DST%\%%N.lib" >nul
         if errorlevel 1 (
            echo ERRORE copia LIB %%N.lib da destinazione LIB a destinazione DLL
            set "ERR=1"
         ) else (
            echo OK LIB %%N.lib da destinazione LIB a destinazione DLL
         )
      ) else (
         echo ATTENZIONE: %%N.lib non trovato ne' in %SRC% ne' in %LIBDST%
         set "ERR=1"
      )
   )
)

echo.
if "%ERR%"=="0" (
   echo Completato.
) else (
   echo Completato con errori.
)
exit /b %ERR%
