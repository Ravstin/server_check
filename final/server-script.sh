#!/bin/bash

#------------------------------------------------------------------------
#TASSTA T.(Lion/Brother) Compatibility Tool for Deployment, Server-Script
#------------------------------------------------------------------------

echo "TASSTA T.Lion/Brother Compatibility Tool. This tool checks the requirements on hardware, software, system environment, and security configurations, needed, in order to run the T.Lion/Brother Server. See: http://kb.tassta.com:8090/display/PHC/System+requirements "

echo

echo "Starting Minimum System Requirement Check"

if [[ $(arch) = x86_64 ]];
then
    echo "[ARCHITECTURE: PASSED] - As required, you are running a 64 Bit x86 system."
else 
    echo "[ARCHITECTURE: NOT PASSED] - Other architectures are not supported. Only x86_64 supported."
fi

if [[ $(nproc --all) -lt 2 ]];
then
    echo "[CPU: NOT PASSED] - CPU" "[$(echo -e ""`awk -F':' '/^model name/ {print $2}' /proc/cpuinfo | uniq | sed -e 's/^[ \t]*//'`)]" "is not meeting the minimum requirements with" "$(nproc --all)" "core(s). More 2 than cores are needed. If a VM is used, check core allocation."
else 
    echo "[CPU: PASSED] - Your CPU" "[$(echo -e ""`awk -F':' '/^model name/ {print $2}' /proc/cpuinfo | uniq | sed -e 's/^[ \t]*//'`)]" "has" "$(nproc --all)" "cores, which meets the minimum requirement."
fi

if [[ "$(free -m | grep 'Mem' | awk '{print $2}')" -lt 5000 ]];
then
    echo "[RAM: NOT PASSED] - More than 5000MB (5GB) system memory are needed to run the server properly. Only" "$(free -m | grep 'Mem' | awk '{print $2}')" "MB usable RAM found!"
else 
    echo "[RAM: PASSED] - The available RAM is" "$(free -m | grep 'Mem' | awk '{print $2}')" "MB, which meets the minimum requirement."
fi

if [[ "$(df -hT / | grep '/' | awk '{print $3}' | tr -d G | awk '{printf("%d\n",$1 + 0.5)}' )" -lt 20 ]];
then
    echo "[DISK: NOT PASSED] - More than 20 GB disk space are needed to run the server properly. The available disk space is" "$(df -hT / | grep '/' | awk '{print $3}' | tr -d G)" "GB."
else 
    echo "[DISK: PASSED] - The available disk space is" "$(df -hT / | grep '/' | awk '{print $3}' | tr -d G)" "GB, which meets the minimum requirement."
fi

echo

# ENABLE FIREWALL RULES FOR TLS\TBS
sudo ufw --force enable
ufw allow 6500:6550/tcp
ufw allow 6500:6550/udp
ufw allow 4000/tcp
ufw allow 4321/tcp
ufw allow 8082/tcp
ufw allow 80/tcp
ufw allow 22/tcp
ufw deny mysql

echo

##################################################
# Force user to input server's name / IP address #
##################################################
# Arguments for script are following             #
# arg1 = TBS/TLS address                         #
# arg2 = arbitrator address                      #
##################################################

inp=$1
inp2=$2

if [ -z "$inp" ]; then
  echo "There's no T.Lion/T.Brother ip in arguments, please input ip!"
  read server
  if [ -z "$server" ]; then
    exit
  fi
else
  server=$1
fi

# Now we can use $server as address for TLS or TBS

if [ -z "$inp2" ]; then
  echo "There's no arbitrator ip/port in arguments, please input ip/port!"
  read arbitrator
  if [ -z "$arbitrator" ]; then
    break
  fi
else
  arbitrator=$2
fi

# Arbitrator as $arbitrator as well

srv_pts=(4567 4568 4444 27017)
srv_len=${#srv_pts[@]}

# Checking ports on server, 13000 - arbitrator

for (( x=0; x<$srv_len; x++ )); do
  nc -zv $server ${srv_pts[x]} &> /dev/null
  result=$?
  0 &> /dev/null
  if [ "$result" != 0 ]; then
    echo "Port "${srv_pts[x]}" is closed on $server - Failed"
  else
    echo "Port "${srv_pts[x]}" is open on $server - Successful"
  fi
done

# Checking arbitrator or TLS/TBS port of it

if [ -z "$arbitrator" ]; then
  break
elif [[ "$arbitrator" =~ ^[0-9]+$ ]]; then
  nc -zv $server $arbitrator &> /dev/null
  result=$?
  0 &> /dev/null
  if [ "$result" != 0 ]; then
    echo "Port "$arbitrator" is closed on $server - Failed"
  else
    echo "Port "$arbitrator" is open on $server - Successful"
  fi
else 
  nc -zv $arbitrator 13000 &> /dev/null
  result=$?
  0 &> /dev/null
  if [ "$result" != 0 ]; then
    echo "Port "13000" is closed on $arbitrator - Failed"
  else
    echo "Port "13000" is open on $arbitrator - Successful"
  fi
fi

echo

#License servers availability check

RMP_addr1="116.203.164.16 55555"
RMP_addr2="88.99.84.2 55555"

echo "Checking TASSTA License Server availability:"

nc -zvn $RMP_addr1 &> /dev/null
res=$?
if [ "res" != 0 ]; then
        echo "central.tassta.com is open - Succesful"
else
        echo "central.tassta.com is closed - Failed"
fi

nc -zvn $RMP_addr2 &> /dev/null
res=$?
if [ "res" != 0 ]; then
        echo "central1.tassta.com is open - Succesful"
else
        echo "central1.tassta.com is closed - Failed"
fi

echo

echo "Starting Minimum Software Requirement Check"

echo "[TIME: INFO] -" "$(date)"

if [ -f /usr/bin/dpkg ] || [ -f /bin/dpkg ]
then
    echo "[OS: INFO] - Debian-based Linux Distribution detected!"
    if [[ "$(hostnamectl | grep "Operating System" | cut -d ' ' -f5-)" = "Debian GNU/Linux 9 (stretch)"  ]];
    then
        echo "[OS: PASSED] - Operating System Debian 9 (Supported) detected."
    else 
        echo "[OS: NOT PASSED] - Only Debian 9 as host os is supported."
    fi
else
    echo "[OS: NOT PASSED] - No Debian detected! (NO DPKG FOUND). Leaving."
    exit 1
fi

if [ -d /var ] && [ -d /home ] && [ -d /tmp ]
then
    echo "[FILESYSTEM: INFO] - Needed Directories (/tmp, /home, /var) found! "
else
    echo "[FILESYSTEM: INFO] - Please recheck your partitions / file-system!"
fi

if [[ $(dpkg-query -W -f='${Status}' apparmor 2>/dev/null | grep -c "ok installed") -eq 1 ]];
then
    echo "[SECURITY: INFO] - Installed AppArmor package detected!"
    if (systemctl is-active --quiet apparmor.service)
    then
        echo "[SECURITY: NOT PASSED] - AppArmor is still active! It must be disabled or set to permissive mode."
    else
        echo "[SECURITY: PASSED] - AppArmor is not running."
    fi
else
    echo "[SECURITY: INFO] - AppArmor is not installed."
fi

if [[ $(dpkg-query -W -f='${Status}' selinux-basics 2>/dev/null | grep -c "ok installed") -eq 1 ]];
then
    echo "[SECURITY: INFO] - Installed SELinux package detected!"
    if [["$(getenforce)" = "Enforcing"]];
    then
        echo "[SECURITY: NOT PASSED] - SELinux is still active! It must be disabled or set to permissive mode."
    else
        echo "[SECURITY: PASSED] - SELinux is not running."
    fi
else
    echo "[SECURITY: INFO] - SELinux is not installed."
fi

if [[ $(dpkg-query -W -f='${Status}' bash 2>/dev/null | grep -c "ok installed") -eq 1 ]];
then
    echo "[SHELL: PASSED] - Bash is installed with version" "$(echo "$BASH_VERSION")""."
else
    echo "[SHELL: NOT PASSED] - No Bash installation found!"
fi

if [[ $(dpkg-query -W -f='${Status}' openssh-client 2>/dev/null | grep -c "ok installed") -eq 1 ]];
then
    echo "[SSH_CLIENT: PASSED] - OpenSSH client is installed."
else
    echo "[SSH_CLIENT: NOT PASSED] - OpenSSH client is missing."
fi

if [[ $(dpkg-query -W -f='${Status}' openssh-server 2>/dev/null | grep -c "ok installed") -eq 1 ]];
then
    echo "[SSH_SERVER: PASSED] - OpenSSH Server is installed."
else
    echo "[SSH_SERVER: NOT PASSED] - No OpenSSH Server installation found!"
fi

exit
