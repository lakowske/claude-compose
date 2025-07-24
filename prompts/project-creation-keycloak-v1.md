Create a docker compose file that includes:

**Postgres Setup:**

- Postgres container named "postgres"
- Username: claude, Password: claudepassword321, Database: claude
- Check for available host port above 5432 and bind postgres to it

**Redis Setup:**

- Redis container named "redis"
- Use redis:7-alpine image for lightweight deployment
- Check for available host port above 6379 and bind redis to it
- Enable persistence with appendonly=yes
- Set maxmemory-policy=allkeys-lru for memory management
- Volume mount for Redis data persistence

**Keycloak Setup:**

- Keycloak container named "keycloak"
- Use quay.io/keycloak/keycloak:latest image
- Run in development mode with --dev flag
- Admin user: admin, Admin password: admin
- Database: Use postgres container for Keycloak database
- Create separate database "keycloak" in postgres for Keycloak
- Check for available host port above 8080 and bind keycloak to it
- Set KC_HOSTNAME_STRICT=false for development
- Set KC_HTTP_ENABLED=true for development
- Volume mount for Keycloak data persistence

**Claude Container Setup:**

- Container named "claude" built from debian:bookworm-slim
- Install: curl, ca-certificates, tmux, nano, emacs, python3, python3.11-venv, python3-pip, postgresql-client, sudo
- Install Redis client tools: redis-tools
- Install Node.js LTS and npm via NodeSource repository
- Install claude code: `npm install -g @anthropic-ai/claude-code`
- Install Python tools: `pip3 install --break-system-packages uv ruff`
- Install Flyway: Download and install Flyway Community Edition from GitHub releases
  - Use: `curl -L https://github.com/flyway/flyway/releases/download/flyway-11.10.4/flyway-commandline-11.10.4-linux-x64.tar.gz -o flyway.tar.gz`  
  - Extract: `tar -xzf flyway.tar.gz`
  - Move: `mv flyway-11.10.4 /opt/flyway`
  - Symlink: `ln -s /opt/flyway/flyway /usr/local/bin/flyway`
  - Cleanup: `rm flyway.tar.gz`
  - Note: Check https://github.com/flyway/flyway/releases for latest version number
- Create user "claude" with home directory
- Add claude user to sudo group with NOPASSWD access: `echo 'claude ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers`
- Create directory /workspace owned by claude:claude

**Directory Structure:**

- Create directories: workspace/
- Check if ../../home exists, if not create it (shared across all versions)
- Mount ../../home to /home/claude (shared home directory)
- Mount ./workspace to /workspace (version-specific workspace)
- Set working directory to /workspace
- Copy ./prompts directory to ./workspace/prompts (making prompts available in container)
- Copy ./migrations2 directory to ./workspace/migrations2 (if migrations2/ exists, making migrations available in container)
- Create .env file in ./workspace with postgres, redis, and keycloak connection information

**Networking:**

- Check for available host port above 8000 and bind claude container to it
- Add environment variables for postgres, redis, and keycloak connections
- Create shared network for all containers

**Docker Configuration:**

- Remove version field from docker-compose.yml
- Use CMD (not ENTRYPOINT) to start tmux in foreground: `CMD ["tmux", "new-session", "-s", "claude", "-c", "/workspace", "claude"]`
- Add restart: unless-stopped, tty: true, stdin_open: true
- Add depends_on for claude container to wait for postgres, redis, and keycloak

**Environment File:**

- Create .env file in ./workspace directory containing:
  - DATABASE_URL=postgresql://claude:claudepassword321@postgres:5432/claude
  - POSTGRES_HOST=postgres
  - POSTGRES_PORT=5432
  - POSTGRES_USER=claude
  - POSTGRES_PASSWORD=claudepassword321
  - POSTGRES_DB=claude
  - REDIS_URL=redis://redis:6379/0
  - REDIS_HOST=redis
  - REDIS_PORT=6379
  - REDIS_DB=0
  - KEYCLOAK_URL=http://keycloak:8080
  - KEYCLOAK_HOST=keycloak
  - KEYCLOAK_PORT=8080
  - KEYCLOAK_ADMIN_USER=admin
  - KEYCLOAK_ADMIN_PASSWORD=admin
  - KEYCLOAK_DB_URL=jdbc:postgresql://postgres:5432/keycloak
  - KEYCLOAK_DB_USERNAME=claude
  - KEYCLOAK_DB_PASSWORD=claudepassword321
  - CLAUDE_HOST_PORT=[selected host port for claude container]
  - CLAUDE_INTERNAL_PORT=8000
  - POSTGRES_HOST_PORT=[selected host port for postgres]
  - REDIS_HOST_PORT=[selected host port for redis]
  - KEYCLOAK_HOST_PORT=[selected host port for keycloak]

**Redis Configuration:**

- Enable AOF persistence for data durability
- Set reasonable memory limits and eviction policy
- Configure Redis to accept connections from all network interfaces within Docker network
- Volume persistence for Redis data directory

**Keycloak Configuration:**

- Run in development mode for easy setup and testing
- Use shared postgres database with separate keycloak database
- Enable HTTP for development (disable HTTPS requirement)
- Set hostname to be flexible for development environment
- Volume persistence for Keycloak themes and configuration