#!/bin/bash

USAGE_MESSAGE="Use $0 -n project_name -s SRRs_list_path [-c cores] [-p project_output_path]"

while getopts c:n:p:s: option
do
    case "${option}"
        in
        c)cores=${OPTARG};;
        n)project_name=${OPTARG};;
	p)project_output_path=${OPTARG};;
        s)SRRs_list_path=${OPTARG};;
    esac
done

if [[ -z $SRRs_list_path ]] || [[ ! -f $SRRs_list_path ]] || [[ -z $project_name ]]; then
	echo $USAGE_MESSAGE
	exit
fi

main_path=$HOME/Desktop/research/RNA

if [[ -z $project_output_path ]]; then
	project_output_path=$main_path/output/$project_name
fi

scripts_path=$main_path/scripts
fastqdump=$scripts_path/fastq-dump.sh
output_path=$project_output_path
generalLog=$project_output_path/generalLog
lock=lock.fastqdump
#release=release.fastqdump

mkdir -p $output_path
date | tee -a $generalLog
echo Project output: $output_path | tee -a $generalLog
echo Fastqdump: $fastqdump | tee -a $generalLog

SRRs_path=$(dirname $SRRs_list_path)
SRRs=$(basename $SRRs_list_path)
echo SRRs: $SRRs_path/$SRRs | tee -a $generalLog

total_cores=$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l)
#running_cores=$((total_cores-1))
if [[ -z $cores ]] || [[ $cores -gt $total_cores ]]; then
	cores=$total_cores
fi
echo Will be used $cores cores | tee -a $generalLog

echo Reset tmp lock | tee -a $generalLog
rm -f /tmp/SRR*.$lock
while [ $(cat $SRRs_path/$SRRs | wc -l) -gt 0 ]; do
	srr=$(head -n1 $SRRs_path/$SRRs)
	echo Trying for $srr | tee -a $generalLog
	echo Searching for $output_path/$srr and /tmp/${srr}.$lock
	#if [ ! -f $output_path/$srr ] && [ ! -f /tmp/${srr}.$lock ]; then
	if [ ! -f /tmp/${srr}.$lock ]; then
		if [[ $(ls /tmp/SRR*.$lock 2>/dev/null) == "" ]] || [ $(ls /tmp/SRR*.$lock | wc -l ) -lt $cores ]; then
			touch /tmp/${srr}.$lock
			#cmd="$fastqdump -s $srr -p $output_path -l $lock -r $release &>/dev/null & disown"
			#cmd="$fastqdump -s $srr -p $output_path -l $lock -r $release & disown"
			cmd="$fastqdump -s $srr -p $output_path -l $lock & disown"
			echo $cmd | tee -a $generalLog
			eval $cmd #| tee -a $generalLog
			sleep 5
			sed -i 's/'$srr'//g' $SRRs_path/$SRRs
			sed -i '/^[[:space:]]*$/d' $SRRs_path/$SRRs
		else
			echo SECOND IF
			sleep 60
		fi
	else
		echo FIRST IF
		sleep 1
	fi
	##if [[ $(ls /tmp/SRR*.$release 2>/dev/null) != "" ]]; then
	#if [[ $(ls /tmp/SRR*.$lock 2>/dev/null) != "" ]]; then
	#	#for release in $(ls /tmp/SRR*.$release); do
	#	for release in $(ls /tmp/SRR*.$lock); do
	#		echo removing $release | tee -a $generalLog
	#		release_name=$(basename $release)
	#		releaser=$(echo $release_name | grep -o "SRR[0-9]*")
	#		sed -i 's/'$releaser'//g' $SRRs_path/$SRRs
	#		sed -i '/^[[:space:]]*$/d' $SRRs_path/$SRRs
	#		#cat $SRRs | grep -v $release > $SRRs
	#		#rm $release
	#	done
	#	sleep 5
	#fi
done


#$scripts_path/SRRNamesStandardization.sh
#tar -czvf new_folder.tar.gz $output_path/*
