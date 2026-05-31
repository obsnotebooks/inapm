#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:-site-release}"
LAYOUT="${2:-root}" # root | docs
REMOTE="${3:-origin}"
WORKTREE_DIR=".tmp/publish-${BRANCH}"

if [[ "$LAYOUT" != "root" && "$LAYOUT" != "docs" ]]; then
  echo "Usage: $0 [branch] [root|docs] [remote]"
  exit 1
fi

echo "Building site into dist/..."
npm run build

mkdir -p .tmp

if [[ -d "$WORKTREE_DIR/.git" || -d "$WORKTREE_DIR" ]]; then
  git worktree remove --force "$WORKTREE_DIR" >/dev/null 2>&1 || true
fi

if git ls-remote --exit-code --heads "$REMOTE" "$BRANCH" >/dev/null 2>&1; then
  git fetch "$REMOTE" "$BRANCH"
  git worktree add -B "$BRANCH" "$WORKTREE_DIR" "$REMOTE/$BRANCH"
else
  git worktree add --detach "$WORKTREE_DIR"
  (
    cd "$WORKTREE_DIR"
    git checkout --orphan "$BRANCH"
    git rm -rf . >/dev/null 2>&1 || true
  )
fi

(
  cd "$WORKTREE_DIR"

  find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +

  if [[ "$LAYOUT" == "docs" ]]; then
    mkdir -p docs
    rsync -a --delete ../dist/ docs/
  else
    rsync -a --delete ../dist/ ./
  fi

  # Prevent Jekyll from rewriting output paths unexpectedly.
  touch .nojekyll

  git add -A
  if git diff --cached --quiet; then
    echo "No changes to publish on $BRANCH."
  else
    git commit -m "Publish dist from $(git -C .. rev-parse --short HEAD)"
    git push "$REMOTE" "$BRANCH"
    echo "Published dist to $REMOTE/$BRANCH ($LAYOUT layout)."
  fi
)

git worktree remove --force "$WORKTREE_DIR"
