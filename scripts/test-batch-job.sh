#!/bin/bash

# Test script for the batch job
# Run this after the job completes to verify results

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/rundata/output"

echo "📊 Checking batch job results..."
echo ""

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "❌ Output directory does not exist: $OUTPUT_DIR"
    exit 1
fi

# Count output files
OUTPUT_COUNT=$(find "$OUTPUT_DIR" -name "*.json" -type f | wc -l | tr -d ' ')

if [ "$OUTPUT_COUNT" -eq 0 ]; then
    echo "❌ No output files found in $OUTPUT_DIR"
    exit 1
fi

echo "✅ Found $OUTPUT_COUNT output file(s):"
echo ""

# Display each output file
for file in "$OUTPUT_DIR"/*.json; do
    if [ -f "$file" ]; then
        echo "📄 $(basename "$file"):"
        if command -v python3 &> /dev/null; then
            python3 -m json.tool "$file" 2>/dev/null || cat "$file"
        else
            cat "$file"
        fi
        echo ""
    fi
done

echo "✅ All output files processed successfully!"

