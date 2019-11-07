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
echo "whilee"

userExist=$(echo "$line" | awk '{print $10}')

if [ "$userExist" = "from" ]; then
user=$(echo "$line" | awk '{print $9}')
ip=$(echo "$line" | awk '{print $11}')

sudo ufw deny from $ip to any
echo "Blocked ip $ip for user $user" >> blockList.txt

#else

fi

echo "invalid user last num $i"
echo "$userExist"
echo "$line"

i=$((i+1))

 
done < "$authlog"

echo "Done Ok Done"
