#!/bin/bash

# Configuration
OLLAMA_HOST="http://desktop-12900k.bear.internal:11434"  # Replace with your network Ollama server
MODEL="phi4"
PROMPT="$*"

# Exit if no prompt is provided
if [ -z "$PROMPT" ]; then
  echo "Usage: $0 \"Your prompt here\""
  exit 1
fi

# Get system local time
LOCAL_TIME=$(date +"%A, %B %d, %Y %H:%M:%S %Z")

# Inject local time into prompt
FULL_PROMPT="As of now, the local time is $LOCAL_TIME. $PROMPT"

# Send to Ollama and return paragraph response
RESPONSE=$(curl -sN "$OLLAMA_HOST/api/generate" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"prompt\": \"$FULL_PROMPT\",
    \"stream\": true
  }" | jq -r '.response' 2>/dev/null)

echo
echo "$RESPONSE" | tr -d '\n'
echo