#!/bin/bash

RNA_path=/home/utente/Desktop/research/RNA
scripts_path=$RNA_path/scripts
output_path=$RNA_path/output

experiments()
{
	echo Try one of the following:
        for experiment in $(ls $output_path); do
                if [[ -d $output_path/$experiment/analysis ]]; then
                        echo "- $scripts_path/sendAnalysisToSpliced.sh -e $experiment"
                fi
        done
}

while getopts e: option
do
    case "${option}"
        in
        e)experiment=${OPTARG};;
    esac
done

if [[ -z $experiment ]]; then
	experiments
        exit
fi

spliced_path=/home/spliced/lab/server_python/static/experiments/$experiment
server=spliced@172.18.139.11

if [[ ! -d $output_path/$experiment ]]; then
	echo Directory $output_path/$experiment not found
	experiments
	exit
fi

origin=$output_path/$experiment/analysis/
destination=$spliced_path/
echo Sending folder to spliced
echo From: $origin
echo To: $destination
cmd="rsync -az --info=progress2 --rsync-path='rm -rf $destination && mkdir -p $destination && rsync' $origin $server:$destination"
echo $cmd
eval $cmd
