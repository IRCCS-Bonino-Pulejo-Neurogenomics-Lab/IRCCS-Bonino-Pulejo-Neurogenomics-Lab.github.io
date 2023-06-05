#!/bin/bash

while getopts s:o:p: option
do
    case "${option}"
        in
	o)output_path=${OPTARG};;
    esac
done

if [[ -z $output_path ]]; then
        echo "Use $0 -o output_path"
        exit
fi

echo output: $output_path
scriptR=$output_path/script.R

>&2 echo Creating R script in $scriptR

echo "rm(list=ls())

args <- commandArgs()
species <- args[6]
if(species == 'human'){
  species <- 'hsa'
} else if(species == 'mouse'){
  species <- 'mmu'
}
priority <- args[7] #1,2,3
output.path <- args[8] #FULL_PATH
degs.condition <- args[9] #true
kegg.enrichment.condition <- args[10] #false
go.enrichment.condition <- args[11] #true
kegg.pathway.condition <- args[12] #false
kegg.pathway.maps <- args[13] #01234,56789
comparisons <- args[14] #GROUP1_GROUP2,GROUP1_GROUP3

#source(paste(Sys.getenv('HOME'), 'Scrivania/NGS-SCRIPT/Luigi/R/RNAseq_enrichment.R', sep='/'))
source('/home/utente/Desktop/research/RNA/scripts/RNAseq_enrichment.R')

if(!require('stringr')){
  install.packages('stringr', repos='https://cran.stat.unipd.it/', version='1.4.0')
  library(stringr)
}
if(!require('rstudioapi')){
  install.packages('rstudioapi', repos='https://cran.stat.unipd.it/', version='0.13')
  library(rstudioapi)
}

#output.path <- paste(dirname(rstudioapi::getSourceEditorContext()$path), '/', sep='')

sink(paste(output.path, 'Rlog', sep = '/'), split = TRUE)
print(args)
print(paste('species: ', species, sep = ''))
print(paste('priority: ', priority, sep = ''))
print(paste('output.path: ', output.path, sep = ''))
print(paste('degs: ', degs.condition, sep = ''))
print(paste('kegg enrichment: ', kegg.enrichment.condition, sep = ''))
print(paste('go enrichment: ', go.enrichment.condition, sep = ''))
print(paste('kegg pathway: ', kegg.pathway.condition, sep = ''))
print(paste('kegg pathway maps sublist: ', kegg.pathway.maps, sep = ''))
print(paste('comparisons to do: ', comparisons, sep = ''))

groups <- list.dirs(paste(output.path, 'Groups', sep='/'), recursive=FALSE, full.name=FALSE)
print('groups: ')
print(groups)

if(nchar(priority) == 0){
  print('>>> Re-run with priorities!!!!!')
} else {
  groups.priority <- c()
  splitted.priority <- str_split(priority, ',')[[1]]
  for(p in splitted.priority){
    groups.priority <- c(groups.priority, as.numeric(p))
  }

  print(groups.priority)
  print('groups sorted by priority: ')
  print(groups[groups.priority])
 
  kegg.pathway.maps.sublist <- c()
  if(nchar(kegg.pathway.maps) != 0){
    splitted.kegg.pathway.maps <- str_split(kegg.pathway.maps, ',')[[1]]
    for(p in splitted.kegg.pathway.maps){
      kegg.pathway.maps.sublist <- c(kegg.pathway.maps.sublist, p)
    }
  }
  
  comparisons.to.do <- c()
  if(nchar(comparisons) != 0){   
    splitted.comparisons <- str_split(comparisons, ',')[[1]]
    for(c in splitted.comparisons){
      comparisons.to.do <- c(comparisons.to.do, c)
    }
  }

  fc.threshold <- c(0, 2)
  
  get.priority <- function(min.group, max.group){
    priorities <- groups.priority #REPLACE WITH ARRAY WITH ID GROUPS SORTED BY PRIORITY
    if(length(priorities) == 0) {
      return(c(min.group, max.group))
    } else {
      min.group.priority <- which(priorities == min.group)
      max.group.priority <- which(priorities == max.group)
      if(length(min.group.priority) == 0 || length(max.group.priority) == 0){
        if(length(min.group.priority) == 0){
          return(c(max.group, min.group))
        } else {
          return(c(min.group, max.group)) 
        }
      } else {
        if(min.group.priority < max.group.priority){
          return(c(min.group, max.group)) 
        } else {
          return(c(max.group, min.group))
        }
      }
    }
  }
  
  comparisonToDo <- function(group.comparison){
    if(length(comparisons.to.do) == 0){
      return(TRUE)
    } else {
      return(group.comparison %in% comparisons.to.do)
    }
  }
  
  print('Establish comparisons')
  groups.comparison.ids <- list()
  for(groups.id.1 in 1:length(groups)){
    for(groups.id.2 in 1:length(groups)){
      if(groups.id.1 != groups.id.2){
        min.group <- min(groups.id.1, groups.id.2)
        max.group <- max(groups.id.1, groups.id.2)
        group.priority <- get.priority(min.group, max.group)
        if(! list(group.priority) %in% groups.comparison.ids){
          groups.comparison.ids <- c(groups.comparison.ids, list(group.priority)) 	
        }
      }
    }
  }
  
  groups.comparison <- list()
  for(groups.comparison.id in 1:length(groups.comparison.ids)){
    groups.comparison <- c(groups.comparison, list(c(groups[groups.comparison.ids[groups.comparison.id][[1]][1]], groups[groups.comparison.ids[groups.comparison.id][[1]][2]]))) 
  }
  
  if(degs.condition){
    print('DESeq2 analys')
    for(group.comparison.id in 1:length(groups.comparison)){
      group.comparison <- groups.comparison[[group.comparison.id]]
      comparison <- paste(group.comparison[1], group.comparison[2], sep = '_')
      print(comparison)
      if(comparisonToDo(comparison)){
        if(dir.exists(paste(output.path, 'analysis', comparison, 'Tables', 'DEGs', sep = '/'))){
          print('Removing previous analysis')
          unlink(paste(output.path, 'analysis', comparison, 'Tables', 'DEGs', sep = '/'), recursive = TRUE)
        }
        DEG.analysis(data.path = output.path, CTR = group.comparison[1], noCTR = group.comparison[2], fc.threshold)
      } else {
        print('Comparison exluded')
      }
    }
  }
  
  if(kegg.enrichment.condition){
    print('KEGG enrichment')
    for(group.comparison.id in 1:length(groups.comparison)){
      group.comparison <- groups.comparison[[group.comparison.id]]
      comparison <- paste(group.comparison[1], group.comparison[2], sep = '_')
      print(comparison)
      if(comparisonToDo(comparison)){
        for(fc in fc.threshold){
          print(paste('Fold change > |', fc, '| list'))
          if(dir.exists(paste(output.path, 'analysis', comparison, 'Tables', paste('KEGG_enrichment_FC', fc, sep = ''), sep = '/'))){
            print('Removing previous analysis')
            unlink(paste(output.path, 'analysis', comparison, 'Tables', paste('KEGG_enrichment_FC', fc, sep = ''), sep = '/'), recursive = TRUE)
          }
          group.path <- paste(output.path, 'analysis', comparison, sep = '/')
          KEGG.enrichment.table.path(DEGs.table.path = paste(group.path, 'Tables', 'DEGs', 'DEGs.tsv', sep = '/'), output.main.dir = paste(group.path, 'Tables', sep = '/'), fc = fc, species = species)
        }
      } else {
        print('Comparison exluded')
      }
    }
  }
  
  if(go.enrichment.condition){
    print('GO enrichment')
    for(group.comparison.id in 1:length(groups.comparison)){
      group.comparison <- groups.comparison[[group.comparison.id]]
      comparison <- paste(group.comparison[1], group.comparison[2], sep = '_')
      print(comparison)
      if(comparisonToDo(comparison)){
        for(fc in fc.threshold){
          print(paste('Fold change > |', fc, '| list'))
          if(dir.exists(paste(output.path, 'analysis', comparison, 'Tables', paste('GO_enrichment_FC', fc, sep = ''), sep = '/'))){
            print('Removing previous analysis')
            unlink(paste(output.path, 'analysis', comparison, 'Tables', paste('GO_enrichment_FC', fc, sep = ''), sep = '/'), recursive = TRUE)
          }
          group.path <- paste(output.path, 'analysis', comparison, sep = '/')
          gene.ontology.enrichment.table.path(DEGs.table.path = paste(group.path, 'Tables', 'DEGs', 'DEGs.tsv', sep = '/'), output.main.dir = paste(group.path, 'Tables', sep = '/'), fc = fc, species = species)
        }
      } else {
        print('Comparison exluded')
      }
    }
  }
  
  if(kegg.pathway.condition){
    print('KEGG pathways')
    for(group.comparison.id in 1:length(groups.comparison)){
      group.comparison <- groups.comparison[[group.comparison.id]]
      comparison <- paste(group.comparison[1], group.comparison[2], sep = '_')
      print(comparison)
      if(comparisonToDo(comparison)){
        if(dir.exists(paste(output.path, 'analysis', comparison, 'Plot', 'KEGG_pathways', sep = '/'))){
          print('Removing previous analysis')
          unlink(paste(paste(output.path, 'analysis', comparison, 'Plot', 'KEGG_pathways', sep = '/')), recursive = TRUE)
        }
        group.path <- paste(output.path, 'analysis', comparison, sep = '/')
        KEGG.pathway.table.path(DEGs.table.path = paste(group.path, 'Tables', 'DEGs', 'DEGs.tsv', sep = '/'), output.main.dir =  paste(group.path, 'Plot', sep = '/'), species = species, maps.sublist = kegg.pathway.maps.sublist)
      } else {
        print('Comparison exluded')
      }
    }
  }
}

warnings()

sink()" > $scriptR

#echo Running $scriptR
#Rscript $scriptR
