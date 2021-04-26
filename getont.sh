#!/bin/sh
#
# Huawei GPON OLT ONU Status discovery script
# NET-SNMP version: 5.7.3
# FreeBSD 12.1-RELEASE-p4
# OLT HUAWEI
#
# olt_list csv file format:
# IP,VERSION,NAME,COMMUNITY,IGNORE
# Add as many as you want.
#
# SNMP SUCKS
#
# Written by Axey Gabriel Muller Endres
# 02 February 2021
#

runmode="$1"

ont_list="/tmp/ont_list"
csv_file="/tmp/ont_csv"
olt_list="/tmp/olt_list"
lock_file="/tmp/ont.lock"

if [ -f "$lock_file" ]; then
	echo "Lock file $lock_file already exists."
	exit 1
fi

touch $lock_file

startdate=`date`
echo "Script started at $startdate"
echo "Cleaning old files if necessary"

rm -f $olt_list
rm -f $csv_file
rm -f $ont_list
rm -f $zabbixsender_discovery_file
rm -f $zabbixsender_data_file

#### OLTS

echo "Adding OLTs to list"
echo "xxx.xxx.xxx.xxx,2c,OLTNUMBER1,public,no" >> $olt_list
echo "yyy.yyy.yyy.yyy,1,OLTNUMBER2,public,no" >> $olt_list


while IFS=, read -r ip version oltname community ignore;
do
	if [ "$ignore" = "yes" ]; then
		echo "Ignoring $oltname."
		continue;
	fi

	echo -n "Testing SNMP daemon at $oltname[$ip] ... "
	nc -zu $ip 161 > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Not listening. Aborting."
		continue;
	fi
	echo "OK"
	
	rm -f $ont_list

	echo "Discovering ONTs in $oltname[$ip] ..."
	starttime=`date +%s`
	
	snmpwalk -Oq -v$version -c$community $ip .1.3.6.1.4.1.2011.6.128.1.1.2.43.1.9 | sed 's/"//g' | cut -d'.' -f11,12 >> $ont_list

	totalcount=`cat $ont_list | wc -l | awk '{print $1}'`
	echo "Found $totalcount devices. Getting params now."

	i=0

	while read line;
	do
		username=`echo $line | cut -d' ' -f2- | sed 's/,/ /g'`
		ont=`echo $line | cut -d' ' -f1`
		timestamp=`date +%s`
	
		signal=`snmpget -Oqv -v$version -c$community $ip .1.3.6.1.4.1.2011.6.128.1.1.2.51.1.4.$ont | sed 's/"//g' | awk '{ if($1 < -60000 || $1 > 50000) { print "99999999" } else { print $1 * 0.01 } }'`
		
		echo "${oltname},${username},${signal},${ont},$timestamp" >> $csv_file

		i=$((i+1))
		if [ ! "$runmode" = "noninteractive" ]; then
			printf "\r		   "
			printf "\r%.1f%% done" "`echo "scale=1; $i * 100 / $totalcount" | bc -l`"
		fi
	done < $ont_list
	printf "\n"

	endtime=`date +%s`
	runtime=$((endtime-starttime))

	echo "Done. Took $runtime seconds."
done < $olt_list

sort --field-separator=',' --key=1,2 -o $csv_file $csv_file

echo "All done. Output CSV file written at $csv_file. Exiting."

rm -f $olt_list
rm -f $ont_list
rm -f $lock_file

exit 
