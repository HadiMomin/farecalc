# L55 - Metro Fare Calculator (Linux Shell Scripting)

**Student:** HADI MOMIN | **Roll:** F20 | **Division:** G | **Enrollment:** 24004501210207

## Problem and target users
A menu-driven Bash utility for commuters to check example metro fares between stations,
record trips, track monthly travel spending and compare it against a monthly pass.
It demonstrates Linux commands rather than an actual metro booking service.

**Important:** This coursework uses **illustrative** station positions, five simplified fare slabs,
and an example INR 800.00 monthly pass. It does NOT represent official Ahmedabad Metro
route distances, fares, eligibility, or pass availability. Verify official fare information
before using results for real travel.

## Folder structure
```
farecalc/
  main.sh                 Interactive menu + CLI arguments
  lib/functions.sh        Functions for all features
  data/stations.csv       station,distance_km (16 sample stations)
  data/journeys.csv       date,from,to,fare (sample trip history)
  data/pass_price.txt     Example monthly pass cost (INR)
  reports/                Monthly comparison report / cron log summary
  backups/                Data archives generated with tar
  logs/activity.log       Operation history
  logs/cron.log           Output from cron (when actually run)
  tests/run_tests.sh      Safe automatic tests on temporary copies
  CRON_GUIDE.md           Cron setup and WSL tips
  README.md               This file
```

## Five required features
1. **Fare by distance slabs using `case`**: Look up two stations, use `bc` to calculate
   absolute distance difference, use `awk` for distance category, and Bash `case` for fare.
2. **Log a journey**: Validate names and calendar date, calculate fare, append row to journeys.csv.
3. **Monthly travel cost**: `awk` aggregates trip counts and spending for a given YYYY-MM.
4. **Compare with pass price**: Compare monthly ticket expense with example pass price using `bc`.
5. **Most frequent route**: `awk`, `sort`, and `uniq -c` rank directed routes by frequency.

Additional: view stations/journeys, update example pass price, compressed backups,
activity logs, command-line options, and a monthly cron report.

## Sample slab configuration (NOT official prices)
| Travel distance | Example fare |
| --- | ---: |
| >0 to 2 km | INR 5 |
| >2 to 5 km | INR 10 |
| >5 to 10 km | INR 15 |
| >10 to 15 km | INR 20 |
| >15 km | INR 25 |

The first/second station distance positions represent positions along a single
**simplified linear teaching route**, not a verified real-world route planner.
Trip direction is preserved in the CSV. The same-station case is rejected.

## Environment
- Ubuntu or WSL Ubuntu, Bash 4+, GNU coreutils, awk, GNU bc, tar, cron (for scheduling).
- `sudo apt install bc cron` if missing. No Python, web access or database required at runtime.

## Running
```
cd ~/linux_project/Hadi/farecalc
chmod +x main.sh tests/run_tests.sh
./main.sh
./main.sh --help
./main.sh --fare "Vastral" "Thaltej"
./main.sh --log "Vastral" "Kalupur" 2026-10-28
./main.sh --monthly 2026-10
./main.sh --compare 2026-10
./main.sh --frequent
./main.sh --backup
./main.sh --cron 2026-10
./tests/run_tests.sh
```
**Tests only modify an isolated temporary copy**, so your main data stays unchanged.

## Data columns
- `stations.csv`: `station` is the sample place name; `distance_km` is a fictional position along the teaching route.
- `journeys.csv`: `date` is YYYY-MM-DD, `from` and `to` refer to listed stations,
  and `fare` records the sample price calculated when the journey is logged.
- `pass_price.txt` holds only a positive numeric example price (default 800.00).

## Backup and logging
Menu 7 / `--backup` creates `backups/data_TIMESTAMP_PID_RANDOM.tar.gz` and validates the
archive with `tar -tzf`. Option 8 reads `logs/activity.log`. File updates append
rather than replacing the original sample trip data. Backup archives are never restored
into other projects automatically.

## Cron task
At **9 PM on the last day of each month**, write the monthly fare-versus-pass comparison
using the cron expression in `CRON_GUIDE.md`. The `--cron` command can be tested manually,
but manual testing does not establish that the cron scheduler has run.

## Linux commands learned
`case`, `awk`, `bc`, `sort`, `uniq -c`, `read`, `grep`, `tail`, `date`,
`ls`, `tar -czf`, `tar -tzf`, `find`, `wc`, `crontab`, `printf`.

## What I learned (personalize before submitting)
- I learned how to create interactive menus using Bash `while` and `case`.
- I learned how to search CSV data using `awk` and save new records to a text file.
- I learned to use `bc` for arithmetic and validate user input before recording journeys.
- I learned how `sort` and `uniq -c` rank repeated data.
- I learned how to schedule scripts with `crontab` and create compressed `tar.gz` backups.

## Notes for college submission
- Replace sample data or add authentic consented test journeys if required.
- Capture your own screenshots of menu options, help, backup, and crontab status.
- Include actual evidence of automated cron execution on Ubuntu/WSL if demanded.
- Follow the campus guide: 3-5 page PDF report and `F20_L55_farecalc.tar.gz`.
