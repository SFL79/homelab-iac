# homelab-iac

Infrastructure-as-Code for my personal homelab — a 3-node bare-metal k3s cluster managed with GitOps.

> **Note:** This is a public, history-less mirror of the real repository hosted on a private Gitea instance. It is published as a single snapshot commit. The authoritative repo with full history lives on my homelab.

## Background

This started as a Docker Compose setup and evolved into a full Kubernetes environment as I wanted hands-on experience with GitOps workflows, secrets management, and cluster operations outside of a managed cloud. The goal was to run real workloads (media, AI, observability) on real hardware and deal with the operational challenges that come with it.

## Architecture

```
Gitea + Vault (Docker Compose, bare-metal)
       │
       ▼
Argo CD ──► k3s cluster
                │
    ┌───────────┼───────────┐
    │           │           │
AI Stack    Media Stack  Platform
(LiteLLM,  (Jellyfin,   (ESO, Longhorn,
 OpenWebUI,  Sonarr, etc) Traefik, Netdata)
 Langfuse)
```

- **GitOps:** Argo CD watches this repo and reconciles the cluster to match. Changes are made via git, not kubectl.
- **Networking:** Tailscale runs on every node, providing secure remote access to the homelab from anywhere without exposing any ports to the internet.
- **Secrets:** HashiCorp Vault stores all credentials. The External Secrets Operator syncs them into Kubernetes Secrets at runtime — no secrets are stored in this repository.
- **Storage:** Longhorn for persistent volumes across nodes.
- **Ingress:** Traefik with IngressRoute CRDs, exposing services on an internal `.sfl` domain via AdGuard DNS.
- **Observability:** Netdata in parent-child mode across all nodes.

## What's in this repo

| Path | Contents |
|------|----------|
| `k8s/apps/` | Argo CD Application CRDs — one per stack |
| `k8s/platform/` | Kubernetes manifests (deployments, ExternalSecrets, config) |
| `compose/` | Docker Compose stacks that run outside the cluster (Gitea, Vault) |
| `ansible/` | Named-service management for bootstrap Compose stacks via `sf-g9` |
| `nodes/` | Per-node k3s configuration files |

## Application catalog

[Homepage](https://gethomepage.dev/) discovers every user-facing `.sfl` route directly from Kubernetes. Keep catalog metadata beside the Ingress or IngressRoute so deploying an app and publishing its link remain one GitOps change.

An enabled route requires these annotations:

```yaml
gethomepage.dev/enabled: "true"
gethomepage.dev/name: Example
gethomepage.dev/description: One-line purpose
gethomepage.dev/group: Operations
gethomepage.dev/icon: example.png
gethomepage.dev/href: http://example.sfl
gethomepage.dev/siteMonitor: http://example.sfl
gethomepage.dev/weight: "10"
```

Routes with no user-facing UI must set `gethomepage.dev/enabled: "false"`. Run `validate-homepage-catalog.ps1` before committing; the public snapshot workflow runs it automatically.

## Secrets

> All credentials are managed through [External Secrets Operator](https://external-secrets.io/) backed by HashiCorp Vault. No secrets, tokens, or keys are committed to this repository.
