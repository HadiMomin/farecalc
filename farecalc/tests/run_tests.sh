#!/usr/bin/env bash
# All tests run on a temporary COPY of the project, never on real data.
set -euo pipefail
SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
command -v bc >/dev/null || { echo 'Missing bc. Install: sudo apt install bc'; exit 1; }
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
cp -a "$SRC"/. "$TMP"/
cd "$TMP"
passed=0
ok() { passed=$((passed+1)); printf 'PASS %02d  %s\n' "$passed" "$1"; }
assert_grep() { grep -Fq -- "$2" <<< "$1" || { echo "FAIL: $3" >&2; printf '%s\n' "$1" >&2; exit 1; }; }

[[ $(awk -F',' 'END{print NR-1}' data/stations.csv) -ge 15 ]]; ok 'At least 15 stations'
[[ $(awk -F',' 'END{print NR-1}' data/journeys.csv) -ge 10 ]]; ok 'Seed journey data'
q=$(./main.sh --fare Vastral 'Nirant Cross Road'); assert_grep "$q" 'INR 5.00' 'short slab'; ok 'Short journey: INR 5'
q=$(./main.sh --fare Vastral 'Rabari Colony'); assert_grep "$q" 'INR 10.00' 'local slab'; ok 'Local journey: INR 10'
q=$(./main.sh --fare Vastral Kalupur); assert_grep "$q" 'INR 15.00' 'medium slab'; ok 'Medium journey: INR 15'
q=$(./main.sh --fare Vastral 'Old High Court'); assert_grep "$q" 'INR 20.00' 'long slab'; ok 'Long journey: INR 20'
q=$(./main.sh --fare Vastral Thaltej); assert_grep "$q" 'INR 25.00' 'extended slab'; ok 'Extended journey: INR 25'
q=$(./main.sh --fare thaltej VASTRAL); assert_grep "$q" 'INR 25.00' 'reverse case-insensitive'; ok 'Reverse trip + case-insensitive names'
if ./main.sh --fare Vastral Vastral >/dev/null 2>&1; then echo 'FAIL: same station allowed'; exit 1; fi; ok 'Same-station trips rejected'
if ./main.sh --fare Vastral Unknown >/dev/null 2>&1; then echo 'FAIL: unknown station allowed'; exit 1; fi; ok 'Unknown station rejected'
if ./main.sh --log Vastral Thaltej 2026-02-30 >/dev/null 2>&1; then echo 'FAIL: invalid date allowed'; exit 1; fi; ok 'Invalid calendar date rejected'
q=$(./main.sh --monthly 2026-10); assert_grep "$q" 'Journeys: 10' 'month count'; assert_grep "$q" 'INR 195.00' 'month total'; ok 'October monthly travel summary'
q=$(./main.sh --compare 2026-10); assert_grep "$q" 'Single tickets are cheaper by INR 605.00' 'pass comparison'; ok 'Monthly pass comparison'
q=$(./main.sh --frequent); assert_grep "$q" 'Vastral -> Thaltej' 'frequent route'; ok 'Most frequent route ranking'
./main.sh --log Vastral Thaltej 2026-10-28 >/dev/null
[[ $(wc -l < data/journeys.csv) -eq 14 ]]; q=$(./main.sh --monthly 2026-10); assert_grep "$q" 'INR 220.00' 'new month total'; ok 'Journey logging and updated monthly spending'
./main.sh --backup >/dev/null
b=$(find backups -type f -name '*.tar.gz' | head -n 1)
[[ -f "$b" ]]; tar -tzf "$b" | grep -q 'data/stations.csv'; ok 'Verified tar.gz backup'
./main.sh --cron 2026-10 >/dev/null
[[ -s reports/monthly_comparison_2026-10.txt && -s reports/monthly_fare_vs_pass.txt ]]; ok 'Scheduled monthly report generation'
./main.sh --cron 2026-10 >/dev/null
[[ $(find reports -name 'monthly_comparison_2026-10.txt' | wc -l) -eq 1 ]]; ok 'Monthly report can be rerun safely'
[[ -s logs/activity.log && -s reports/cron_output.txt ]]; ok 'Activity and scheduled execution logs'
[[ $(grep -c '^date,from,to,fare$' data/journeys.csv) -eq 1 ]]; ok 'Journey CSV header preserved'
# Check that the interactive menu triggers the same routines.
q=$(printf '1\nVastral\nThaltej\n3\n2026-10\n4\n2026-10\n5\n0\n' | ./main.sh)
assert_grep "$q" 'INR 25.00' 'interactive fare'; assert_grep "$q" 'MOST FREQUENT DIRECTED ROUTES' 'interactive ranking'; ok 'Interactive menu features work'
# Pass price can be modified in the test copy only.
q=$(printf '9\n120.00\n0\n' | ./main.sh)
[[ $(cat data/pass_price.txt) == '120.00' ]]; ok 'Sample pass price editable in menu'
q=$(./main.sh --compare 2026-10)
assert_grep "$q" 'Sample pass is cheaper by INR 100.00' 'updated pass price'; ok 'Pass recommendations adjust to price changes'
printf '\nALL %d AUTOMATED TESTS PASSED (test copy only).\n' "$passed"
