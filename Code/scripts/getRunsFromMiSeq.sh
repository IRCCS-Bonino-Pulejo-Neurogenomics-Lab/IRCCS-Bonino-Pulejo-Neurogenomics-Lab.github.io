#!/bin/bash

while getopts o:p:d: option
do 
    case "${option}"
        in
        o)output_path=${OPTARG};;
	p)hdd=${OPTARG};;
        d)dates=${OPTARG};;
    esac
done

echo output: $output_path
echo hdd: $hdd
echo dates: $dates

if [[ -z $output_path ]] || [[ -z $hdd ]]; then
        echo "Use $0 -o output_full_path -p {C/D/E} -d [date_run1,date_run2,...]"
        exit
fi


miseq_ip=$(curl https://biolab-server-irccs.firebaseio.com/IRCCS/MiSeqDx/IP.json 2>/dev/null | cut -f4 -d'"')
miseq_port=3818
runs_path=Data/Intensities/BaseCalls/

if [ -z $dates ]; then
	echo List of runs date on MiSeqDx:
	curl ${miseq_ip}:$miseq_port 2>/dev/null | grep M70390 | cut -f2 -d'"' | cut -f1 -d'_'
	
	echo
	read -p "Choose a date for the run: " dates
fi

for date in $(echo $dates | sed 's/,/ /g'); do
	echo Preparing $date
	run_id=$(curl ${miseq_ip}:$miseq_port 2>/dev/null | grep M70390 | cut -f2 -d'"' | grep $date)
	if [[ ${#run_id} -eq 0 ]]; then
		echo Date not found
	else
		runs=$(curl ${miseq_ip}:$miseq_port/$run_id/$runs_path 2>/dev/null | grep ".fastq.gz" | cut -f2 -d'"' | grep -v Undetermined)
		if [[ ${#runs} -eq 0 ]]; then
			echo No run for this date
		else
			mkdir -p $output_path
	
			for run in $runs; do
				echo
				echo Downloading run $run
				curl ${miseq_ip}:$miseq_port/$run_id/$runs_path/$run -o $output_path/${date}+$run
			done
		fi
	fi
done
