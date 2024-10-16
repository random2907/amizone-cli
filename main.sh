#!/bin/env bash

read -p "Enter User ID: " username
read -sp "Enter Password: " password

response=$(curl -is https://s.amizone.net/)
loginform=$(echo "$response" | grep loginform | sed 's/"/\n/g')
loginform_number=$(echo "$response" | grep loginform | sed 's/"/\n/g' | grep -n value= | cut --delimiter=: --fields=1)

requestcookie=$(echo "$response" | grep "set-cookie:" | grep -i '^set-cookie: __RequestVerificationToken=' | awk -F '=' '{print $2}' | awk '{gsub(/;/,""); print $1}')
requestver1=$(echo "$loginform" | sed -n $(($(echo "$loginform_number" | sed -n 1p)+1))p)
salt=$(echo "$loginform" | sed -n $(($(echo "$loginform_number" | sed -n 2p)+1))p)
secret_no=$(echo "$loginform" | sed -n $(($(echo "$loginform_number" | sed -n 3p)+1))p)
signature=$(echo "$loginform" | sed -n $(($(echo "$loginform_number" | sed -n 4p)+1))p)
challenge=$(echo "$loginform" | sed -n $(($(echo "$loginform_number" | sed -n 5p)+1))p)
session=$(curl -s 'https://s.amizone.net/' -X POST  -H 'Referer: https://s.amizone.net/' -H "Connection: keep-alive" -H "Cookie: __RequestVerificationToken=$requestcookie" --data-raw "__RequestVerificationToken=$requestver1" -c - | grep -oP 'ASP.NET_SessionId\t\K[^\t]*')
asp=$(curl -s 'https://s.amizone.net/' -X POST  -H 'Content-Type: application/x-www-form-urlencoded' -H 'Referer: https://s.amizone.net/' -H "Connection: keep-alive" -H "Cookie: __RequestVerificationToken=$requestcookie" --data-raw "__RequestVerificationToken=$requestver1&Salt=$salt&SecretNumber=$secret_no&Signature=$signature&Challenge=$challenge&_UserName=$username&_QString=&_Password=$password&recaptchaToken=" -c - | grep -oP '.ASPXAUTH\t\K[^\t]*')

exam_result(){
        
	read -p "Enter the semester number: " sem

	local exam=$(curl -s 'https://s.amizone.net/Examination/Examination?X-Requested-With=XMLHttpRequest' -H 'Referer: https://s.amizone.net/Home' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H "Cookie: __RequestVerificationToken=$requestcookie; ASP.NET_SessionId=$session; .ASPXAUTH=$asp" --data-raw "sem=$sem")
	local input_data=$(echo "$exam" | grep "data-title=" | head -n -4 | sed 's/^[[:space:]]*//' | sed -e 's/<[^>]*>//g' | sed 's/\s*$//')
	local overall=$(echo "$exam" | grep "&nbsp" | tail -n 4 | sed 's/^[[:space:]]*//' | sed -e 's/<[^>]*>//g' | sed 's/\s*$//' | sed 's/&nbsp;//')
        
	local x='['
        x+='{"Semester":"'"$(echo "$overall" | sed -n 1p)"'", "SGPA":"'"$(echo "$overall" | sed -n 2p)"'", "CGPA":"'"$(echo "$overall" | sed -n 3p)"'", "Back Papers":"'"$(echo "$overall" | sed -n 4p)"'"}'
        x+=','

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
		x+='{"Sno":"'"$Sno"'", "Course Code":"'"$Course_Code"'","Course_Title":"'"$Course_Title"'", "Max_Total":"'"$Max_Total"'", "ACU":"'"$ACU"'", "Go":"'"$Go"'", "GP":"'"$GP"'", "CP":"'"$CP"'", "ECU":"'"$ECU"'", "PublishDate":"'"$PublishDate"'"}'
		if [ $((i+10)) -lt $xcount ]; then
			x+=','
		fi
	done
	x+=']'

	echo "$x"

}

exam_schedule(){

	local exam_sch_req=$(curl -s 'https://s.amizone.net/Examination/ExamSchedule?X-Requested-With=XMLHttpRequest' -H 'Referer: https://s.amizone.net/Home' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H "Cookie: __RequestVerificationToken=$request_cookie; .ASPXAUTH=$asp; asp.net_sessionid=$session")

	local input_data=$(echo "$exam_sch_req" | sed 's/\r$//' | grep "data-title=" | sed 's/^[[:space:]]*//' | sed -e 's/<[^>]*>//g')
	local x='['
	local xcount=$(echo "$input_data" | wc -l)

	for (( i=0; i<xcount; i+=5)); do
		local Course_Code=$(echo "$input_data" | sed -n "$((i+1))p")
		local Course_Title=$(echo "$input_data" | sed -n "$((i+2))p")
		local Date=$(echo "$input_data" | sed -n "$((i+3))p")
		local Time=$(echo "$input_data" | sed -n "$((i+4))p")
		local Exam_Type=$(echo "$input_data" | sed -n "$((i+5))p"| cut --delimiter=" " --fields=4)
		x+='{"Course_Code":"'"$Course_Code"'", "Course_Title":"'"$Course_Title"'", "Date":"'"$Date"'", "Time":"'"$Time"'", "Exam_Type":"'"$Exam_Type"'"}'
		if [ $((i+5)) -lt $xcount ]; then
			x+=','
		fi
	done
	x+=']'
	echo "$x"

}

fee(){

	local req_fee=$(curl -s 'https://s.amizone.net/FeeStructure/FeeStructure/AllFeeReceipt' -X POST -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'Referer: https://s.amizone.net/Home' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H "Cookie: __RequestVerificationToken=$requestcookie; ASP.NET_SessionId=$session; .ASPXAUTH=$asp" --data-raw 'ifeetype=1' | sed 's/^"\(.*\)"$/\1/' | tr -d '\\')
	echo "$req_fee"
}

course_list(){

	read -p "Enter the semester number: " sem
	local req_course=$(curl -s 'https://s.amizone.net/Academics/MyCourses/CourseListSemWise' -X POST -H 'Referer: https://s.amizone.net/Home' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H "Cookie: __RequestVerificationToken=$requestcookie; ASP.NET_SessionId=$session; .ASPXAUTH=$asp" --data-raw "sem=$sem")
	data=$(echo "$req_course" | sed 's/\r$//')
	compulsory_start=$(echo "$data" | grep -n '<tbody>' | head -n 1 | tail -n 1 | cut -d ':' -f 1)

	compulsory_end=$(echo "$data" | grep -n '</tbody>' | head -n 1 |tail -n 1 | cut -d ':' -f 1)

	domain_start=$(echo "$data" | grep -n '<tbody>' | head -n 2 | tail -n 1 | cut -d ':' -f 1)

	domain_end=$(echo "$data" | grep -n '</tbody>' | head -n 2 | tail -n 1 | cut -d ':' -f 1)

	compulsory_data=$(echo "$data" | sed -n "${compulsory_start},${compulsory_end}p" | sed 's/^[[:space:]]*//' | sed -e 's/<[^>]*>//g' | sed 's/View//g' | sed '/^$/d')
	compulsory_link=$(echo "$data" | sed -n "${compulsory_start},${compulsory_end}p" | grep -oP '(?<=href=)[^ ]*' | sed 's/"//g')

	domain_data=$(echo "$data" | sed -n "${domain_start},${domain_end}p" | sed 's/^[[:space:]]*//' | sed -e 's/<[^>]*>//g' | sed 's/View//g' | sed '/^$/d')
	domain_link=$(echo "$data" | sed -n "${domain_start},${domain_end}p" | grep -oP '(?<=href=)[^ ]*' | sed 's/"//g')

	input_data=$(echo "$compulsory_data" && echo "$domain_data")
	input_link=$(echo "$compulsory_link" && echo "$domain_link")
	local x='['
	local xcount=$(echo "$input_data" | wc -l)
	if (echo "$input_data" | grep -q ']' ); then
		local jump=5
	else
		local jump=4
	fi

	for (( i=0; i<xcount; i+=$jump )); do
		local code=$(echo "$input_data" | sed -n "$((i+1))p")
		local title=$(echo "$input_data" | sed -n "$((i+2))p")
		local type=$(echo "$input_data" | sed -n "$((i+3))p")
		local attendence=$(echo "$input_data" | sed -n "$((i+4))p")
		if (( $jump == 5 )); then
			local marks=$(echo "$input_data" | sed -n "$((i+5))p")
		fi
		local link=$(echo "$input_link" | sed -n "$((i/$jump+1))p")
		if (( $jump == 4 )); then
			local x+='{"code":"'"$code"'","title":"'"$title"'","type":"'"$type"'","attendence":"'"$attendence"'","link":"'"$link"'"}'
		else
			local x+='{"code":"'"$code"'","title":"'"$title"'","type":"'"$type"'","attendence":"'"$attendence"'","marks":"'"$marks"'","link":"'"$link"'"}'
		fi
		if [ $((i+$jump)) -lt $xcount ]; then
			x+=','
		fi
	done

	x+=']'
	echo "$x"


}
class_schedule(){

	if [ $1 ]; then
		start_date=$(date -u '+%Y-%m-%d')
		end_date=$(date -u '+%Y-%m-%d')
	else
		read -p "Enter the start date in YYYY-MM-DD format: " start_date
		read -p "Enter the end date in YYYY-MM-DD format: " end_date
	fi

	local class=$(curl -s "https://s.amizone.net/Calendar/home/GetDiaryEvents?start=$start_date&end=$end_date&_=1707456987909"  -H 'Referer: https://s.amizone.net/Home' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H "Cookie: __RequestVerificationToken=$requestcookie; .ASPXAUTH=$asp")

	echo "$class"
}


attendance(){

	local attendance_request=$(curl -s 'https://s.amizone.net/Home/_Home?X-Requested-With=XMLHttpRequest'  -H 'Referer: https://s.amizone.net/Home' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H "Cookie: __RequestVerificationToken=$request; .ASPXAUTH=$asp")

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

faculty(){
        local faculty_request=$(curl -s 'https://s.amizone.net/FacultyFeeback/FacultyFeedback?X-Requested-With=XMLHttpRequest' -H 'Referer: https://s.amizone.net/Home' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H "Cookie: ASP.NET_SessionId=$session; __RequestVerificationToken=$requestcookie; .ASPXAUTH=$asp")
        local token=$(echo "$faculty_request" | grep -oP '(?<=value=)[^ ]*' | sed 's/"//g')
        local faculty_request_data=$(echo "$faculty_request" | grep -oP '(?<=href=)[^ ]*' | sed 's/"//g' | grep "_FeedbackRating" | sed 's/amp;//g')
        local max=$(echo "$faculty_request_data" | wc -l )
	for (( i=1; i<=max; i+=1 )); do
                local per_faculty=$(echo "$faculty_request_data" | sed -n "$i"p | sed 's/%2F/\//g')
                local token=$(curl -s "https://s.amizone.net$per_faculty" --compressed -X POST -H 'Referer: https://s.amizone.net/Home' -H 'X-Requested-With: XMLHttpRequest' -H 'Origin: https://s.amizone.net' -H "Cookie: ASP.NET_SessionId=$session; __RequestVerificationToken=$requestcookie; .ASPXAUTH=$asp" --data-raw 'X-Requested-With=XMLHttpRequest' | grep "/FacultyFeeback/FacultyFeedback/SaveFeedbackRatin" | grep -oP '(?<=value=)[^ ]*' | sed 's/"//g')
                local course_type=$(echo "$per_faculty" | grep -o 'CourseType=[^&]*' | cut -d'=' -f2)
                local det_id=$(echo "$per_faculty" | grep -o 'DetID=[^&]*' | cut -d'=' -f2)
                local faculty_id=$(echo "$per_faculty" | grep -o 'FacultyStaffID=[^&]*' | cut -d'=' -f2)
                local sr_no=$(echo "$per_faculty" | grep -o 'SrNo=[^&]*' | cut -d'=' -f2)
                echo $course_type
                echo $det_id
                echo $faculty_id
                echo $sr_no
                echo $token
                curl -s 'https://s.amizone.net/FacultyFeeback/FacultyFeedback/SaveFeedbackRating' --compressed -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:131.0) Gecko/20100101 Firefox/131.0' -H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br, zstd' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'Referer: https://s.amizone.net/Home' -H 'X-Requested-With: XMLHttpRequest' -H 'Origin: https://s.amizone.net' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' -H 'Connection: keep-alive' -H "Cookie: ASP.NET_SessionId=$session; __RequestVerificationToken=$requestcookie; .ASPXAUTH=$asp" --data-raw "__RequestVerificationToken=$token&CourseType=$course_type&clsCourseFaculty.iDetId=$det_id&clsCourseFaculty.iFacultyStaffId=$faculty_id&clsCourseFaculty.iSRNO=$sr_no&FeedbackRating%5B0%5D.iAspectId=1&FeedbackRating%5B0%5D.Rating=5&FeedbackRating%5B1%5D.iAspectId=3&FeedbackRating%5B1%5D.Rating=5&FeedbackRating%5B2%5D.iAspectId=4&FeedbackRating%5B2%5D.Rating=5&FeedbackRating%5B3%5D.iAspectId=5&FeedbackRating%5B3%5D.Rating=5&FeedbackRating%5B4%5D.iAspectId=6&FeedbackRating%5B4%5D.Rating=5&FeedbackRating%5B5%5D.iAspectId=7&FeedbackRating%5B5%5D.Rating=5&FeedbackRating%5B6%5D.iAspectId=8&FeedbackRating%5B6%5D.Rating=5&FeedbackRating%5B7%5D.iAspectId=9&FeedbackRating%5B7%5D.Rating=5&FeedbackRating%5B8%5D.iAspectId=10&FeedbackRating%5B8%5D.Rating=5&FeedbackRating%5B9%5D.iAspectId=11&FeedbackRating%5B9%5D.Rating=5&FeedbackRating%5B10%5D.iAspectId=12&FeedbackRating%5B10%5D.Rating=5&FeedbackRating%5B11%5D.iAspectId=13&FeedbackRating%5B11%5D.Rating=5&FeedbackRating%5B12%5D.iAspectId=14&FeedbackRating%5B12%5D.Rating=5&FeedbackRating%5B13%5D.iAspectId=15&FeedbackRating%5B13%5D.Rating=5&FeedbackRating%5B14%5D.iAspectId=18&FeedbackRating%5B14%5D.Rating=5&FeedbackRating%5B15%5D.iAspectId=28&FeedbackRating%5B15%5D.Rating=5&FeedbackRating%5B16%5D.iAspectId=22&FeedbackRating%5B16%5D.Rating=5&FeedbackRating%5B17%5D.iAspectId=23&FeedbackRating%5B17%5D.Rating=5&FeedbackRating%5B18%5D.iAspectId=24&FeedbackRating%5B18%5D.Rating=5&FeedbackRating%5B19%5D.iAspectId=25&FeedbackRating%5B19%5D.Rating=5&FeedbackRating_Q1Rating=1&FeedbackRating_Q2Rating=1&FeedbackRating_Q3Rating=1&FeedbackRating_Q5Rating=1&FeedbackRating_Comments=Taught+us+well&X-Requested-With=XMLHttpRequest"
        done
}

count=0
while [ $count != 1 ]
do
        menu="\n1. Exam Result\n2. Exam Schedule\n3. Fee Structure\n4. Calender Schedule\n5. Course\n6. Attendance\n7. Class Schedule\n8. FacultyFeeback\n9. Exit\nEnter your choice: "
        read -p "$(echo -e $menu)" choice
        case $choice in
                1) exam_result
                        ;;
                2) exam_schedule
                        ;;
                3) fee
                        ;;
                4) class_schedule
                        ;;
                5) course_list
                        ;;
                6) attendance
                        ;;
                7) class_schedule 1
                        ;;
                8) faculty
                        ;;
                9) count=1
                        ;;
                *) echo "Invalid choice"
                        ;;
        esac
done

