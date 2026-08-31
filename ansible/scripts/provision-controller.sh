#!/usr/bin/env bash
set -euo pipefail

readonly RUNNER_ROOT="/home/sf135/apps/homelab-ansible"
readonly REPO_ROOT="${RUNNER_ROOT}/repo"
readonly ANSIBLE_ROOT="${REPO_ROOT}/ansible"
readonly GIT_SSH_WRAPPER="${RUNNER_ROOT}/keys/git-ssh"
readonly VIRTUALENV_VERSION="21.7.4"
readonly VIRTUALENV_SHA256="2dfdb6785b762b8a7a7a31d413c16516aa785552d05f61435b072fde1cb340cc"
readonly VIRTUALENV_ZIPAPP="${RUNNER_ROOT}/virtualenv-${VIRTUALENV_VERSION}.pyz"

[[ "$(hostname -s)" == sf-g9 ]] || { printf 'Run this on sf-g9.\n' >&2; exit 2; }
[[ -d "${REPO_ROOT}/.git" ]] || { printf 'Read-only homelab-iac checkout is missing.\n' >&2; exit 2; }
[[ -x "${GIT_SSH_WRAPPER}" ]] || { printf 'Gitea SSH wrapper is missing.\n' >&2; exit 2; }

git -C "${REPO_ROOT}" config --local core.sshCommand "${GIT_SSH_WRAPPER}"
git -C "${REPO_ROOT}" fetch --quiet origin main

install -d -m 0700 "${RUNNER_ROOT}/keys" "${RUNNER_ROOT}/revisions"
if [[ ! -f "${VIRTUALENV_ZIPAPP}" ]]; then
  curl -fsSLo "${VIRTUALENV_ZIPAPP}.tmp" https://bootstrap.pypa.io/virtualenv.pyz
  printf '%s  %s\n' "${VIRTUALENV_SHA256}" "${VIRTUALENV_ZIPAPP}.tmp" |
    sha256sum --check --status
  mv "${VIRTUALENV_ZIPAPP}.tmp" "${VIRTUALENV_ZIPAPP}"
fi
printf '%s  %s\n' "${VIRTUALENV_SHA256}" "${VIRTUALENV_ZIPAPP}" |
  sha256sum --check --status
python3 "${VIRTUALENV_ZIPAPP}" --clear "${RUNNER_ROOT}/venv"
"${RUNNER_ROOT}/venv/bin/python" -m pip install --upgrade pip
"${RUNNER_ROOT}/venv/bin/pip" install --requirement "${ANSIBLE_ROOT}/requirements.txt"
"${RUNNER_ROOT}/venv/bin/ansible-galaxy" collection install \
  --requirements-file "${ANSIBLE_ROOT}/requirements.yml" \
  --collections-path "${ANSIBLE_ROOT}/.collections"
install -d -m 0750 /home/sf135/.local/bin
ln -sfn "${ANSIBLE_ROOT}/scripts/bootstrapctl" /home/sf135/.local/bin/bootstrapctl
printf 'Controller installed. Run bootstrapctl status <service>.\n'
