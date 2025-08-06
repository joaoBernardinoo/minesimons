#!/bin/bash
# =============================================================================
# Configuration
# =============================================================================
REPO_URL="https://github.com/joaoBernardinoo/minesimons.git"
INSTANCE_NAME="minesimons"
INSTANCES_DIR="$HOME/.local/share/PrismLauncher/instances"

# =============================================================================
# Main Script Start
# =============================================================================
echo "========================================"
echo "MineSimons Repository Update Script"
echo "========================================"
echo

echo "[DEBUG] Starting repository update process..."
echo "[DEBUG] Repository URL: $REPO_URL"
echo "[DEBUG] Instance Name: $INSTANCE_NAME"
echo "[DEBUG] Instances Directory: $INSTANCES_DIR"
echo

# =============================================================================
# Verify Prerequisites
# =============================================================================
echo "Checking prerequisites..."
echo "[DEBUG] Verifying Git installation..."

if ! command -v git &> /dev/null; then
    echo "[ERROR] Git is not installed or not in PATH. Please install Git and try again."
    echo
    echo "Installation options:"
    echo "1. Ubuntu/Debian: sudo apt install git"
    echo "2. CentOS/RHEL: sudo yum install git"
    echo "3. Fedora: sudo dnf install git"
    echo "4. Arch: sudo pacman -S git"
    echo "5. macOS: brew install git"
    echo
    echo "After installation, restart this script."
    exit 1
fi
echo "[SUCCESS] Git is installed and accessible"
echo

# =============================================================================
# Handle Git Repository Issues
# =============================================================================
echo "[DEBUG] Checking if directory is a Git repository..."

if [ ! -d ".git" ]; then
    echo "Directory is not a Git repository. Initializing..."
    echo "[DEBUG] Initializing Git repository..."
    git init
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to initialize Git repository"
        read -p "Press Enter to continue..."
        exit 1
    fi
    
    echo "[DEBUG] Adding remote origin: $REPO_URL"
    git remote add origin "$REPO_URL"
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to add remote origin"
        read -p "Press Enter to continue..."
        exit 1
    fi
    
    echo "[DEBUG] Fetching from remote..."
    git fetch origin
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to fetch from remote"
        read -p "Press Enter to continue..."
        exit 1
    fi
    
    echo "[DEBUG] Adding all files to Git..."
    git add .
    
    echo "[DEBUG] Attempting to checkout master branch..."
    git checkout -b master origin/master
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to checkout master branch"
        read -p "Press Enter to continue..."
        exit 1
    fi
    echo "[SUCCESS] Checked out master branch"
    
    echo "[SUCCESS] Repository initialized and synced"
else
    echo "[DEBUG] Directory is already a Git repository"
    
    # Check if repository is in a broken state
    git rev-parse --verify HEAD &> /dev/null
    if [ $? -ne 0 ]; then
        echo "[WARNING] Repository is in an incomplete state - no initial commit found"
        echo "[DEBUG] Attempting to fix repository state..."
        
        # Check if remote exists
        git remote get-url origin &> /dev/null
        if [ $? -ne 0 ]; then
            echo "[DEBUG] Adding remote origin: $REPO_URL"
            git remote add origin "$REPO_URL" 2>/dev/null
        fi
        
        # Fetch from remote
        echo "[DEBUG] Fetching from remote to fix repository state..."
        git fetch origin
        if [ $? -ne 0 ]; then
            echo "[ERROR] Failed to fetch from remote"
            read -p "Press Enter to continue..."
            exit 1
        fi
        
        # Handle untracked files that would conflict
        echo "[DEBUG] Checking for conflicting untracked files..."
        
        # Create backup directory
        backupDir="$latestFolder/.git/backup_$(date +%Y%m%d_%H%M%S)"
        echo "[DEBUG] Creating backup directory: $backupDir"
        if [ ! -d "$backupDir" ]; then
            mkdir -p "$backupDir"
        fi
        # Add all untracked files to git first
        echo "[DEBUG] Adding untracked files to Git..."
        git add .
        
        # Try to checkout a proper branch
        echo "[DEBUG] Attempting to checkout master branch..."
        git checkout master
        if [ $? -ne 0 ]; then
            echo "[DEBUG] Master branch not found, trying to checkout origin/master with force..."
            git checkout -f -b master origin/master
            if [ $? -ne 0 ]; then
                echo "[ERROR] Could not checkout master branch"
                read -p "Press Enter to continue..."
                exit 1
            fi
            echo "[SUCCESS] Force checked out master branch"
        else
            echo "[SUCCESS] Checked out master branch"
        fi
        echo "[SUCCESS] Repository state fixed"
    fi
fi
# =============================================================================
# Determine Current Branch
# =============================================================================
echo "[DEBUG] Determining current Git branch..."

currentBranch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ -z "$currentBranch" ]; then
    echo "[ERROR] Failed to determine the current Git branch"
    read -p "Press Enter to continue..."
    exit 1
fi
if [ "$currentBranch" = "HEAD" ]; then
    echo "[DEBUG] Currently in detached HEAD state, using master as default"
    currentBranch="master"
fi
echo "[SUCCESS] Current branch: $currentBranch"
echo

# =============================================================================
# Update Repository
# =============================================================================
echo "Updating repository from remote..."
echo "[DEBUG] Pulling latest changes from origin/$currentBranch..."

git pull origin "$currentBranch"
if [ $? -ne 0 ]; then
    echo "[DEBUG] Pull failed, trying reset to remote branch..."
    git reset --hard origin/$currentBranch
    if [ $? -ne 0 ]; then
        echo "[WARNING] Could not update from remote. Manual intervention may be required."
    else
        echo "[SUCCESS] Repository reset to match remote"
    fi
else
    echo "[SUCCESS] Pull completed successfully"
fi
# =============================================================================
# Restore Deleted Files
# =============================================================================
echo "[DEBUG] Checking for deleted tracked files..."

deletedCount=0
while IFS= read -r deletedFile; do
    if [ -n "$deletedFile" ]; then
        deletedCount=$((deletedCount + 1))
        echo "Restoring deleted file: $deletedFile"
        echo "[DEBUG] Restoring: $deletedFile"
        git restore --staged --worktree "$deletedFile" 2>/dev/null
    fi
done < <(git ls-files -d 2>/dev/null)

if [ "$deletedCount" -gt 0 ]; then
    echo "[SUCCESS] Restored $deletedCount deleted file(s)"
else
    echo "[DEBUG] No deleted files found"
fi
# =============================================================================
# Completion
# =============================================================================
echo
echo "========================================"
echo "[SUCCESS] Update completed successfully!"
echo "========================================"
echo
echo "Summary:"
echo "- Repository: $REPO_URL"
echo "- Local path: $latestFolder"
echo "- Branch: $currentBranch"
echo "- Deleted files restored: $deletedCount"
echo

exit 0
