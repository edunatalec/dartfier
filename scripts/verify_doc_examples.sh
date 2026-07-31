#!/bin/bash
set -e

TOTAL_STEPS=3
STEP=0
step() {
  STEP=$((STEP + 1))
  echo
  echo "[$STEP/$TOTAL_STEPS] $1"
}

OUT="doc_examples_tmp"
SKIP_FILES="lib/src/observer.dart lib/src/async_value.dart"

step "Cleaning previous run"
rm -rf "$OUT"
mkdir -p "$OUT"

cat > "$OUT/analysis_options.yaml" <<'YAML'
analyzer:
  language:
    strict-casts: true
  errors:
    unused_local_variable: ignore
    unused_element: ignore
    unused_import: ignore
YAML

step "Extracting samples from lib/"

TOTAL=0
SKIPPED=0

for FILE in $(find lib -name '*.dart' | sort); do
  COUNT=$(grep -c '/// ```dart' "$FILE" || true)

  if [ "$COUNT" -eq 0 ]; then
    continue
  fi

  case " $SKIP_FILES " in
    *" $FILE "*)
      SKIPPED=$((SKIPPED + COUNT))
      TOTAL=$((TOTAL + COUNT))
      echo "  skipped $FILE — $COUNT sample(s) in widget context"
      continue
      ;;
  esac

  TOTAL=$((TOTAL + COUNT))

  awk -v out="$OUT" -v q="'" -v base="$(basename "$FILE" .dart)" '
    function flush() {
      if (buffer == "") return

      name = sprintf("%s/%s_%d.dart", out, base, start)

      print "import " q "dart:async" q ";" > name
      print "" > name
      print "import " q "package:dartfier/dartfier.dart" q ";" > name
      print "import " q "package:flutter/foundation.dart" q ";" > name
      print "import " q "package:flutter/widgets.dart" q ";" > name
      print "" > name
      print "Future<void> example() async {" > name
      printf "%s", buffer > name
      print "}" > name
      close(name)

      buffer = ""
      start = 0
    }
    {
      line = $0
      sub(/^[ \t]*/, "", line)

      if (line ~ /^\/\/\//) {
        sub(/^\/\/\/ ?/, "", line)

        if (line ~ /^```dart/) {
          fenced = 1
          if (start == 0) start = NR
          next
        }

        if (line ~ /^```/) {
          fenced = 0
          next
        }

        if (fenced) buffer = buffer "  " line "\n"

        indoc = 1
        next
      }

      if (indoc) {
        flush()
        indoc = 0
      }
    }
    END { flush() }
  ' "$FILE"
done

FILES=$(find "$OUT" -name '*.dart' | wc -l | tr -d ' ')
echo "  $TOTAL sample(s) found, $SKIPPED skipped, $((TOTAL - SKIPPED)) extracted into $FILES file(s)"

step "Analyzing extracted samples"
dart analyze "$OUT"

rm -rf "$OUT"
