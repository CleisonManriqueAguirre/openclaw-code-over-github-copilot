#!/bin/bash

# Test script for diagnosing litellm issues
set -e

echo "🔍 Diagnosing LiteLLM setup..."

# Check if .env file exists and has the required keys
if [[ ! -f .env ]]; then
    echo "❌ .env file not found!"
    exit 1
fi

echo "✅ .env file found"

# Check if master key is set
MASTER_KEY=$(grep LITELLM_MASTER_KEY .env | cut -d'=' -f2 | tr -d '"' | tr -d "'")
if [[ -z "$MASTER_KEY" ]]; then
    echo "❌ LITELLM_MASTER_KEY not found in .env"
    exit 1
fi

echo "✅ Master key found: ${MASTER_KEY:0:20}..."

# Check if virtual environment exists
if [[ ! -d openclaw-env ]]; then
    echo "❌ Virtual environment 'openclaw-env' not found!"
    echo "   Run 'make setup' first"
    exit 1
fi

echo "✅ Virtual environment found"

# Check if litellm is installed
if ! ./openclaw-env/bin/python -c "import litellm" 2>/dev/null; then
    echo "❌ LiteLLM not installed in virtual environment"
    echo "   Run 'make setup' first"
    exit 1
fi

echo "✅ LiteLLM installed"

# Test configuration file parsing
echo "🔍 Testing configuration file..."
if ! ./openclaw-env/bin/python -c "
import yaml
import os

# Load environment variables
with open('.env') as f:
    for line in f:
        if '=' in line and not line.startswith('#'):
            key, value = line.strip().split('=', 1)
            os.environ[key] = value.strip('\"').strip(\"'\")

# Test config loading
with open('test-config.yaml') as f:
    config = yaml.safe_load(f)

# Substitute environment variables
import re
def substitute_env(obj):
    if isinstance(obj, dict):
        return {k: substitute_env(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [substitute_env(item) for item in obj]
    elif isinstance(obj, str) and obj.startswith('\${') and obj.endswith('}'):
        env_var = obj[2:-1]
        return os.environ.get(env_var, obj)
    return obj

config = substitute_env(config)
print('✅ Configuration file is valid')
print(f'Master key resolved to: {config[\"general_settings\"][\"master_key\"][:20]}...')
" 2>/dev/null; then
    echo "❌ Configuration file has issues"
    exit 1
fi

echo "✅ Configuration file is valid"

# Try to start litellm on a different port for testing
echo "🚀 Starting test LiteLLM server on port 4445..."
echo "   (This won't interfere with your current setup)"

# Export environment variables
export $(grep -v '^#' .env | xargs)

# Start litellm in background
./openclaw-env/bin/litellm --config test-config.yaml --port 4445 &
LITELLM_PID=$!

# Wait for server to start
echo "⏳ Waiting for server to start..."
for i in {1..30}; do
    if curl -s http://localhost:4445/health >/dev/null 2>&1; then
        echo "✅ Test server started successfully"
        break
    fi
    if [[ $i -eq 30 ]]; then
        echo "❌ Test server failed to start within 30 seconds"
        kill $LITELLM_PID 2>/dev/null || true
        exit 1
    fi
    sleep 1
done

# Test API endpoint
echo "🧪 Testing API endpoint..."
RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" -X POST http://localhost:4445/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MASTER_KEY" \
    -d '{
        "model": "gpt-4",
        "messages": [{"role": "user", "content": "Hello, this is a test"}],
        "max_tokens": 10
    }')

HTTP_CODE=$(echo "$RESPONSE" | grep -o 'HTTP_CODE:[0-9]*' | cut -d':' -f2)
RESPONSE_BODY=$(echo "$RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

echo "📊 Response code: $HTTP_CODE"

if [[ "$HTTP_CODE" == "200" ]]; then
    echo "✅ API test successful!"
    echo "📝 Response: $RESPONSE_BODY" | head -c 200
elif [[ "$HTTP_CODE" == "400" ]]; then
    echo "❌ API test failed with 400 Bad Request"
    echo "📝 Error details: $RESPONSE_BODY"
    echo ""
    echo "🔧 This suggests an authentication or request format issue"
else
    echo "⚠️  API test returned code: $HTTP_CODE"
    echo "📝 Response: $RESPONSE_BODY"
fi

# Cleanup
echo "🧹 Cleaning up test server..."
kill $LITELLM_PID 2>/dev/null || true
sleep 2

echo ""
echo "🎯 Diagnosis complete!"