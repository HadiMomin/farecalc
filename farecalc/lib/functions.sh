#!/usr/bin/env bash
# L55: Metro Fare Calculator - reusable functions.
# All fares, distances and monthly pass prices are illustrative classroom data.
DATA=data/stations.csv
DATA2=data/journeys.csv
PASS=data/pass_price.txt
LOG=logs/activity.log

log() {
  printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"
}

check_data() {
  local f
  for f in "$DATA" "$DATA2" "$PASS"; do
    [[ -f "$f" && -r "$f" ]] || { echo "Missing/unreadable file: $f" >&2; return 1; }
  done
  [[ $(head -n 1 "$DATA") == 'station,distance_km' ]] || { echo 'Invalid stations CSV header.' >&2; return 1; }
  [[ $(head -n 1 "$DATA2") == 'date,from,to,fare' ]] || { echo 'Invalid journeys CSV header.' >&2; return 1; }
}

show_help() {
  cat <<'USAGE'
L55 - Metro Fare Calculator (illustrative data; NOT official ticket prices)
Usage:
 ./main.sh                       Interactive menu
 ./main.sh --help                Help
 ./main.sh --fare "From" "To"    Check a fare
 ./main.sh --log "From" "To" [YYYY-MM-DD]   Save a journey
 ./main.sh --monthly [YYYY-MM]   Monthly travel total
 ./main.sh --compare [YYYY-MM]   Monthly travel versus pass
 ./main.sh --frequent            Most frequent route(s)
 ./main.sh --backup              Tar.gz data backup
 ./main.sh --cron [YYYY-MM]      Write monthly comparison report
USAGE
}

valid_month() { [[ "$1" =~ ^[0-9]{4}-(0[1-9]|1[0-2])$ ]]; }
valid_date() {
  [[ "$1" =~ ^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$ ]] || return 1
  [[ "$(date -d "$1" +%F 2>/dev/null)" == "$1" ]]
}

# Find station by exact, case-insensitive name. Output canonical spelling + km.
station_record() {
  local needle=${1,,}
  awk -F',' -v key="$needle" 'NR>1 && tolower($1)==key { print $1 "," $2; found=1; exit }
    END {if(!found) exit 1}' "$DATA"
}

list_stations() {
  printf '%-26s %s\n' 'Station' 'Sample distance (km)'
  printf '%s\n' '----------------------------------------------'
  awk -F',' 'NR>1 { printf "%-26s %8.1f\n", $1, $2 }' "$DATA"
}

# Compute a single trip, returning (from,to,distance,fare) in fields split by |.
# Slabs are for teaching only: 0-2 km=5, >2-5=10, >5-10=15,
# >10-15=20 and >15 km=25 INR. Same-station trips are rejected.
fare_details() {
  local a b ra rb name_a name_b km_a km_b distance slab fare
  a=$1; b=$2
  [[ -n "$a" && -n "$b" ]] || { echo 'Both station names are required.' >&2; return 1; }
  ra=$(station_record "$a") || { echo "Unknown departure station: $a" >&2; return 1; }
  rb=$(station_record "$b") || { echo "Unknown destination station: $b" >&2; return 1; }
  IFS=, read -r name_a km_a <<< "$ra"
  IFS=, read -r name_b km_b <<< "$rb"
  [[ "$name_a" != "$name_b" ]] || { echo 'Choose two different stations.' >&2; return 1; }
  if awk -v a="$km_a" -v b="$km_b" 'BEGIN {exit (a>=b ? 0 : 1)}'; then
    distance=$(echo "scale=2; $km_a - $km_b" | bc)
  else
    distance=$(echo "scale=2; $km_b - $km_a" | bc)
  fi
  # awk assigns a distance class, while Bash case explicitly maps class to fare.
  slab=$(awk -v d="$distance" 'BEGIN { if(d<=2) print "short"; else if(d<=5) print "local";
    else if(d<=10) print "medium"; else if(d<=15) print "long"; else print "extended" }')
  case "$slab" in
    short) fare='5.00' ;;
    local) fare='10.00' ;;
    medium) fare='15.00' ;;
    long) fare='20.00' ;;
    extended) fare='25.00' ;;
    *) echo 'Invalid distance class.' >&2; return 1 ;;
  esac
  printf '%s|%s|%s|%s\n' "$name_a" "$name_b" "$distance" "$fare"
}

fare_quote() {
  check_data || return 1
  local details from to distance fare
  details=$(fare_details "$1" "$2") || return 1
  IFS='|' read -r from to distance fare <<< "$details"
  printf '\nFrom: %-22s To: %s\n' "$from" "$to"
  printf 'Sample distance: %s km\nIllustrative single fare: INR %s\n' "$distance" "$fare"
  log "fare quoted $from -> $to INR $fare"
}

log_journey() {
  check_data || return 1
  local from_arg=$1 to_arg=$2 trip_date=$3 details from to distance fare
  valid_date "$trip_date" || { echo 'Invalid date. Use an actual YYYY-MM-DD calendar date.' >&2; return 1; }
  details=$(fare_details "$from_arg" "$to_arg") || return 1
  IFS='|' read -r from to distance fare <<< "$details"
  printf '%s,%s,%s,%s\n' "$trip_date" "$from" "$to" "$fare" >> "$DATA2" || return 1
  printf 'Journey saved: %s | %s -> %s | %s km | INR %s\n' "$trip_date" "$from" "$to" "$distance" "$fare"
  log "journey saved $trip_date $from -> $to INR $fare"
}

monthly_total() {
  local month=$1
  valid_month "$month" || { echo 'Month format must be YYYY-MM.' >&2; return 1; }
  # Print COUNT|TOTAL. bc handles the final fixed-point output.
  local stats count total
  stats=$(awk -F',' -v m="$month" 'NR>1 && substr($1,1,7)==m {n++; total+=$4}
    END {printf "%d|%.2f", n+0, total+0}' "$DATA2")
  IFS='|' read -r count total <<< "$stats"
  total=$(echo "scale=2; $total / 1" | bc)
  printf '%s|%s\n' "$count" "$total"
}

monthly_report() {
  check_data || return 1
  local month=${1:-$(date +%Y-%m)} stats count total
  stats=$(monthly_total "$month") || return 1
  IFS='|' read -r count total <<< "$stats"
  printf '\nMONTHLY TRAVEL REPORT - %s\n' "$month"
  printf 'Journeys: %s\nTotal spent: INR %s\n' "$count" "$total"
  awk -F',' -v m="$month" 'NR>1 && substr($1,1,7)==m {
    printf "  %s  %-22s -> %-22s INR %6.2f\n", $1, $2, $3, $4
  }' "$DATA2" | sort
  log "monthly cost viewed $month INR $total ($count journeys)"
}

pass_price() {
  local price
  price=$(tr -d '[:space:]' < "$PASS")
  [[ "$price" =~ ^[0-9]+([.][0-9]{1,2})?$ ]] || { echo 'Invalid pass price in data/pass_price.txt' >&2; return 1; }
  printf '%s\n' "$price"
}

comparison_text() {
  check_data || return 1
  local month=$1 stats count total price savings result
  stats=$(monthly_total "$month") || return 1
  IFS='|' read -r count total <<< "$stats"
  price=$(pass_price) || return 1
  printf 'Month: %s\nJourneys: %s\nSingle tickets total: INR %s\n' "$month" "$count" "$total"
  printf 'Illustrative monthly pass: INR %s\n' "$price"
  if [[ $(echo "$total > $price" | bc -l) == 1 ]]; then
    savings=$(echo "scale=2; $total - $price" | bc)
    printf 'Recommendation: Sample pass is cheaper by INR %s\n' "$savings"
  elif [[ $(echo "$total < $price" | bc -l) == 1 ]]; then
    savings=$(echo "scale=2; $price - $total" | bc)
    printf 'Recommendation: Single tickets are cheaper by INR %s\n' "$savings"
  else
    printf 'Recommendation: Both options cost the same.\n'
  fi
}

compare_pass() {
  local month=${1:-$(date +%Y-%m)}
  comparison_text "$month" || return 1
  log "monthly pass comparison viewed $month"
}

frequent_routes() {
  check_data || return 1
  printf '\nMOST FREQUENT DIRECTED ROUTES\n'
  if [[ $(wc -l < "$DATA2") -le 1 ]]; then echo 'No logged journeys.'; return 0; fi
  # Report routes directionally: A -> B differs from B -> A.
  awk -F',' 'NR>1 {print $2 " -> " $3}' "$DATA2" | sort | uniq -c | sort -k1,1nr -k2,2 | head -10
  log 'frequent routes viewed'
}

view_data() {
  check_data || return 1
  printf '\nSTATIONS (sample km positions)\n'
  list_stations
  printf '\nRECENT JOURNEYS\n'
  tail -n 11 "$DATA2"
  printf '\nSAMPLE MONTHLY PASS PRICE: INR %s\n' "$(pass_price)"
  log 'data viewed'
}

do_backup() {
  check_data || return 1
  local out="backups/data_$(date +%Y%m%d_%H%M%S)_$$_${RANDOM}.tar.gz"
  if tar -czf "$out" data/ && tar -tzf "$out" >/dev/null; then
    printf 'Verified backup saved: %s (%s)\n' "$out" "$(du -h "$out" | cut -f1)"
    log "backup created $out"; return 0
  fi
  rm -f -- "$out"
  echo 'Backup failed.' >&2
  return 1
}

view_log() {
  if [[ -f "$LOG" ]]; then tail -n 20 "$LOG"; else echo 'No activity yet.'; fi
}

update_pass() {
  local value
  read -r -p 'Enter new DEMO monthly pass price (INR): ' value || return 1
  if [[ ! "$value" =~ ^[0-9]+([.][0-9]{1,2})?$ ]] || [[ $(echo "$value <= 0" | bc -l) == 1 ]]; then
    echo 'Please enter a positive number with up to two decimals.'; return 1
  fi
  printf '%s\n' "$value" > "$PASS" || return 1
  printf 'Sample monthly pass price updated to INR %s\n' "$value"
  log "demo monthly pass price updated to INR $value"
}

feature_1() {
  local start end
  list_stations
  read -r -p 'From station: ' start || return 1
  read -r -p 'To station: ' end || return 1
  fare_quote "$start" "$end"
}
feature_2() {
  local start end day
  list_stations
  read -r -p 'From station: ' start || return 1
  read -r -p 'To station: ' end || return 1
  read -r -p "Date [YYYY-MM-DD; enter for today]: " day || return 1
  log_journey "$start" "$end" "${day:-$(date +%F)}"
}
feature_3() {
  local month
  read -r -p 'Month [YYYY-MM; enter for current month]: ' month || return 1
  monthly_report "${month:-$(date +%Y-%m)}"
}
feature_4() {
  local month
  read -r -p 'Month [YYYY-MM; enter for current month]: ' month || return 1
  compare_pass "${month:-$(date +%Y-%m)}"
}
feature_5() { frequent_routes; }

# At 9 PM on the last day of the month, cron calls this function.
# Re-running the same month overwrites that month's report, not a new duplicate.
cron_task() {
  local month=${1:-$(date +%Y-%m)} out
  valid_month "$month" || { echo 'Month must be YYYY-MM' >&2; return 1; }
  check_data || return 1
  out="reports/monthly_comparison_${month}.txt"
  {
    printf 'L55 METRO FARE CALCULATOR - MONTH END REPORT\n'
    printf 'Generated: %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    comparison_text "$month"
    printf '\nNote: Demonstration slab fares and pass price, not official transit rates.\n'
  } > "$out" || return 1
  cp "$out" reports/monthly_fare_vs_pass.txt || return 1
  printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$out" >> reports/cron_output.txt
  log "cron report generated $out"
  printf 'Monthly comparison report written: %s\n' "$out"
}
