# Simplified Makefile for OpenClaw over GitHub Copilot model endpoints

.PHONY: help setup install-openclaw start stop clean test test-openclaw verify openclaw-enable openclaw-disable openclaw-status list-models list-models-enabled setup-db start-db stop-db

PYENV_PY := $(shell pyenv which python)

# Default target
help:
	@echo "Available targets:"
	@echo "  make setup            - Set up virtual environment and dependencies (PostgreSQL optional)"
	@echo "  make install-openclaw  - Install OpenClaw CLI application"
	@echo "  make setup-db         - Install and configure PostgreSQL"
	@echo "  make start-db         - Start PostgreSQL database"
	@echo "  make start            - Start LiteLLM proxy server (no database required)"
	@echo "  make test             - Test the proxy connection"
	@echo "  make test-openclaw    - Test OpenClaw agent functionality"
	@echo "  make openclaw-enable  - Configure OpenClaw to use local proxy"
	@echo "  make openclaw-status  - Show current OpenClaw configuration"
	@echo "  make openclaw-disable - Restore OpenClaw to default settings"
	@echo "  make stop-db          - Stop PostgreSQL database"
	@echo "  make stop             - Stop running processes"
	@echo "  make list-models        - List all GitHub Copilot models"
	@echo "  make list-models-enabled - List only enabled GitHub Copilot models"

# Set up environment
setup:
	@echo "Setting up OpenClaw environment..."
	@if ! command -v pyenv >/dev/null 2>&1; then \
		echo "❌ pyenv not found. Please install pyenv first:"; \
		echo "   curl https://pyenv.run | bash"; \
		exit 1; \
	fi
	@if ! $(PYENV_PY) --version | grep -q "3\.[8-9]\|3\.[1-9][0-9]"; then \
		echo "❌ Python 3.8+ not found. Please install with:"; \
		echo "   pyenv install 3.10.12 && pyenv global 3.10.12"; \
		exit 1; \
	fi
	@echo "✓ Python version: $$($(PYENV_PY) --version)"
	@if ! command -v nvm >/dev/null 2>&1; then \
		echo "❌ nvm not found. Please install nvm first:"; \
		echo "   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"; \
		echo "   Then restart your terminal and run this command again."; \
		exit 1; \
	fi
	@echo "✓ nvm found"
	@mkdir -p scripts
	@$(PYENV_PY) -m venv openclaw-env
	@./openclaw-env/bin/pip install --upgrade pip
	@./openclaw-env/bin/pip install -r requirements.txt
	@if [ ! -f .env ]; then \
		echo "Generating .env file..."; \
		$(PYENV_PY) generate_env.py; \
	else \
		echo "✓ .env file already exists, skipping generation"; \
	fi
	@echo "✓ Basic setup complete"
	@echo ""
	@echo "🎯 OpenClaw can run without database (recommended for simple setup)"
	@echo "   Run 'make start' to start LiteLLM proxy without database"
	@echo ""
	@echo "📊 To optionally set up PostgreSQL database:"
	@echo "   Run 'make setup-db' (only if you need database features)"

# Install and configure PostgreSQL
setup-db:
	@echo "Setting up PostgreSQL..."
	@if command -v apt-get >/dev/null 2>&1; then \
		echo "Installing PostgreSQL on Ubuntu/Debian..."; \
		sudo apt-get update && sudo apt-get install -y postgresql postgresql-contrib; \
	elif command -v yum >/dev/null 2>&1; then \
		echo "Installing PostgreSQL on RHEL/CentOS..."; \
		sudo yum install -y postgresql postgresql-server postgresql-contrib; \
		sudo postgresql-setup initdb; \
	elif command -v brew >/dev/null 2>&1; then \
		echo "Installing PostgreSQL on macOS..."; \
		brew install postgresql; \
	else \
		echo "❌ Unsupported system. Please install PostgreSQL manually:"; \
		echo "   Ubuntu/Debian: sudo apt-get install postgresql postgresql-contrib"; \
		echo "   RHEL/CentOS: sudo yum install postgresql postgresql-server"; \
		echo "   macOS: brew install postgresql"; \
		exit 1; \
	fi
	@echo "✓ PostgreSQL installed"
	@echo "Starting PostgreSQL service..."
	@if command -v systemctl >/dev/null 2>&1; then \
		sudo systemctl start postgresql && sudo systemctl enable postgresql; \
	elif command -v brew >/dev/null 2>&1; then \
		brew services start postgresql; \
	else \
		echo "⚠️  Please start PostgreSQL manually"; \
	fi
	@echo "Setting up database and user..."
	@sudo -u postgres psql -c "CREATE DATABASE litellm;" 2>/dev/null || echo "Database may already exist"
	@sudo -u postgres psql -c "CREATE USER litellm_user WITH PASSWORD 'litellm_pass';" 2>/dev/null || echo "User may already exist"
	@sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE litellm TO litellm_user;" 2>/dev/null || true
	@echo "✓ Database setup complete"

# Start PostgreSQL database
start-db:
	@echo "Starting PostgreSQL database..."
	@if command -v systemctl >/dev/null 2>&1; then \
		sudo systemctl start postgresql; \
	elif command -v brew >/dev/null 2>&1; then \
		brew services start postgresql; \
	else \
		echo "⚠️  Please start PostgreSQL manually"; \
	fi
	@echo "✓ PostgreSQL started"

# Stop PostgreSQL database
stop-db:
	@echo "Stopping PostgreSQL database..."
	@if command -v systemctl >/dev/null 2>&1; then \
		sudo systemctl stop postgresql; \
	elif command -v brew >/dev/null 2>&1; then \
		brew services stop postgresql; \
	else \
		echo "⚠️  Please stop PostgreSQL manually"; \
	fi
	@echo "✓ PostgreSQL stopped"

# Install OpenClaw CLI application
install-openclaw:
	@echo "Installing OpenClaw CLI application..."
	@if ! command -v node >/dev/null 2>&1 || ! node --version | grep -q "v2[2-9]\|v[3-9]"; then \
		echo "❌ Node.js 22+ not found. Please install Node.js 22+:"; \
		echo "   https://nodejs.org/"; \
		exit 1; \
	fi
	@echo "✓ Node.js version: $$(node --version)"
	@echo "Installing OpenClaw CLI..."
	@curl -fsSL https://openclaw.ai/install.sh | bash && \
	echo "✓ OpenClaw CLI installed successfully" && \
	echo "💡 You can now run 'make openclaw-enable' to configure daemon"

# Start LiteLLM proxy (no database required)
start:
	@echo "Starting LiteLLM proxy..."
	@echo "✓ Using simple configuration (no database required)"
	@if command -v nvm >/dev/null 2>&1; then \
		echo "Setting Node.js to version 22..."; \
		. $(HOME)/.nvm/nvm.sh && nvm use 22 2>/dev/null || nvm install 22 && nvm use 22; \
	elif command -v fnm >/dev/null 2>&1; then \
		echo "Setting Node.js to version 22 with fnm..."; \
		fnm use 22 2>/dev/null || fnm install 22 && fnm use 22; \
	elif command -v n >/dev/null 2>&1; then \
		echo "Setting Node.js to version 22 with n..."; \
		n 22; \
	else \
		echo "⚠️  No Node version manager found. Ensure Node.js 22+ is installed."; \
		node --version 2>/dev/null || echo "❌ Node.js not found!"; \
	fi
	@echo "✓ Node.js version: $$(node --version 2>/dev/null || echo 'Not found')"
	@echo "Starting LiteLLM proxy (simple configuration, no database)..."
	@. openclaw-env/bin/activate && litellm --config copilot-config-no-db.yaml --port 4444

# Stop running processes
stop:
	@echo "Stopping processes..."
	@pkill -f litellm 2>/dev/null || true
	@pkill -f openclaw 2>/dev/null || true
	@echo "✓ LiteLLM and OpenClaw processes stopped"
	@echo ""
	@echo "💡 To also stop PostgreSQL (if running): make stop-db"

# Test proxy connection
test:
	@echo "Testing proxy connection..."
	@curl -X POST http://localhost:4444/chat/completions \
		-H "Content-Type: application/json" \
		-H "Authorization: Bearer $$(grep LITELLM_MASTER_KEY .env | cut -d'=' -f2 | tr -d '\"')" \
		-d '{"model": "gpt-4", "messages": [{"role": "user", "content": "Hello from OpenClaw"}]}'
	@echo ""
	@echo "✅ Test completed successfully!"

# Test OpenClaw agent functionality
test-openclaw:
	@echo "Testing OpenClaw agent functionality..."
	@echo "Setting Node.js to version 22..."
	@if command -v nvm >/dev/null 2>&1; then \
		echo "Found nvm, setting Node.js to version 22..."; \
		bash -c '. $(HOME)/.nvm/nvm.sh && nvm use 22 && echo "Node.js version: $$(node --version)"'; \
	elif command -v fnm >/dev/null 2>&1; then \
		fnm use 22; \
	elif command -v n >/dev/null 2>&1; then \
		n 22; \
	else \
		echo "⚠️  No Node version manager found. Current Node.js version: $$(node --version 2>/dev/null || echo 'Not found')"; \
	fi
	@echo "Activating Python environment and testing OpenClaw agent..."
	@bash -c '. $(HOME)/.nvm/nvm.sh && nvm use 22 && . openclaw-env/bin/activate && . ./.env && openclaw agent --agent main -m "Hello, what model are you?"'
	@echo "✅ OpenClaw agent test completed!"

# Configure OpenClaw to use local proxy and install daemon
openclaw-enable:
	@echo "Configuring OpenClaw with local proxy and daemon..."
	@if [ ! -f .env ]; then echo "❌ .env file not found. Run 'make setup' first."; exit 1; fi
	@MASTER_KEY=$$(grep LITELLM_MASTER_KEY .env | cut -d'=' -f2 | tr -d '"'); \
	if [ -z "$$MASTER_KEY" ]; then echo "❌ LITELLM_MASTER_KEY not found in .env"; exit 1; fi; \
	echo "Installing OpenClaw daemon..."; \
	openclaw onboard --install-daemon && \
	echo "Configuring OpenClaw with proxy settings..."; \
	python3 scripts/openclaw_enable.py "$$MASTER_KEY"
	@echo "✅ OpenClaw configured with daemon and local proxy"
	@echo "💡 Make sure to run 'make start' to start the LiteLLM proxy server"

# Restore OpenClaw to default settings
openclaw-disable:
	@echo "Restoring OpenClaw to default settings..."
	@python3 scripts/openclaw_disable.py
	@echo "✅ OpenClaw restored to default configuration"

# Show current OpenClaw configuration
openclaw-status:
	@echo "Current OpenClaw configuration:"
	@echo "================================="
	@echo "🔍 Checking OpenClaw daemon status..."
	@if pgrep -f "openclaw.*daemon" >/dev/null 2>&1; then \
		echo "✅ OpenClaw daemon: Running"; \
	else \
		echo "❌ OpenClaw daemon: Not running (run 'make openclaw-enable')"; \
	fi
	@echo "🔍 Checking configuration files..."
	@if [ -f ~/.config/openclaw/config.yaml ]; then \
		echo "📄 Config file: ~/.config/openclaw/config.yaml"; \
		echo ""; \
		cat ~/.config/openclaw/config.yaml 2>/dev/null || echo "❌ Cannot read config file"; \
		echo ""; \
		if grep -q "localhost:4444" ~/.config/openclaw/config.yaml 2>/dev/null; then \
			echo "🔗 Status: Using local proxy"; \
			if curl -s http://localhost:4444/health >/dev/null 2>&1; then \
				echo "✅ Proxy server: Running"; \
			else \
				echo "❌ Proxy server: Not running (run 'make start')"; \
			fi; \
		else \
			echo "🌐 Status: Using default OpenClaw servers"; \
		fi; \
	else \
		echo "📄 No config file found - using OpenClaw defaults"; \
		echo "🌐 Status: Using default OpenClaw servers"; \
	fi

# List available GitHub Copilot models
list-models:
	@echo "Listing available GitHub Copilot models..."
	@./list-copilot-models.sh

# List only enabled models
list-models-enabled:
	@echo "Listing enabled GitHub Copilot models..."
	@./list-copilot-models.sh --enabled-only