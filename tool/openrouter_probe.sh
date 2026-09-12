#!/usr/bin/env bash
# Sends the menu scanner's request to OpenRouter in the three shapes the app
# can send it, and prints the HTTP status and the first lines of each answer.
#
# Why this exists: `design/m16_structured_output_fix.md`. The one environment
# that writes this code cannot reach openrouter.ai, and `ChatFailed`
# deliberately carries no error body, so a user report of "הניתוח נכשל" could
# not be told apart from a refused request shape, a retired model id or an
# unusable answer. Run this where the app runs and paste the output into the
# issue — it names the model, the status per shape and the reply head, and it
# never prints the key.
#
#   OPENROUTER_API_KEY=sk-or-... tool/openrouter_probe.sh [model]
#
# Requires curl and python3. Sends three requests, each counted against the
# key's free-tier quota (50 a day at the time of writing).
set -euo pipefail

if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
  echo "OPENROUTER_API_KEY is not set" >&2
  exit 2
fi

# Keep in step with `OpenRouterClient.defaultModel`.
MODEL="${1:-dots-studio/dots-3-note-preview:free}"
ENDPOINT="https://openrouter.ai/api/v1/chat/completions"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# A short real menu, so the reply is quick and the provenance rule has
# something to match. Hebrew on purpose: it is what the app sends.
MENU='עיקריות
אנטריקוט על הגריל 128 - בשר בקר, חמאת עשבים, ירקות מוקפצים
סלמון בתנור 96 - פילה סלמון, ברוקולי, רוטב לימון
פסטה קרבונרה 68 - פסטה, שמנת, בייקון, פרמזן
פיצה מרגריטה 55 - רוטב עגבניות, מוצרלה, בזיליקום
סלט קיסר 62 - חסה, קרוטונים, פרמזן, רוטב קיסר'

SYSTEM='אתה מסווג מנות מתוך תפריט מסעדה לפי מידת ההתאמה שלהן לתזונה קטוגנית. השב אך ורק באובייקט JSON יחיד בצורה {"dishes":[{"name":"...","description":"...","verdict":"orderAsIs|modifiable|nonKeto","why":"...","modification":"..."}],"unclassified":["..."]}'

python3 - "$MODEL" "$SYSTEM" "$MENU" "$WORK" <<'PY'
import json, sys
model, system, menu, work = sys.argv[1:5]
user = "להלן טקסט תפריט מסעדה לניתוח.\n--- תחילת התפריט ---\n" + menu + "\n--- סוף התפריט ---\n"
verdicts = ["orderAsIs", "modifiable", "nonKeto"]

# The schema the app shipped before the fix: two optional properties, open
# objects. A strict-mode validator refuses it.
old_schema = {
    "type": "object",
    "properties": {
        "dishes": {"type": "array", "items": {"type": "object", "properties": {
            "name": {"type": "string"}, "description": {"type": "string"},
            "verdict": {"type": "string", "enum": verdicts},
            "why": {"type": "string"}, "modification": {"type": "string"}},
            "required": ["name", "verdict", "why"]}},
        "unclassified": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["dishes", "unclassified"],
}
# The schema the app sends now.
new_schema = {
    "type": "object",
    "properties": {
        "dishes": {"type": "array", "items": {"type": "object", "properties": {
            "name": {"type": "string"}, "description": {"type": ["string", "null"]},
            "verdict": {"type": "string", "enum": verdicts},
            "why": {"type": "string"}, "modification": {"type": ["string", "null"]}},
            "required": ["name", "description", "verdict", "why", "modification"],
            "additionalProperties": False}},
        "unclassified": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["dishes", "unclassified"],
    "additionalProperties": False,
}

def body(response_format):
    return {
        "model": model,
        "messages": [{"role": "system", "content": system},
                     {"role": "user", "content": [{"type": "text", "text": user}]}],
        "temperature": 0,
        "max_tokens": 6000,
        "response_format": response_format,
    }

shapes = {
    "1_old_strict_schema": {"type": "json_schema", "json_schema": {"name": "reply", "strict": True, "schema": old_schema}},
    "2_new_strict_schema": {"type": "json_schema", "json_schema": {"name": "reply", "strict": True, "schema": new_schema}},
    "3_json_object": {"type": "json_object"},
}
for name, fmt in shapes.items():
    with open(f"{work}/{name}.json", "w") as f:
        json.dump(body(fmt), f, ensure_ascii=False)
PY

echo "model: $MODEL"
for req in "$WORK"/*.json; do
  name="$(basename "$req" .json)"
  start=$(date +%s)
  status=$(curl -sS -o "$WORK/$name.out" -w '%{http_code}' \
    --max-time 180 \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -H "Content-Type: application/json" \
    --data-binary "@$req" "$ENDPOINT" || echo "curl-failed")
  echo
  echo "== $name: HTTP $status in $(( $(date +%s) - start ))s"
  # The reply head only, and never the request: an error body can echo a
  # header, so the key is filtered out of the printed text defensively too.
  head -c 900 "$WORK/$name.out" | sed "s/${OPENROUTER_API_KEY}/<key>/g"
  echo
done
