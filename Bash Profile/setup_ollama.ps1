<#
How to run this file? Use Powershell and run the following:

irm https://github.com/littlebearz/Linux-Server-Administration/raw/refs/heads/master/Bash%20Profile/setup_ollama.ps1 | iex

1.Download From Github
2.Put Files in correct location
#>
$scriptFolderPath = "C:\Users\$env:USERNAME\Scripts"

if (Test-Path -Path $folderPath) {
    Write-Output "Folder already exists: $scriptFolderPath"
} else {
    New-Item -ItemType Directory -Path $scriptFolderPath
    Write-Output "Folder created: $scriptFolderPath"
}

Write-Host "The folder 'C:\Users\$env:USERNAME\Scripts' has been created."
Invoke-WebRequest -Uri https://github.com/littlebearz/Linux-Server-Administration/raw/refs/heads/master/Bash%20Profile/ollama-remote.ps1 -OutFile C:\Users\$env:USERNAME\Scripts\ollama-remote.ps1
# Check if the ps1 file has been downloaded successfully
$ollamaRemote = "C:\Users\$env:USERNAME\Scripts\ollama-remote.ps1"
$ollamaRemoteBat= "C:\Users\$env:USERNAME\ollama-remote.bat"
if (Test-Path $file) {
    Write-Host "The file '$ollamaRemote' has been downloaded successfully."
} else {
    Write-Host "Failed to download the file '$ollamaRemote'."
}
Invoke-WebRequest -Uri https://github.com/littlebearz/Linux-Server-Administration/raw/refs/heads/master/Bash%20Profile/ollama-remote.bat -OutFile C:\Users\$env:USERNAME\ollama-remote.bat

# Check if $ollamaRemoteBat has been downloaded successfully
if (Test-Path $ollamaRemoteBat) {
    Write-Host "The file '$ollamaRemoteBat' has been downloaded successfully."
} else {
    Write-Host "Failed to download the file '$ollamaRemoteBat'."
}

# Inform the user that an alias will be set.
Write-Host "An alias will be set. Please wait..."

# Example function or command to set an alias
Set-Alias -Name ai -Value "C:\Users\$env:USERNAME\ollama-remote.bat"
# Validate that the alias is set correctly
if (Get-Alias -Name ai) {
    Write-Host "Alias 'ai' has been set successfully."
} else {
    Write-Host "Failed to set the alias 'ai'."
}
