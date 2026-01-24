# Valley Pike

## Docker dev setup

This repo is set up to run Rails in a container with Postgres. Each checkout
gets its own database container + volume (based on the directory name), so
separate copies of the repo do not interfere with each other.

### One-time setup

```bash
bin/docker-setup
```

### Run the app

```bash
docker compose up
```

Visit http://localhost:3000

### Run tests

```bash
docker compose run --rm web bin/rails test
```

## Creating an isolated copy for another branch

Use a git worktree (fast and keeps one git history) and bootstrap a fresh DB:

```bash
bin/new-workdir <branch-name>
```

That creates a new directory and runs `bin/docker-setup` inside it. Each
worktree has its own Postgres volume, so dev/test DBs are isolated by folder.

To clean up a worktree and delete its data:

1) Stop containers and remove the DB volume from inside the worktree:

```bash
docker compose down -v
```

2) Remove the worktree directory (run from the main repo):

```bash
git worktree remove <path-to-worktree>
```
