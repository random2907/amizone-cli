read -p "Enter User ID: " username
read -sp "Enter Password: " password

response=$(curl -is https://s.amizone.net/)


requestcookie=$(echo "$response" | grep "set-cookie:" | grep -i '^set-cookie: __RequestVerificationToken=' | awk -F '=' '{print $2}' | awk '{gsub(/;/,""); print $1}')



requestver1=$(echo "$response" | grep '<form action="/" class=" validate-form" id="loginform" method="post" name="loginform"><input name="__RequestVerificationToken" type="hidden" value=' | grep -oP '<input[^>]*name="__RequestVerificationToken"[^>]*value="\K[^"]*')


asp=$(curl -s 'https://s.amizone.net/' -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Referer: https://s.amizone.net/' -H "Connection: keep-alive" -H "Cookie: __RequestVerificationToken=$requestcookie" --data-raw "__RequestVerificationToken=$requestver1&_UserName=$username&_QString=&_Password=$password" -c - | grep -oP '.ASPXAUTH\t\K[^\t]*')


session=$(curl -s 'https://s.amizone.net/' -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0' -H 'Referer: https://s.amizone.net/' -H "Connection: keep-alive" -H "Cookie: __RequestVerificationToken=$requestcookie" --data-raw "__RequestVerificationToken=$requestver1" -c - | grep -oP 'ASP.NET_SessionId\t\K[^\t]*')

exam_result(){
	
	local exam=$(curl -s 'https://s.amizone.net/Examination/Examination?X-Requested-With=XMLHttpRequest' --compressed -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0' -H 'Referer: https://s.amizone.net/Home' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H "Cookie: __RequestVerificationToken=$requestcookie; ASP.NET_SessionId=$session; .ASPXAUTH=$asp")

	local input_data=$(echo "$exam" | grep "data-title=" | head -n -4 | sed 's/^[[:space:]]*//' | sed -e 's/<[^>]*>//g' | sed 's/\s*$//')

	local x='['
	local xcount=$(echo "$input_data" | wc -l)

	for (( i=0; i<xcount; i+=10 )); do
    	local Sno=$(echo "$input_data" | sed -n "$((i+1))p")
    	local Course_Code=$(echo "$input_data" | sed -n "$((i+2))p")
    	local Course_Title=$(echo "$input_data" | sed -n "$((i+3))p")
    	local Max_Total=$(echo "$input_data" | sed -n "$((i+4))p")
    	local ACU=$(echo "$input_data" | sed -n "$((i+5))p")
    	local Go=$(echo "$input_data" | sed -n "$((i+6))p")
    	local GP=$(echo "$input_data" | sed -n "$((i+7))p")
    	local CP=$(echo "$input_data" | sed -n "$((i+8))p")
    	local ECU=$(echo "$input_data" | sed -n "$((i+9))p")
    	local PublishDate=$(echo "$input_data" | sed -n "$((i+10))p")
    	x+='{"Sno":"'"$Sno"'", "Course_Title":"'"$Course_Title"'", "Max_Total":"'"$Max_Total"'", "ACU":"'"$ACU"'", "Go":"'"$Go"'", "GP":"'"$GP"'", "CP":"'"$CP"'", "ECU":"'"$ECU"'", "PublishDate":"'"$PublishDate"'"}'
    	if [ $((i+10)) -lt $xcount ]; then
        	x+=','
    	fi
		done
	x+=']'

	echo $x

}


fee(){

	local req_fee=$(curl -s 'https://s.amizone.net/FeeStructure/FeeStructure/AllFeeReceipt' -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'Referer: https://s.amizone.net/Home' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H "Cookie: __RequestVerificationToken=$requestcookie; ASP.NET_SessionId=$session; .ASPXAUTH=$asp" --data-raw 'ifeetype=1' | sed 's/^"\(.*\)"$/\1/' | tr -d '\\')
	echo "$req_fee"
}

class_schedule(){

	read -p "Enter the start date in YYYY-MM-DD format: " start_date
	read -p "Enter the end date in YYYY-MM-DD format: " end_date

	local class=$(curl -s "https://s.amizone.net/Calendar/home/GetDiaryEvents?start=$start_date&end=$end_date&_=1707456987909" -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0' -H 'Referer: https://s.amizone.net/Home' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H "Cookie: __RequestVerificationToken=$requestcookie; .ASPXAUTH=$asp")

	echo "$class"
}


attendance(){

	local attendance_request=$(curl -s 'https://s.amizone.net/Home/_Home?X-Requested-With=XMLHttpRequest' --compressed -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0' -H 'Referer: https://s.amizone.net/Home' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H "Cookie: __RequestVerificationToken=$request; .ASPXAUTH=$asp")

	local input_data=$(echo "$attendance_request" | grep -E 'sub-code|class-count' | sed 's/^[[:space:]]*//' | head -n 18 | sed -e 's/<[^>]*>//g' | sed 's/ \{2,\}/&\n/' | sed 's/\s*$//')

	local x='['
	local xcount=$(echo "$input_data" | wc -l)

	for (( i=0; i<xcount; i+=3 )); do
    	local code=$(echo "$input_data" | sed -n "$((i+1))p")
    	local title=$(echo "$input_data" | sed -n "$((i+2))p")
    	local completion_percentage=$(echo "$input_data" | sed -n "$((i+3))p")
    	local x+='{"code":"'"$code"'", "title":"'"$title"'", "completion_percentage":"'"$completion_percentage"'"}'
    	if [ $((i+3)) -lt $xcount ]; then
        	x+=','
    	fi
		done

	x+=']'

	echo "$x"

}

count=0
while [ $count != 1 ]
do
	menu="\n1. Exam Result\n2. Fee Structure\n3. Class Schedule\n4. Attendance\n5. Exit\nEnter your choice: "
	read -p "$(echo -e $menu)" choice
	case $choice in
	1) exam_result
	;;
	2) fee
	;;
	3) class_schedule
	;;
	4) attendance
	;;
	5) count=1
	;;
	*) echo "Invalid choice"
	;;
esac
done

