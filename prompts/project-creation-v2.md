Create a docker compose file that includes:

**Postgres Setup:**

- Postgres container named "postgres"
- Username: claude, Password: claudepassword321, Database: claude
- Check for available host port above 5432 and bind postgres to it

**Claude Container Setup:**

- Container named "claude" built from debian:bookworm-slim
- Install: curl, ca-certificates, tmux, nano, emacs, python3, python3-pip, postgresql-client
- Install Node.js LTS and npm via NodeSource repository
- Install claude code: `npm install -g @anthropic-ai/claude-code`
- Install Python tools: `pip3 install --break-system-packages uv ruff`
- Create directory /workspace owned by claude:claude

**Directory Structure:**

- Create directories: workspace/
- Check if ../../home exists, if not create it (shared across all versions)
- Mount ../../home to /home/claude (shared home directory)
- Mount ./workspace to /workspace (version-specific workspace)
- Set working directory to /workspace
- Copy ./prompts directory to ./workspace/prompts (making prompts available in container)
- Create .env file in ./workspace with postgres connection URL and port information

**Networking:**

- Check for available host port above 8000 and bind claude container to it
- Add environment variables for postgres connection

**Docker Configuration:**

- Remove version field from docker-compose.yml
- Use CMD (not ENTRYPOINT) to start tmux in foreground: `CMD ["tmux", "new-session", "-s", "claude", "-c", "/workspace", "claude"]`
- Add restart: unless-stopped, tty: true, stdin_open: true

**Environment File:**

- Create .env file in ./workspace directory containing:
  - DATABASE_URL=postgresql://claude:claudepassword321@postgres:5432/claude
  - POSTGRES_HOST=postgres
  - POSTGRES_PORT=5432
  - POSTGRES_USER=claude
  - POSTGRES_PASSWORD=claudepassword321
  - POSTGRES_DB=claude
  - CLAUDE_HOST_PORT=[selected host port for claude container]
  - CLAUDE_INTERNAL_PORT=8000
  - POSTGRES_HOST_PORT=[selected host port for postgres]
