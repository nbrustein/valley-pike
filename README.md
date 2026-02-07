# Valley Pike

## Docker dev setup

This repo is set up to run Rails in a container with Postgres. Each checkout
gets its own database container + volume (based on the directory name), so
separate copies of the repo do not interfere with each other.

### Scripts

`host-bin/` contains scripts intended to run on the host
(wrapping `docker compose`, git worktrees, etc.). `bin/` contains scripts that
are meant to run inside the container.

To run generic commands inside the container, do something like:

```
docker compose run --rm -e RAILS_ENV=test web bin/rails db:reset
```

### One-time setup

```bash
host-bin/setup
```

That script will prompt you to manage ruby via asdf. If you choose to manage ruby a different way and you are using vscode, then you will need to override vscode settings so the rubocop extension can use the correct ruby.

You will need to run this script again if:

 * gems are added or updated (you can run `bundle install` on the host and re-run)
 * Docker build inputs change (`Dockerfile`, `Dockerfile.dev`, or `docker-compose.yml`)
 * database setup changes (new migrations or reset/removed volumes)

### Run the app

```bash
docker compose up
```

Visit http://localhost:3000

### Run tests

```bash
host-bin/test
host-bin/test path/to/file_spec.rb
host-bin/test path/to/file_spec.rb:123
host-bin/test --name "example name"
host-bin/test "example name"

# direct docker invocation
docker compose run --rm web bundle exec rspec
```

## Creating an isolated copy for another branch

Use a git worktree (fast and keeps one git history) and bootstrap a fresh DB:

```bash
host-bin/new-workdir <branch-name>
```

That creates a new directory and runs `host-bin/setup` inside it. Each
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

## Editor setup (VS Code)

The repo includes recommended VS Code extensions in `.vscode/extensions.json`.
Rubocop is included to provide linting and formatting support for Ruby.
Autocorrect on save is enabled via `.vscode/settings.json`.

## Coding guidelines

Read docs/coding_guidelines.md