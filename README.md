# Valley Pike

## Docker dev setup

This repo is set up to run Rails in a container with Postgres. Each checkout
gets its own database container + volume (based on the directory name), so
separate copies of the repo do not interfere with each other.

### One-time setup

```bash
bin/docker-setup
```

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
bin/test
bin/test path/to/file_spec.rb
bin/test path/to/file_spec.rb:123
bin/test --name "example name"
bin/test "example name"

# direct docker invocation
docker compose run --rm web bundle exec rspec
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

## Editor setup (VS Code)

The repo includes recommended VS Code extensions in `.vscode/extensions.json`.
Rubocop is included to provide linting and formatting support for Ruby.
Autocorrect on save is enabled via `.vscode/settings.json`.
