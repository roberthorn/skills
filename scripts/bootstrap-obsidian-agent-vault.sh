#!/usr/bin/env bash
# Create the base folders that vault-writing skills expect, in the most
# recently focused Obsidian vault. Obsidian must be running.
#
#   00 - Agents/Issues    issue-tracker-obsidian, to-spec, to-tickets, wayfinder
#   00 - Agents/Research  research
#   00 - Agents/Handoffs  handoff
set -euo pipefail

if ! command -v obsidian >/dev/null 2>&1; then
  echo "error: obsidian CLI not found on PATH" >&2
  exit 1
fi

vault=$(obsidian vault info=path)
if [[ -z "$vault" || ! -d "$vault" ]]; then
  echo "error: could not resolve open vault path (is Obsidian running?): '$vault'" >&2
  exit 1
fi

root="00 - Agents"
dirs=(
  "$root/Issues"
  "$root/Research"
  "$root/Handoffs"
)

echo "Vault: $vault"
for d in "${dirs[@]}"; do
  if [[ -d "$vault/$d" ]]; then
    echo "  exists   $d"
  else
    mkdir -p "$vault/$d"
    echo "  created  $d"
  fi
done
