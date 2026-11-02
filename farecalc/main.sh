#!/usr/bin/env bash
# L55 - Metro Fare Calculator; college demonstration project.
set -o pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")" || exit 1
source lib/functions.sh

case "${1:-}" in
  --help|-h) show_help; exit 0 ;;
  --backup) do_backup; exit $? ;;
  --cron) cron_task "${2:-}"; exit $? ;;
  --fare) [[ $# -eq 3 ]] || { echo 'Usage: ./main.sh --fare "From" "To"' >&2; exit 2; }; fare_quote "$2" "$3"; exit $? ;;
  --log) [[ $# -ge 3 && $# -le 4 ]] || { echo 'Usage: ./main.sh --log "From" "To" [YYYY-MM-DD]' >&2; exit 2; }; log_journey "$2" "$3" "${4:-$(date +%F)}"; exit $? ;;
  --monthly) monthly_report "${2:-$(date +%Y-%m)}"; exit $? ;;
  --compare) compare_pass "${2:-$(date +%Y-%m)}"; exit $? ;;
  --frequent) frequent_routes; exit $? ;;
  '') ;;
  *) echo "Unknown option: $1. Run ./main.sh --help" >&2; exit 2 ;;
esac

while true; do
  printf '\n=============================================\n'
  printf '  L55  |  METRO FARE CALCULATOR  |  F20\n'
  printf '=============================================\n'
  printf ' 1) Fare by distance slabs (case)\n'
  printf ' 2) Log a journey\n'
  printf ' 3) Monthly travel cost\n'
  printf ' 4) Compare with monthly pass price\n'
  printf ' 5) Most frequent route\n'
  printf ' 6) View data (stations and journeys)\n'
  printf ' 7) Backup data (tar.gz)\n'
  printf ' 8) View activity log\n'
  printf ' 9) Update sample monthly pass price\n'
  printf ' 0) Exit\n'
  printf '%s\n' '---------------------------------------------'
  read -r -p 'Choose an option: ' ch || { echo; break; }
  case "$ch" in
    1) feature_1 ;;
    2) feature_2 ;;
    3) feature_3 ;;
    4) feature_4 ;;
    5) feature_5 ;;
    6) view_data ;;
    7) do_backup ;;
    8) view_log ;;
    9) update_pass ;;
    0) echo 'Goodbye!'; break ;;
    *) echo 'Invalid menu choice.' ;;
  esac
done
