<#
.SYNOPSIS
    Sends a prompt to a remote Ollama server and returns a paragraph-style response.
    Automatically installs itself to %USERPROFILE%\Scripts\ on first run.

.PARAMETER Prompt
    The prompt to send to the Ollama server.

.PARAMETER DebugMode
    Enables debug output for troubleshooting.

.EXAMPLE
    .\ollama-remote.ps1 "Summarize the causes of World War I."
    .\ollama-remote.ps1 -DebugMode -Prompt "What is the current time?"
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
    [string]$Prompt,
    [switch]$DebugMode
)

$DebugPreference = if ($DebugMode) { "Continue" } else { "SilentlyContinue" }

### AUTO-INSTALL TO USER SCRIPTS
Write-Debug "Checking script installation..."
$targetDir = "$HOME\Scripts"
$targetFile = Join-Path $targetDir "ollama-remote.ps1"

if ($MyInvocation.MyCommand.Path -ne $targetFile) {
    Write-Debug "Script not in target location, installing to $targetFile"
    if (-not (Test-Path $targetDir)) {
        Write-Debug "Creating directory $targetDir"
        New-Item -ItemType Directory -Path $targetDir | Out-Null
    }

    Copy-Item -Path $MyInvocation.MyCommand.Path -Destination $targetFile -Force
    Write-Host "Info: Relaunching script from installed location..."
    $newPath = "$env:Path;$targetDir"
    Write-Debug "Updating PATH with $newPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Success: Added to PATH. Restart terminal to use from anywhere (e.g. ollama-remote.ps1)."
    Start-Sleep -Seconds 1
    Write-Debug "Relaunching script with args: $Prompt"
    & $targetFile -Prompt $Prompt -DebugMode:$DebugMode
    exit 0
}

# === CONFIGURATION ===
$ollamaHost = "http://desktop-12900k.bear.internal:11434"   # Replace with your remote Ollama server
$model = "phi4"
Write-Debug "Configuration: Host=$ollamaHost, Model=$model"

# === GET PROMPT & TIME ===
$localTime = Get-Date -Format "dddd, MMMM dd, yyyy HH:mm:ss zzz"
# For time-related prompts, return local time directly
if ($Prompt -match "(?i)\b(time|clock|hour|minute|second)\b") {
    Write-Debug "Time-related prompt detected, returning local time"
    Write-Output "The current time is $localTime." | Out-String
    exit 0
}
# Otherwise, prepend time to non-time-related prompts
$fullPrompt = "As of now, the local time is $localTime. $Prompt"
Write-Debug "Full prompt: $fullPrompt"

# === BUILD JSON BODY ===
$body = @{
    model  = $model
    prompt = $fullPrompt
    stream = $false
} | ConvertTo-Json -Depth 2
Write-Debug "JSON body: $body"

# === MAKE REQUEST ===
try {
    Write-Debug "Sending request to $ollamaHost/api/generate"
    $response = Invoke-RestMethod -Uri "$ollamaHost/api/generate" -Method Post -Body $body -ContentType "application/json"
    Write-Debug "Raw response: $($response | ConvertTo-Json -Depth 2 -ErrorAction SilentlyContinue)"
} catch {
    Write-Host "Error: Failed to connect to Ollama server at $ollamaHost"
    Write-Debug "Request error: $_"
    exit 1
}

# === PRINT PARAGRAPH OUTPUT ===
try {
    Write-Debug "Processing response..."
    if ($response) {
        Write-Debug "Response is single object"
        Write-Debug "Response.response content: $($response.response)"
        if ($response.response) {
            Write-Output $response.response.Trim() | Out-String
        } else {
            Write-Host "Error: Response.response is empty or null"
            Write-Debug "Full response: $($response | ConvertTo-Json -Depth 2 -ErrorAction SilentlyContinue)"
            exit 1
        }
    } else {
        Write-Host "Error: No response received from server"
        Write-Debug "Empty response received"
        exit 1
    }
} catch {
    Write-Host "Error processing response: $_"
    Write-Debug "Response processing error: $_"
    exit 1
}