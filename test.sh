#!/bin/env bash



if [ $# -gt 0 ]; then
	x=$(jq -r '.[] | .title, .start, .end' < "$1")
else
	x=$(cat - | jq -r '.[] | .title, .start, .end')
fi

echo -e "BEGIN:VCALENDAR\nVERSION:2.0\nCALSCALE:GREGORIAN" > nice.ics

xcount=$(echo "$x" | wc -l)

for (( i=1; i<=$xcount; i+=3 )); do
	echo "BEGIN:VEVENT" >> nice.ics
	echo "SUMMARY:$(echo "$x" | sed -n "$i"p)" >> nice.ics
	echo "DTSTART;TZID=Asia/Kolkata:$(date -d "$(echo "$x" | sed -n "$((i+1))"p)" +%Y%m%dT%H%M%S)" >> nice.ics
	echo "DTEND;TZID=Asia/Kolkata:$(date -d "$(echo "$x" | sed -n "$((i+2))"p)" +%Y%m%dT%H%M%S)" >> nice.ics
	echo -e "SEQUENCE:3\nBEGIN:VALARM\nTRIGGER:-PT10M\nACTION:DISPLAY\nEND:VALARM\nEND:VEVENT" >> nice.ics
done

echo "END:VCALENDAR" >> nice.ics

