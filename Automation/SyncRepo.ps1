<#
.SYNOPSIS
    Syncs a GitHub repository to a local path.
    Designed for PowerShell 5.1 with logging and error handling.
#>

param(
    [string]$RepoUrl,
    [string]$TargetPath,
    [string]$LogFile
)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp - $Message"
    Add-Content -Path $LogFile -Value $entry
}

try {
    Write-Log "=== Starting GitHub sync task ==="

    # Ensure Git is available
    $gitPath = (Get-Command git.exe -ErrorAction SilentlyContinue).Source
    if (-not $gitPath) {
        throw "Git executable not found in PATH. Please install Git."
    }

    # If target path does not exist, clone repo
    if (-not (Test-Path $TargetPath)) {
        Write-Log "Target path not found. Cloning repository..."
        git clone $RepoUrl $TargetPath 2>&1 | ForEach-Object { Write-Log $_ }
    }
    else {
        Write-Log "Target path exists. Pulling latest changes..."
        Set-Location $TargetPath
        git pull 2>&1 | ForEach-Object { Write-Log $_ }
    }

    Write-Log "Sync completed successfully."
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
}
finally {
    Write-Log "=== Task finished ===`n"
}