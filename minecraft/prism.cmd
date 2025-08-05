@echo off
setlocal

:: Cross-platform launcher script for MineSimons Repository Update
:: Detects OS and runs the appropriate script

echo MineSimons Cross-Platform Launcher
echo Detecting operating system...

:: Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

:: Windows detected - run prism.bat
echo Windows detected - launching prism.bat

set "BAT_PATH=%SCRIPT_DIR%prism.bat"

if exist "%BAT_PATH%" (
    call "%BAT_PATH%"
) else (
    echo Error: prism.bat not found in %SCRIPT_DIR%
    pause
    exit /b 1
)