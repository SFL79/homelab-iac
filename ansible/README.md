# Bootstrap Compose management

This directory manages exactly one named bootstrap service at a time from the
dedicated `sf-g9` controller. It has no timer, daemon, CI trigger, or implicit
all-host mode.

## Controller contract

- Controller root: `/home/sf135/apps/homelab-ansible`
- Read-only Gitea checkout: `repo/`
- Python virtual environment: `venv/`
- Dedicated managed-host key: `keys/bootstrap-managed-hosts`
- Dedicated Gitea deploy key: `keys/gitea-readonly`
- Cached immutable revisions: `revisions/<sha>/`
- Stable command: `/home/sf135/.local/bin/bootstrapctl`

The installer uses PyPA's no-root `virtualenv` zipapp because the stock Ubuntu
image on `sf-g9` does not include `python3.12-venv`. The accepted zipapp is
version 21.7.4 with a hard-coded SHA-256; an upstream replacement fails closed.

The Gitea deploy key must be read-only. The managed-host SSH key is installed
only on `sf-g9`, `sf-g6`, and `sf-optiplex7000`; it must never be mounted into
Hermes or copied into a service directory.

The checkout's local `core.sshCommand` is pinned to `keys/git-ssh`, which in
turn enforces the dedicated deploy key, strict host-key checking, and the
controller-owned `known_hosts` file for every fetch.

## Commands

```text
bootstrapctl status <service>
bootstrapctl audit <service>
bootstrapctl plan <service> --revision <sha>
bootstrapctl deploy <service> --revision <sha>
bootstrapctl rollback <service> --revision <sha>
```

Allowed services are `gitea`, `vault`, `adguard`, `netdata`, and `hermes`.
`deploy` and `rollback` require a revision already cached by `plan`. Online
commands verify that the revision is an ancestor of `origin/main`. Explicit
`--offline` operation is limited to cached Gitea and Vault revisions.

Only files listed in `group_vars/all/bootstrap.yml` are copied. Persistent data,
credentials, generated state, and unknown host-local files are never purged.
Netdata's parent `stream.conf` is deliberately host-local and is managed only
during explicit key rotation or host rebuild.

## Netdata stream-key rendering

`playbooks/netdata-stream-key.yml` is the only Ansible path that writes the
parent's host-local `stream.conf`. Pipe a JSON list containing one or two UUID
keys to an SSH shell that reads it into `NETDATA_STREAM_KEYS_JSON`: two while
old and new keys overlap, then only the new key after every child has
reconnected. The decode and copy tasks suppress logs, the copy suppresses diffs,
and the file is written mode `0600`. Normal `status`, `audit`, `plan`, `deploy`,
and `rollback` commands never read Vault and never manage this file.
