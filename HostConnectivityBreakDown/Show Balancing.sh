hostlist=`cat hostportlist.txt | awk '{print $1}'`
host="newhost"
count=1
for i in $hostlist
do
	if [ "$i" == "$host" ]
	then 
		((count++))
	else
		#echo -e "$host" '\t\t\t' "$count"
		if [ $((count%2)) -eq 0 ]
		then
			printf "%-30s %-30s %-30s\n" "$host" "$count" "OK"
		else
			printf "%-30s %-30s %-30s\n" "$host" "$count" "UNBALANCED"
		fi
		host=$i
		count=1
	fi
done
