# Agent instructions — Spring Petclinic (JFrog + MCP)

This repository ships **Spring Petclinic** with **JFrog Artifactory**, **Xray**, **Curation** (`jf ca`), **JFrog Advanced Security** (CLI `jf audit`: SAST/SCA/secrets/IaC-style checks per workflow flags), **Evidence** (`jf evd`), and **GitHub Actions** OIDC via `jfrog/setup-jfrog-cli`.

## Where to look first

1. **CI workflows**: `.github/workflows/jfcli-entX.yml` (build, curation, audit, Xray scan, Docker/Maven package, evidence) and `.github/workflows/jfcli-entX-bpr.yml` (promotions, `jf bs`, evidence).
2. **Shell examples**: `jfrog/jfcli-entX.sh`, `jfrog/jfcli-bpr.sh`, `jfrog/jfcli-evidence.sh`, `jfrog/frogbot.sh`.
3. **Human-oriented notes**: `jfrog/README.md`, `jfrog/BPR.md`, `jfrog/AppTrust.md`.

## Rules for edits

- Keep **BUILD_NAME**, **PROJECT_KEY**, **JF_RT_URL**, and **repository keys** consistent with the workflow you are modifying; BPR and EntX tracks use different virtual/local repository names.
- Do **not** embed real tokens, API keys, or private PEM material in repo files. Use GitHub **secrets** / **vars** (and local env vars) only.
- When changing security gates (`--fail`, `continue-on-error`, audit flags), state the **risk tradeoff** (noise vs blocked releases).

## MCP

- **Schema-first**: before calling any MCP tool, read that tool’s descriptor JSON (workspace `mcps/<server>/tools/`) and match argument names and types exactly.
- MCP servers available depend on the user’s Cursor configuration; this repo may include **browser** or **diagram** MCPs without JFrog MCP. If a JFrog MCP is present, prefer it for read-only platform queries; still avoid exfiltrating secrets.

## Deeper workflow skill

For a compact checklist and command mapping (Artifactory, Xray, Curation, JAS/audit, evidence, MCP hygiene), use the project skill **`spring-petclinic-jfrog`**: `.cursor/skills/spring-petclinic-jfrog/SKILL.md`.
