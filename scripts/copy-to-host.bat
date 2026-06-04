@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

set "VARIANT=lib200-2598"
if defined VDB_BUILD_VARIANT set "VARIANT=%VDB_BUILD_VARIANT%"

if exist "%~dp0host-paths.bat" (
   call "%~dp0host-paths.bat"
) else if not defined VDB_HOST_EXE (
   echo ERRORE: path host non configurati.
   echo.
   echo   1. copy scripts\host-paths.bat.example scripts\host-paths.bat
   echo   2. Modifica VDB_HOST_EXE e VDB_HOST_LIB in host-paths.bat
   echo.
   echo Oppure imposta le variabili d'ambiente VDB_HOST_EXE e VDB_HOST_LIB, poi rilancia.
   exit /b 1
)

if not defined VDB_HOST_EXE (
   echo ERRORE: VDB_HOST_EXE non definito ^(host-paths.bat o ambiente^).
   exit /b 1
)

if not defined VDB_HOST_LIB set "VDB_HOST_LIB=%VDB_HOST_EXE%"

echo Copia rapida host:
echo   EXE/LIB runtime -^> %VDB_HOST_EXE%
if /I not "%VDB_HOST_LIB%"=="%VDB_HOST_EXE%" echo   LIB link only   -^> %VDB_HOST_LIB%
echo   variante build   -^> %VARIANT%
echo.

call "%~dp0copy-build-artifacts.bat" "%VARIANT%" "%VDB_HOST_EXE%" "%VDB_HOST_LIB%"
exit /b %ERRORLEVEL%
