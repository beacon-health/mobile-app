#!/bin/sh
# PreToolUse(Bash) guard: Read(...) deny rules don't cover shell commands, so a
# stray `cat config/dart_defines.json` would still spill secrets into the
# transcript. Block any command that both names a secret file and looks like it
# is reading one out.
payload=$(cat)

cmd=$(printf '%s' "$payload" | python3 -c '
import json,sys
try:
    print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception:
    pass
')

[ -z "$cmd" ] && exit 0

# Compiled artifacts carry secrets too: the Maps key is injected into the built
# APK's manifest. A redacting pipe is NOT trusted here — one already failed to
# match aapt2's output format and leaked a key. Check presence, never dump.
if printf '%s' "$cmd" | grep -Eq '(aapt2?|apkanalyzer)[^|;&]*(xmltree|manifest)'; then
  printf '%s\n' \
    "Blocked: dumping a built APK manifest prints injected API keys." \
    "Check presence only, e.g.:" \
    "  aapt2 dump xmltree app.apk --file AndroidManifest.xml | grep -c 'geo.API_KEY'" >&2
  case "$cmd" in *"grep -c"*|*"grep -q"*) : ;; *) exit 2 ;; esac
fi

# Escape hatch: a command that explicitly redacts values is fine (and is the
# technique this hook's own error message recommends).
case "$cmd" in *redacted*) exit 0 ;; esac

# Templates (anything ending .example) hold placeholders, never secrets. Strip
# those tokens before the name check so editing a template isn't blocked.
# Build flags that merely pass a secrets file to flutter (--dart-define-from-file)
# don't print it either; strip them too.
scan=$(printf '%s' "$cmd" | python3 -c 'import re,sys;s=sys.stdin.read();s=re.sub(r"[^\s\x27\x22]*\.example", "", s);s=re.sub(r"--dart-define-from-file[=\s]+[^\s\x27\x22]+", "", s);print(s)')

# Secret files, by basename (path-independent).
secrets="dart_defines.json Secrets.xcconfig sentry.properties google-services.json GoogleService-Info.plist local.properties key.properties"

# Commands that emit file contents. `grep`/`sed -n`/`awk` included: they are
# perfectly good exfiltration tools.
readers="cat less more head tail bat grep egrep rg sed awk strings xxd od nl open pbcopy"

for s in $secrets; do
  case "$scan" in
    *"$s"*)
      for r in $readers; do
        # match the reader as a word, not as a substring of another token
        if printf '%s' "$cmd" | grep -Eq "(^|[|;&[:space:]()\`])${r}([[:space:]]|$)"; then
          printf '%s\n' \
            "Blocked: '$r' on '$s' would print secret values into the transcript." \
            "" \
            "Check key *names* instead, e.g.:" \
            "  python3 -c \"import json;print(list(json.load(open('config/dart_defines.json'))))\"" \
            "  sed -E 's/=.*/=<redacted>/' sentry.properties" \
            "" \
            "Or ask Rohan to read the value directly." >&2
          exit 2
        fi
      done
      ;;
  esac
done
exit 0
