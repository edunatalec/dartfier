#!/bin/bash
set -e

TOTAL_STEPS=11
STEP=0
step() {
  STEP=$((STEP + 1))
  echo
  echo "[$STEP/$TOTAL_STEPS] $1"
}

step "Installing dependencies"
flutter pub get

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')

step "Verifying README installation snippet matches pubspec version"

README_VERSION=$(grep -E '^\s*dartfier: \^' README.md | head -n1 | sed -E 's/.*\^([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
if [ -z "$README_VERSION" ]; then
  echo
  echo "❌ Aborting release: could not find 'dartfier: ^X.Y.Z' in README.md."
  echo "   The Installation section must pin the current pubspec.yaml version."
  exit 1
fi
if [ "$README_VERSION" != "$VERSION" ]; then
  echo
  echo "❌ Aborting release: README pins dartfier ^${README_VERSION}, but pubspec.yaml is ${VERSION}."
  echo "   Update the README '## Installation' block to '^${VERSION}' before releasing."
  exit 1
fi

echo "README pinned at dartfier ^${README_VERSION} ✓"

step "Analyzing"
flutter analyze

step "Running tests"
flutter test

step "Verifying the examples inside the API docs"
./scripts/verify_doc_examples.sh

step "Generating API docs"
DOC_OUT=$(mktemp -d)
dart doc --output "$DOC_OUT" 2>&1 | tee /dev/stderr | grep -q "Found 0 warnings and 0 errors" || {
  echo
  echo "❌ Aborting release: 'dart doc' reported warnings or errors."
  rm -rf "$DOC_OUT"
  exit 1
}
rm -rf "$DOC_OUT"

step "Validating package (dry-run)"
flutter pub publish --dry-run

step "Running pana (pub.dev score)"
PANA_OUT=$(GIT_ASKPASS= GIT_TERMINAL_PROMPT=0 pana --no-warning . | tee /dev/stderr)
if ! grep -q "Points: 160/160" <<<"$PANA_OUT"; then
  echo
  echo "❌ Aborting release: pana score is below 160/160. Fix the issues above."
  exit 1
fi

step "Creating tag v$VERSION"
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
  echo "Tag v$VERSION already exists, skipping"
else
  git tag "v$VERSION"
fi

step "Pushing"
git push origin master
git push --tags

step "Publishing to pub.dev"
flutter pub publish --force

echo
echo "🎉 Done! Published v$VERSION"
