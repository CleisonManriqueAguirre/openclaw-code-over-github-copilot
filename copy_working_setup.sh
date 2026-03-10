#!/bin/bash

echo "🎯 ULTIMATE SOLUTION: Copy working setup from claude-setup"
echo "========================================================"

# Check if claude-setup exists
if [[ ! -d "/home/cleison/window_to_future/claude-setup" ]]; then
    echo "❌ claude-setup directory not found"
    exit 1
fi

echo "📋 Copying working configuration from claude-setup..."

# Copy the working config
cp /home/cleison/window_to_future/claude-setup/copilot-config.yaml ./copilot-config-from-working.yaml

echo "✅ Copied working copilot-config.yaml"

# Copy the requirements to see if there's a version difference
cp /home/cleison/window_to_future/claude-setup/requirements.txt ./requirements-from-working.txt

echo "✅ Copied working requirements.txt"

echo "🔍 Checking differences:"
echo "========================"

echo "📋 Working config:"
cat copilot-config-from-working.yaml

echo ""
echo "📋 Your current config:"
cat copilot-config.yaml

echo ""
echo "📋 Working requirements:"
cat requirements-from-working.txt

echo ""
echo "📋 Your current requirements:"
cat requirements.txt

echo ""
echo "🎯 SOLUTION:"
echo "============"
echo "1. Replace your copilot-config.yaml with the working one"
echo "2. Update your Makefile to NOT set master_key"
echo "3. Use the simple configuration without authentication"