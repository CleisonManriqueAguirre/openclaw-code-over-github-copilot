#!/usr/bin/env python3
"""
Script to enable OpenClaw proxy configuration.
Usage: openclaw_enable.py <master_key>
"""
import json
import yaml
import sys
import os
from pathlib import Path

def main():
    if len(sys.argv) != 2:
        print("Usage: openclaw_enable.py <master_key>")
        sys.exit(1)

    master_key = sys.argv[1]
    openclaw_config_dir = Path.home() / '.config' / 'openclaw'
    config_file = openclaw_config_dir / 'config.yaml'

    # Create .config/openclaw directory if it doesn't exist
    openclaw_config_dir.mkdir(parents=True, exist_ok=True)

    # Load existing config or create empty dict
    config = {}
    if config_file.exists():
        try:
            with open(config_file, 'r') as f:
                config = yaml.safe_load(f) or {}
        except (yaml.YAMLError, IOError):
            config = {}

    # Add proxy configuration for OpenClaw
    config['api'] = {
        'base_url': 'http://localhost:4444',
        'key': master_key,
        'model': 'gpt-4',
        'fallback_model': 'claude-3-5-sonnet-20241022'
    }

    # Add OpenClaw specific settings
    config['openclaw'] = {
        'default_model': 'gpt-4',
        'streaming': True,
        'max_tokens': 4096,
        'temperature': 0.7
    }

    # Add daemon settings
    config['daemon'] = {
        'enabled': True,
        'port': 8080,
        'host': 'localhost'
    }

    # Save updated config
    with open(config_file, 'w') as f:
        yaml.dump(config, f, default_flow_style=False, indent=2)

    print('✅ Updated OpenClaw config while preserving existing configuration')
    print(f'✅ Config saved to: {config_file}')

if __name__ == '__main__':
    main()