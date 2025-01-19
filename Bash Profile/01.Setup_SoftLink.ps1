if ((Get-Command -Name mklink 2>&1 | Select-Object -First 1)) {
    Write-Host "The MKLINK command is available."
} else {
    Write-Host "The MKLINK command is not available on this system."
}

$env:PSExecutePath = $env:PATH
if ($env:PS_execute_path) {
    Write-Host "Environment variable PS_execute_path is set."
} elseif (-not (Get-ChildItem -Path Env:\PS_execute_path)) {
    Write-Host "Environment variable PS_execute_path is not set."
}

# Test running PowerShell script
MKLINK /D C:\a \\\100.64.0.4\a

if ($LASTEXITCODE -ne 0) {
    Write-Host "Script failed with exit code $LASTEXITCODE"
} else {
    Write-Host "Script ran successfully."
}

