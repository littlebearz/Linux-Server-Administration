<#
.SYNOPSIS
    Sends a prompt to a remote Ollama server and returns a paragraph-style response.

.EXAMPLE
    .\ollama-remote.ps1 "Summarize the causes of World War I."
#>

# === CONFIGURATION ===
$ollamaHost = "http://desktop-12900k.bear.internal:11434"   # Replace with your remote Ollama server
$model = "phi4"

# === CHECK FOR PROMPT ===
if ($args.Count -eq 0) {
    Write-Host "`nUsage: .\ollama-remote.ps1 `"Your prompt here`"`n"
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
    # For streamed responses, simulate paragraph
    if ($response -is [System.Collections.IEnumerable]) {
        ($response | ForEach-Object { $_.response }) -join "" | Write-Output
    } else {
        Write-Output $response.response
    }
} else {
    Write-Host "No response received."
}
