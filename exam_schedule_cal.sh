#!/bin/env bash



if [ $# -gt 0 ]; then
	x=$(jq -r '.[] | .Course_Code, .Course_Title, .Date, .Time' < "$1")
else
        x=$(jq -r '.[] | .Course_Code, .Course_Title, .Date, .Time')
fi

echo -e "BEGIN:VCALENDAR\nVERSION:2.0\nCALSCALE:GREGORIAN" > nice.ics

xcount=$(echo "$x" | wc -l)

for (( i=1; i<=$xcount; i+=4 )); do
	echo "BEGIN:VEVENT" >> nice.ics
	echo "SUMMARY:$(echo "$x" | sed -n "$i"p)" >> nice.ics
        echo "DESCRIPTION:$(echo "$x" | sed -n "$((i+1))"p)" >> nice.ics
        date="$(echo "$x" | sed -n "$((i+2))"p | cut -d '/' --fields=1)"
        month="$(echo "$x" | sed -n "$((i+2))"p | cut -d '/' --fields=2)"
        year="$(echo "$x" | sed -n "$((i+2))"p | cut -d '/' --fields=3)"
        time="$(echo "$x" | sed -n "$((i+3))"p)"
        formated_date_time="$(echo "$year/$month/$date $time")"
	echo "DTSTART;TZID=Asia/Kolkata:$(date -d "$(echo "$formated_date_time")" +%Y%m%dT%H%M%S)" >> nice.ics
	echo -e "SEQUENCE:3\nBEGIN:VALARM\nTRIGGER:-PT10M\nACTION:DISPLAY\nEND:VALARM\nEND:VEVENT" >> nice.ics
done

echo "END:VCALENDAR" >> nice.ics


