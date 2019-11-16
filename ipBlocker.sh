#!/bin/bash
authlogPath="/var/log/auth.log"
workPath="work"
cp $authlogPath $workPath/auth.txt
sudo chmod 777 $workPath/auth.txt
authlog="$workPath/auth.txt"
grep "Failed password for" $authlog | grep -v "COMMAND=" > $workPath/authGrep.txt
authlog="$workPath/authGrep.txt"
i=0

> $workPath/ufwOut.txt
> $workPath/blockList.txt
> $workPath/listUserIp.txt
> $workPath/listIp.txt
sleep 1

lineNum=$( wc -l $authlog | awk '{print $1}')
echo $lineNum
while IFS= read -r line
do
 
userExist=$(echo "$line" | awk '{print $10}')
#if user exist in machine
if [ "$userExist" = "from" ]; then
user=$(echo "$line" | awk '{print $9}')
ip=$(echo "$line" | awk '{print $11}')

#sudo ufw insert 1 deny from $ip to any >> $workPath/ufwOut.txt
echo "$ip,$user" >> $workPath/listUserIp.txt
echo "$ip" >> $workPath/listIp.txt
fi

if [ "$userExist" = "user" ]; then
user=$(echo "$line" | awk '{print $11}')
ip=$(echo "$line" | awk '{print $13}')

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



lineNum=$( wc -l $workPath/listIpUniq.txt | awk '{print $1}')
echo "\n"
while IFS= read -r line
do
	sudo ufw insert 1 deny from $line to any  >> $workPath/ufwOut.txt
	i=$((i+1))
    result=$(((100*$i)/$lineNum))

    echo "\b\rPercentage $result%. Blocked Ip for $line "
done < "$workPath/listIpUniq.txt"
	
echo "Done Ok Done"