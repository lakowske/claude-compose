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

**Claude Container Setup:**

- Container named "claude" built from debian:bookworm-slim
- Install: curl, ca-certificates, tmux, nano, emacs, python3, python3.11-venv, python3-pip, postgresql-client, sudo
- Install Redis client tools: redis-tools
- Install Node.js LTS and npm via NodeSource repository
- Install claude code: `npm install -g @anthropic-ai/claude-code`
- Install Python tools: `pip3 install --break-system-packages uv ruff`
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
- Create .env file in ./workspace with postgres and redis connection information

**Networking:**

- Check for available host port above 8000 and bind claude container to it
- Add environment variables for postgres and redis connections
- Create shared network for all containers

**Docker Configuration:**

- Remove version field from docker-compose.yml
- Use CMD (not ENTRYPOINT) to start tmux in foreground: `CMD ["tmux", "new-session", "-s", "claude", "-c", "/workspace", "claude"]`
- Add restart: unless-stopped, tty: true, stdin_open: true
- Add depends_on for claude container to wait for postgres and redis

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
  - CLAUDE_HOST_PORT=[selected host port for claude container]
  - CLAUDE_INTERNAL_PORT=8000
  - POSTGRES_HOST_PORT=[selected host port for postgres]
  - REDIS_HOST_PORT=[selected host port for redis]

**Redis Configuration:**

- Enable AOF persistence for data durability
- Set reasonable memory limits and eviction policy
- Configure Redis to accept connections from all network interfaces within Docker network
- Volume persistence for Redis data directory