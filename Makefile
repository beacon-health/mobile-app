.PHONY: run test analyze format l10n clean

DEFINES_FILE := config/dart_defines.json

# ── Default developer command ─────────────────────────────────────────────────
# Reads secrets from config/dart_defines.json (gitignored).
# Copy config/dart_defines.json.example → config/dart_defines.json and fill in
# your keys before running for the first time.
run:
	flutter run --dart-define-from-file=$(DEFINES_FILE)

test:
	flutter test

analyze:
	flutter analyze --fatal-infos

format:
	dart format .

l10n:
	flutter gen-l10n

clean:
	flutter clean
