---
name: spring-petclinic-jfrog
description: >-
  Operates Spring Petclinic CI and local scripts against JFrog Artifactory (build
  info, publish, promote), Xray (scan, build scan), Curation Audit (jf ca), and
  JFrog Advanced Security via JFrog CLI (jf audit SAST/SCA/secrets/IaC). Use when
  editing .github/workflows/jfcli-*.yml, jfrog/*.sh, Docker/Maven evidence or BPR,
  or when the user mentions Artifactory, Xray, Curation, JAS, OIDC setup-jfrog-cli,
  Frogbot, or Evidence (jf evd).
---

# Spring Petclinic — JFrog platform

## Source of truth in this repo

| Area | Location |
|------|----------|
| EntX build (Docker/Maven, curation, audit, scan, evidence) | `.github/workflows/jfcli-entX.yml` |
| EntX promote chain (BPR, Xray build scan, evidence) | `.github/workflows/jfcli-entX-bpr.yml` |
| Other pipelines | `.github/workflows/jfcli-rbv2.yml`, legacy BPR docs in `jfrog/BPR.md` |
| Runnable shell examples | `jfrog/jfcli-entX.sh`, `jfrog/jfcli-bpr.sh`, `jfrog/jfcli-evidence.sh`, `jfrog/frogbot.sh` |
| Narrative / diagrams | `jfrog/README.md`, `jfrog/AppTrust.md` |

Treat workflow `env:` blocks as the canonical **BUILD_NAME**, **PROJECT_KEY**, **JF_RT_URL**, and **repository keys** for each track (BPR vs EntX naming differs).

## Artifactory (CLI)

- Configure server context with `jf c use <server_id>` locally; CI uses `jfrog/setup-jfrog-cli@v5` with **OIDC** (`oidc-provider-name` from GitHub `vars`).
- Maven resolution/deploy through virtual repos: `jf mvnc --global --repo-resolve-releases … --repo-resolve-snapshots …` then `jf mvn …` or plain `mvn` with build metadata flags as in workflows.
- **Build info**: collect (`jf rt bce`), annotate Git (`jf rt bag`), publish (`jf rt bp`) with `--project="${PROJECT_KEY}"` when the org uses Projects.
- **Promote**: `jf rt bpr <build_name> <build_id> <target_local_repo> --project=… --status=…` (optional `--include-dependencies` for Docker track in EntX BPR).

## Xray

- **Filesystem / artifact scan**: `jf scan <path> --format=table --extended-table=true --vuln=true --fail=false --project=…`
- **Published build scan**: `jf bs <build_name> <build_id> --fail=false --format=table --extended-table=true --vuln=true --project=…`

Match flags and timeouts to existing workflow steps unless the user requests a policy change.

## Curation Audit

- **CLI**: `jf ca` — see workflow comments in `jfcli-entX.yml` (e.g. `--format=table --threads=100`, optional `--image=<registry/repo:tag>` for base images).

Official surface: [JFrog CLI — Curation](https://docs.jfrog-applications.jfrog.io/jfrog-applications/jfrog-cli/cli-for-jfrog-security/cli-for-jfrog-curation).

## JAS / JFrog Security (audit)

- **CLI**: `jf audit` with Maven context, e.g. `--mvn --sast=true --sca=true --secrets=true --licenses=true --validate-secrets=true --vuln=true` plus table output and `--fail=false` in CI where workflows use `continue-on-error`.

Official surface: [JFrog CLI — Security](https://docs.jfrog-applications.jfrog.io/jfrog-applications/jfrog-cli/cli-for-jfrog-security).

## Evidence (optional but common here)

- **CLI**: `jf evd create` with `--predicate`, `--predicate-type`, signing `--key` / `--key-alias`, and `--project`.
- Prefer reusing predicate types already present in workflows (e.g. CycloneDX SBOM path, `https://jfrog.com/evidence/…` URIs).

## MCP (Cursor)

- **Discover tools**: list JSON descriptors under the workspace `mcps/<server>/tools/*.json` (or the path shown in the product MCP file-system view).
- **Before any MCP call**: read the tool’s schema file and pass only documented arguments.
- This repository’s checked-in MCP set is defined by the IDE/project config; there is **no** guarantee of a JFrog-specific MCP server. If JFrog MCP tools exist in the user’s session, use them for read-only queries (metadata, issues) and still keep **secrets and keys out of logs** and out of committed files.

## Safety and hygiene

- Never commit plaintext private keys, OIDC tokens, or `jf config`-style credentials. CI should use GitHub **secrets** / **vars** only.
- When changing `continue-on-error` or `--fail` flags, call out the security or release impact explicitly.
- Align local scripts with workflow repository names before suggesting “copy-paste” commands.

## Further reading

- [reference.md](reference.md) — link index for JFrog docs used in workflows.
