#!/bin/bash
authlogPath="/var/log/auth.log"
workPath="work"
cp $authlogPath $workPath/auth.txt
sudo chmod 777 $workPath/auth.txt
authlog="$workPath/auth.txt"
grep "Failed password for" $authlog | grep -v "COMMAND=" > $workPath/authGrep.txt
authlog="$workPath/authGrep.txt"
i=0
spinner="/|\\-/|\\-"
sleep 1
while IFS= read -r line
do
 
userExist=$(echo "$line" | awk '{print $10}')
#if user exist in machine
if [ "$userExist" = "from" ]; then
user=$(echo "$line" | awk '{print $9}')
ip=$(echo "$line" | awk '{print $11}')

sudo ufw insert 1 deny from $ip to any
echo "Blocked ip $ip for user $user" >> $workPath/blockList.txt
echo "$ip" >> $workPath/blockIps.txt



#else

fi

#if user is unknown

if [ "$userExist" = "user" ]; then
user=$(echo "$line" | awk '{print $11}')
ip=$(echo "$line" | awk '{print $13}')

sudo ufw insert 1 deny from $ip to any
echo "Blocked ip $ip for user $user" >> $workPath/blockList.txt
echo "$ip" >> $workPath/blockIps.txt

#else

fi

#echo "Line Num $i"

i=$((i+1))
#echo "INFO :: Blocked ip $ip for user $user"

echo -n "${spinner:$n:1}"

sleep 1 
done < "$authlog"

echo "Done Ok Done"

