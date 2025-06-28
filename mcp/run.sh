#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash python313Packages.pyppeteer python312


uvx mcpo --port 8001 --api-key "thekey" -- npx -y puppeteer-mcp-server
