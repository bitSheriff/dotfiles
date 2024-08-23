#!/bin/bash 
  
UPDIR_LVL=$1 
  
if [ $# -lt 1 ]; then 
 UPDIR_LVL=1 
fi 
  
UPDIR="" 
for i in `seq 1 $UPDIR_LVL`; 
do 
 UPDIR="$UPDIR../" 
done 
  
cd $UPDIR 
