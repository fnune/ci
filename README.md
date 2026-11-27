# ci

Shared CI for my public repositories. One GitHub Action runs a repository's own command in a pinned Debian 12 container with Nix, and can publish the pushed tag as a release.

## Why

- The build environment is the same everywhere and changes only when this repository changes. Each repository pins a commit of it.
- Debian 12 sets glibc 2.36 as the floor, so binaries and AppImages built here run on systems from 2022 onward, SteamOS included.
- The runner is only the host. Nothing runs on its Ubuntu directly. The container runs under rootless podman, so it holds no more rights than the runner's own user.
- Nix builds in its sandbox, always. A build that cannot be sandboxed fails.
- The command runs as an ordinary user with the runner's own UID, as it would on a developer's machine. Tests that check file permissions or refuse root behave as they do locally.
- `/etc` holds plain files, as on a machine, with none of them mounted from outside. The runtime's bind mounts of `resolv.conf`, `hosts` and `hostname` are copied in as files, so that a tool under test can overlay `/etc` with bubblewrap.
- Like a login session, the command has an `XDG_RUNTIME_DIR` and a D-Bus session bus, which compositors and desktop apps under test expect.
- The tools are a Nix flake, so they run the same way locally, here, or under another forge.

## Use

```yaml
jobs:
  test:
    runs-on: ubuntu-26.04
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: fnune/ci@<commit>
        with:
          command: just test
          cache-paths: |
            .cache/go-build
            go/pkg/mod
          cache-key-files: "**/go.sum"
```

The command runs inside `nix develop` of the nearest `flake.nix` at or above `working-directory`, so the repository's dev shell provides its toolchain. `dev-shell` picks another of its dev shells. Run several jobs to run commands in parallel.

| Input | Default | What it does |
| --- | --- | --- |
| `command` | | The command to run. Required. |
| `dev-shell` | `default` | The flake dev shell to run the command in. Empty runs it outside Nix's dev shells. |
| `apt-packages` | | Debian packages the command needs and Nix does not provide well, such as the libraries Playwright's Chromium links against. |
| `env` | | Names of environment variables to pass into the container. |
| `kvm` | `false` | Give the container `/dev/kvm` and let Nix build derivations that need it, such as NixOS VM tests from `pkgs.testers.runNixOSTest`. |
| `cache-paths` | | Paths to keep between runs, one on each line: under the container user's home, `/home/ci`, such as `.cache/go-build`, or under `working-directory` when they start with `./`, such as `./target`. |
| `cache-key-files` | | A glob of files whose contents decide when `cache-paths` start again. A change to `flake.lock` always starts them again, because build caches such as Go's do not notice a changed toolchain. |
| `working-directory` | `.` | Where to run the command, relative to the workspace. |
| `release` | `false` | Build `tag` as a release. |
| `tag` | the pushed ref | The tag to release. |
| `release-dir` | `dist` | Where the release command puts the files to publish, relative to `working-directory`. |
| `attest` | `true` | Attest the release files with GitHub's build provenance. |
| `publish` | `true` | Publish the release. Without it, the files stay in `release-dir`. |

The Nix store is cached between runs, keyed on this repository's commit and the caller's `flake.lock`.

## Releases

A release job runs on a pushed tag:

```yaml
on:
  push:
    tags: ["v*"]

jobs:
  release:
    runs-on: ubuntu-26.04
    permissions:
      contents: write
      id-token: write
      attestations: write
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: fnune/ci@<commit>
        with:
          command: just release
          release: true
```

The action then:

1. Checks the changelog with `check-changelog release`.
2. Runs the command, which puts the files to publish in `release-dir`.
3. Writes `SHA256SUMS` next to them.
4. Attests the files, unless `attest` is `false`.
5. Publishes the release with `release-notes <tag>`. If the release already exists, as when GitHub delivers one tag push twice, its files are replaced.

Changelogs use one of two tools:

- [changie](https://changie.dev), when the repository has `.changes/`. Each change adds a fragment with `changie new`. A release runs `changie batch <version>` and `changie merge`, then tags. The check needs `.changes/<tag>.md`, no unreleased fragments, and a `CHANGELOG.md` that matches `changie merge`. The notes come from `.changes/<tag>.md`.
- [git-cliff](https://git-cliff.org), when the repository has `cliff.toml` and no `.changes/`. Commits follow Conventional Commits. A release runs `git-cliff --tag <tag> --unreleased --prepend CHANGELOG.md`, then tags. The check needs a `## [<version>]` section in `CHANGELOG.md`. The notes are git-cliff's for the commits since the previous tag, so check out with `fetch-depth: 0`.

## Tools

The flake's tools work in any CI and locally, with `nix run github:fnune/ci#<tool>`:

| Tool | What it does |
| --- | --- |
| `check-changelog fragment <base>` | Fails unless the branch adds a changie fragment since `<base>`. |
| `check-changelog release <tag>` | Fails unless the changelog is ready to release `<tag>`, with changie or git-cliff. |
| `release-notes <tag>` | Prints the notes for `<tag>`. |
| `checksums <dir>` | Writes `SHA256SUMS` for the files in `<dir>`. |
| `lint-workflows` | Runs actionlint and zizmor. A repository can override the defaults with its own `.github/actionlint.yaml` or `zizmor.yml`. |
| `scan-secrets` | Runs gitleaks over the history. |
| `publish-github <tag> <dir>` | Creates the GitHub release for `<tag>` with the files in `<dir>`, or replaces its files if it exists. |

Only `action.yml` and `publish-github` depend on GitHub.

## Developing

`nix flake check` runs everything that does not need a container:

- shellcheck and shfmt on every script, alejandra, statix and deadnix on the Nix, action-validator on `action.yml` and the workflows, and `lint-workflows`;
- the bats tests in `tests/`, one file for each tool.

The `action` job in this repository's own CI runs the action itself against `tests/fixture`: as a check, as a sandboxed build that fails if it can see the container's files, and as a release that it does not publish.

## Updating

- The Debian image is pinned by digest in `run.sh`.
- Nix is pinned by version and hash in `entry.sh`.
- The actions this one uses are pinned by commit in `action.yml`.
- The tools come from the nixpkgs in `flake.lock`.

Change any of these here, then move each repository to the new commit.
