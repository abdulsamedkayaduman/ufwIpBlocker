#!/bin/bash
authlogPath="/var/log/auth.log"
workPath="/home/abdulsamed/ipBlocker/work"
authlogLastLineNum=$( sudo wc -l $authlogPath |  awk '{print $1}' )
lastLineNum=$( tail -1 $workPath/lastLineNum.txt)

sudo sed -n "$lastLineNum,\$p" $authlogPath > $workPath/auth.txt
sudo chmod 777 $workPath/auth.txt
authlog="$workPath/auth.txt"
echo "Grep authlog started...."
grep "Failed password for" $authlog | grep -v "COMMAND=" | cut -d " " -f 6- | sort | uniq > $workPath/authGrep.txt
authlog="$workPath/authGrep.txt"
i=0
echo $authlogLastLineNum > $workPath/lastLineNum.txt 
echo "Grep authlog ended...."
echo "Changed Line Size = $(($authlogLastLineNum-$lastLineNum))"

echo "Cleaning files started...."
> $workPath/ufwOut.txt
> $workPath/blockList.txt
> $workPath/listUserIp.txt
> $workPath/listIp.txt
> $workPath/blockedIPs.txt 
echo "Cleaning files ended...."
sleep 1

echo "Blocaked IPs value "
sudo ufw status | wc -l
echo "------------"
sudo ufw status |  grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > $workPath/blockedIPs.txt 
lineNum=$( wc -l $authlog | awk '{print $1}')
echo $lineNum
while IFS= read -r line
do
 
userExist=$(echo "$line" | awk '{print $5}')
#if user exist in machine
if [ "$userExist" = "from" ]; then
user=$(echo "$line" | awk '{print $4}')
ip=$(echo "$line" | awk '{print $6}')

#sudo ufw insert 1 deny from $ip to any >> $workPath/ufwOut.txt
echo "$ip,$user" >> $workPath/listUserIp.txt
echo "$ip" >> $workPath/listIp.txt
fi

if [ "$userExist" = "user" ]; then
user=$(echo "$line" | awk '{print $6}')
ip=$(echo "$line" | awk '{print $8}')

#sudo ufw insert 1 deny from $ip to any >> $workPath/ufwOut.txt
echo "$ip,$user" >> $workPath/listUserIp.txt
echo "$ip" >> $workPath/listIp.txt
fi
i=$((i+1))
result=$(((100*$i)/$lineNum))

echo "\b\rPercentage $result%. File operations."


done < "$authlog"

lineNum=0
i=0

sort $workPath/listIp.txt | uniq  > $workPath/listIpUniq.txt
sort $workPath/blockedIPs.txt > $workPath/blockedIPsTMP.txt
mv $workPath/blockedIPsTMP.txt $workPath/blockedIPs.txt
sort $workPath/listIpUniq.txt > $workPath/listIpUniqTMP.txt
mv $workPath/listIpUniqTMP.txt $workPath/listIpUniq.txt

comm -2 -3 $workPath/listIpUniq.txt  $workPath/blockedIPs.txt | grep -v from | grep -v port > $workPath/diffIpList.txt

lineNum=$( wc -l $workPath/diffIpList.txt | awk '{print $1}')
echo "\n"

while IFS= read -r line
do
	sudo ufw insert 1 deny from $line to any  >> $workPath/ufwOut.txt
	i=$((i+1))
    result=$(((100*$i)/$lineNum))

    echo "\b\b\r Percentage $result%. Blocked Ip for $line ...."
done < "$workPath/diffIpList.txt"

echo "Blocaked IPs value "
sudo ufw status | wc -l
echo "------------"
echo "Done Ok Done"