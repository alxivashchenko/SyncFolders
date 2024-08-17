param (
    [string]$SourcePath,
    [string]$ReplicaPath,
    [string]$LogFilePath
)

function Log-Operation {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Output $logMessage
    Add-Content -Path $LogFilePath -Value $logMessage
}

function Sync-Folders {
    param (
        [string]$Source,
        [string]$Replica
    )

    New-Item -ItemType File -Path $logFilePath -Force | Out-Null

    if (-not (Test-Path -Path $Source)) {
        Log-Operation "Source path does not exist: $Source"
        return
    }

    if (-not (Test-Path -Path $Replica)) {
        Log-Operation "Replica path does not exist. Creating: $Replica"
        New-Item -Path $Replica -ItemType Directory | Out-Null
    }


    Get-ChildItem -Path $Source -Recurse | ForEach-Object {
        $sourceItem = $_
        $relativePath = $sourceItem.FullName.Substring($Source.Length)
        $replicaItemPath = Join-Path -Path $Replica -ChildPath $relativePath

        if ($sourceItem.PSIsContainer) {
            if (-not (Test-Path -Path $replicaItemPath)) {
                New-Item -Path $replicaItemPath -ItemType Directory | Out-Null
                Log-Operation "Created directory: $replicaItemPath"
            }
        }
        else {
            if (-not (Test-Path -Path $replicaItemPath) -or ($sourceItem.LastWriteTime -gt (Get-Item -Path $replicaItemPath).LastWriteTime)) {
                Copy-Item -Path $sourceItem.FullName -Destination $replicaItemPath -Force
                Log-Operation "Copied file: $sourceItem to $replicaItemPath"
            }
        }
    }


    Get-ChildItem -Path $Replica -Recurse | ForEach-Object {
        $replicaItem = $_
        $relativePath = $replicaItem.FullName.Substring($Replica.Length)
        $sourceItemPath = Join-Path -Path $Source -ChildPath $relativePath

        if (-not (Test-Path -Path $sourceItemPath)) {
            if ($replicaItem.PSIsContainer) {
                Remove-Item -Path $replicaItem.FullName -Recurse -Force
                Log-Operation "Removed directory: $replicaItem"
            }
            else {
                Remove-Item -Path $replicaItem.FullName -Force
                Log-Operation "Removed file: $replicaItem"
            }
        }
    }

    Log-Operation "Synchronization complete."
}

Sync-Folders -Source $SourcePath -Replica $ReplicaPath
