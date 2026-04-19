#!/bin/sh
# Fail CI if token-pure code regresses (uses raw hex or legacy AppTheme).
# Scoped to NEW code written during the visual-foundation spec. Legacy
# directories (lib/workouts, lib/recipes, lib/tracker, etc.) are exempt
# until each migrates in its own follow-up spec.
#
# Escape hatch: append `// ALLOW-HEX: <reason>` to a line to permit a raw
# Color hex (used once for the ActivityCard map placeholder, and once for
# the WorkoutHeroCard const-required light-mode shadow).

set -eu

FORBIDDEN_DIRS="lib/widgets/core lib/navigation lib/screens/home_screen.dart lib/shared/theme"

# Raw hex scan — ignore the tokens file itself (where the palette is defined)
# and any line bearing an ALLOW-HEX marker.
HEX_HITS=$(grep -rn --include='*.dart' 'Color(0x' $FORBIDDEN_DIRS 2>/dev/null \
  | grep -v 'ALLOW-HEX:' \
  | grep -v 'lib/shared/theme/trego_tokens.dart' || true)

if [ -n "$HEX_HITS" ]; then
  echo "ERROR: raw hex literal found in token-pure code:"
  echo "$HEX_HITS"
  echo "Use context.tokens.<name> instead, or add '// ALLOW-HEX: reason' to the line."
  exit 1
fi

# Legacy AppTheme reference scan
THEME_HITS=$(grep -rn --include='*.dart' 'AppTheme\.' $FORBIDDEN_DIRS 2>/dev/null || true)
if [ -n "$THEME_HITS" ]; then
  echo "ERROR: deprecated AppTheme reference in token-pure code:"
  echo "$THEME_HITS"
  exit 1
fi

echo "check-tokens.sh: OK"
