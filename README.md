# OpenClaw Setup with LiteLLM and GitHub Copilot Models

This folder contains an automated installation and configuration setup for OpenClaw with LiteLLM proxy using GitHub Copilot models.

## Prerequisites

- **Node.js 22+**: Required for OpenClaw installation (managed via nvm)
- **Python 3.8+**: Managed via pyenv
- **pyenv**: For Python version management
- **nvm**: For Node.js version management
- **PostgreSQL**: Database backend for LiteLLM (auto-installed)

## Quick Start

1. **Setup environment and install dependencies:**
   ```bash
   make setup
   ```

2. **Install OpenClaw CLI:**
   ```bash
   make install-openclaw
   ```

3. **Configure OpenClaw with daemon and proxy:**
   ```bash
   make openclaw-enable
   ```

4. **Start the LiteLLM proxy server:**
   ```bash
   make start
   ```

5. **Test the setup:**
   ```bash
   make test
   make test-openclaw
   ```

## Available Commands

- `make help` - Show all available commands
- `make setup` - Set up virtual environment, dependencies, and PostgreSQL
- `make setup-db` - Install and configure PostgreSQL only
- `make install-openclaw` - Install OpenClaw CLI application
- `make start-db` - Start PostgreSQL database
- `make start` - Start LiteLLM proxy server (includes database startup)
- `make stop-db` - Stop PostgreSQL database
- `make stop` - Stop all running processes
- `make test` - Test the proxy connection
- `make test-openclaw` - Test OpenClaw agent functionality
- `make openclaw-enable` - Configure OpenClaw to use local proxy with daemon
- `make openclaw-disable` - Restore OpenClaw to default settings
- `make openclaw-status` - Show current OpenClaw configuration
- `make list-models` - List all GitHub Copilot models
- `make list-models-enabled` - List only enabled GitHub Copilot models

## Architecture

- **OpenClaw CLI**: Primary AI assistant client
- **LiteLLM Proxy**: Routes requests to GitHub Copilot models
- **PostgreSQL**: Database backend for LiteLLM proxy
- **GitHub Copilot**: Provides the actual model endpoints
- **OpenClaw Daemon**: Background service for enhanced functionality

## Configuration Files

- `Makefile` - Main automation commands
- `requirements.txt` - Python dependencies
- `copilot-config.yaml` - LiteLLM model configuration
- `generate_env.py` - Environment file generator
- `scripts/openclaw_enable.py` - OpenClaw proxy configuration
- `scripts/openclaw_disable.py` - Restore default settings

## Environment Variables

Generated automatically in `.env` file:
- `DATABASE_URL` - PostgreSQL connection string
- `LITELLM_MASTER_KEY` - Authentication key for proxy
- `LITELLM_SALT_KEY` - Salt for security
- `GITHUB_TOKEN` - GitHub Copilot authentication
- `OPENCLAW_API_BASE` - Local proxy endpoint
- `OPENCLAW_API_KEY` - API key for OpenClaw

## Usage Flow

1. The setup creates a Python virtual environment with pyenv
2. OpenClaw CLI is installed via the official installer
3. OpenClaw daemon is configured and started
4. LiteLLM proxy routes requests to GitHub Copilot models
5. OpenClaw communicates through the local proxy

## Model Support

Includes configurations for:
- GPT-4
- GPT-4o
- Claude 3.5 Sonnet
- o1-preview
- o1-mini

Additional models can be discovered using `make list-models`.

## Troubleshooting

- Use `make openclaw-status` to check configuration and daemon status
- Use `make test` to verify proxy connectivity
- Use `make test-openclaw` to test the complete OpenClaw agent workflow
- Check PostgreSQL status: `make start-db` or `systemctl status postgresql`
- Verify Node.js version: `nvm use 22`
- Check logs in the terminal where `make start` is running
- Use `make stop` to clean up all processes if needed

For detailed setup information, see [SETUP_GUIDE.md](./SETUP_GUIDE.md).

## Reference
https://github.com/kjetiljd/claude-code-over-github-copilot

## Test
https://youtu.be/EIWXkqn7-3o
