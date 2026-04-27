#!/usr/bin/env bash
# package.sh — Empacota a skill para cada agente
set -e

SKILL_NAME="blazor-rcl-generator"
rm -rf dist && mkdir -p dist

# ── Claude (claude.ai) ────────────────────────────────────────────────────────
zip -r "dist/$SKILL_NAME.skill" SKILL.md scripts/

# ── Claude Code ───────────────────────────────────────────────────────────────
mkdir -p "dist/claude-code/$SKILL_NAME"
cp SKILL.md "dist/claude-code/$SKILL_NAME/"
cp -r scripts "dist/claude-code/$SKILL_NAME/"

# ── OpenCode ──────────────────────────────────────────────────────────────────
mkdir -p "dist/opencode/$SKILL_NAME"
cp SKILL.md "dist/opencode/$SKILL_NAME/"
cp -r scripts "dist/opencode/$SKILL_NAME/"

# ── Qwen Code (system prompt avulso, sem frontmatter YAML) ───────────────────
mkdir -p dist/qwen
awk '/^---$/{n++; if(n==2){found=1; next}} found' SKILL.md \
  > "dist/qwen/$SKILL_NAME.md"

echo "✅ Pacotes gerados em dist/"
