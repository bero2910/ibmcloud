######################################################################
#this script goes through all PowerServices on an account and exports 
#instances type, CPU, RAM, and sumarized disk usage 
#In order to use script you need to be logedin into desired account 


#!/bin/bash


echo "Instance,CPU,RAM,Tier1GB,Tier3GB" >> powerout.csv
ibmcloud pi sl | awk '{ print $1 }' | grep -v ID  | while read service
do 
ibmcloud pi st $service 
ibmcloud pi ins | grep -v Name | awk '{ print $2 }' | while read line
do 
tier1total=0
tier3total=0

#get instance name 
instancename=`(ibmcloud pi in $line | grep "Name" | awk '{ print $2 }')`

#get systype
systype=`(ibmcloud pi in $line  --json | grep sysType | awk -F "\"" '{ print $4 }')` 

#get proc
cpu=`(ibmcloud pi in $line | grep "CPU Cores" | awk '{ print $3 }')`

#get memory
memory=`(ibmcloud pi in $line | grep "Memory" | awk '{ print $2 }')`




# get volumes and sumarize capacity 

volumelist=`(ibmcloud pi in $line | grep Volumes | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' | sed  's/\,//g')`
for i in $volumelist
do
 
type=`(ibmcloud pi vol $i | grep Profile | awk '{print $2}')` 
if [[ $type == tier1 ]]
then
size=`(ibmcloud pi vol $i | grep Size | awk '{print $2}')`
tier1total=$(( $tier1total + $size ))
#echo instance $line $type volume size $size GB
#echo $tier1total
else 
size3=`(ibmcloud pi vol $i | grep Size | awk '{print $2}')`
#echo instance $line tier3 volume size $size3 GB
tier3total=$(( $tier3total + $size3 ))
#echo $tier3total
fi
done
echo $instancename,$systype,$cpu,$memory,$tier1total,$tier3total >> powerout.csv
done 
done
