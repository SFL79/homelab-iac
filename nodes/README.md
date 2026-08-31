# Node-Level Configuration

Configuration files for k3s nodes that live **outside** the cluster (on the host filesystem) and therefore can't be GitOps-synced by Argo CD. Tracked here in git as the source of truth; applied manually until Ansible exists.

## Layout

```
nodes/
  sf-g6/
    k3s-config.yaml      → /etc/rancher/k3s/config.yaml on sf-g6
  sf-optiplex7000/
    k3s-config.yaml      → /etc/rancher/k3s/config.yaml on sf-optiplex7000
  sf-y530/
    k3s-config.yaml      → /etc/rancher/k3s/config.yaml on sf-y530
  sf-g9/
    k3s-config.yaml      → /etc/rancher/k3s/config.yaml on sf-g9
    registries.yaml       → /etc/rancher/k3s/registries.yaml on sf-g9
```

## Apply procedure

After editing a file here, on the corresponding node:

```bash
# 1. copy the file into place
sudo install -m 0644 -D <local copy> /etc/rancher/k3s/config.yaml

# 2. restart the matching service for changes to take effect
sudo systemctl restart k3s          # control-plane nodes
sudo systemctl restart k3s-agent    # sf-g9 worker

# 3. verify rejoin from another node (Mac)
kubectl get nodes -w
```

Because this is HA k3s with embedded etcd, restart one node at a time and wait for `Ready` before moving to the next.

## Why these configs exist

- **`node-ip`** — pin k3s identity to the Ethernet IP. Without this, k3s auto-detects from the default route, which can flip to WiFi if Ethernet flaps (this caused a real incident on 2026-05-08; see `Runbooks/Recover k3s Node.md` in the Obsidian vault). sf-g6 and sf-optiplex7000 are Ethernet-only so the auto-detection is reliable, but pinning is documented anyway for plug-and-play recovery on a fresh install.

Future additions tracked in the [k3s HA hardening plan](../README.md): etcd snapshot schedule, snapshot rsync cron, systemd drop-in for clean shutdown.
