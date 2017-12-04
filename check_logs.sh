#!/bin/bash
RUNDECKIP=''
yt_comp=$(date --date="yesterday" | awk {'print $1 " " $2 " " $3'})
now=$(date -d "yesterday 00:03")
day=$(echo $now| awk {'print $2'})
month=$(echo $now| awk {'print $3'})
access=$(cat /var/log/auth.log* |egrep "$day +$month" |grep -i "fail") #failed login attempts
sud=$(cat /var/log/auth.log* |egrep "$day +$month"  | grep "sudo.*TTY" |grep -v "ssh status") #sudo activities
ppts=$(cat /var/log/auth.log* |egrep "$day +$month" | grep "sshd.*Did") #possible scanners
#rundeck_con=$(cat /var/log/auth.log* |egrep "$day +$month" | grep "sshd.*Accepted publickey"|grep "IPHERE"  |wc -l) #IF YOU AREUSING RUNDECK INSERT IP HERE
#rundeck_ip=$(cat /var/log/auth.log* | grep "sshd.*Accepted publickey" |egrep "$day +$month" |grep rundeck |awk '{print $11}' |sort -u) #finde the IP for rundeck
sshok=$(cat /var/log/auth.log* |egrep "$day +$month" | grep "sshd.*Accepted publickey" |grep -v "$RUNDECKIP") #valid ssh logins
 
 
#if someone logged in via ssh
if [[ ! -z $sshok ]]; then
	subj="- SSH CONNECTION (KEY) \n\n$sshok\n\n"
fi
 
#for sudo activity
if [[ ! -z $sud ]]; then
	subj=$(echo -e "${subj}""- SUDO ACTIVITY \n\n$sud\n\n")
fi
 
#if rundeck has connected
#if [[  $rundeck_con -gt 0 ]]; then
#	subj=$(echo -e "${subj}""\n\n- RUNDECK CONNECTIONS \n\nRundeck connected $rundeck_con times from $rundeck_ip\n\n")
#fi
 
#check failed access
if [[ ! -z $access ]]; then
	subj=$(echo -e "${subj}""\n\n- AUTH FAILED \n\n$access\n\n")
fi
 
#check potential port scanners
if [[ ! -z $ppts ]]; then
	subj=$( echo -e "${subj}""- POTENTIAL PORT SCANNING \n\n$ppts\n\n"\n\n)
fi
 
#check if variable is empty or not
if [[ ! -z $subj ]]; then
	echo -ne "${subj}" | mail -s "[Monitoring] - AUTH REPORT FOR [$yt_comp]" monitoring -aFrom:"monitoring([Monitoring] $(hostname))"
else
	echo -ne "No Relevant activity today" | mail -s "[Monitoring] - AUTH REPORT FOR [$yt_comp]" monitoring -aFrom:"monitoring([Monitoring] $(hostname))"
fi

