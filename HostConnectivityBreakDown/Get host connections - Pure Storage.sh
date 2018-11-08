#Get host list
hostname=`purehost list --connect --notitle | awk '{print $1}' | sort -u`

#Get WWN per host
for i in $hostname
do
    hostwwns=`purehost list $i --all --notitle | awk '{print $2}' | grep -v "^$" | sort -u`
    for j in $hostwwns
    do
       pureport list --initiator --notitle | awk '{print "\t\t"$1"\t\t\t\t"$4" \t"t$5}' | grep $j |sed "s/.*/$i&/"
    done
done