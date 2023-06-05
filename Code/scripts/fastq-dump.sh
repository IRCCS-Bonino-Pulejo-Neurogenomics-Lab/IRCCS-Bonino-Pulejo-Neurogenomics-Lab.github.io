#!/bin/bash

USAGE_MESSAGE="Use $0 -s SRR [-p project_output_path] [-l lock_name] [-r release_name]"

while getopts p:s:l:r: option
do
    case "${option}"
        in
        p)project_output_path=${OPTARG};;
        s)SRR=${OPTARG};;
	l)lock=${OPTARG};;
	r)release=${OPTARG};;
    esac
done

if [[ -z $SRR ]]; then
        echo $USAGE_MESSAGE
        exit
fi

if [[ -z $project_output_path ]]; then
	project_output_path=$HOME/Desktop/research/RNA/output/fastq_dump
fi
generalLog=$project_output_path/log.$SRR
fastqdump=$HOME/resources/tools/sratoolkit.3.0.2-centos_linux64/bin/fastq-dump.3.0.2
sra=$HOME/ncbi/public/sra
if [[ -z $lock ]]; then
	lock=lock.fastqdump
fi
if [[ -z $release ]]; then
	release=release.fastqdump
fi

mkdir -p $project_output_path
date | tee -a $generalLog

#echo Creating lock for $SRR | tee -a $output/log
#touch /tmp/${SRR}.$lock | tee -a $output/log
cmd="$fastqdump -A $SRR -O $project_output_path/ --gzip -v -v --split-3"
echo $cmd | tee -a $generalLog
eval $cmd | tee -a $generalLog
rm $sra/${SRR}.sra.cache | tee -a $generaLog
rm $sra/${SRR}.sra | tee -a $generalLog
echo Releasing lock | tee -a $generalLog
#touch /tmp/${SRR}.$release | tee -a $generalLog
rm /tmp/${SRR}.$lock | tee -a $generalLog
