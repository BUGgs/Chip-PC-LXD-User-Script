#!/bin/bash

echo "Autostarting Connection the include keyword: $1"

while true
do
  for i in /root/Desktop/*$1* ;
  do
    if [ -f "$i" ]
    then
      CONNECTION=`cat "$i" | grep Exec | sed 's/Exec=//' | sed 's/\%f//' | sed '1!d'`
      echo "Connection found to autostart : $i = $CONNECTION"
      eval "${CONNECTION} &";
      exit 0;
    fi;
  done;
  sleep 1
  echo "No connection found yet : $j sec"
done;
