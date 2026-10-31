#!/usr/bin/env bash
#
# Merge upstream Omarchy changes into this fork without touching the fork's own
# edits, using a three-way file merge (git merge-file).
#
# A built-in Omarchy plugin has no repository of its own — it ships inside the
# omarchy package. So the "base" (upstream as it was when the fork was made) and
# the "current" upstream are fetched from omacom/omarchy over the GitHub API and
# recorded in .upstream-base.
#
# Usage:
#   tools/merge-upstream.sh                  # check only: has upstream moved?
#   tools/merge-upstream.sh --apply          # merge, write files, bump the base
#   tools/merge-upstream.sh --ref <sha>      # merge up to a specific upstream sha
#   tools/merge-upstream.sh --base <sha>     # pretend the fork was made from <sha>
#   tools/merge-upstream.sh --keep           # leave merged files in the temp dir only
#
# Exit codes: 0 = up to date or clean merge, 1 = conflicts (nothing written),
# 2 = error.
set -euo pipefail

UPSTREAM_REPO=${UPSTREAM_REPO:-omacom/omarchy}
UPSTREAM_PATH=${UPSTREAM_PATH:-shell/plugins/panels/power}
STATE_FILE=.upstream-base
# Files the fork owns outright and must never be merged from upstream.
KEEP_LOCAL="manifest.json README.md LICENSE"

apply=0
ref=""
base=""
mode="check"

die() { echo "merge-upstream: $*" >&2; exit 2; }
say() { printf '%s\n' "$*"; }

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

while (($#)); do
  case $1 in
    --apply) mode="apply"; shift ;;
    --check) mode="check"; shift ;;
    --keep)  apply=0; mode="keep"; shift ;;
    --ref)   ref=${2:?--ref needs a sha}; shift 2 ;;
    --base)  base=${2:?--base needs a sha}; shift 2 ;;
    -h|--help) usage ;;
    *) die "unknown argument: $1" ;;
  esac
done

root=$(git rev-parse --show-toplevel 2>/dev/null) || die "run this inside the fork's git checkout"
cd "$root"

command -v gh >/dev/null || die "gh is required (GitHub API)"
command -v jq >/dev/null || die "jq is required"

# --- recorded base -----------------------------------------------------------
if [[ -f $STATE_FILE ]]; then
  read -r state_repo state_sha state_path <"$STATE_FILE" || true
  [[ -n ${state_sha:-} ]] && base=${base:-$state_sha}
  [[ -n ${state_path:-} ]] && UPSTREAM_PATH=${UPSTREAM_PATH_OVERRIDE:-$state_path}
  [[ -n ${state_repo:-} ]] && UPSTREAM_REPO=${UPSTREAM_REPO_OVERRIDE:-$state_repo}
fi

latest=$(gh api "repos/$UPSTREAM_REPO/commits?path=$UPSTREAM_PATH&per_page=1" --jq '.[0].sha' 2>/dev/null) \
  || die "cannot read upstream history for $UPSTREAM_REPO/$UPSTREAM_PATH"
ref=${ref:-$latest}

say "upstream : $UPSTREAM_REPO · $UPSTREAM_PATH"
say "base     : ${base:-<not recorded>}"
say "target   : $ref"

if [[ -n $base && $base == "$ref" ]]; then
  say "апстрим не менялся с $ref — мержить нечего."
  exit 0
fi
[[ -n $base ]] || die "base не записан в $STATE_FILE — укажи --base <sha> (коммит, от которого сделан форк)"

# --- fetch -------------------------------------------------------------------
tmp=$(mktemp -d "${TMPDIR:-/tmp}/merge-upstream.XXXXXX")
cleanup() { [[ ${mode:-} == keep ]] || rm -rf "$tmp"; }
trap cleanup EXIT
mkdir -p "$tmp/base" "$tmp/cur" "$tmp/merged"

fetch() { # <sha> <dir> <file>
  gh api "repos/$UPSTREAM_REPO/contents/$UPSTREAM_PATH/$3?ref=$1" --jq '.content' 2>/dev/null \
    | base64 -d > "$2/$3" 2>/dev/null
}

mapfile -t files < <(gh api "repos/$UPSTREAM_REPO/contents/$UPSTREAM_PATH?ref=$ref" --jq '.[].name' 2>/dev/null)
((${#files[@]})) || die "upstream path $UPSTREAM_PATH пуст или недоступен"

merged_any=0
conflicts=0
skipped=()
for f in "${files[@]}"; do
  case " $KEEP_LOCAL " in *" $f "*) skipped+=("$f (fork owns it)"); continue ;; esac
  [[ -f $f ]] || { skipped+=("$f (нет в форке — новый файл апстрима)"); continue; }

  fetch "$base" "$tmp/base" "$f" || true
  fetch "$ref"  "$tmp/cur"  "$f"  || true
  [[ -s $tmp/base/$f && -s $tmp/cur/$f ]] || { skipped+=("$f (не удалось скачать)"); continue; }

  if cmp -s "$tmp/base/$f" "$tmp/cur/$f"; then
    skipped+=("$f (апстрим не менял)"); continue
  fi

  rc=0
  git merge-file -p "$f" "$tmp/base/$f" "$tmp/cur/$f" > "$tmp/merged/$f" 2>/dev/null || rc=$?
  if ((rc > 0)); then
    conflicts=$((conflicts + 1))
    say "КОНФЛИКТ: $f ($rc шт.) — разреши вручную, см. $tmp/merged/$f"
    sed -n '/<<<<<<</,/>>>>>>>/p' "$tmp/merged/$f" | head -40 | sed 's/^/    /'
    continue
  fi

  changed=$(diff -u "$f" "$tmp/merged/$f" | grep -cE '^[+-]' || true)
  say "ok: $f — ${changed} строк из апстрима, правки форка сохранены"
  merged_any=1
done

for s in "${skipped[@]}"; do say "skip: $s"; done

if ((conflicts)); then
  say ""
  say "Мерж не применён: ${conflicts} файл(ов) с конфликтами."
  say "Разреши вручную: держи структуру форка, бери значения апстрима."
  exit 1
fi

if ((merged_any == 0)); then
  say "Нечего применять."
  exit 0
fi

if [[ $mode != apply ]]; then
  say ""
  say "Пробный прогон. Применить: tools/merge-upstream.sh --apply"
  [[ $mode == keep ]] && say "merged files: $tmp/merged"
  exit 0
fi

for f in "$tmp"/merged/*; do
  [[ -f $f ]] && cp "$f" "$root/$(basename "$f")"
done
printf '%s %s %s\n' "$UPSTREAM_REPO" "$ref" "$UPSTREAM_PATH" > "$STATE_FILE"

say ""
say "Применено. Записано в $STATE_FILE: $UPSTREAM_REPO $ref $UPSTREAM_PATH"
say "Дальше: omarchy restart shell && omarchy-shell <target> open && grim /tmp/shot.png"
say "И закоммить: git add -A && git commit -m 'Merge upstream <plugin> (<sha>)'"
