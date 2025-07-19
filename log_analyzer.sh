#!/bin/bash

# Check input
if [ $# -ne 1 ]; then
  echo "Usage: $0 <log_file>"
  exit 1
fi

LOG_FILE="$1"

if [ ! -f "$LOG_FILE" ]; then
  echo "Error: File '$LOG_FILE' not found."
  exit 1
fi


DATE_NOW=$(date "+%a %b %d %T %Z %Y")
FILE_SIZE_BYTES=$(stat -c%s "$LOG_FILE")
FILE_SIZE_MB=$(awk "BEGIN {printf \"%.1f\", $FILE_SIZE_BYTES/1024/1024}")
OUTPUT_FILE="log_analysis_$(date '+%Y%m%d_%H%M%S').txt"


ERROR_COUNT=$(grep -c "ERROR" "$LOG_FILE")
WARNING_COUNT=$(grep -c "WARNING" "$LOG_FILE")
INFO_COUNT=$(grep -c "INFO" "$LOG_FILE")


TOP_ERRORS=$(grep "ERROR" "$LOG_FILE" | sed -E 's/^.*ERROR[[:space:]]+//' | \
            sort | uniq -c | sort -nr | head -n 5)


FIRST_ERROR=$(grep "ERROR" "$LOG_FILE" | head -n 1)
LAST_ERROR=$(grep "ERROR" "$LOG_FILE" | tail -n 1)


HOUR_HISTOGRAM=$(grep "ERROR" "$LOG_FILE" | \
    grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}' | \
    cut -d' ' -f2 | \
    awk '{
        hour=int($1);
        if (hour >= 0 && hour < 4) bucket="00-04";
        else if (hour < 8) bucket="04-08";
        else if (hour < 12) bucket="08-12";
        else if (hour < 16) bucket="12-16";
        else if (hour < 20) bucket="16-20";
        else bucket="20-24";
        count[bucket]++;
    } END {
        for (b in count) {
            printf "%s: %-20s (%d)\n", b, bar(count[b]), count[b];
        }
    }
    function bar(n) {
        s="";
        for (i=0; i<n/5; i++) s=s "█";
        return s;
    }' | sort)


{
echo "===== LOG FILE ANALYSIS REPORT ====="
echo "File: $LOG_FILE"
echo "Analyzed on: $DATE_NOW"
echo "Size: ${FILE_SIZE_MB}MB ($FILE_SIZE_BYTES bytes)"
echo
echo "MESSAGE COUNTS:"
echo "ERROR: $ERROR_COUNT messages"
echo "WARNING: $WARNING_COUNT messages"
echo "INFO: $INFO_COUNT messages"
echo
echo "TOP 5 ERROR MESSAGES:"
echo "$TOP_ERRORS"
echo
echo "ERROR TIMELINE:"
echo "First error: [$FIRST_ERROR]"
echo "Last error:  [$LAST_ERROR]"
echo
echo "Error frequency by hour:"
echo "$HOUR_HISTOGRAM"
echo
echo "Report saved to: $OUTPUT_FILE"
} | tee "$OUTPUT_FILE"
