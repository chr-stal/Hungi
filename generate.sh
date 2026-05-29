#!/bin/bash
# Run this script once to generate the .xcodeproj from project.yml
# Requires: brew install xcodegen

set -e

if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen not found. Installing via Homebrew..."
    brew install xcodegen
fi

echo "Generating MealPrepMVP.xcodeproj..."
xcodegen generate

echo ""
echo "Done! Open the project with:"
echo "  open MealPrepMVP.xcodeproj"
