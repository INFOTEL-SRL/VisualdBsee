@echo off

cls

echo Imposta variabili d'ambiente
echo per compilazione libreria Visual dBsee
echo.
echo Toolchain corrente rilevata: Alaska Xbase++ 2.00.2598
echo Ricordarsi di impostare Alaska Xbase prima di lanciare questo .BAT
echo.

pause

set VDBLIB_MAINDIR=%CD%\libreria
set path=%VDBLIB_MAINDIR%\uti;%path%
set include=%VDBLIB_MAINDIR%\INCLUDE;%include%
set include=%VDBLIB_MAINDIR%\SRC\EXTRA_CH;%include%
set lib=%VDBLIB_MAINDIR%\output\lib200-2598\rel;%lib%

echo Ambiente impostato correttamente su %VDBLIB_MAINDIR%

if not exist "%CD%\ide\Lib200-2598" mkdir "%CD%\ide\Lib200-2598"
if not exist "%CD%\ide\Lib200-2598\omf" mkdir "%CD%\ide\Lib200-2598\omf"

cd libreria\src\

call gotutto200-2598.bat
if errorlevel 1 goto exit

copy ..\..\libreria\output\lib200-2598\rel     ..\..\ide\Lib200-2598
copy ..\..\libreria\output\lib200-2598\rel\omf ..\..\ide\Lib200-2598\omf

:exit
