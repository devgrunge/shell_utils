#!/bin/bash

git fetch --prune

# Mock date time (3 months)
OUTDATED_BRANCHE_DATETIME=$(date -v -3m "+%Y-%m-%d")

ALL_BRANCHES=$(git branch --format "%(refname:short) %(committerdate:iso8601)")

OLD_BRANCHES=$(echo "$ALL_BRANCHES" | awk -v date="$OUTDATED_BRANCHE_DATETIME" '$2 < date {print $1}')

BRANCH_COUNT=$(echo "$OLD_BRANCHES" | wc -l)

if [[ -z "$OLD_BRANCHES" || "$BRANCH_COUNT" -eq 0 ]]; then
    echo "No outdated branches found."
    echo "Here are all existing branches and their last updated dates:"
    echo "$ALL_BRANCHES"
    exit 0
fi

echo "The following $BRANCH_COUNT branches have not been updated for over 3 months:"
echo "$OLD_BRANCHES"
echo ""

read -p "Are you sure you want to delete these $BRANCH_COUNT outdated branches? [y/N]: " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Deleting outdated branches..."
    echo "$OLD_BRANCHES" | xargs git branch -D
    echo "Deletion complete!"
else
    echo "No branches were deleted."
fi