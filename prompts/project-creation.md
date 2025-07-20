Create a docker compose file that include postgres db with username claude and claudepassword321.
The name of the postgres container should be postgres.
Create another container in the compose file named claude that's built on top of debian slim image.
Within the claude code image install:
latest npm.
Install claude code using, npm install -g @anthropic-ai/claude-code.
Add python, pip, psql, tmux, nano and emacs to the image.
Install uv and ruff.
Create a directory called home/ in the project directory and host mount the home/ directory.
Create a directory called workspace/ in the project directory and host mount to home/workspace/.
Set the working directory to /home/claude/workspace
Find an open host port above 5432 to bind the postgres container to.
Find an open host port above 8000 to bind the claude container to.
The entrypoint of the docker image should start a tmux session named claude with claude running in it in the foreground (not detached) to keep the container alive.
