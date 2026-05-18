#!/bin/bash

# Fix common design standard violations in presentation layer
# Usage: ./Scripts/fix-design-violations.sh [--dry-run]

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "🔍 DRY RUN MODE - showing changes only"
fi

PRESENTATION_DIR="Apps/FinanceOSMac/FinanceOSMac/Presentation"

echo "🎨 Fixing design standard violations..."

# Helper function to apply sed changes
apply_fix() {
  local pattern="$1"
  local replacement="$2"
  local description="$3"

  if $DRY_RUN; then
    echo "  Would fix: $description"
    grep -r "$pattern" "$PRESENTATION_DIR" --include="*.swift" | head -3 || true
  else
    find "$PRESENTATION_DIR" -name "*.swift" -type f -exec sed -i '' "s/$pattern/$replacement/g" {} +
    echo "  ✓ Fixed: $description"
  fi
}

# Font fixes: Common patterns observed in audit
apply_fix "\.font(\.system(size: 11, weight: \.semibold))" ".captionSmall()" "Font size 11 semibold"
apply_fix "\.font(\.system(size: 12, weight: \.medium))" ".labelSmall()" "Font size 12 medium"
apply_fix "\.font(\.system(size: 13, weight: \.medium))" ".bodySmall()" "Font size 13 medium"
apply_fix "\.font(\.system(size: 14, weight: \.semibold))" ".bodyMedium()" "Font size 14 semibold"
apply_fix "\.font(\.system(size: 14, weight: \.medium))" ".bodyMedium()" "Font size 14 medium"
apply_fix "\.font(\.system(size: 16, weight: \.semibold))" ".bodyLarge()" "Font size 16 semibold"
apply_fix "\.font(\.system(size: 18, weight: \.bold))" ".headingMedium()" "Font size 18 bold"
apply_fix "\.font(\.system(size: 28, weight: \.bold))" ".displayMedium()" "Font size 28 bold"

# Color fixes: Basic Color.white → AppColors
# Note: be careful with Color.white in opacity expressions, those need manual review
apply_fix "foregroundColor(\.white)" "foregroundStyle(AppColors.textPrimary)" "Foreground Color.white"
apply_fix "foregroundColor(\.gray)" "foregroundStyle(AppColors.textSecondary)" "Foreground Color.gray"
apply_fix "foregroundColor(\.black)" "foregroundStyle(AppColors.base)" "Foreground Color.black"

# Spacing fixes: Common hardcoded values
apply_fix "\.padding(16)" ".padding(AppSpacing.md)" "Padding 16"
apply_fix "\.padding(8)" ".padding(AppSpacing.xs)" "Padding 8"
apply_fix "\.padding(12)" ".padding(AppSpacing.sm)" "Padding 12"
apply_fix "\.padding(20)" ".padding(AppSpacing.lg)" "Padding 20"
apply_fix "\.padding(24)" ".padding(AppSpacing.xl)" "Padding 24"
apply_fix "\.padding(32)" ".padding(AppSpacing.xxl)" "Padding 32"

# Spacing on axis
apply_fix "\.padding(\.horizontal, 16)" ".padding(.horizontal, AppSpacing.md)" "Horizontal padding 16"
apply_fix "\.padding(\.vertical, 16)" ".padding(.vertical, AppSpacing.md)" "Vertical padding 16"
apply_fix "\.padding(\.horizontal, 12)" ".padding(.horizontal, AppSpacing.sm)" "Horizontal padding 12"
apply_fix "\.padding(\.vertical, 12)" ".padding(.vertical, AppSpacing.sm)" "Vertical padding 12"

echo ""
if $DRY_RUN; then
  echo "📋 Review above changes and run without --dry-run to apply"
else
  echo "✅ Design standard violations fixed!"
  echo "⚠️  Manual review needed for:"
  echo "   - Color.white.opacity() calls (context-dependent)"
  echo "   - Card network RGB colors (domain-specific)"
  echo "   - VStack/HStack surface colors (may need FDSGlassSurface)"
fi
