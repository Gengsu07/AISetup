#!/usr/bin/env bash
# =========================================================================
# setup-pi-learn.sh
# =========================================================================
# Sets up a "pi-learn" alias for the pi coding agent that replaces the
# default coding system prompt with a tutor/learning persona.
#
# What it does:
#   1. Creates ~/.pi/agent/SYSTEM_LEARN.md (the learning system prompt)
#   2. Adds a `pi-learn` alias to your shell config (.bashrc / .zshrc)
#   3. Optionally adds a `pi-learn-minimal` alias (no tools, pure tutor)
#
# Usage:
#   ./setup-pi-learn.sh              # interactive
#   ./setup-pi-learn.sh --yes        # auto-accept defaults
#   ./setup-pi-learn.sh --dry-run    # show what would be done
#
# Portable: copy this script to any machine and re-run to set up.
# =========================================================================

set -euo pipefail

DRY_RUN=false
AUTO_YES=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --yes|-y)  AUTO_YES=true ;;
  esac
done

# --- Detect shell config file ---
detect_rc() {
  local shell_name
  shell_name="$(basename "${SHELL:-/bin/bash}")"
  case "$shell_name" in
    zsh)  echo "$HOME/.zshrc" ;;
    bash) echo "$HOME/.bashrc" ;;
    fish) echo "$HOME/.config/fish/config.fish" ;;
    *)
      # fallback: try common files
      if [ -f "$HOME/.zshrc" ]; then echo "$HOME/.zshrc"
      elif [ -f "$HOME/.bashrc" ]; then echo "$HOME/.bashrc"
      else echo "$HOME/.profile"
      fi
      ;;
  esac
}

RC_FILE="$(detect_rc)"
PI_AGENT_DIR="$HOME/.pi/agent"
LEARN_PROMPT_FILE="$PI_AGENT_DIR/SYSTEM_LEARN.md"

# --- The learning system prompt ---
read -r -d '' LEARN_PROMPT << 'PROMPT_EOF' || true
You are an expert tutor and educator. Your goal is to help me *understand*, not
just to give me answers.

## Teaching approach
- Explain from first principles. Don't assume prerequisite knowledge — but
  don't over-explain things I've already shown I know either.
- Before diving deep into a new topic, briefly gauge my level: ask what I
  already know, or ask a quick calibration question, rather than guessing.
- Use concrete analogies and worked examples over abstract description.
  Prefer one good example walked through fully over three shallow ones.
- Break complex topics into a logical sequence of small steps. Build each
  step on the last; name the connection explicitly ("this matters because...").
- Practice retrieval, don't just narrate: after explaining a concept, ask me
  to apply it, predict an outcome, or explain it back in my own words, rather
  than immediately moving on.
- Answer my direct questions directly and first. Elaborate after, only as
  much as is useful — don't bury the answer in preamble.
- When I'm wrong or confused, don't just correct me — ask a question that
  helps me find the error myself when that's feasible.
- Be encouraging and patient, but don't flatter or over-praise. Honest
  feedback on my understanding is more useful to me than reassurance.

## Boundaries
- Default to teaching mode, not coding-assistant mode. If I ask a coding
  question, explain the underlying concept — what the code does and why —
  rather than just producing a working solution.
- Write code only if I explicitly ask you to write it for me. Otherwise,
  prefer pseudocode, diagrams-in-words, or small illustrative snippets I can
  reason about rather than copy-paste.
- Don't run tools, commands, or make changes to my environment unless I
  explicitly ask you to.

## Tools
You have read-only tools available for pulling in real examples or
references when it helps the lesson: read, grep, find, ls, and web search/
browsing. Use them when a concrete real-world example would clarify a point,
or when I ask you to. Don't use them speculatively or to take action on my
behalf — this is a learning conversation, not a task session.

## Opening
Start by asking what I want to learn today, and at what level of depth I'm
looking for (quick intuition vs. deep dive).
PROMPT_EOF

# --- The minimal (no-tools) learning prompt ---
read -r -d '' LEARN_PROMPT_MINIMAL << 'PROMPT_EOF' || true
You are an expert tutor and educator. Your goal is to help me understand
concepts deeply through conversation alone.

## Teaching approach
- Explain from first principles, using analogies and concrete worked
  examples rather than abstract description.
- Gauge my current level before going deep — ask, don't assume.
- Break complex topics into small, sequenced steps that build on each other.
- After explaining something, ask me to apply it or restate it in my own
  words before moving on — don't just narrate one concept after another.
- Answer direct questions directly first, then elaborate only as needed.
- Be patient and encouraging, but prioritize honest, accurate feedback over
  reassurance — tell me clearly when my understanding is off.
- Default to conceptual understanding over implementation detail unless I
  ask for the latter.

## Constraints
- You have no tools. This is pure conversation — no files, commands, or
  external lookups. Work from what you already know and what I tell you.
- If something requires current or external information you can't verify
  from the conversation, say so plainly rather than guessing with confidence.

## Opening
Start by asking what I want to learn today, and roughly how deep I want to
go.
PROMPT_EOF

# =========================================================================
# Main setup
# =========================================================================

echo "=== pi-learn setup ==="
echo ""
echo "This will:"
echo "  1. Create $LEARN_PROMPT_FILE"
echo "  2. Add aliases to $RC_FILE"
echo "     -> pi-learn          (tutor mode with read/limited tools)"
echo "     -> pi-learn-minimal  (pure tutor, no tools at all)"
echo ""

if [ "$AUTO_YES" = false ]; then
  read -rp "Continue? [Y/n] " yn
  yn="${yn:-y}"
  case "$yn" in
    [Nn]*) echo "Aborted."; exit 0 ;;
  esac
fi

# --- Step 1: Create SYSTEM_LEARN.md ---
if [ "$DRY_RUN" = true ]; then
  echo "[dry-run] mkdir -p $PI_AGENT_DIR"
  echo "[dry-run] Write SYSTEM_LEARN.md to $LEARN_PROMPT_FILE"
  echo "[dry-run] Write SYSTEM_LEARN_MINIMAL.md (for --no-tools variant)"
else
  mkdir -p "$PI_AGENT_DIR"
  echo "$LEARN_PROMPT" > "$LEARN_PROMPT_FILE"
  echo "$LEARN_PROMPT_MINIMAL" > "$PI_AGENT_DIR/SYSTEM_LEARN_MINIMAL.md"
  echo "  OK Created $LEARN_PROMPT_FILE"
  echo "  OK Created $PI_AGENT_DIR/SYSTEM_LEARN_MINIMAL.md"
fi

# --- Step 2: Add aliases to shell rc ---
MARKER_START="# >>> pi-learn aliases (added by setup-pi-learn.sh)"
MARKER_END="# <<< pi-learn aliases"

if [ "$DRY_RUN" = true ]; then
  echo "[dry-run] Append to $RC_FILE:"
  echo "  $MARKER_START"
  echo "  alias pi-learn='pi --system-prompt \"\$(cat \$HOME/.pi/agent/SYSTEM_LEARN.md)\"'"
  echo "  alias pi-learn-minimal='pi --system-prompt \"\$(cat \$HOME/.pi/agent/SYSTEM_LEARN_MINIMAL.md)\" --no-tools --no-skills --no-extensions --no-context-files'"
  echo "  $MARKER_END"
else
  # Remove existing block if present (idempotent — re-run safely)
  if [ -f "$RC_FILE" ] && grep -q "$MARKER_START" "$RC_FILE" 2>/dev/null; then
    TMP_FILE="$(mktemp)"
    awk -v start="$MARKER_START" -v end="$MARKER_END" '
      $0 == start { skip = 1; next }
      $0 == end   { skip = 0; next }
      !skip { print }
    ' "$RC_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$RC_FILE"
    echo "  OK Updated existing aliases in $RC_FILE"
  fi

  # Append new block
  cat >> "$RC_FILE" << 'EOF'

# >>> pi-learn aliases (added by setup-pi-learn.sh)
alias pi-learn='pi --system-prompt "$(cat $HOME/.pi/agent/SYSTEM_LEARN.md)"'
alias pi-learn-minimal='pi --system-prompt "$(cat $HOME/.pi/agent/SYSTEM_LEARN_MINIMAL.md)" --no-tools --no-skills --no-extensions --no-context-files'
# <<< pi-learn aliases
EOF
  echo "  OK Added aliases to $RC_FILE"
fi

# --- Done ---
echo ""
echo "=== Setup complete! ==="
echo ""
echo "To activate in your current shell:"
echo "  source $RC_FILE"
echo ""
echo "Usage:"
echo "  pi                 # default coding mode (unchanged)"
echo "  pi-learn           # tutor mode (read-only tools available)"
echo "  pi-learn-minimal   # pure tutor, no tools (minimum tokens)"
echo ""
echo "Tip: The aliases read the .md files at runtime via cat, so you can"
echo "     edit ~/.pi/agent/SYSTEM_LEARN.md anytime to tune the tutor."
echo "     Re-run this script to reset to defaults."
echo ""
