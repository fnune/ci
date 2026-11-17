# Notes for agents

- Before each commit, run the `stripping-code-comments` skill on your change.
- Keep the tools in `tools/` free of GitHub. Only `action.yml`, `run.sh` and the `publish-github` tool may depend on it.
- A change to `entry.sh` or `run.sh` needs a run in the container. Run `run.sh` locally with `RUNNER_TEMP`, `GITHUB_WORKSPACE` and `COMMAND` set, on a copy of a repository.
- Nix must build in its sandbox. Do not turn on `sandbox-fallback`: with it, a missing sandbox passes silently.
- Pin every action by commit, with its version in a comment. Pin the Debian image by digest, and Nix by version and hash.
- Run `nix flake check` before committing. It lints everything and runs the bats tests.
- Give each behaviour of a tool a bats test named after it, in `tests/<tool>.bats`.
