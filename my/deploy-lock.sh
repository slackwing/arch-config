#!/usr/bin/env bash
# deploy-lock.sh acquire|release|status|wait — ONE lock for the moments
# when a Claude session (or Andrew) merges to master/main or deploys the
# website / hobby-server. Two sessions work on the hxh site at once;
# whoever holds the lock may fetch, rebase, build, push and deploy;
# everyone else waits. The lock is a directory (mkdir is atomic) in /tmp,
# shared by every session on this machine, with an owner note inside.
#
#   deploy-lock.sh acquire "hxh-roster"   # exits 1 if someone else holds it
#   deploy-lock.sh wait "hxh-roster"      # blocks (up to 20 min) until acquired
#   deploy-lock.sh status
#   deploy-lock.sh release
# A lock older than 30 min whose owner process is gone is stale and is
# removed by acquire/wait.
set -uo pipefail
LOCK=/tmp/hxh-deploy.lock
STALE_MIN=30

owner() { cat "$LOCK/owner" 2>/dev/null; }
stale() {
  [[ -d "$LOCK" ]] || return 1
  local pid; pid=$(sed -n 's/^pid=//p' "$LOCK/owner" 2>/dev/null)
  local age=$(( ($(date +%s) - $(stat -c %Y "$LOCK")) / 60 ))
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && return 1   # owner alive → not stale
  (( age >= STALE_MIN ))
}
acquire() {
  local who="${1:-$(whoami)}"
  if stale; then echo "removing stale lock: $(owner | tr '\n' ' ')"; rm -rf "$LOCK"; fi
  if mkdir "$LOCK" 2>/dev/null; then
    printf 'who=%s\npid=%s\nsince=%s\n' "$who" "$PPID" "$(date -Is)" > "$LOCK/owner"
    echo "lock acquired by $who"; return 0
  fi
  echo "lock held: $(owner | tr '\n' ' ')" >&2; return 1
}
case "${1:-}" in
  acquire) acquire "${2:-}";;
  wait)
    for i in $(seq 1 120); do acquire "${2:-}" 2>/dev/null && exit 0; (( i == 1 )) && echo "waiting for the deploy lock: $(owner | tr '\n' ' ')"; sleep 10; done
    echo "gave up after 20 min; lock: $(owner | tr '\n' ' ')" >&2; exit 1;;
  release) rm -rf "$LOCK" && echo "lock released";;
  status) if [[ -d "$LOCK" ]]; then echo "held: $(owner | tr '\n' ' ')"; stale && echo "(stale)"; else echo "free"; fi;;
  *) echo "usage: deploy-lock.sh acquire|wait [who] | release | status" >&2; exit 2;;
esac
