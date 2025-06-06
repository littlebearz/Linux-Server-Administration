<#
How to run this file?
irm | iex

1.Download From Github
2.Put Files in correct location
#>
New-Item -ItemType Directory -Path "C:\Users\$env:USERNAME\Scripts"
Write-Host "The folder 'C:\Users\$env:USERNAME\Scripts' has been created."
Invoke-WebRequest -Uri https://github.com/littlebearz/Linux-Server-Administration/raw/refs/heads/master/Bash%20Profile/ollama-remote.ps1 -OutFile C:\Users\$env:USERNAME\Scripts\ollama-remote.ps1
# Check if the ps1 file has been downloaded successfully
$file = "C:\Users\$env:USERNAME\Scripts\ollama-remote.ps1"
$file2= "C:\Users\$env:USERNAME\ollama-remote.bat"
if (Test-Path $file) {
    Write-Host "The file '$file' has been downloaded successfully."
} else {
    Write-Host "Failed to download the file '$file'."
}
Invoke-WebRequest -Uri https://github.com/littlebearz/Linux-Server-Administration/raw/refs/heads/master/Bash%20Profile/ollama-remote.bat -OutFile C:\Users\$env:USERNAME\ollama-remote.bat

# Check if $file2 has been downloaded successfully
if (Test-Path $file2) {
    Write-Host "The file '$file2' has been downloaded successfully."
} else {
    Write-Host "Failed to download the file '$file2'."
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
