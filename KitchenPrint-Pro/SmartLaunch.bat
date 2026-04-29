@echo off
title Sakura KitchenPrint-Pro [%COMPUTERNAME%]
cd /d "%~dp0"

IF NOT EXIST "app.py" (
  echo ERROR: app.py not found in:
  echo %cd%
  pause
  exit /b 1
)

:: -------------------------------------------------------
:: Check Python
:: -------------------------------------------------------
python --version >nul 2>&1
IF ERRORLEVEL 1 (
  echo ERROR: Python not installed or not in PATH.
  echo.
  echo For Windows 7 / Windows Embedded Standard ^(32-bit^):
  echo   Install Python 3.8.10 32-bit:
  echo   https://www.python.org/ftp/python/3.8.10/python-3.8.10.exe
  echo.
  echo Check "Add Python to PATH" during install.
  echo IMPORTANT: Use the 32-bit installer ^(python-3.8.10.exe^) for 32-bit Windows.
  pause
  exit /b 1
)

:: -------------------------------------------------------
:: First-run auto-install: install packages if marker missing
:: -------------------------------------------------------
IF NOT EXIST "data\.installed" (
  echo.
  echo [First Run] Installing required Python packages...
  echo This only happens once. Please wait.
  echo.

  if not exist "data" mkdir data

  python -m pip install --upgrade pip
  IF ERRORLEVEL 1 (
    echo WARNING: pip upgrade failed, continuing with existing pip...
  )

  python -m pip install --only-binary :all: -r requirements.txt
  IF ERRORLEVEL 1 (
    echo.
    echo Retrying without binary-only flag ^(may take longer^)...
    python -m pip install -r requirements.txt
    IF ERRORLEVEL 1 (
      echo.
      echo ERROR: Package install failed.
      echo See RESTAURANT_PC_SETUP.txt for help.
      pause
      exit /b 1
    )
  )

  echo.
  echo [First Run] Packages installed successfully.
  echo 1 > "data\.installed"
  echo.
) ELSE (
  :: Quick sanity check - if flask import breaks, force reinstall
  python -c "import flask, win32print" >nul 2>&1
  IF ERRORLEVEL 1 (
    echo WARNING: Core packages missing. Reinstalling...
    del "data\.installed" >nul 2>&1
    python -m pip install --only-binary :all: -r requirements.txt >nul 2>&1
    IF ERRORLEVEL 1 (
      python -m pip install -r requirements.txt
    )
    echo 1 > "data\.installed"
  )
)

:: -------------------------------------------------------
:: Warn if Tesseract is missing (for PDF OCR)
:: -------------------------------------------------------
set "TESS_EXE="
IF EXIST "C:\Program Files\Tesseract-OCR\tesseract.exe" (
  set "TESS_EXE=C:\Program Files\Tesseract-OCR\tesseract.exe"
)
IF NOT DEFINED TESS_EXE (
  IF EXIST "C:\Program Files (x86)\Tesseract-OCR\tesseract.exe" (
    set "TESS_EXE=C:\Program Files (x86)\Tesseract-OCR\tesseract.exe"
  )
)
IF NOT DEFINED TESS_EXE (
  echo.
  echo WARNING: Tesseract OCR not found.
  echo   PDF order parsing requires Tesseract for image-based PDFs.
  echo   Download ^(32-bit^): https://github.com/UB-Mannheim/tesseract/wiki
  echo   Install to: C:\Program Files ^(x86^)\Tesseract-OCR
  echo.
  echo   Also recommended - Ghostscript ^(32-bit^) for better PDF rendering:
  echo   https://github.com/ArtifexSoftware/ghostpdl-downloads/releases
  echo.
  echo   See RESTAURANT_PC_SETUP.txt for full instructions.
  echo.
  echo Press any key to continue without OCR...
  pause >nul
)

:: -------------------------------------------------------
:: Open firewall ports (silent - already done on first run too)
:: -------------------------------------------------------
netsh advfirewall firewall add rule name="KitchenPrint IPP" dir=in action=allow protocol=TCP localport=8631 >nul 2>&1
netsh advfirewall firewall add rule name="KitchenPrint Web" dir=in action=allow protocol=TCP localport=5000 >nul 2>&1
netsh advfirewall firewall add rule name="KitchenPrint RAW9100" dir=in action=allow protocol=TCP localport=9100 >nul 2>&1
netsh advfirewall firewall add rule name="KitchenPrint mDNS" dir=in action=allow protocol=UDP localport=5353 >nul 2>&1
netsh firewall add portopening TCP 8631 "KitchenPrint IPP" ENABLE ALL >nul 2>&1
netsh firewall add portopening TCP 5000 "KitchenPrint Web" ENABLE ALL >nul 2>&1
netsh firewall add portopening TCP 9100 "KitchenPrint RAW9100" ENABLE ALL >nul 2>&1
netsh firewall add portopening UDP 5353 "KitchenPrint mDNS" ENABLE ALL >nul 2>&1

:: -------------------------------------------------------
:: Launch server
:: -------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -Command "exit 0" >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
  start "Sakura KitchenPrint-Pro [%COMPUTERNAME%]" powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Set-Location -LiteralPath '%~dp0'; $env:PRINT_CAPTURE_AIRPRINT_NAME='KitchenPrintPro'; $env:PRINT_CAPTURE_USE_NATIVE_MDNS='1'; if ('%TESS_EXE%' -ne '') { $env:TESSERACT_CMD='%TESS_EXE%' }; python .\app.py"
) ELSE (
  set PRINT_CAPTURE_AIRPRINT_NAME=KitchenPrintPro
  set PRINT_CAPTURE_USE_NATIVE_MDNS=1
  IF DEFINED TESS_EXE set TESSERACT_CMD=%TESS_EXE%
  start "Sakura KitchenPrint-Pro [%COMPUTERNAME%]" python app.py
)

ping -n 4 127.0.0.1 >nul 2>&1
exit /b 0
