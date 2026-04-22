@echo off
title Sakura KitchenPrint-Pro
cd /d "%~dp0"

IF NOT EXIST "app.py" (
  echo ERROR: app.py not found in:
  echo %cd%
  pause
  exit /b 1
)

netsh advfirewall firewall add rule name="KitchenPrint IPP" dir=in action=allow protocol=TCP localport=8631 >nul 2>&1
netsh advfirewall firewall add rule name="KitchenPrint Web" dir=in action=allow protocol=TCP localport=5000 >nul 2>&1
netsh advfirewall firewall add rule name="KitchenPrint mDNS" dir=in action=allow protocol=UDP localport=5353 >nul 2>&1
netsh firewall add portopening TCP 8631 "KitchenPrint IPP" ENABLE ALL >nul 2>&1
netsh firewall add portopening TCP 5000 "KitchenPrint Web" ENABLE ALL >nul 2>&1
netsh firewall add portopening UDP 5353 "KitchenPrint mDNS" ENABLE ALL >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command "exit 0" >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
  start "Sakura KitchenPrint-Pro Server" powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-Location -LiteralPath '%~dp0'; $env:PRINT_CAPTURE_AIRPRINT_NAME='KitchenPrintPro'; $env:PRINT_CAPTURE_USE_NATIVE_MDNS='1'; python .\app.py"
) ELSE (
  set PRINT_CAPTURE_AIRPRINT_NAME=KitchenPrintPro
  set PRINT_CAPTURE_USE_NATIVE_MDNS=1
  start "Sakura KitchenPrint-Pro Server" python app.py
)
ping -n 4 127.0.0.1 >nul 2>&1
exit /b 0
