#!/usr/bin/env bash
# Adopts the Linux renders from a failed CI run as the new golden images.
#
# Golden tests only run on Linux (see test/helpers/pump_app.dart), so after an
# intentional visual change: push, let CI fail, look at the uploaded diffs,
# then run this with that run's ID (or no ID for the latest run on the branch).
#
#   tool/update_goldens_from_ci.sh [run-id]
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
branch=$(git branch --show-current)
run_id=${1:-$(gh run list --branch "$branch" --workflow CI --limit 1 \
  --json databaseId --jq '.[0].databaseId')}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
gh run download "$run_id" --name golden-failures --dir "$tmp"

count=0
while IFS= read -r render; do
  name=$(basename "$render" _testImage.png)
  cp "$render" "test/goldens/images/$name.png"
  echo "updated test/goldens/images/$name.png"
  count=$((count + 1))
done < <(find "$tmp" -name '*_testImage.png')

echo "$count golden(s) updated from run $run_id — review, then commit."
