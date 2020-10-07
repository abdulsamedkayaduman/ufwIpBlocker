#!/bin/bash
echo "----------------------------------------------------------------------------------------------------"
echo "- Procces Starting"
echo "- `date`"
echo "----------------------------------------------------------------------------------------------------"
authlogPath="/var/log/auth.log" #ana log dizini
workPath="/home/abdulsamed/ipBlocker/work" #dosya isleme dizini
authlogLastLineNum=$( sudo wc -l $authlogPath |  awk '{print $1}' ) #authlogun satir sayisi
lastLineNum=$( tail -1 $workPath/lastLineNum.txt) # bir onceki taramada satir sayisi
echo "Last readed last line num = $lastLineNum"
sudo sed -n "$lastLineNum,\$p" $authlogPath > $workPath/auth.txt # kalan satırdan baslatma icin
sudo chmod 777 $workPath/auth.txt
authlog="$workPath/auth.txt"
echo "Grep authlog started...."
grep "Failed password for" $authlog | grep -v "COMMAND=" | cut -d " " -f 6- | sort | uniq > $workPath/authGrep.txt
authlog="$workPath/authGrep.txt"
i=0
echo $authlogLastLineNum > $workPath/lastLineNum.txt
echo "Grep authlog ended...."
diffLine=$(($authlogLastLineNum-$lastLineNum))
echo "Changed Line Size = $diffLine"
if [ $diffLine -lt 0 ] ; then
    echo "1" > $workPath/lastLineNum.txt
    sleep 1
    echo "***---***"
    echo "Line value reset."
    echo "Next proccess will start from 1."
    echo "***---***"
    sleep 1
fi

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
echo "Authlog file line values : "$lineNum
while IFS= read -r line
do

    userExist=$(echo "$line" | awk '{print $5}')
    #if user exist in machine
    if [ "$userExist" = "from" ]; then
        user=$(echo "$line" | awk '{print $4}')
        ip=$(echo "$line" | awk '{print $6}')

        #sudo ufw insert 1 deny from $ip to any >> $workPath/ufwOut.txt
        echo "$ip $user" >> $workPath/listUserIp.txt
        echo "$ip" >> $workPath/listIp.txt
    fi

    if [ "$userExist" = "user" ]; then
        user=$(echo "$line" | awk '{print $6}')
        ip=$(echo "$line" | awk '{print $8}')

        #sudo ufw insert 1 deny from $ip to any >> $workPath/ufwOut.txt
        echo "$ip $user" >> $workPath/listUserIp.txt
        echo "$ip" >> $workPath/listIp.txt
    fi
    i=$((i+1))
    result=$(((100*$i)/$lineNum))

    echo $uesrExist
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
lineNum=0
i=0
lineNum=$( wc -l $workPath/diffIpList.txt | awk '{print $1}')


while IFS= read -r line
do
    sudo ufw insert 1 deny from $line to any  >> $workPath/ufwOut.txt
    i=$((i+1))
    result=$(((100*$i)/$lineNum))

    echo "\b\r Percentage $result%. Blocked Ip for $line ...."
done < "$workPath/diffIpList.txt"

lineNum=0
i=0
echo "Posting IPs to server."
echo ""
lineNum=$( wc -l $workPath/listUserIp.txt | awk '{print $1}')
while IFS= read -r line
do

    ip=$(echo "$line" | awk '{print $1}')
    user=$(echo "$line" | awk '{print $2}')
    #echo $user"<--user -- --ip-->"$ip
    #result=$(curl -X POST -H "Content-Type: application/json" --data '{"ip":"'$ip'","user":"'$user'"}' http://108.61.135.97/ipblock/setip > /dev/null 2>&1 &)
    result=$(curl -s -X POST -H "Content-Type: application/json" --data '{"ip":"'$ip'","user":"'$user'"}' http://localhost:5002/api/ipblock/setip | jq -r '.status')
    if [ "$result" != "true" ]; then
        sleep 2
        echo "[`date +"%m-%d-%Y %T"`]$result for user $user and ip $ip" >> log/error.log
    fi
    i=$((i+1))
    result=$(((100*$i)/$lineNum))
    echo "Percentage $result%."
    
    #echo "\b\r Percentage $result%."
done < "$workPath/listUserIp.txt"

echo "Posting done."
 
echo "----------------------------------------------------------------------------------------------------"
echo "- Procces End"
echo "- Last blocked IP value `sudo ufw status | wc -l`"
echo "- `date`"
echo "----------------------------------------------------------------------------------------------------"
