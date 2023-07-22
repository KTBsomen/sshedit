# Prompt for user input
$host = Read-Host -Prompt "Host Ip"
$user = Read-Host -Prompt "Host Username"
$key = Read-Host -Prompt "Path of key file (*.pem)"
$dir = Read-Host -Prompt "Remote Directory (with / at the end)"

# Create the necessary directory
if (-Not (Test-Path -Path "$host")) {
    New-Item -ItemType Directory -Path $host | Out-Null
    Write-Host "$host directory is created and entering into it"
    Set-Location -Path $host
}
else {
    $newfile = "$host" + "_" + (Get-Date -Format "yyyy.MM.dd-HH.mm.ss")
    New-Item -ItemType Directory -Path $newfile | Out-Null
    Write-Host "$newfile directory is created and entering into it"
    Set-Location -Path $newfile
}

# Compress and download files from remote server
Write-Host "Compressing files from remote. This might take time, please wait..."
ssh -i $key $user@$host "cd $dir; zip -r $newfile.zip ."
Write-Host "Downloading $newfile.zip. This might take time, please wait..."
scp -i $key -r $user@$host:$dir$newfile.zip .
unzip $newfile.zip
Remove-Item $newfile.zip
ssh -i $key $user@$host "cd $dir; rm -r $newfile.zip"

# Prompt for editor command
$editor = Read-Host -Prompt "Favorite Editor command (without .)"

# Open the editor
Start-Process -FilePath "$editor" -ArgumentList "." -Verb RunAs

# Watch for changes and update files on the remote server
$targetDir = "."
Write-Host "Watching for changes in the directory..."
while ($true) {
    $action = (Get-ChildItem $targetDir -Recurse -Force | Where-Object { $_.LastWriteTime -ne $_.CreationTime }).Count
    if ($action -gt 0) {
        Write-Host "There is a change in the directory. Updating to the server..."
        $result = Get-Location | ForEach-Object { $_.Path.Substring(2) }
        scp -i $key $result $user@$host:$dir -Recurse
    }
    Start-Sleep -Seconds 2
}
