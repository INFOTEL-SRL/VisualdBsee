@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

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

set "SRC=%~dp0libreria\output\%VARIANT%\rel"
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
echo   sorgente LIB OMF: %SRCOMF%
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

echo.
set "COPIED_LIBS=;"

for %%F in ("%SRCOMF%\*.lib" "%SRCOMF%\*.LIB") do (
   if exist "%%~fF" (
      copy /Y "%%~fF" "%LIBDST%\%%~nxF" >nul
      if errorlevel 1 (
         echo ERRORE copia LIB %%~nxF da OMF
         set "ERR=1"
      ) else (
         echo OK LIB %%~nxF da OMF
         set "COPIED_LIBS=!COPIED_LIBS!%%~nF;"
      )
   )
)

for %%F in ("%SRC%\*.lib" "%SRC%\*.LIB") do (
   if exist "%%~fF" (
      echo !COPIED_LIBS! | findstr /I /C:";%%~nF;" >nul
      if errorlevel 1 (
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
)

echo.
if "%ERR%"=="0" (
   echo Completato.
) else (
   echo Completato con errori.
)
exit /b %ERR%
