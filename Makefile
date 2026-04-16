.PHONY: run run-demo test analyze clean

DEFINES_FILE := config/dart_defines.json

# ── Default developer command ─────────────────────────────────────────────────
# Reads secrets from config/dart_defines.json (gitignored).
# Copy config/dart_defines.json.example → config/dart_defines.json and fill in
# your keys before running for the first time.
run:
	flutter run --dart-define-from-file=$(DEFINES_FILE)

# Run in demo mode (no Supabase keys required)
run-demo:
	flutter run --dart-define=DEMO_MODE=true

test:
	flutter test

analyze:
	flutter analyze

clean:
	flutter clean
