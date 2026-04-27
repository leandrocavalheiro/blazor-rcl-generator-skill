#!/usr/bin/env bash
# install.sh — Installs the blazor-rcl-generator skill into detected AI agents
# Can be run standalone (downloaded from GitHub) or from inside the cloned repo.
set -e

SKILL_NAME="blazor-rcl-generator"
REPO_URL="git@github.com:leandrocavalheiro/blazor-rcl-generator-skill.git"

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

# ── Helpers ───────────────────────────────────────────────────────────────────
confirm() {
  printf "${CYAN}?${RESET} ${BOLD}%s${RESET} ${DIM}[y/N]${RESET} " "$1"
  read -r answer
  [[ "$answer" =~ ^[yY]$ ]]
}

success() { echo -e "${GREEN}✔${RESET} $1"; }
skip()    { echo -e "${DIM}–${RESET} $1"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $1"; }
info()    { echo -e "${CYAN}→${RESET} $1"; }
die()     { echo -e "${YELLOW}✘${RESET} $1"; echo ""; exit 1; }

strip_frontmatter() {
  awk '/^---$/{n++; if(n==2){found=1; next}} found' "$SKILL_DIR/SKILL.md"
}

# ── Bootstrap: ensure skill files are available ───────────────────────────────
CLONED=false
TMP_DIR=""

bootstrap() {
  if [ -f "$SKILL_DIR/SKILL.md" ]; then
    return  # files already present, nothing to do
  fi

  warn "SKILL.md not found next to this script."
  echo ""

  if command -v git &>/dev/null; then
    info "Git detected — cloning repository to a temporary directory..."
    TMP_DIR="$(mktemp -d)"
    if GIT_TERMINAL_PROMPT=0 git clone --depth 1 "$REPO_URL" "$TMP_DIR" 2>/dev/null; then
      SKILL_DIR="$TMP_DIR"
      CLONED=true
      success "Repository cloned."
      echo ""
    else
      rm -rf "$TMP_DIR"
      die "Could not clone $REPO_URL\nCheck your internet connection and try again."
    fi
  else
    die "Git is not installed and skill files are missing.\nInstall Git from https://git-scm.com\nor download the full release at:\n  ${REPO_URL}/releases"
  fi
}

# ── Cleanup: remove temp clone on exit ───────────────────────────────────────
cleanup() {
  if [ "$CLONED" = true ] && [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
    info "Temporary clone removed."
  fi
}
trap cleanup EXIT

# ── Agent detectors ───────────────────────────────────────────────────────────
detect_agents() {
  AGENTS=()
  { command -v claude &>/dev/null || [ -d "$HOME/.claude" ]; }               && AGENTS+=("claude")
  { command -v opencode &>/dev/null || [ -d "$HOME/.config/opencode" ]; }    && AGENTS+=("opencode")
  { command -v gemini &>/dev/null || [ -d "$HOME/.gemini" ]; }               && AGENTS+=("gemini")
  { command -v qwen &>/dev/null || command -v qwencoder &>/dev/null; }       && AGENTS+=("qwen")
}

# ── Installers ────────────────────────────────────────────────────────────────
install_claude() {
  local dest="$HOME/.claude/skills/$SKILL_NAME"
  mkdir -p "$dest"
  cp "$SKILL_DIR/SKILL.md" "$dest/"
  cp -r "$SKILL_DIR/scripts" "$dest/"
  success "Claude / Claude Code — installed at $dest"
  echo -e "  ${DIM}The skill will be available automatically in claude.ai and Claude Code.${RESET}"
}

install_opencode() {
  local dest="$HOME/.config/opencode/skills/$SKILL_NAME"
  mkdir -p "$dest"
  cp "$SKILL_DIR/SKILL.md" "$dest/"
  cp -r "$SKILL_DIR/scripts" "$dest/"
  success "OpenCode — installed at $dest"
  echo -e "  ${DIM}Restart OpenCode to load the new skill.${RESET}"
}

install_gemini() {
  local dest="$HOME/.gemini/skills/$SKILL_NAME"
  mkdir -p "$dest"
  strip_frontmatter > "$dest/SKILL.md"
  cp -r "$SKILL_DIR/scripts" "$dest/"
  success "Gemini CLI — installed at $dest"
  echo -e "  ${DIM}Reference the skill in your project GEMINI.md to activate it.${RESET}"
}

install_qwen() {
  local dest="$HOME/.config/qwen/skills"
  mkdir -p "$dest"
  strip_frontmatter > "$dest/$SKILL_NAME.md"
  success "Qwen Code — installed at $dest/$SKILL_NAME.md"
  echo -e "  ${DIM}Usage: qwen --system-prompt ~/.config/qwen/skills/$SKILL_NAME.md${RESET}"
}

agent_label() {
  case "$1" in
    claude)   echo "Claude / Claude Code" ;;
    opencode) echo "OpenCode" ;;
    gemini)   echo "Gemini CLI" ;;
    qwen)     echo "Qwen Code" ;;
  esac
}

# ── Main ──────────────────────────────────────────────────────────────────────
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Blazor RCL Generator — Installer      ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

bootstrap
detect_agents

if [ ${#AGENTS[@]} -eq 0 ]; then
  warn "No compatible agents detected on this system."
  echo -e "${DIM}Supported: Claude / Claude Code, OpenCode, Gemini CLI, Qwen Code${RESET}"
  echo ""
  exit 0
fi

echo -e "Detected ${BOLD}${#AGENTS[@]}${RESET} compatible agent(s)."
echo ""

INSTALLED=0

for agent in "${AGENTS[@]}"; do
  label=$(agent_label "$agent")
  if confirm "Install into $label?"; then
    echo ""
    "install_$agent"
    echo ""
    INSTALLED=$((INSTALLED + 1))
  else
    skip "$label — skipped"
  fi
done

echo ""
if [ "$INSTALLED" -eq 0 ]; then
  warn "No agents were configured."
else
  echo -e "${GREEN}${BOLD}Done — $INSTALLED agent(s) configured successfully.${RESET}"
fi
echo ""