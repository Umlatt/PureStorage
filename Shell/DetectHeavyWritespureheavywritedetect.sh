#Create working folders
cd /home/os76/

#Create a file name from the date
dateinf=`date | awk '{print $6$2$3}'`
flname="vollumelist-$dateinf.txt"
outfl="volumeinf-$dateinf"

#Collect a list of the volumes on the array
purevol list --notitle | awk '{print $1}' > $flname
totalvols=`cat $flname | wc -l`
count=0
echo "" > $outfl"txt"

#Iterate through the list of volumes and get performance stats
#Get the last 3 hours of historical data for this lun | get time and read bw | sort from highest to lowest (including K/B/G -h) | keep only the top 20
for i in `cat $flname`
 do
 ((count++))
 echo $count"/"$totalvols" -> "$i
 #purevol monitor --historical 24h $i --notitle | awk '{print $1"\t"$3"\t"$6}' | sort -k3 -h -r | head -5 >> $outfl".txt"
 purevol monitor --historical 3h $i --notitle | awk '{print $1"\t"$3"\t"$6}' >> $outfl".txt"
done

#Sort the output and clean the old files
cat $outfl".txt" | sort -k3 -h -r > $outfl".csv"
rm $flname
rm $outfl".txt"
