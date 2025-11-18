#!/bin/bash

echo "================================"
echo "Package Structure Verification"
echo "================================"
echo ""

# Check essential files
echo "=== Essential Files ==="
for file in DESCRIPTION NAMESPACE LICENSE README.md NEWS.md; do
    if [ -f "$file" ]; then
        echo "✓ $file"
    else
        echo "✗ $file MISSING"
    fi
done
echo ""

# Check directories
echo "=== Directories ==="
for dir in R tests man inst; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -type f | wc -l)
        echo "✓ $dir/ ($count files)"
    else
        echo "⚠ $dir/ (not yet created)"
    fi
done
echo ""

# Check R files
echo "=== R Source Files ==="
find R -name "*.R" -type f | sort | while read f; do
    lines=$(wc -l < "$f")
    printf "✓ %-35s %5d lines\n" "$f" "$lines"
done
echo ""

# Check test files
echo "=== Test Files ==="
if [ -d "tests/testthat" ]; then
    find tests/testthat -name "*.R" -type f | sort | while read f; do
        lines=$(wc -l < "$f")
        tests=$(grep -c "test_that" "$f" 2>/dev/null || echo 0)
        printf "✓ %-35s %5d lines, %2d tests\n" "$f" "$lines" "$tests"
    done
else
    echo "⚠ No test files found"
fi
echo ""

# Check for common issues
echo "=== Syntax Check ==="
echo "Checking for common R syntax issues..."

# Check for unclosed braces
echo -n "Checking for balanced braces... "
for f in R/*.R tests/testthat/*.R; do
    if [ -f "$f" ]; then
        open=$(grep -o '{' "$f" | wc -l)
        close=$(grep -o '}' "$f" | wc -l)
        if [ "$open" -ne "$close" ]; then
            echo "✗"
            echo "  Warning: $f has unbalanced braces (open: $open, close: $close)"
        fi
    fi
done
echo "✓"

# Check for TODO/FIXME comments
echo -n "Checking for TODO/FIXME comments... "
todos=$(grep -r "TODO\|FIXME" R/ tests/ 2>/dev/null | wc -l)
if [ "$todos" -gt 0 ]; then
    echo "⚠ Found $todos TODO/FIXME comments"
else
    echo "✓"
fi

echo ""
echo "=== Package Statistics ==="
total_lines=$(find R -name "*.R" -type f -exec wc -l {} + | tail -1 | awk '{print $1}')
total_functions=$(grep -h "^[a-zA-Z_][a-zA-Z0-9_]* <-" R/*.R | wc -l)
exported_functions=$(grep -h "@export" R/*.R | wc -l)
echo "Total R code lines: $total_lines"
echo "Total functions: $total_functions"
echo "Exported functions: $exported_functions"
echo ""

echo "================================"
echo "Structure check complete!"
echo "================================"
