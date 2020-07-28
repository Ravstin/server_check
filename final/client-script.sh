#!/bin/bash

# User input for server IP

inp=$1

if [ -z "$inp" ]; then
  echo "There's no server name in arguments, please input host name or IP!"
  read server
  if [ -z "$server" ]; then
    exit
  fi
else
  server=$1
fi

op_port=(4000 4321 8082 22 80)
cl_port=(3306)
Lion_port=($(seq 65000 1 65099))

op_len=${#op_port[@]}
cl_len=${#cl_port[@]}
Lion_len=${#Lion_port[@]}

echo
echo "Checking for opened ports:"
echo

for (( x=0; x<$op_len; x++ )); do
  nc -zv $server ${op_port[x]} &> /dev/null
  result=$?
  0 &> /dev/null
  if [ "$result" != 0 ]; then
    echo "Port "${op_port[x]}" is closed on $server - Failed"
  else
    echo "Port "${op_port[x]}" is open on $server - Successful"
  fi
done

echo
echo "Checking for closed ports:"
echo

for (( x=0; x<$cl_len; x++ )); do
  nc -zv $server ${cl_port[x]} &> /dev/null
  result=$?
  0 &> /dev/null
  if [ "$result" != 0 ]; then
    echo "Port "${cl_port[x]}" is closed on $server - Succesful"
  else
    echo "Port "${cl_port[x]}" is open on $server - Failed"
  fi
done

echo
echo "Checking T.Lion tcp ports:"
echo

for (( x=0; x<$Lion_len; x++ )); do
  nc -zv $server ${Lion_port[x]} &> /dev/null
  result=$?
  0 &> /dev/null
  if [ "$result" != 0 ]; then
#     echo "Port "${Lion_port[x]}" is closed on $server - Failed"
    break
  else
    echo "Port "${Lion_port[x]}" is open on $server - Succesful"
  fi
done

echo
echo "Checking T.Lion udp ports:"
echo

for (( x=0; x<$Lion_len; x++ )); do
  nc -uzv $server ${Lion_port[x]} &> /dev/null
  result=$?
  0 &> /dev/null
  if [ "$result" != 0 ]; then
#   echo "UDP port "${Lion_port[x]}" is closed on $server - Failed"
    break
  else
    echo "UDP port "${Lion_port[x]}" is open on $server - Succesful"
  fi
done

echo

exit
