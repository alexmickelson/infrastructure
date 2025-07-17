#!/usr/bin/env bash
# Run MCP server using flake devShell

nix develop .#default --command run_flake
