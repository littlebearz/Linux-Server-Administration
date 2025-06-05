<#
.SYNOPSIS
    Sends a prompt to a remote Ollama server and returns a paragraph-style response.
    Automatically installs itself to %USERPROFILE%\Scripts\ on first run.

.EXAMPLE
    .\ollama-remote.ps1 "Summarize the causes of World War I."
#>

# === AUTO-INSTALL TO USER SCRIPTS ===
$targetDir = "$HOME\Scripts"
$targetFile = Join-Path $targetDir "ollama-remote.ps1"

# If script is not running from the target location, copy it there
if ($MyInvocation.MyCommand.Path -ne $targetFile) {
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $targetFile -Force
    Write-Host "`n✅ Script installed to: $targetFile"

    # Offer to update PATH if not already present
    if ($env:Path -notlike "*$targetDir*") {
        Write-Host "ℹ️ Adding '$targetDir' to your PATH for future use..."
        $newPath = "$env:Path;$targetDir"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "✅ Added to PATH. Restart terminal to use from anywhere (e.g., 'ollama-remote.ps1').`n"
    }

    Start-Sleep -Seconds 1
    Write-Host "🔁 Relaunching script from installed location...`n"
    & "$targetFile" @args
    exit
}

# === CONFIGURATION ===
$ollamaHost = "http://desktop-12900k.bear.internal:11434"   # Replace with your remote Ollama server
$model = "phi4"

# === CHECK FOR PROMPT ===
if ($args.Count -eq 0) {
    Write-Host "`nUsage: ollama-remote.ps1 `"Your prompt here`"`n"
    exit 1
}

# === GET PROMPT & TIME ===
$prompt = $args -join " "
$localTime = Get-Date -Format "dddd, MMMM dd, yyyy HH:mm:ss zzz"
$fullPrompt = "As of now, the local time is $localTime. $prompt"

# === BUILD JSON BODY ===
$body = @{
    model  = $model
    prompt = $fullPrompt
    stream = $true
} | ConvertTo-Json -Depth 2

# === MAKE REQUEST ===
try {
    $response = Invoke-RestMethod -Uri "$ollamaHost/api/generate" `
        -Method Post `
        -Body $body `
        -ContentType "application/json"
} catch {
    Write-Host "`n❌ Failed to connect to Ollama server at $ollamaHost"
    Write-Host $_.Exception.Message
    exit 1
}

# === PRINT PARAGRAPH OUTPUT ===
if ($response) {
    if ($response -is [System.Collections.IEnumerable]) {
        ($response | ForEach-Object { $_.response }) -join "" | Write-Output
    } else {
        Write-Output $response.response
    }
} else {
    Write-Host "No response received."
}
