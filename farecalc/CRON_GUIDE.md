# Month-end cron setup - L55 Metro Fare Calculator

Project path: `$HOME/linux_project/Hadi/farecalc`

1. Test first (manual, does NOT prove cron ran):
```
cd ~/linux_project/Hadi/farecalc
./main.sh --cron
cat reports/monthly_fare_vs_pass.txt
```

2. Start cron service in WSL Ubuntu: `sudo service cron start`.
3. Run `crontab -e` (without sudo), then add this line:

```
0 21 28-31 * * [ "$(date -d tomorrow +\%d)" = "01" ] && /bin/bash "$HOME/linux_project/Hadi/farecalc/main.sh" --cron >> "$HOME/linux_project/Hadi/farecalc/logs/cron.log" 2>&1
```

The five fields mean `minute hour day-of-month month day-of-week`. The date check
makes 9 PM run only on the actual last calendar day. The `\%` is required in crontab.
The schedule runs in your Ubuntu's configured timezone. WSL and cron must be running.

4. Verify: `crontab -l` and later `cat logs/cron.log`.
5. Save a real screenshot of `crontab -l` and actual scheduled logs for your report.

**Do not use `sudo crontab -e`** and do not replace your existing GST or Hamza
cron entries. Add this on a new line. Remove it once the coursework is over.

If testing the schedule itself is necessary, temporarily use a cron expression
for the next two minutes and restore the original when done. Keep the test on
user-owned files; do not change the computer's date or system time.
