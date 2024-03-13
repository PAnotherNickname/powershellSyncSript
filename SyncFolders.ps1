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

function Sync-Folders {
    param (
        [string]$source,
        [string]$replica,
        [string]$logFile
    )

    function Log {
        param (
            [string]$message
        )
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp - $message"
        $logEntry | Out-File -FilePath $logFile -Append
        Write-Host $logEntry
    }

    function Copy-Files {
        param (
            [string]$source,
            [string]$destination
        )

        $files = Get-ChildItem -Path $source -File -Recurse

        foreach ($file in $files) {
            $destinationFile = $file.FullName -replace [regex]::Escape($source), $destination
            Copy-Item -Path $file.FullName -Destination $destinationFile -Force
            Log "Copied file: $($file.FullName) to $($destinationFile)"
        }
    }

    function Delete-Files {
        param (
            [string]$source,
            [string]$destination
        )

        $sourceFiles = Get-ChildItem -Path $source -File -Recurse
        $destinationFiles = Get-ChildItem -Path $destination -File -Recurse

        $filesToDelete = Compare-Object -ReferenceObject $destinationFiles -DifferenceObject $sourceFiles -Property FullName -PassThru

        foreach ($file in $filesToDelete) {
            $fileToDelete = $file.FullName -replace [regex]::Escape($destination), $source
            if (-not (Test-Path -Path $fileToDelete)) {
                Remove-Item -Path $file.FullName -Force
                Log "Deleted file: $($file.FullName)"
            }
        }
    }

    Copy-Files -source $source -destination $replica

    Delete-Files -source $source -destination $replica
}

Sync-Folders -source $sourceFolder -replica $replicaFolder -logFile $logFilePath
