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
    winget install Git.git
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
:: Find Latest Instance Folder
:: =============================================================================
echo Searching for the most recent instance folder...
echo [DEBUG] Scanning directory: %INSTANCES_DIR%

set "latestFolder="
set "latestDate=0"
set "folderCount=0"

for /d %%I in ("%INSTANCES_DIR%\*") do (
    set /a folderCount+=1
    echo [DEBUG] Found folder: %%~nxI ^(%%~tI^)
    
    for /f "tokens=1-3 delims=/" %%a in ("%%~tI") do (
        set "folderDate=%%c%%a%%b"
        echo [DEBUG] Folder date: !folderDate! ^(comparing with: !latestDate!^)
        
        if !folderDate! gtr !latestDate! (
            set "latestDate=!folderDate!"
            set "latestFolder=%%~fI"
            echo [DEBUG] New latest folder found: %%~fI
        )
    )
)

echo [DEBUG] Total folders scanned: !folderCount!

:: =============================================================================
:: Handle No Existing Instance
:: =============================================================================
if "!latestFolder!"=="" (
    echo No instance folder found. Creating new repository...
    echo [DEBUG] Cloning repository to: %INSTANCES_DIR%\%INSTANCE_NAME%
    
    git clone "%REPO_URL%" "%INSTANCES_DIR%\%INSTANCE_NAME%"
    if errorlevel 1 (
        echo [ERROR] Failed to clone the repository. Check the URL and your connection.
        pause
        exit /b 1
    )
    
    echo [SUCCESS] Repository cloned successfully to %INSTANCES_DIR%\%INSTANCE_NAME%
    pause
    exit /b 0
)

:: =============================================================================
:: Process Existing Instance
:: =============================================================================
echo.
echo [SUCCESS] Most recent folder found: !latestFolder!
echo [DEBUG] Changing to directory: !latestFolder!

cd "!latestFolder!"
if errorlevel 1 (
    echo [ERROR] Failed to change to directory: !latestFolder!
    pause
    exit /b 1
)

:: =============================================================================
:: Handle Git Repository Issues
:: =============================================================================
echo [DEBUG] Checking if directory is a Git repository...

if not exist ".git" (
    echo Directory is not a Git repository. Initializing...
    echo [DEBUG] Initializing Git repository...
    
    git init
    if errorlevel 1 (
        echo [ERROR] Failed to initialize Git repository
        pause
        exit /b 1
    )
    
    echo [DEBUG] Adding remote origin: %REPO_URL%
    git remote add origin "%REPO_URL%"
    if errorlevel 1 (
        echo [ERROR] Failed to add remote origin
        pause
        exit /b 1
    )
    
    echo [DEBUG] Fetching from remote...
    git fetch origin
    if errorlevel 1 (
        echo [ERROR] Failed to fetch from remote
        pause
        exit /b 1
    )
    
    echo [DEBUG] Adding all files to Git...
    git add .
    
    echo [DEBUG] Attempting to checkout master branch...
    git checkout -b master origin/master
    if errorlevel 1 (
        echo [DEBUG] Master branch checkout failed, trying main branch...
        git checkout -b main origin/main
        if errorlevel 1 (
            echo [DEBUG] Main branch checkout failed, trying default branch...
            git checkout -b main origin/HEAD
            if errorlevel 1 (
                echo [ERROR] Failed to checkout any remote branch
                pause
                exit /b 1
            )
            echo [SUCCESS] Checked out default branch as main
        ) else (
            echo [SUCCESS] Checked out main branch
        )
    ) else (
        echo [SUCCESS] Checked out master branch
    )
    
    echo [SUCCESS] Repository initialized and synced
) else (
    echo [DEBUG] Directory is already a Git repository
    
    :: Check if repository is in a broken state
    git rev-parse --verify HEAD >nul 2>&1
    if errorlevel 1 (
        echo [WARNING] Repository is in an incomplete state - no initial commit found
        echo [DEBUG] Attempting to fix repository state...
        
        :: Check if remote exists
        git remote get-url origin >nul 2>&1
        if errorlevel 1 (
            echo [DEBUG] Adding remote origin: %REPO_URL%
            git remote add origin "%REPO_URL%" 2>nul
        )
        
        :: Fetch from remote
        echo [DEBUG] Fetching from remote to fix repository state...
        git fetch origin
        if errorlevel 1 (
            echo [ERROR] Failed to fetch from remote
            pause
            exit /b 1
        )
        
        :: Handle untracked files that would conflict
        echo [DEBUG] Checking for conflicting untracked files...
        
        :: Create backup directory
        set "backupDir=!latestFolder!\.git\backup_%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
        set "backupDir=!backupDir: =0!"
        echo [DEBUG] Creating backup directory: !backupDir!
        if not exist "!backupDir!" mkdir "!backupDir!"
        
        :: Add all untracked files to git first
        echo [DEBUG] Adding untracked files to Git...
        git add .
        
        :: Try to checkout a proper branch
        echo [DEBUG] Attempting to checkout master branch...
        git checkout master
        if errorlevel 1 (
            echo [DEBUG] Master branch not found, trying main branch...
            git checkout main
            if errorlevel 1 (
                echo [DEBUG] Trying to checkout origin/master with force...
                git checkout -f -b master origin/master
                if errorlevel 1 (
                    echo [DEBUG] Trying to checkout origin/main with force...
                    git checkout -f -b main origin/main
                    if errorlevel 1 (
                        echo [ERROR] Could not checkout any branch
                        pause
                        exit /b 1
                    )
                    echo [SUCCESS] Force checked out main branch
                ) else (
                    echo [SUCCESS] Force checked out master branch
                )
            ) else (
                echo [SUCCESS] Checked out main branch
            )
        ) else (
            echo [SUCCESS] Checked out master branch
        )
        echo [SUCCESS] Repository state fixed
    )
)

:: =============================================================================
:: Determine Current Branch
:: =============================================================================
echo [DEBUG] Determining current Git branch...

for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "currentBranch=%%b"

if "!currentBranch!"=="" (
    echo [ERROR] Failed to determine the current Git branch
    pause
    exit /b 1
)

if "!currentBranch!"=="HEAD" (
    echo [DEBUG] Currently in detached HEAD state, using master as default
    set "currentBranch=master"
)

echo [SUCCESS] Current branch: !currentBranch!
echo.

:: =============================================================================
:: Update Repository
:: =============================================================================
echo Updating repository from remote...
echo [DEBUG] Pulling latest changes from origin/!currentBranch!...

git pull origin "!currentBranch!"
if errorlevel 1 (
    echo [DEBUG] Pull failed, trying reset to remote branch...
    git reset --hard origin/!currentBranch!
    if errorlevel 1 (
        echo [WARNING] Could not update from remote. Manual intervention may be required.
    ) else (
        echo [SUCCESS] Repository reset to match remote
    )
) else (
    echo [SUCCESS] Pull completed successfully
)

:: =============================================================================
:: Restore Deleted Files
:: =============================================================================
echo [DEBUG] Checking for deleted tracked files...

set "deletedCount=0"
for /f "delims=" %%D in ('git ls-files -d 2^>nul') do (
    set /a deletedCount+=1
    echo Restoring deleted file: %%D
    echo [DEBUG] Restoring: %%D
    git restore --staged --worktree "%%D" 2>nul
)

if !deletedCount! gtr 0 (
    echo [SUCCESS] Restored !deletedCount! deleted file^(s^)
) else (
    echo [DEBUG] No deleted files found
)

:: =============================================================================
:: Completion
:: =============================================================================
echo.
echo ========================================
echo [SUCCESS] Update completed successfully!
echo ========================================
echo.
echo Summary:
echo - Repository: %REPO_URL%
echo - Local path: !latestFolder!
echo - Branch: !currentBranch!
echo - Deleted files restored: !deletedCount!
echo.

exit /b 0
