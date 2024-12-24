$defaultPath = Join-Path $PSScriptRoot "winssheditConfig.json"
$filePath = Read-Host -Prompt "config file path (press Enter for default: $defaultPath) "
if ([string]::IsNullOrWhiteSpace($filePath)) {
    $filePath = $defaultPath
}
# Read the content of the file
$jsonContent = Get-Content -Path $filePath -Raw

# Convert JSON content to PowerShell object
$configData = $jsonContent | ConvertFrom-Json
Write-Host "Choose a server:"
for ($i = 0; $i -lt $configData.Count; $i++) {
    Write-Host "$($i + 1). $($configData[$i].name)"
}

$serverChoice = Read-Host -Prompt "Enter the server number (1-$($configData.Count))"
if ($serverChoice -lt 1 -or $serverChoice -gt $configData.Count) {
    Write-Host "Invalid server choice. Exiting script."
    exit
}

$selectedServer = $configData[$serverChoice - 1]
$global:hostip = $selectedServer.hostip
$global:user = $selectedServer.username
$global:key = $selectedServer.pemkeyfile
$global:dir = $selectedServer.documentRoot
$exclusions = $selectedServer.exclusions
$reloadFromServer = Read-Host -Prompt "Do you want to reload files from the server? (y/n) Default: y"
if ([string]::IsNullOrWhiteSpace($reloadFromServer)) {
    $reloadFromServer = "y"
}
if ($reloadFromServer -eq "y" -or $reloadFromServer -eq "Y" -or $reloadFromServer -eq "yes" -or $reloadFromServer -eq "Yes" -or $reloadFromServer -eq "YES") {
    # Create the necessary directory
    # replace / with _in dir
    $safedir = $dir.Replace("/", "_")
    $newfile = "$hostip" + "_" + "$safedir" + "_" + (Get-Date -Format "yyyy.MM.dd-HH.mm.ss")
    New-Item -ItemType Directory -Path $newfile | Out-Null
    Write-Host "$newfile directory is created and entering into it"
    Set-Location -Path $newfile
    # Build the exclude parameters
    $excludeParams = ""
    if ($null -ne $exclusions -and $exclusions.Count -gt 0) {
        $excludeParams = "-x"
        foreach ($exclude in $exclusions) {
            # Preprocess each exclusion to ensure proper formatting
                
            $excludeParams += " '$exclude'"
        }
    }

    # Format the remote command
    $remoteCommand = "cd $dir; zip -r $newfile.zip . $excludeParams"

    # Debugging: Output the remote command to ensure it's correct
    Write-Host "Executing remote command: $remoteCommand"

    # Build the SSH command with explicit arguments
    ssh -i $key $user@$hostip $remoteCommand

    Write-Host "Downloading $newfile.zip. This might take time, please wait..."
    scp -i $key -r "${user}@${hostip}:${dir}${newfile}.zip" .
    7z x "./${newfile}.zip"

    Write-Host "Removing the zip file from remote"
    ssh -i $key $user@$hostip "cd $dir; rm -r $newfile.zip"
}
Write-Host "Copy paste this line to open a remote shell."
Write-Host "ssh -i $key $user@$hostip"
Write-Host ""



if ($reloadFromServer -notmatch '^(y|Y|yes|Yes|YES)$') {
    # Get all directories matching the pattern hostip_date
    $directories = Get-ChildItem -Directory | Where-Object { $_.Name -match "^${hostip}_.*" } | Sort-Object LastWriteTime -Descending        
    if ($directories.Count -eq 0) {
        Write-Host "No existing directories found.Try reloading from server"
        exit
    }
    
    Write-Host "Available directories for this host:"
    for ($i = 0; $i -lt $directories.Count; $i++) {
        Write-Host "$($i + 1): $($directories[$i].Name)"
    }
    
    $dirChoice = Read-Host -Prompt "Select a directory (1-$($directories.Count))"
    if ([int]$dirChoice -lt 1 -or [int]$dirChoice -gt $directories.Count) {
        Write-Host "Invalid selection"
        exit
    }
    
    $selectedDir = $directories[$dirChoice - 1].Name
    Write-Host "Backing up selected directory: $selectedDir"
    # copy and rename the selected directory
    $newDir = "Backup_of_" + "$selectedDir" + "_timestamp_" + (Get-Date -Format "yyyy.MM.dd-HH.mm.ss")

    $process = Start-Process robocopy -ArgumentList @(
        "`"$selectedDir`"",
        "`"$newDir`"",
        "/E", "/COPY:DAT", "/MT:16", "/W:0", "/R:0"
    ) -NoNewWindow -PassThru -RedirectStandardOutput ".\robocopy.log"
        
    while (!$process.HasExited) {
        if (Test-Path ".\robocopy.log") {
            $stats = Get-Content ".\robocopy.log" -Tail 1
            if ($stats -match '\s*(\d+(?:\.\d+)?)\s*%') {
                $progress = [math]::Min([math]::Max([int]$matches[1], 0), 100)
                Write-Progress -Activity "Copying files" -Status "Progress: ${progress}%" -PercentComplete $progress
            }
        }
        Start-Sleep -Milliseconds 100
    }
        
    Remove-Item ".\robocopy.log"
    Write-Progress -Activity "Backing up files" -Completed
    Write-Host "Backup completed: $newDir"
    Set-Location -Path $selectedDir
    
}
# Prompt for editor command
$editor = Read-Host -Prompt "Favorite Editor command (without .)"
Start-Process -FilePath "$editor" -ArgumentList "$pwd" -NoNewWindow

# Watch for changes and update files on the remote server
$targetDir = "$pwd"
Write-Host "Watching for changes in the directory..."

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "$pwd"
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Define a function to check if a path matches any exclusion patterns
function IsExcluded($path) {
    foreach ($pattern in $exclusions) {
        if ($path -like $pattern) {
            return $true
        }
    }
    return $false
}

$action = {
    $path = $Event.SourceEventArgs.FullPath 
    $pathx = (Resolve-Path -Path $path -Relative).Replace(".\", "").Replace("\", "/")
    $changeType = $Event.SourceEventArgs.ChangeType

    if (-not (IsExcluded $pathx)) {
        Write-Host "There is a change in the directory $pathx. Updating to the server..."
        scp -i $key "$path" "${user}@${hostip}:${dir}${pathx}"
        Write-Host "Done updating..."
    }
}

Register-ObjectEvent $watcher "Created" -Action $action
Register-ObjectEvent $watcher "Changed" -Action $action
Register-ObjectEvent $watcher "Deleted" -Action $action
Register-ObjectEvent $watcher "Renamed" -Action $action

while ($true) { Start-Sleep 5 }
