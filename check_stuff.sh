#!/bin/bash

#########################################
# CHECK CPU USAGE && RAM                #
# CHECK FILESYSTEM(s) OCCUPY 75%        #
# CHECK UP Ping                         #
# CHECK UP Services                     #
# NETWORKG USAGE                        #
#########################################
#to be executed every 15 minutes
#rundeck crontab syntax: 0 0/15 * * * ? *


fs_root_partition="" #device for root partition
fs_home_partition="" #device for home partition
usage=$(df -H | grep "$fs_home_partition" | awk '{ print $5 }' | sed 's/%//g')
services=( ) #services needed to be checked

today=$(date --date="today")
critical=75 #filesystem critical value

usageroot=$(df -H | grep "$fs_root_partition" | awk '{ print $5 }' | sed 's/%//g')
servers=( ) #if you need to check others online server (just a ping)
cpu_usage=$(top -n 2 | grep -i cpu\(s\) | awk '{print  100 -$8}' |sed -n 2p)

if [[ cpu_usage == 0 ]]; then
	cpu_usage=1
fi
rcpu=$(echo "$cpu_usage" | awk '{printf("%d\n",$1 + 0.5)}')
if [[ rcpu == 0 ]]; then
	rcpu=1
fi

mem=$(free -mto | grep Mem: | awk '{ print $3 - $7 - $6}')

# CPU & RAM#

if [ $rcpu -ge 100 ]; then
	dcpu=$(($rcpu / $(grep -c ^processor /proc/cpuinfo)))
	if [[ dcpu == 0 ]]; then
		dcpu=1
	fi

	if [ $dcpu -ge 80 ]; then
       echo "*** WARNING *** $cpu_usage % of CPU in use on system, please check asap [$(hostname)]" | mail -s "[Monitoring] - WARNING: CPU threshold exceeded 80% on $(hostname) [$today]" monitoring@mymail.com -aFrom:"monitoring([Monitoring] $(hostname))"
	fi
fi

if [ $mem -ge 1011 ]; then
       echo "*** WARNING *** $mem MB (RAM) in use on system, please check asap [$(hostname)]" | mail -s "[Monitoring] - WARNING: RAM in USE exceeded 50% on $(hostname) [$today]" monitoring@mymail.com -aFrom:"monitoring([Monitoring] $(hostname))"
fi


# FS #
if [ \( $usage -gt $critical \) -o \( $usageroot -gt $critical \) ]; then
	echo -ne "*** WARNING *** Almost out of disk space [FS HOME] $fs_mail_partition [CRIT] $usage % used\n\n*** WARNING *** Almost out of disk space [FS ROOT] $fs_root_parition % used" | mail -s "[Monitoring] - WARNING: FS AVAILABLE on $(hostname) [$today]" monitoring@mymail.com -aFrom:"monitoring([Monitoring] $(hostname))"

fi

if [ $usageroot -ge $critical ]; then
	echo -ne "*** WARNING *** Almost out of disk space [FS ROOT] $fs_root_partition [CRIT] $usageroot % used" | mail -s "[Monitoring] - WARNING: FS AVAILABLE on $(hostname) [$today]" monitoring@mymail.com -aFrom:"monitoring([Monitoring] $(hostname))"
fi


# UP MS#
for i in ${servers[@]}
do
	ping -c 2 $i > /dev/null 2>&1
	if [ $? -ne 0 ];then
		off=("${off[@]}" "$i")
	fi
done

if [ ! -z $off ]; then
	echo -ne "NODE(s)  [${off[@]}] appear DOWN! *** Check IMMEDIATELY ***" | mail -s "[Monitoring] - URGENT: NODE(s) appear DOWN! [$today]" monitoring@mymail.com -aFrom:"monitoring([Monitoring] $(hostname))" 
fi

# UP DAEMON
for i in "${services[@]}"
do
	active=$(systemctl status $i |grep 'active (running)\| active (exited)')

	if [[ -z $active ]]; then
		soff=("${soff[@]}" "$i")
	fi
done

if [ ! -z $soff ]; then
	echo -ne "DAEMON(s) [${soff[@]}] appear DOWN! *** Check IMMEDIATELY ***" | mail -s "[Monitoring] - URGENT: DAEMON appear DOWN! [$today]" monitoring@mymail.com -aFrom:"monitoring([Monitoring] $(hostname))"
fi

# NETWORK THRESHOLD
for i in  $(ifstat  -i eth0 1 5 |awk '$1 ~ /[0-9.]+/ { print$2 }'|tail -n 5);do #result in kb/s
        inte=$(echo $i|awk '{printf "%.0f\n", $1}')
        tot=$(expr $tot + $inte)
done

if [ $tot -ge 100000 ]; then # > 100 MB
        echo "$tot" | mail -s "[Monitoring] - WARNING: Network traffic threshold exceeded (> 100 M) [$today]" monitoring@mymail.com -aFrom:"monitoring([Monitoring] $(hostname))"

fi

exit 0

