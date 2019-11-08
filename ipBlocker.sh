#!/bin/bash
authlogPath="/var/log/auth.log"
cp $authlogPath auth.log
sudo chmod 777 auth.log
authlog="auth.log"
grep "Failed password for" $authlog | grep -v "COMMAND=" > authGrep.log
authlog="authGrep.log"
i=0
sleep 1
while IFS= read -r line
do
 
userExist=$(echo "$line" | awk '{print $10}')
#if user exist in machine
if [ "$userExist" = "from" ]; then
user=$(echo "$line" | awk '{print $9}')
ip=$(echo "$line" | awk '{print $11}')

sudo ufw deny from $ip to any
echo "Blocked ip $ip for user $user" >> blockList.txt
echo "$ip" >> blockIps.txt



#else

fi

#if user is unknown

if [ "$userExist" = "user" ]; then
user=$(echo "$line" | awk '{print $11}')
ip=$(echo "$line" | awk '{print $13}')

sudo ufw deny from $ip to any
echo "Blocked ip $ip for user $user" >> blockList.txt
echo "$ip" >> blockIps.txt

#else

fi

echo "Line Num $i"

i=$((i+1))
echo "INFO :: Blocked ip $ip for user $user"
done < "$authlog"

echo "Done Ok Done"

