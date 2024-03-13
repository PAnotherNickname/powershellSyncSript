param (
    [string]$sourceFolder,
    [string]$replicaFolder,
    [string]$logFilePath,
    [switch]$help
)

if ($help) {
    Write-Host "Options:"
    Write-Host "  -sourceFolder       Specifies the path to the source folder."
    Write-Host "  -replicaFolder      Specifies the path to the replica folder."
    Write-Host "  -logFilePath        Specifies the path to the log file."
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

Sync-Folders -source $sourceFolder -replica $replicaFolder -logFile $logFilePath
