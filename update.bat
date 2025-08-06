@echo off
setlocal EnableDelayedExpansion

:: =============================================================================
:: Configuration
:: =============================================================================
set "REPO_URL=https://github.com/joaoBernardinoo/minesimons.git"
set "INSTANCE_NAME=minesimons"
set "INSTANCES_DIR=%APPDATA%\PrismLauncher\instances"

:: =============================================================================
:: Main Script Start
:: =============================================================================
echo ========================================
echo MineSimons Repository Update Script
echo ========================================
echo.

echo [DEBUG] Starting repository update process...
echo [DEBUG] Repository URL: %REPO_URL%
echo [DEBUG] Instance Name: %INSTANCE_NAME%
echo [DEBUG] Instances Directory: %INSTANCES_DIR%
echo.

:: =============================================================================
:: Verify Prerequisites
:: =============================================================================
echo Checking prerequisites...
echo [DEBUG] Verifying Git installation...

git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git is not installed or not in PATH. Please install Git and try again.
    echo.
    echo Installation options:
    echo 1. Download from: https://git-scm.com/download/win
    echo 2. If you have winget: winget install Git.git
    echo 3. If you have chocolatey: choco install git
    echo 4. If you have scoop: scoop install git
    echo.
    echo After installation, restart this script.
    pause
    exit /b 1
)

echo [SUCCESS] Git is installed and accessible
echo.

:: =============================================================================
:: Ensure Directory Structure
:: =============================================================================
echo [DEBUG] Ensuring instances directory exists...

if not exist "%INSTANCES_DIR%" (
    echo [DEBUG] Creating instances directory: %INSTANCES_DIR%
    mkdir "%INSTANCES_DIR%"
    if errorlevel 1 (
        echo [ERROR] Failed to create instances directory
        pause
        exit /b 1
    )
    echo [SUCCESS] Instances directory created
) else (
    echo [DEBUG] Instances directory already exists
)
echo.

:: =============================================================================
:: Handle No Existing Instance
:: =============================================================================
echo No instance folder found. Creating new repository...
echo [DEBUG] Cloning repository to: %INSTANCES_DIR%\%INSTANCE_NAME%

git clone "%REPO_URL%" "%INSTANCES_DIR%\%INSTANCE_NAME%"
if errorlevel 1 (
    echo [ERROR] Failed to clone the repository. Check the URL and your connection.
    pause
    exit /b 1
)

echo [SUCCESS] Repository cloned successfully to %INSTANCES_DIR%\%INSTANCE_NAME%
echo.
echo.
echo Se você está vendo essa mensagem
echo passe para o próximo passo !
echo.
echo.

pause
exit /b 0
