@echo off

cls

echo Imposta variabili d'ambiente
echo per compilazione libreria Visual dBsee

echo.
echo Ricordarsi di impostare Alaska Xbase prima di lanciare questo .BAT
echo.

pause

set VDBLIB_MAINDIR=%CD%\libreria
set path=%VDBLIB_MAINDIR%\uti;%path%
set include=%VDBLIB_MAINDIR%\INCLUDE;%include%
set include=%VDBLIB_MAINDIR%\SRC\EXTRA_CH;%include%
set lib=%VDBLIB_MAINDIR%\output\lib200\rel;%lib%

echo Ambiente impostato correttamente su %VDBLIB_MAINDIR%

if not exist "%CD%\ide\Lib200" mkdir "%CD%\ide\Lib200"
if not exist "%CD%\ide\Lib200\omf" mkdir "%CD%\ide\Lib200\omf"
if not exist "%CD%\ide\LIB" mkdir "%CD%\ide\LIB"

cd libreria\src\

call gotutto200-832.bat

copy ..\..\libreria\output\lib200-832\rel     ..\..\ide\Lib200
copy ..\..\libreria\output\lib200-832\rel\omf ..\..\ide\Lib200\omf
copy /Y ..\..\libreria\output\lib200-832\rel\omf\DBLANG.lib   ..\..\ide\LIB >nul
copy /Y ..\..\libreria\output\lib200-832\rel\omf\VDBSEE1O.lib ..\..\ide\LIB >nul
copy /Y ..\..\libreria\output\lib200-832\rel\omf\VDBSEE1S.lib ..\..\ide\LIB >nul
