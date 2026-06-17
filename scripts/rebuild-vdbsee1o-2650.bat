@echo off
setlocal EnableDelayedExpansion
REM Forza rebuild VDBSEE1O.DLL (BASE: ddWin, DDFILE, DBLOOK, PG...)
REM Richiede: prompt Alaska Xbase++ 2.00.2650 (xppload nel PATH).

cd /d "%~dp0.."
call "%~dp0set-vdbsee-build-env.bat"
if errorlevel 1 exit /b 1

set "REL=%VDBLIB_MAINDIR%\output\lib200-2650\rel"
set "SRC=%VDBLIB_MAINDIR%\src"

cd /d "%SRC%"

echo Pulizia artefatti VDBSEE1O / rel\obj (link DLL da rifare)...
if exist "%REL%\VDBSEE1O.DLL" del /q "%REL%\VDBSEE1O.DLL"
if exist "%REL%\VDBSEE1O.lib" del /q "%REL%\VDBSEE1O.lib"
if exist "%REL%\VDBSEE1O.def" del /q "%REL%\VDBSEE1O.def"
if exist "%REL%\VDBSEE1O.exp" del /q "%REL%\VDBSEE1O.exp"
if exist "%REL%\omf\VDBSEE1O.lib" del /q "%REL%\omf\VDBSEE1O.lib"
if exist "%REL%\omf\VDBSEE1O.exp" del /q "%REL%\omf\VDBSEE1O.exp"
if exist "%REL%\obj" del /q "%REL%\obj\*.obj" 2>nul
if exist "%SRC%\obj" del /q "%SRC%\obj\*.obj" 2>nul

echo.
echo Avvio gotutto200-2650.bat /DYNAMIC ...
call gotutto200-2650.bat /DYNAMIC
set "RC=!ERRORLEVEL!"

if not "!RC!"=="0" (
   echo.
   echo ERRORE build DYNAMIC — controlla %SRC%\log.log o %REL%\log.log
   exit /b !RC!
)

if exist "%REL%\log.log" copy /Y "%REL%\log.log" "%SRC%\log-dynamic-2650.txt" >nul

if not exist "%REL%\VDBSEE1O.DLL" (
   echo ERRORE: VDBSEE1O.DLL non generata in %REL%
   exit /b 1
)

echo.
echo OK — verifica date DLL:
dir /T:W "%REL%\VDBSEE1O.DLL" "%REL%\VDBSEE1S.DLL" 2>nul
echo.
echo Poi copia verso il progetto host:
echo   scripts\copy-build-artifacts.bat lib200-2650 ^<dst-dll^> ^<dst-lib^>
exit /b 0
