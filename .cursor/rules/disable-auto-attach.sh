#!/bin/bash

# Script to disable auto-attach for all rules except minimal base set
# This implements the index-based rule distribution system

echo "🔧 Disabling auto-attach for all rules except minimal base set..."

# Define the minimal rules that should remain auto-attached
MINIMAL_RULES=(
    "base-rules-minimal.mdc"
    "rule-index.mdc"
    "development-rules.mdc"
    "file-protection-rules.mdc"
)

# Counter for disabled rules
DISABLED_COUNT=0

# Function to disable auto-attach for a file
disable_auto_attach() {
    local file="$1"
    if [[ -f "$file" ]]; then
        # Replace alwaysApply: true with alwaysApply: false
        sed -i '' 's/alwaysApply: true/alwaysApply: false/g' "$file"
        echo "  ✅ Disabled auto-attach: $(basename "$file")"
        ((DISABLED_COUNT++))
    fi
}

# Function to enable auto-attach for a file (for minimal rules)
enable_auto_attach() {
    local file="$1"
    if [[ -f "$file" ]]; then
        # Replace alwaysApply: false with alwaysApply: true
        sed -i '' 's/alwaysApply: false/alwaysApply: true/g' "$file"
        echo "  ✅ Enabled auto-attach: $(basename "$file")"
    fi
}

echo "📋 Processing rules in .cursor/rules directory..."

# Process all .mdc files
for file in .cursor/rules/**/*.mdc; do
    if [[ -f "$file" ]]; then
        filename=$(basename "$file")
        
        # Check if this is a minimal rule that should remain auto-attached
        is_minimal=false
        for minimal_rule in "${MINIMAL_RULES[@]}"; do
            if [[ "$filename" == "$minimal_rule" ]]; then
                is_minimal=true
                break
            fi
        done
        
        if [[ "$is_minimal" == true ]]; then
            enable_auto_attach "$file"
        else
            disable_auto_attach "$file"
        fi
    fi
done

echo ""
echo "📊 Summary:"
echo "  - Disabled auto-attach for $DISABLED_COUNT rules"
echo "  - Kept auto-attach for ${#MINIMAL_RULES[@]} minimal rules"
echo ""
echo "🎯 New auto-attach rules:"
for rule in "${MINIMAL_RULES[@]}"; do
    echo "  - $rule"
done

echo ""
echo "✅ Rule distribution optimization complete!"
echo "   Token usage should be reduced by ~80-90%"
echo ""
echo "📖 Next steps:"
echo "   1. Rules will now load contextually via rule-index.mdc"
echo "   2. Additional rules load based on file patterns and keywords"
echo "   3. Monitor token usage and adjust as needed"
