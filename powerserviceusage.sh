######################################################################
#this script goes through all PowerServices on an account and exports 
#instances type, CPU, RAM, and sumarized disk usage 
#In order to use script you need to be logedin into desired account 


#!/bin/bash


echo "Location,Service,Instance,CPU,RAM,Tier1GB,Tier3GB" >> powerout.csv
#ibmcloud pi sl | awk '{ print $1 }' | grep -v ID  | while read service
#ibmcloud pi sl | grep -v ID | awk -F "::" '{ print  $2 }' |  sed -e 's/^[ \t]*//' | while read service
ibmcloud pi sl | grep -v ID | while read service 
	do 
	
	serviceid=`(echo $service | awk '{ print $1 }')`
	servicename=`(echo $service | awk -F "::" '{ print  $2 }' |  sed -e 's/^[ \t]*//')`
	geo=`(ibmcloud resource service-instance "$servicename" | grep Location | awk '{ print $2}')`	
	ibmcloud pi st $serviceid 
	ibmcloud pi ins | grep -v Name | awk '{ print $2 }' | while read line
		do 
		tier1total=0
		tier3total=0
		# get instance and save it to file in order to minimaze API calls 
		ibmcloud pi in $line > instance.txt
		#get instance name 
		#instancename=`(ibmcloud pi in $line | grep "Name" | awk '{ print $2 }')`
		instancename=`(cat instance.txt | grep "Name" | awk '{ print $2 }')` 
		
		#get systype
		systype=`(ibmcloud pi in $line  --json | grep sysType | awk -F "\"" '{ print $4 }')` 

		#get proc
		#cpu=`(ibmcloud pi in $line | grep "CPU Cores" | awk '{ print $3 }')`
		cpu=`(cat instance.txt | grep "CPU Cores" | awk '{ print $3 }')`
		#get memory
		#memory=`(ibmcloud pi in $line | grep "Memory" | awk '{ print $2 }')`
		memory=`(cat instance.txt | grep "Memory" | awk '{ print $2 }')`



		# get volumes and sumarize capacity 

		volumelist=`(ibmcloud pi in $line | grep Volumes | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' | sed  's/\,//g')`
		for i in $volumelist
			do
 
			type=`(ibmcloud pi vol $i | grep Profile | awk '{print $2}')` 
			if [[ $type == tier1 ]]
				then
				size=`(ibmcloud pi vol $i | grep Size | awk '{print $2}')`
				tier1total=$(( $tier1total + $size ))
				else 
				size3=`(ibmcloud pi vol $i | grep Size | awk '{print $2}')`
				tier3total=$(( $tier3total + $size3 ))
			fi
		done
		echo $geo,$servicename,$instancename,$systype,$cpu,$memory,$tier1total,$tier3total >> powerout.csv
	done 
done
rm -f instance.txt 
