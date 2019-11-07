#!/bin/bash
input="/var/log/auth.log"

cp $input auth.log
sudo chmod 777 auth.log

input="auth.log"

grep "Failed password for" $input > authGrep.log

input="authGrep.log"
while IFS= read -r line
do
  echo "$line"
done < "$input"
