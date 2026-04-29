@echo off
setlocal

if not defined XPPREL set "XPPREL="
set "SCRIPT_DIR=%~dp0"

echo [pgupsize] START build (Xbase++ 2.00.2598)
pushd "%SCRIPT_DIR%"
pbuild "pgUpsizeExe.xpj" %1 %2 %3
if errorlevel 1 (
  popd
  echo [pgupsize] FAIL build
  exit /b 1
)
popd

echo [pgupsize] OK build: ..\..\..\output\lib200-2598\rel\pgupsize.exe
exit /b 0
