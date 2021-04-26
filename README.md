Files:

getont.sh -> Gets data from ONTs connected in HUWAEI GPON OLTs. Right now it can measure the ONT Rx Signal only, but its dead easy to incorporate. I don't know the MIBS(they are closed source) and didnt bother to do better.
Read the code to understand, it's *really* messy but works fine. I use it in production with a cronjob and never failed.
Sometimes the OLT reliably sends buggy data via SNMP, just filter it out with sed(1).. It's not nice but gets the job done.
I use it to sense my customers signal with Zabbix. The original script send data to it via zabbix_sender(1).
Tested with:
HUAWEI GPON OLT
NET-SNMP 5.7.3
FreeBSD 12.1-RELEASE-p4

I tried to run it in my Linux laptop but it doenst work(fuck gnu userland).
