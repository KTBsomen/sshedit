# Prompt for user input
# File path
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
if ($serverChoice -le 1 -and $serverChoice -ge $configData.Count) {
    Write-Host "Invalid server choice. Exiting script."
    exit
}
$selectedServer = $configData[$serverChoice - 1]
$global:hostip = $selectedServer.hostip
$global:user = $selectedServer.username
$global:key = $selectedServer.pemkeyfile
$global:dir = $selectedServer.documentRoot
# Create the necessary directory

$newfile = "$hostip" + "_" + (Get-Date -Format "yyyy.MM.dd-HH.mm.ss")
New-Item -ItemType Directory -Path $newfile | Out-Null
Write-Host "$newfile directory is created and entering into it"
Set-Location -Path $newfile
Write-Host "Watching for changes in the directory... $newfile"


# Compress and download files from remote server
Write-Host "Compressing files from remote. This might take time, please wait..."
ssh -i $key $user@$hostip "cd $dir; zip -r $newfile.zip ."
Write-Host "Downloading $newfile.zip. This might take time, please wait..."
scp -i $key -r "${user}@${hostip}:${dir}${newfile}.zip" .
7z x "./${newfile}.zip"
#Remove-Item ./$newfile.zip
Write-Host "Removing the zip file from remote"

ssh -i $key $user@$hostip "cd $dir; rm -r $newfile.zip"

# Prompt for editor command
$editor = Read-Host -Prompt "Favorite Editor command (without .)"

# Open the editor
Start-Process -FilePath "$editor" -ArgumentList "$pwd" -NoNewWindow
#use with above line for elevated permissions## -Verb RunAs

# Watch for changes and update files on the remote server
$targetDir = "$pwd"

Write-Host "Watching for changes in the directory..."

### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "$pwd"
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

### DEFINE ACTIONS AFTER AN EVENT IS DETECTED
$action = {
    $path = $Event.SourceEventArgs.FullPath 
    $pathx = (Resolve-Path -Path $path -Relative).Replace(".\", "").Replace("\", "/")

    $changeType = $Event.SourceEventArgs.ChangeType
    $logline = "$(Get-Date), $changeType, $path"
    #Write-Host "printing variables $key $user $hostip"

    ###Add-content "C:\Users\somen\MOULD\sshedit\xx\log.txt" -value $logline
    if (Test-Path -Path $path -PathType Leaf) {
        #$scpCommand =  "scp -i `"$($key)`" `"$($path)`" `"$($user)@$($hostip):$($dir)$($pathx)`""

        #Write-Host "SCP Command: $scpCommand"
        
        Write-Host "There is a change in the directory $pathx. Updating to the server..."
        scp -i $key "$path" "${user}@${hostip}:${dir}${pathx}"
        Write-Host "Done updating..."
   

    }
}

### delete action
$delaction = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $logline = "$(Get-Date), $changeType, $path"
    ###Add-content "$C:\Users\somen\MOULD\sshedit\xx\log.txt" -value $logline
    if (Test-Path -Path $path -PathType Leaf) {
        Write-Host "won't deleting file $logline"
        ###ssh -i $key $user@$hostip "cd $dir; rm -r $newfile.zip"

    }
}

### rename action
$renameaction = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $logline = "$(Get-Date), $changeType, $path"
    ###Add-content "C:\Users\somen\MOULD\sshedit\xx\log.txt" -value $logline
    if (Test-Path -Path $path -PathType Leaf) {
        Write-Host "$logline"
    }
}

### DECIDE WHICH EVENTS SHOULD BE WATCHED
Register-ObjectEvent $watcher "Created" -Action $action
Register-ObjectEvent $watcher "Changed" -Action $action
Register-ObjectEvent $watcher "Deleted" -Action $action
Register-ObjectEvent $watcher "Renamed" -Action $action

while ($true) { Start-Sleep 5 }
