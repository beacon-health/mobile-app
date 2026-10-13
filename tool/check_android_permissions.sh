#!/usr/bin/env bash
# Fails when the permissions the built Android app requests differ from
# android/permissions.txt. Run after a debug build:
#
#   flutter build apk --debug && tool/check_android_permissions.sh
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
manifest=$(find build/app/intermediates/merged_manifests/debug \
  -name AndroidManifest.xml 2>/dev/null | head -1)
if [ -z "$manifest" ]; then
  echo "No merged manifest found. Run: flutter build apk --debug" >&2
  exit 1
fi

# An element can wrap across lines, so flatten the file before matching.
actual=$(tr '\n' ' ' <"$manifest" |
  grep -oE '<uses-permission(-sdk-23)?[^>]*android:name="[^"]+"' |
  sed -E 's/.*android:name="([^"]+)"/\1/' | sort -u)
expected=$(grep -vE '^[[:space:]]*(#|$)' android/permissions.txt | sort -u)

if [ "$actual" = "$expected" ]; then
  echo "Android permissions match android/permissions.txt."
  exit 0
fi

echo "The built app's permissions differ from android/permissions.txt:" >&2
diff <(echo "$expected") <(echo "$actual") |
  sed -n 's/^< /  no longer requested: /p; s/^> /  newly requested: /p' >&2
echo "A new permission usually arrives with a plugin update. If Beacon uses" >&2
echo "it, add it to android/permissions.txt; if not, remove it in" >&2
echo "android/app/src/main/AndroidManifest.xml with tools:node=\"remove\"." >&2
exit 1
