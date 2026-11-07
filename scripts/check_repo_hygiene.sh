#!/usr/bin/env bash
# GOV-01: fails (exit 1) if third-party or generated material is tracked by git.
cd "$(dirname "$0")/.." || exit 2
bad=$(git ls-files | grep -E -i '\.(apk|aab|riv)$|duolingo[^/]*\.(png|jpg|gif|apk|json|txt|html|zip)$|^research/(captures|live-reference-[^/]+/frames)/|^research/animation-reference/(media|runtime)/|^research/.*\.(png|jpg|gif|mp4|webm)$|^tools/jadx|^OPEN-BUILD-reference-pack\.zip$|^Mascot concepts$')
if [ -n "$bad" ]; then echo "Tracked third-party/generated files:"; echo "$bad"; exit 1; fi
echo "Repository hygiene OK"
