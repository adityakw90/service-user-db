# Docker-based Liquibase Makefile
# Uses custom Liquibase Docker image with PostgreSQL JDBC driver

# Docker image configuration
LIQUIBASE_IMAGE := liquibase-service-user:latest
LIQUIBASE_DIR := /liquibase/changes
DOCKERFILE := Dockerfile

# Environment file (default: .env)
ENV_FILE ?= .env

# Helper function to read env file values
get-env-value = $(shell grep '^$(1)=' $(ENV_FILE) | cut -d'=' -f2-)

# Base Docker command pattern
# Read environment variables from env file and pass them directly to Liquibase
DOCKER_RUN = docker run --rm \
	-v $(PWD):$(LIQUIBASE_DIR) \
	-w $(LIQUIBASE_DIR) \
	$(LIQUIBASE_IMAGE) \
	--changelog-file=master.yml \
	--url=$(call get-env-value,DATABASE_URL) \
	--username=$(call get-env-value,DATABASE_USER) \
	--password=$(call get-env-value,DATABASE_PASSWORD) 

.PHONY: help check-env build update status validate update-sql rollback-count history release-locks generate-docs

# Default target
help:
	@echo "Liquibase Docker Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make build           - Build the custom Liquibase Docker image"
	@echo "  make update          - Apply pending migrations"
	@echo "  make status          - Show migration status"
	@echo "  make validate        - Validate changelog files"
	@echo "  make update-sql      - Generate SQL without applying"
	@echo "  make rollback-count N=<number> - Rollback N changesets"
	@echo "  make history         - Show migration history"
	@echo "  make release-locks   - Release migration locks"
	@echo "  make generate-docs   - Generate documentation (outputs to docs/)"
	@echo "  make check-env       - Check if environment file exists and has required variables"
	@echo ""
	@echo "Environment file:"
	@echo "  Default: .env (can be overridden with ENV_FILE variable)"
	@echo "  Required variables in env file:"
	@echo "    DATABASE_URL         - JDBC connection URL"
	@echo "    DATABASE_USER        - Database username"
	@echo "    DATABASE_PASSWORD    - Database password"
	@echo ""
	@echo "Example usage with custom env file:"
	@echo "  make update ENV_FILE=.env.production"

# Check if environment file exists and has required variables
check-env:
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "Error: Environment file '$(ENV_FILE)' not found"; \
		echo "Create a .env file with DATABASE_URL, DATABASE_USER, and DATABASE_PASSWORD"; \
		exit 1; \
	fi
	@if ! grep -q "^DATABASE_URL=" $(ENV_FILE) || [ -z "$$(grep '^DATABASE_URL=' $(ENV_FILE) | cut -d'=' -f2)" ]; then \
		echo "Error: DATABASE_URL is not set in $(ENV_FILE)"; \
		exit 1; \
	fi
	@if ! grep -q "^DATABASE_USER=" $(ENV_FILE) || [ -z "$$(grep '^DATABASE_USER=' $(ENV_FILE) | cut -d'=' -f2)" ]; then \
		echo "Error: DATABASE_USER is not set in $(ENV_FILE)"; \
		exit 1; \
	fi
	@if ! grep -q "^DATABASE_PASSWORD=" $(ENV_FILE) || [ -z "$$(grep '^DATABASE_PASSWORD=' $(ENV_FILE) | cut -d'=' -f2)" ]; then \
		echo "Error: DATABASE_PASSWORD is not set in $(ENV_FILE)"; \
		exit 1; \
	fi
	@echo "Environment file '$(ENV_FILE)' is valid"

# Build the custom Liquibase Docker image with PostgreSQL driver
build:
	@echo "Building custom Liquibase Docker image..."
	@docker build -t $(LIQUIBASE_IMAGE) -f $(DOCKERFILE) .
	@echo "Image $(LIQUIBASE_IMAGE) built successfully"

# Apply pending migrations
update: check-env
	@$(DOCKER_RUN) update

# Show migration status
status: check-env
	@$(DOCKER_RUN) status

# Validate changelog files
validate:
	@$(DOCKER_RUN) validate

# Generate SQL without applying
update-sql: check-env
	@$(DOCKER_RUN) update-sql

# Rollback N changesets
rollback-count: check-env
	@if [ -z "$(N)" ]; then \
		echo "Error: N is not set. Usage: make rollback-count N=<number>"; \
		exit 1; \
	fi
	@$(DOCKER_RUN) rollback-count $(N)

# Show migration history
history: check-env
	@$(DOCKER_RUN) history

# Release migration locks
release-locks: check-env
	@$(DOCKER_RUN) release-locks

# Generate documentation
generate-docs: check-env
	@mkdir -p docs
	# @$(DOCKER_RUN) db-doc docs/