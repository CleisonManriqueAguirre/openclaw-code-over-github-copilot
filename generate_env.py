#!/usr/bin/env python3
import uuid
import os

# Generate unique keys
master_key = f"litellm-openclaw-{uuid.uuid4()}"
salt_key = f"litellm-salt-{uuid.uuid4()}"

# Create .env file
with open('.env', 'w') as f:
    f.write(f'LITELLM_MASTER_KEY={master_key}\n')
    f.write(f'LITELLM_SALT_KEY={salt_key}\n')
    f.write('ENABLE_NETWORK_MONITOR=true\n')
    f.write('LOG_LEVEL=DEBUG\n')
    f.write('OPENCLAW_API_BASE=http://localhost:4444\n')
    f.write(f'OPENCLAW_API_KEY={master_key}\n')

print(f'Master Key: {master_key}')
print(f'Salt Key: {salt_key}')
print('✓ .env file created for OpenClaw setup')