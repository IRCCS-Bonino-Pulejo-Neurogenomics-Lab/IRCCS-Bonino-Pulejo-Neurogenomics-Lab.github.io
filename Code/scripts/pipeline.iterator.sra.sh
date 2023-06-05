#!/bin/bash

if [ $# -lt 2 ]; then
        echo Use $0 simultaneously_pipelines SRR_list_file
        exit
fi

used_cores=$1
SRRs=$2

cores=4 #$(cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l)
#running_cores=$((cores-1))

if [ $used_cores -gt $cores ]; then
        used_cores=$cores
fi

lock=lock.pipeline
release=release.pipeline
RNA=/home/$USER/Desktop/research/RNA
pipeline=$RNA/scripts/pipeline.sh
input=$RNA/output/fastq_dump
output=$RNA/output/pipeline

echo Will be used $used_cores cores
echo Reset tmp lock
rm -f /tmp/SRR*.$lock

while [ $(cat $SRRs | wc -l) -gt 0 ]; do
        srr=$(head -n1 $SRRs)
        echo Trying for $srr
        if [[ ! -f $output/$srr ]] && [[ ! -f /tmp/${srr}.$lock ]]; then
                if [[ $(ls /tmp/SRR*.$lock 2>/dev/null) == "" ]] || [ $(ls /tmp/SRR*.$lock | wc -l ) -lt $used_cores ]; then
                        touch /tmp/${srr}.$lock
			srrs=$(ls $input/${srr}*.fastq.gz)
                        cmd="$pipeline human $srrs &>/dev/null & disown"
                        echo $cmd
                        eval $cmd
                        sleep 5
                else
                        sleep 60
                fi
        else
                sleep 1
        fi
        #if [[ $(ls /tmp/SRR*.$release 2>/dev/null) != "" ]]; then
        if [[ $(ls /tmp/SRR*.$lock 2>/dev/null) != "" ]]; then
                #for release in $(ls /tmp/SRR*.$release); do
                for release in $(ls /tmp/SRR*.$lock); do
                        echo removing $release
			release_name=$(basename $release)
                        releaser=$(echo $release | grep -o "SRR[0-9]*")
                        sed -i 's/'$releaser'//g' $SRRs
                        sed -i '/^[[:space:]]*$/d' $SRRs
                        #cat $SRRs | grep -v $release > $SRRs
                        #rm $release
                done
                sleep 5
        fi
done
