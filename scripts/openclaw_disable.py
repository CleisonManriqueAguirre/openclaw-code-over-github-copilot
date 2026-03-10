#!/usr/bin/env python3
"""
Script to disable OpenClaw proxy configuration.
Usage: openclaw_disable.py
"""
import yaml
import sys
from pathlib import Path

def main():
    openclaw_config_dir = Path.home() / '.config' / 'openclaw'
    config_file = openclaw_config_dir / 'config.yaml'

    if not config_file.exists():
        print('✅ No OpenClaw config file found - using defaults')
        return

    try:
        # Load current config
        with open(config_file, 'r') as f:
            config = yaml.safe_load(f) or {}

        # Remove proxy configuration
        if 'api' in config:
            # Keep only non-proxy settings
            api_config = config.get('api', {})
            if 'base_url' in api_config and 'localhost:4444' in api_config['base_url']:
                del config['api']
                print('✅ Removed proxy configuration from OpenClaw')

        # Disable daemon if it was enabled for proxy
        if 'daemon' in config:
            config['daemon']['enabled'] = False
            print('✅ Disabled OpenClaw daemon')

        # Restore default OpenClaw settings
        if 'openclaw' in config:
            config['openclaw'] = {
                'default_model': 'gpt-4',
                'streaming': True,
                'max_tokens': 4096,
                'temperature': 0.7
            }

        # Save updated config
        with open(config_file, 'w') as f:
            yaml.dump(config, f, default_flow_style=False, indent=2)

        print('✅ Restored OpenClaw to default configuration')

    except Exception as e:
        print(f'❌ Error updating OpenClaw config: {e}')
        sys.exit(1)

if __name__ == '__main__':
    main()