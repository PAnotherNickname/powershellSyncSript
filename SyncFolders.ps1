param (
    [string]$sourceFolder,
    [string]$replicaFolder,
    [string]$logFilePath,
    [switch]$help,
    [switch]$stopScript,
    [int]$interval = 0
)

if ($help) {
    Write-Host "Options:"
    Write-Host "  -sourceFolder       Specifies the path to the source folder."
    Write-Host "  -replicaFolder      Specifies the path to the replica folder."
    Write-Host "  -logFilePath        Specifies the path to the log file."
    Write-Host "  -interval           Specifies the time interval (in minutes) for script execution. If not provided, the script will run only once."
    Write-Host "  -stopScript         Stops the running SyncFolders.ps1 script."
    Write-Host "  -help               Displays this help message."
    Write-Host ""
    Write-Host "Example: SyncFolders.ps1 -sourceFolder <source folder path> -replicaFolder <replica folder path> -logFilePath <log file path>"
    Exit
}

# Function to synchronize folders
function Sync-Folders {
    param (
        [string]$source,
        [string]$replica,
        [string]$logFile
    )

    # Log function
    function Log {
        param (
            [string]$message
        )
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp - $message"
        $logEntry | Out-File -FilePath $logFile -Append
        Write-Host $logEntry
    }


    # Add separator line to the beginning of the log file
    "----------------------------------------------------------------------------------------------------------------------" | Out-File -FilePath $logFile -Append
    $timestampBegin = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestampBegin - Attempt to synchronize the folders" | Out-File -FilePath $logFile -Append
    
    # Function to copy files recursively
    function Copy-Files {
        param (
            [string]$source,
            [string]$destination
        )

        # Get list of files
        $files = Get-ChildItem -Path $source -File -Recurse

        foreach ($file in $files) {
            $destinationFile = $file.FullName -replace [regex]::Escape($source), $destination
            if (Test-Path -Path $destinationFile) {
                $sourceContent = Get-Content -Path $file.FullName -Raw
                $destinationContent = Get-Content -Path $destinationFile -Raw
                if ($sourceContent -ne $destinationContent) {
                    Copy-Item -Path $file.FullName -Destination $destinationFile -Force
                    Log "Updated file: $($file.FullName) in $($destinationFile)"
                }
            } else {
                Copy-Item -Path $file.FullName -Destination $destinationFile -Force
                Log "Copied file: $($file.FullName) to $($destinationFile)"
            }
        }
    }

    # Function to delete files recursively
    function Delete-Files {
        param (
            [string]$source,
            [string]$destination
        )

        # Get list of files
        $sourceFiles = Get-ChildItem -Path $source -File -Recurse
        $destinationFiles = Get-ChildItem -Path $destination -File -Recurse

        # Find files to delete
        $filesToDelete = Compare-Object -ReferenceObject $destinationFiles -DifferenceObject $sourceFiles -Property FullName -PassThru

        foreach ($file in $filesToDelete) {
            $fileToDelete = $file.FullName -replace [regex]::Escape($destination), $source
            if (-not (Test-Path -Path $fileToDelete)) {
                Remove-Item -Path $file.FullName -Force
                Log "Deleted file: $($file.FullName)"
            }
        }
    }

    # Copy files from source to replica
    Copy-Files -source $source -destination $replica

    # Delete files from replica that are not in source
    Delete-Files -source $source -destination $replica
}

# Check if -stopScript modifier is provided
if ($stopScript) {
    $tempFile = "$env:TEMP\SyncFolders.tmp"
    if (Test-Path $tempFile) {
        $pidToStop = Get-Content $tempFile
        if ($pidToStop -match '\d+') {
            Stop-Process -Id $pidToStop
            Write-Host "Script with PID $pidToStop has been stopped."
        }
        else {
            Write-Host "Invalid PID found in $tempFile."
        }
        Remove-Item $tempFile -Force
    }
    else {
        Write-Host "SyncFolders.tmp file not found in the temp directory."
    }
    Exit
}

# synchronize function 
Sync-Folders -source $sourceFolder -replica $replicaFolder -logFile $logFilePath


# Check if interval is specified, if yes, schedule the script execution
if ($interval -gt 0) {
    $PID | Out-File -FilePath $env:TEMP\SyncFolders.tmp
    Write-Host "Script will run at intervals of $interval minutes. Press Ctrl+C to stop."
    while ($true) {
        Start-Sleep -Seconds ($interval * 60)  
        Sync-Folders -source $sourceFolder -replica $replicaFolder -logFile $logFilePath
    }
}