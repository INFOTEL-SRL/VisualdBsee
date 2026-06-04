@echo off
xppload version

:: build dedicata per Alaska Xbase++ 2.00.2598
if not defined XPPREL set "XPPREL="
strtran _gotutto.base  _gotutto.bat rel=..\output\lib200-2598\rel   setreldate=reldate.exe defines="/d_XBASE200_" cur=%cd%\ lib="<<'XppRt0.lib'+chr(13)+chr(10)+'XppRt1.lib'+chr(13)+chr(10)+'XppUi2.lib'+chr(13)+chr(10)+'xppsys.lib'+chr(13)+chr(10)+'xppdui.lib'>>" xpprel="%XPPREL%"

:: Progetti host PG: VDBSEE1S+1O (DYNAMIC). STATIC (VDBSEE1X) opzionale: /STATIC o /FULL
if "%1" == "/DYNAMIC" goto :dynamic_only
if "%1" == "/STATIC"  goto :static_only
if "%1" == "/FULL"    goto :with_static
goto :dynamic_only

:static_only
echo "--- STATIC LIB (solo VDBSEE1X) ---"
call _gotutto.bat /STATIC %2 %3 %4
if errorlevel 1 goto exit
goto :exit

:with_static
echo "--- STATIC LIB (FULL: static + dynamic) ---"
call _gotutto.bat /STATIC %2 %3 %4
if errorlevel 1 goto exit

:dynamic_only
echo "--- DYNAMIC LIB (VDBSEE1S + VDBSEE1O) ---"
call _gotutto.bat /DYNAMIC %2 %3 %4
if errorlevel 1 goto exit
echo "--- DYNAMIC LIB ---"

:exit
del _gotutto.bat > nul
::del ..\output\lib200-2598\rel\obj\*.obj
del ..\output\lib200-2598\rel\*.def
del ..\output\lib200-2598\rel\*.exp
