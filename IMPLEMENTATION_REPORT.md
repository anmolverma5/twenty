# Vezpec Sales CRM implementation report

## Source baseline

- Upstream URL: `https://github.com/twentyhq/twenty.git`
- Upstream commit: `0d5ada9a466ad1bef8e0880ae1c04465b4dd9974`
- Customization branch: `company-customization`
- Full upstream Git history: preserved
- Upstream remote: preserved as `origin`

## Completed

- Cloned the complete upstream repository with its full Git history on the J: workspace.
- Verified the upstream remote, `main` commit, runtime declarations, Yarn release, Nx projects, Docker Compose topology, frontend, backend, worker, PostgreSQL, Redis, GraphQL, and enterprise-license markers.
- Created the company customization branch before product-source changes.
- Recorded the immutable upstream version in `UPSTREAM_VERSION.md`.
- Installed the exact `.nvmrc` Node release in WSL and identified a host-specific segmentation fault.
- Established and documented the dependency-install baseline in `BASELINE_BUILD.md`.

## Remaining

Product customization, schema work, automations, dashboard expansion, security audit, migrations, and end-to-end verification remain in progress. Dependency caches and temporary files are being kept on the J:-backed WSL filesystem so the constrained host C: drive is not used. Docker remains an optional deployment target; the development baseline uses native PostgreSQL, Redis, server, worker, and frontend processes. No unverified feature is represented as complete.

## Licensing

The upstream `LICENSE`, copyright notices, Git history, and files marked `/* @license Enterprise */` remain intact. No commercial-license bypass or attribution removal has been performed.
