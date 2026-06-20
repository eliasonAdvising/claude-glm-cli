#!/usr/bin/env bash
# install.sh
#
# Symlink-based installer for glm-cli.
#
# Symlinks bin/* scripts to ~/.local/bin/ and skills/* to ~/.claude/skills/.
# Run this once per machine to install glm-cli globally.
#
# Usage:
#   ./install.sh              # Install symlinks
#   ./install.sh --uninstall  # Remove symlinks
#   ./install.sh --help       # Show this help

set -euo pipefail

VERSION="v0.1.0-dev"

# -----------------------------------------------------------------------------
# --help / --version
# -----------------------------------------------------------------------------

if [[ "${1:-}" == "--version" ]]; then
  echo "install.sh $VERSION"
  exit 0
fi

if [[ "${1:-}" == "--help" ]]; then
  cat <<'EOF'
install.sh - Symlink-based installer for glm-cli

USAGE:
  ./install.sh              # Install symlinks
  ./install.sh --uninstall  # Remove symlinks
  ./install.sh --help       # Show this help
  ./install.sh --version    # Show version

INSTALLS:
  ~/.local/bin/glm-subagent   → <repo>/bin/glm-subagent
  ~/.local/bin/glm-init        → <repo>/bin/glm-init
  ~/.local/bin/glm-usage       → <repo>/bin/glm-usage
  ~/.claude/skills/glm-task    → <repo>/skills/glm-task
  ~/.claude/skills/glm-fan     → <repo>/skills/glm-fan

UNINSTALLS:
  Removes the symlinks created above.

REQUIREMENTS:
  - ~/.local/bin/ should be on PATH (installer will warn if not)
  - ~/.claude/skills/ should exist (will be created if missing)
EOF
  exit 0
fi

# -----------------------------------------------------------------------------
# Resolve repo root
# -----------------------------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$REPO_ROOT/bin"
SKILLS_DIR="$REPO_ROOT/skills"

# Validate directories exist
if [[ ! -d "$BIN_DIR" ]]; then
  echo "error: bin directory not found: $BIN_DIR" >&2
  exit 1
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "error: skills directory not found: $SKILLS_DIR" >&2
  exit 1
fi

# -----------------------------------------------------------------------------
# Handle --uninstall
# -----------------------------------------------------------------------------

if [[ "${1:-}" == "--uninstall" ]]; then
  echo "Uninstalling glm-cli..."

  # Remove bin symlinks
  for bin in "$BIN_DIR"/*; do
    [[ -f "$bin" ]] || continue
    local name="$(basename "$bin")"
    local link="$HOME/.local/bin/$name"

    if [[ -L "$link" ]]; then
      rm "$link"
      echo "✓ removed: $link"
    fi
  done

  # Remove skills symlinks
  for skill_dir in "$SKILLS_DIR"/*; do
    [[ -d "$skill_dir" ]] || continue
    local name="$(basename "$skill_dir")"
    local link="$HOME/.claude/skills/$name"

    if [[ -L "$link" ]]; then
      rm "$link"
      echo "✓ removed: $link"
    fi
  done

  echo "Done. glm-cli has been uninstalled."
  exit 0
fi

# -----------------------------------------------------------------------------
# Install mode
# -----------------------------------------------------------------------------

echo "Installing glm-cli..."

# Create target directories
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.claude/skills"

# -----------------------------------------------------------------------------
# Install bin scripts
# -----------------------------------------------------------------------------

for bin in "$BIN_DIR"/*; do
  [[ -f "$bin" ]] || continue
  local name="$(basename "$bin")"
  local link="$HOME/.local/bin/$name"

  ln -sfn "$bin" "$link"
  echo "✓ installed: $name"
done

# -----------------------------------------------------------------------------
# Install skills
# -----------------------------------------------------------------------------

for skill_dir in "$SKILLS_DIR"/*; do
  [[ -d "$skill_dir" ]] || continue
  local name="$(basename "$skill_dir")"
  local link="$HOME/.claude/skills/$name"

  ln -sfn "$skill_dir" "$link"
  echo "✓ installed: $name"
done

# -----------------------------------------------------------------------------
# Verify PATH
# -----------------------------------------------------------------------------

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo ""
  echo "warning: ~/.local/bin is not on PATH" >&2
  echo "  Add this to your ~/.bashrc:" >&2
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\"" >&2
fi

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------

echo ""
echo "Done. Verify with:"
echo "  glm-subagent --version"
echo "  glm-init --version"
echo "  glm-usage --help"

exit 0
