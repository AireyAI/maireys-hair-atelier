#!/usr/bin/env bash
# ship.sh — the ONLY blessed deploy path for this site.
#
# Chains the completeness pipeline so nothing ships half-built:
#   1. STATIC gate   — verify-completeness.sh (SEO/legal/icons/a11y presence + content validity)
#   2. DYNAMIC gate  — audit.mjs (real Core Web Vitals via Lighthouse + axe-core a11y)
#   3. Deploy        — only on --deploy, and only if 1 + 2 both pass (two-stage per CLAUDE.md §12)
#
# Usage:
#   ./ship.sh            run both gates, report ship-readiness (no deploy)
#   ./ship.sh --deploy   run both gates, then git push to the Pages remote IF clear
#   ./ship.sh --fix      auto-generate missing structural files first, then gate
#
# Exit: 0 = ship-clear (and deployed if --deploy) · 1 = a gate failed · 2 = setup error.

set -uo pipefail
PROJ="$(cd "$(dirname "$0")" && pwd)"
WEB="$HOME/Websites"
RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; BLD=$'\033[1m'; DIM=$'\033[2m'; RST=$'\033[0m'

DEPLOY=0; FIXARG=""
for a in "$@"; do
  case "$a" in
    --deploy) DEPLOY=1 ;;
    --fix)    FIXARG="--fix" ;;
  esac
done

echo "${BLD}═══ ship.sh ═══${RST}  ${DIM}$PROJ${RST}"

# ---- 1. static gate ----
echo "${BLD}[1/3] static completeness gate${RST}"
if ! bash "$WEB/verify-completeness.sh" "$PROJ" $FIXARG; then
  echo "${RED}${BLD}✗ static gate failed — not shipping.${RST}"; exit 1
fi

# ---- 2. dynamic gate (needs the site running) ----
echo; echo "${BLD}[2/3] dynamic audit (Lighthouse CWV + axe a11y)${RST}"
STARTED_SERVER=0
if ! curl -sf -o /dev/null http://localhost:3000 2>/dev/null; then
  if [ -f "$PROJ/serve.mjs" ]; then
    echo "${DIM}starting local server…${RST}"
    ( cd "$PROJ" && node serve.mjs >/tmp/ship-serve.log 2>&1 & echo $! > /tmp/ship-serve.pid )
    STARTED_SERVER=1
    for _ in $(seq 1 20); do curl -sf -o /dev/null http://localhost:3000 && break; sleep 0.5; done
  else
    echo "${RED}no server on :3000 and no serve.mjs — cannot run dynamic audit.${RST}"; exit 2
  fi
fi

AUDIT_RC=0
node "$WEB/audit.mjs" http://localhost:3000 || AUDIT_RC=$?

if [ "$STARTED_SERVER" -eq 1 ] && [ -f /tmp/ship-serve.pid ]; then
  kill "$(cat /tmp/ship-serve.pid)" 2>/dev/null; rm -f /tmp/ship-serve.pid
fi

if [ "$AUDIT_RC" -eq 2 ]; then
  echo "${YEL}${BLD}⚠ dynamic audit could not run (setup).${RST} Install once: ${BLD}cd ~/Websites && npm install${RST}. Not shipping."; exit 2
fi
if [ "$AUDIT_RC" -ne 0 ]; then
  echo "${RED}${BLD}✗ dynamic audit failed — not shipping.${RST}"; exit 1
fi

# ---- 2.5 design-quality advisory (taste isn't a hard gate, but it must be SURFACED) ----
echo; echo "${BLD}[2.5] design-quality check${RST}"
LOCK=""
for cand in "$PROJ/.design-locked" "$HOME/Websites/$(basename "$PROJ")/.design-locked"; do
  [ -f "$cand" ] && LOCK="$cand" && break
done
if [ -n "$LOCK" ]; then
  REF=$(grep -o '"design_md_ref"[^,]*' "$LOCK" | sed -E 's/.*:\s*"//; s/"$//')
  [ -n "$REF" ] && [ "$REF" != "none" ] \
    && echo "${DIM}benchmark exemplar: ${BLD}$REF${RST}${DIM} — open it: sed -n '/Inspired by $REF/,+250p' ~/design.md${RST}" \
    || echo "${DIM}no design.md exemplar on file (trades/sandbox).${RST}"
else
  echo "${YEL}⚠ no .design-locked found — was this built through the design gate?${RST}"
fi
echo "${YEL}↳ Before deploy, run the design-quality pass (not auto-runnable from bash):${RST}"
echo "   ${BLD}impeccable:audit${RST} (P0–P3 technical) + ${BLD}impeccable:critique${RST} (UX/persona) — fix P0/P1."
echo "   ${DIM}This stage is advisory: it surfaces the check, it does not hard-block on taste.${RST}"

# ---- 3. deploy (two-stage: only with --deploy) ----
echo; echo "${BLD}[3/3] deploy${RST}"
if [ "$DEPLOY" -ne 1 ]; then
  echo "${GRN}${BLD}✓ SHIP-CLEAR${RST} — both gates passed. Re-run with ${BLD}--deploy${RST} to push live."
  exit 0
fi
if [ ! -d "$PROJ/.git" ]; then
  echo "${YEL}--deploy requested but no git repo here. Initialise + add the Pages remote first.${RST}"; exit 1
fi
echo "${DIM}pushing to Pages remote…${RST}"
( cd "$PROJ" && git add -A && git commit -m "Deploy: gates passed (completeness + CWV/a11y)" && git push )
echo "${GRN}${BLD}✓ DEPLOYED${RST} — gates passed and pushed."
