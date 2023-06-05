#!/bin/bash

USAGE_MESSAGE="Use $0 -p project_path"

while getopts p: option
do
    case "${option}"
        in
        p)project_path=${OPTARG};;
    esac
done

if [[ -z $project_path ]]; then
        echo $USAGE_MESSAGE
        exit
fi

s=0
for srr in $(ls $project_path/SRR*.fastq.gz | xargs -n1 basename | grep -oP '^SRR\d+' | sort | uniq); do
       echo Fixing $srr
       mv $project_path/${srr}_1.fastq.gz $project_path/${srr}_S${s}_L001_R1_001.fastq.gz
       mv $project_path/${srr}_2.fastq.gz $project_path/${srr}_S${s}_L001_R2_001.fastq.gz
       s=$((s+1))
done
