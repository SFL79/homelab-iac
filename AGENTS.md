# Agent guidance for homelab-iac

`AGENTS.md` is the canonical instruction file. `CLAUDE.md` is only a compatibility shim; edit only `AGENTS.md`.

This repository is mirrored publicly to GitHub at github.com/SFL79/homelab-iac.
Never commit plaintext secrets. All credentials must go through External Secrets Operator → Vault.
If a manifest needs a sensitive value, create an ExternalSecret (see k8s/platform/ai-stack/ for examples).

To publish a new snapshot to the public mirror, run sync-to-github.ps1 from the repo root.
The script performs a secret scan before pushing and will abort if anything looks suspicious.
