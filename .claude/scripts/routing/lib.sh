#!/usr/bin/env bash
# Shared routing logic. Source this file; call route_prompt "$prompt".
# Output: two lines — AGENT=<haiku|sonnet|opus>  REASON=<text>
# Order: opus (most specific) → sonnet (feature) → haiku (mechanical) → default sonnet

route_prompt() {
  local prompt="$1"
  local lp
  lp=$(echo "$prompt" | tr '[:upper:]' '[:lower:]')
  local agent="" reason=""

  # ── TIER 1: OPUS ──────────────────────────────────────────────────────────
  if echo "$lp" | grep -qE "(design|redesign|architect) (the |a )?(parser pipeline|ingestion|dedup engine|concurrency|sendable|migration|schema|database|architecture)"; then
    agent="opus"; reason="architectural design keyword"
  elif echo "$lp" | grep -qE "(database (schema|migration)|db schema|grdb (architecture|design))"; then
    agent="opus"; reason="db schema design"
  elif echo "$lp" | grep -qE "(redesign|restructure) (concurrency|the pipeline|ingestion)"; then
    agent="opus"; reason="pipeline/concurrency redesign"
  elif echo "$lp" | grep -qE "(concurrency|sendable|actor isolation|async boundary|race condition|data race)"; then
    agent="opus"; reason="concurrency reasoning"
  elif echo "$lp" | grep -qE "(cross-module|across packages|pipeline restructure)"; then
    agent="opus"; reason="cross-module scope"
  elif echo "$lp" | grep -qE "(performance bottleneck|optimize.*algorithm|profile.*hot path|algorithmic complexity)"; then
    agent="opus"; reason="perf algorithmic"
  elif echo "$lp" | grep -qE "parser .*(broken|wrong|missing|fails|garbled|corrupt|misparses|gives wrong)"; then
    agent="opus"; reason="parser failure (root cause unknown)"
  elif echo "$lp" | grep -qE "(architecture decision|design (doc|review)|tradeoff analysis)"; then
    agent="opus"; reason="architecture decision"

  # ── TIER 2: SONNET ────────────────────────────────────────────────────────
  elif echo "$lp" | grep -qE "(add|build|implement|create|make) (a |an |the |new )*(screen|view|viewmodel|page|feature|dashboard|repository (method|protocol)|service|parser (for|class)|swiftui)"; then
    agent="sonnet"; reason="feature implementation"
  elif echo "$lp" | grep -qE "(swiftui|view ?model|state machine) (work|component|screen|view)"; then
    agent="sonnet"; reason="swiftui/vm work"
  elif echo "$lp" | grep -qE "implement (a |the |new )?[a-z]+(parser|importer|extractor|migrator|repository|service)"; then
    agent="sonnet"; reason="implement new type"
  elif echo "$lp" | grep -qE "(write|add) (unit |integration |snapshot )?tests"; then
    agent="sonnet"; reason="test writing"
  elif echo "$lp" | grep -qE "(refactor|extract|inline) (a |the )?(function|method|protocol|class|view|model)"; then
    agent="sonnet"; reason="medium refactor"
  elif echo "$lp" | grep -qE "(wire up|integrate|hook up|connect (the )?)"; then
    agent="sonnet"; reason="integration"

  # ── TIER 3: HAIKU ─────────────────────────────────────────────────────────
  elif echo "$lp" | grep -qE "(swiftlint|swift build|swift test|swift run|xcodebuild|swift package)"; then
    agent="haiku"; reason="build/test command"
  elif echo "$lp" | grep -qE "^(rebuild|recompile)( |$)"; then
    agent="haiku"; reason="rebuild verb"
  elif echo "$lp" | grep -qE "^build( the )?(project|package|core|parsers|app|all)( |$)"; then
    agent="haiku"; reason="build verb (no feature target)"
  elif echo "$lp" | grep -qE "^run (.*test|.*parser|.*lint|.*build|the cli)"; then
    agent="haiku"; reason="run command"
  elif echo "$lp" | grep -qE "(format|reformat|prettify) (this|the|file|code|all)"; then
    agent="haiku"; reason="format request"
  elif echo "$lp" | grep -qE "^(lint|run lint|swiftlint)"; then
    agent="haiku"; reason="lint"
  elif echo "$lp" | grep -qE "(fix typo|fix the typo|typo in|misspell)"; then
    agent="haiku"; reason="typo fix"
  elif echo "$lp" | grep -qE "^(commit|push|stage|git add|git status|git diff)"; then
    agent="haiku"; reason="git op"
  elif echo "$lp" | grep -qE "^(rename|move|delete|copy)( |$)"; then
    agent="haiku"; reason="file/symbol op"
  elif echo "$lp" | grep -qE "^(grep|search|find|fd|rg) "; then
    agent="haiku"; reason="search"
  elif echo "$lp" | grep -qE "(regenerate|update|refresh).*?(fixture|snapshot|graph|baseline)"; then
    agent="haiku"; reason="regen task"
  elif echo "$lp" | grep -qE "(parse the|run the parser|invoke parser|parser cli|test the parser on)"; then
    agent="haiku"; reason="parser invocation"

  # ── DEFAULT ───────────────────────────────────────────────────────────────
  else
    agent="sonnet"; reason="default (ambiguous → sonnet, never opus)"
  fi

  echo "AGENT=$agent"
  echo "REASON=$reason"
}

# Allow direct invocation: ./lib.sh "some prompt"
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  route_prompt "$1"
fi
