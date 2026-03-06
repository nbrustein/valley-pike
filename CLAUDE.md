# CLAUDE.md

Also read AGENTS.md for coding guidelines and conventions.

## Project decisions

### JavaScript

Prefer vanilla TypeScript modules over Stimulus controllers. Keep DOM logic in pure functions that take elements as arguments — this makes them easy to unit test with jest. Wire them up from views by attaching to `window`. Stimulus is installed but not used; do not introduce it.
