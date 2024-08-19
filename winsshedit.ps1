# Prompt for user input
$filePath = Read-Host -Prompt "config file path "

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

# Create the necessary directory
$newfile = "$hostip" + "_" + (Get-Date -Format "yyyy.MM.dd-HH.mm.ss")
New-Item -ItemType Directory -Path $newfile | Out-Null
Write-Host "$newfile directory is created and entering into it"
Set-Location -Path $newfile
Write-Host "Watching for changes in the directory... $newfile"

$excludeParams = ""
if ($null -ne $exclusions -and $exclusions.Count -gt 0) {
    $excludeParams = "-x"
    foreach ($exclude in $exclusions) {
        $excludeParams += " '$exclude'"
    }
}
# Ensure the remote command string is properly formatted
$remoteCommand = "cd $dir; zip -r $newfile.zip . $excludeParams"

# Debugging: Output the remote command to ensure it's correct
Write-Host "Executing remote command: ssh -i $key $user@$hostip `"$remoteCommand`""

# Execute the command on the remote server
ssh -i $key $user@$hostip $remoteCommand

Write-Host "Downloading $newfile.zip. This might take time, please wait..."
scp -i $key -r "${user}@${hostip}:${dir}${newfile}.zip" .
7z x "./${newfile}.zip"

Write-Host "Removing the zip file from remote"
ssh -i $key $user@$hostip "cd $dir; rm -r $newfile.zip"
Write-Host "Copy paste this line to open a remote shell."
Write-Host "ssh -i $key $user@$hostip"
Write-Host ""

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
