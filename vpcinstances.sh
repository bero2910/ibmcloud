#!/bin/bash

######################################################################
#this script gathers info about VPC VSI instances on the account and 
#saves it into CSV file named vpcvsi.csv   
#In order to use script you need to be logedin into desired account and 




echo "ID,Name,Status,Reserved IP,Floating IP,Profile,Image,VPC,Zone,Resource group,3IOPSGB,5IOPSGB,10IOPSGB,customIOPSGB" > vpcvsi.csv

#get instances on the account into a line 

ibmcloud is ins | grep -v "List"| grep -v "ID" | sed 's/ \{1,\}/,/g' | while read line
do

iops3=0
iops5=0
iops10=0
iopscustom=0

instance_id=`( echo $line |  awk -F "," '{ print $1 }')`

#echo $instance_id

# get volumes and sumarize capacity

ibmcloud is in $instance_id  | grep -A 20 "Boot volume" | grep -v virtio |grep -v "ID"  | awk '{ print $1 }'  | egrep -v '^#|^$' > vols.temp

#ibmcloud is in $instance_id | grep -A 20 "Boot volume" | grep -v ID  | awk '{ print $1 }' | egrep -v '^#|^$' > vols.temp 



while read volume_id 
do 

#echo $volume_id 

ibmcloud is vol $volume_id > vol.temp

type=`( cat vol.temp | grep Profile | awk '{print $2}')` 

if [[ $type == general-purpose ]]
then
size3=`(cat vol.temp  | grep Capacity | awk '{print $2}')`
iops3=$(( $iops3 + $size3 ))
elif [[ $type == 5iops-tier ]]
then
size5=`(cat vol.temp  | grep Capacity | awk '{print $2}')`
iops5=$(( $iops5 + $size5 ))
elif [[ $type == 10iops-tier ]]
then
size10=`(cat vol.temp  | grep Capacity | awk '{print $2}')`
iops10=$(( $iops10 + $size10 ))
else 
sizecustom=`(cat vol.temp  | grep Capacity | awk '{print $2}')`
iopscustom=$(( $iopscustom + $sizecustom ))
fi
done < vols.temp 
rm -f vols.temp 
echo "$line$iops3,$iops5,$iops10,$iopscustom" >> vpcvsi.csv

done

