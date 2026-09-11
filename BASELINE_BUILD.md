# Baseline build

## Upstream

- Repository: `https://github.com/twentyhq/twenty.git`
- Commit: `0d5ada9a466ad1bef8e0880ae1c04465b4dd9974`
- Branch tested: `company-customization` (no product-source changes at baseline)
- Date: `2026-09-10`

## Environment

- Upstream `.nvmrc`: Node.js `24.16.0`
- Upstream package manager: Yarn `4.13.0`
- Native Windows Node.js `24.16.0` and the vendored Yarn release both execute correctly.
- WSL Node.js `24.16.0` installs successfully but reproducibly segfaults on startup on this host.
- WSL Node.js `24.20.0` satisfies the repository's `^24.5.0` engine and executes, but WSL became unresponsive during sustained package-fetch I/O.

## Commands and results

### Clone and source verification

- Full-history `git clone https://github.com/twentyhq/twenty.git`: PASS
- `git remote -v`: PASS; `origin` remains the upstream URL.
- `git rev-parse HEAD`: PASS; `0d5ada9a466ad1bef8e0880ae1c04465b4dd9974`.
- `git branch --show-current`: PASS; changed from `main` to `company-customization` before customization.

### Dependency installation

- WSL / Node `24.16.0` / Yarn immutable install: BLOCKED by a reproducible Node segmentation fault.
- WSL / Node `24.20.0` / Yarn immutable install: resolution and peer validation completed; WSL became unresponsive during fetch.
- Windows / Node `24.16.0` / Yarn immutable install: resolution and peer validation completed; fetch failed with `ENOSPC` because Yarn's default cache and temporary extraction directories filled `C:`.

The Yarn peer-dependency warnings are emitted by the unmodified upstream lockfile and are not the cause of the failed install.

## Current blocker

The Ubuntu-J distribution is backed by `J:\WSL\Ubuntu\ext4.vhdx` and is the required execution environment because the Windows checkout cannot represent every upstream symlink and exceeds default Windows path limits. The host C: drive now has limited working space again, but it will not be used for package caches or temporary extraction.

On 2026-09-11, Windows' `WslService` entered an unresponsive state: `wsl.exe -l -v` and `wsl.exe --shutdown` both hung without output. A normal service restart and forced process termination were denied by Windows (`Cannot open WslService`; `Access is denied`). The distribution cannot be mounted until Windows restarts the service, normally by rebooting the host. After recovery, the immutable install must resume with Node.js 24.20.0 and `TMPDIR`/Yarn cache paths located inside the J:-backed Linux filesystem.

No build or test result is claimed while dependencies are incomplete.
