@echo off
title Sakura KitchenPrint-Pro
cd /d "%~dp0"

IF NOT EXIST "app.py" (
  echo ERROR: app.py not found in:
  echo %cd%
  pause
  exit /b 1
)

python --version >nul 2>&1
IF ERRORLEVEL 1 (
  echo ERROR: Python not installed or not in PATH.
  echo.
  echo For Windows 7: install Python 3.8 ^(last version supporting Win7^):
  echo   https://www.python.org/downloads/release/python-3810/
  echo Check "Add Python to PATH" during install.
  pause
  exit /b 1
)

python -c "import flask" >nul 2>&1
IF ERRORLEVEL 1 (
  echo Installing required Python packages...
  python -m pip install --upgrade pip
  python -m pip install -r requirements.txt
  IF ERRORLEVEL 1 (
    echo.
    echo ERROR: pip install failed.
    pause
    exit /b 1
  )
)

IF NOT EXIST "C:\Program Files\Tesseract-OCR\tesseract.exe" (
  IF NOT EXIST "C:\Program Files (x86)\Tesseract-OCR\tesseract.exe" (
    echo.
    echo WARNING: Tesseract OCR not found.
    echo PDF order parsing from iPad AirPrint needs Tesseract installed.
    echo Download Tesseract for Windows from:
    echo   https://github.com/UB-Mannheim/tesseract/wiki
    echo Install to default location ^(C:\Program Files\Tesseract-OCR^).
    echo.
    echo Continuing without OCR - scanned PDFs won't be parsed.
    echo Press any key to continue anyway...
    pause >nul
  )
)

netsh advfirewall firewall add rule name="KitchenPrint IPP" dir=in action=allow protocol=TCP localport=8631 >nul 2>&1
netsh advfirewall firewall add rule name="KitchenPrint Web" dir=in action=allow protocol=TCP localport=5000 >nul 2>&1
netsh advfirewall firewall add rule name="KitchenPrint RAW9100" dir=in action=allow protocol=TCP localport=9100 >nul 2>&1
netsh advfirewall firewall add rule name="KitchenPrint mDNS" dir=in action=allow protocol=UDP localport=5353 >nul 2>&1
netsh firewall add portopening TCP 8631 "KitchenPrint IPP" ENABLE ALL >nul 2>&1
netsh firewall add portopening TCP 5000 "KitchenPrint Web" ENABLE ALL >nul 2>&1
netsh firewall add portopening TCP 9100 "KitchenPrint RAW9100" ENABLE ALL >nul 2>&1
netsh firewall add portopening UDP 5353 "KitchenPrint mDNS" ENABLE ALL >nul 2>&1

set "TESS_EXE=C:\Program Files\Tesseract-OCR\tesseract.exe"
IF NOT EXIST "%TESS_EXE%" set "TESS_EXE=C:\Program Files (x86)\Tesseract-OCR\tesseract.exe"

powershell -NoProfile -ExecutionPolicy Bypass -Command "exit 0" >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
  start "Sakura KitchenPrint-Pro Server" powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-Location -LiteralPath '%~dp0'; $env:PRINT_CAPTURE_AIRPRINT_NAME='KitchenPrintPro'; $env:PRINT_CAPTURE_USE_NATIVE_MDNS='1'; $env:TESSERACT_CMD='%TESS_EXE%'; python .\app.py"
) ELSE (
  set PRINT_CAPTURE_AIRPRINT_NAME=KitchenPrintPro
  set PRINT_CAPTURE_USE_NATIVE_MDNS=1
  set TESSERACT_CMD=%TESS_EXE%
  start "Sakura KitchenPrint-Pro Server" python app.py
)
ping -n 4 127.0.0.1 >nul 2>&1
exit /b 0
