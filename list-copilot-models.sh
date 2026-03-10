#!/bin/bash

# Script to list GitHub Copilot models in copilot-config.yaml format
# Usage: ./list-copilot-models.sh [--enabled-only]

set -e

GITHUB_TOKEN_FILE="$HOME/.config/litellm/github_copilot/access-token"
ENABLED_ONLY=false

# Parse arguments
if [[ "$1" == "--enabled-only" ]]; then
    ENABLED_ONLY=true
fi

# Check if GitHub token exists
if [[ ! -f "$GITHUB_TOKEN_FILE" ]]; then
    echo "❌ GitHub Copilot token not found at $GITHUB_TOKEN_FILE"
    echo "   Run 'make start' first to authenticate with GitHub"
    exit 1
fi

# Read the token (strip any whitespace)
GITHUB_TOKEN=$(cat "$GITHUB_TOKEN_FILE" | tr -d '\n\r ')

echo "# GitHub Copilot Models Available for OpenClaw"
echo "# Generated on $(date)"
echo "# Usage: Copy the desired models to your copilot-config.yaml"
echo ""

# Fetch models and format for YAML
if [[ "$ENABLED_ONLY" == "true" ]]; then
    echo "# Showing only enabled models"
    FILTER='select(.policy.state == "enabled" or .policy == null)'
else
    echo "# Showing all models (enabled and unconfigured)"
    FILTER='.'
fi

echo ""
echo "model_list:"

curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.githubcopilot.com/models | \
jq -r '.data[] | select(.capabilities.type == "chat") | '"$FILTER"' |
"  - model_name: " + .id + "
    litellm_params:
      model: github_copilot/" + .id + "
      extra_headers: {\"Editor-Version\": \"openclaw/1.0.0\", \"Copilot-Integration-Id\": \"openclaw-chat\"}
    # " + .name + " (" + .vendor + ") - " + (.policy.state // "enabled") + "
    # Max tokens: " + (.capabilities.limits.max_output_tokens | tostring) + ", Context: " + (.capabilities.limits.max_context_window_tokens | tostring) + "
"'

echo ""
echo "# To use these models with OpenClaw:"
echo "# 1. Copy desired model entries to your copilot-config.yaml"
echo "# 2. Restart LiteLLM: make stop && make start"
echo "# 3. Test with: make test"
echo "# 4. Configure OpenClaw: make openclaw-enable"