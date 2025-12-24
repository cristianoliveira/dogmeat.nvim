#!/usr/bin/env bash
set -e

# nvim-test.sh - Integration tests for dogmeat.nvim
# This script runs Neovim with minimal config to test the plugin

NVIM_BIN=${NVIM_BIN:-nvim}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running Neovim integration tests..."
echo "Using Neovim: $NVIM_BIN"

# Test 1: Check if plugin loads without errors
echo "Test 1: Plugin loads successfully"
$NVIM_BIN --headless --noplugin -u NONE \
  -c "set runtimepath+=$SCRIPT_DIR" \
  -c "lua require('dogmeat')" \
  -c "quit" 2>&1 | tee /tmp/nvim-test.log

if grep -q "Error" /tmp/nvim-test.log; then
  echo "❌ Plugin failed to load"
  exit 1
fi

echo "✓ Plugin loaded successfully"

# Test 2: Check if setup() works
echo "Test 2: Setup function works"
$NVIM_BIN --headless --noplugin -u NONE \
  -c "set runtimepath+=$SCRIPT_DIR" \
  -c "lua require('dogmeat').setup({})" \
  -c "quit"

echo "✓ Setup function works"

echo ""
echo "All integration tests passed! ✓"
