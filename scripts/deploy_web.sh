#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if ! command -v godot >/dev/null 2>&1; then
	echo "Error: Godot is not available on PATH." >&2
	exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
	echo "Error: npx is required to run the Vercel CLI." >&2
	exit 1
fi

if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
	echo "Error: commit your source changes before deploying." >&2
	git status --short >&2
	exit 1
fi

echo "Running gameplay checks..."
godot --headless --path . -s res://scripts/tests/smoke_test.gd

echo "Building a fresh browser export..."
mkdir -p exports/web
find exports/web -mindepth 1 -maxdepth 1 ! -name .vercel ! -name .gitignore -delete
godot --headless --path . --export-release Web exports/web/index.html

echo "Deploying the fresh build to Vercel production..."
npx --yes vercel --cwd exports/web --prod "$@"
