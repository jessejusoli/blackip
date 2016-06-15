#!/bin/bash
### BEGIN INIT INFO
# Provides:          blackips for ipset
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       capture cidr from acl
# Authors:           Maravento.com and Novatoz.com
# Permisos:          root y chmod +x
# used:              host -t a or dig +short -f
### END INIT INFO

# Create /etc/zones and /etc/acl
if [ ! -d /etc/zones ]; then mkdir -p /etc/zones; fi
if [ ! -d /etc/acl ]; then mkdir -p /etc/acl; fi

# DOWNLOAD GEOZONES
echo "Descargando GeoIps..."
wget -c --retry-connrefused -t 0 http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz && tar -C /etc/zones -zxvf all-zones.tar.gz && rm -f all-zones.tar.gz

# GIT CLONE BLACKIPS
echo "Descargando proyecto Blackips..."
git clone https://github.com/maravento/blackips

# CAPTURE WHITEIPS
echo "Iniciando la captura de Whiteips. Espere..."
cat blackips/whitedomains.txt | sed '/^$/d; / *#/d' | sed 's:^\.::' | sort -u  > blackips/ipsdomains
	for ip in `cat web2ip/ipsdomains`; do
	for sub in "" "www." "ftp."; do
		host -t a "${sub}${ip}";
	done
  done | awk 'BEGIN { FS = " " } ; { print $4 }' | egrep -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sort -u >> blackips/whiteips.txt
  sort -o blackips/whiteips.txt -u blackips/whiteips.txt -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n blackips/whiteips.txt

# DOWNLOAD EXTRA BLACKIPS
echo "Download and capture Zeus badips..."
wget -c --retry-connrefused -t 0 'https://zeustracker.abuse.ch/blocklist.php?download=badips' -O blackips/ipszeus.txt >/dev/null 2>&1
cat blackips/ipszeus.txt | sed '/#.*/d' | sed '/^$/d' | sort -u > blackips/tmp1

echo "Download and capture Ransomware badips..."
wget -c --retry-connrefused -t 0 'https://ransomwaretracker.abuse.ch/downloads/RW_IPBL.txt' -O blackips/ipsransomware.txt >/dev/null 2>&1
egrep -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" blackips/ipsransomware.txt | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '/#.*/d' | sed '/^$/d' | sort -u > blackips/tmp2

echo "Download and capture Tor exit addresses..."
wget -c --retry-connrefused -t 0 'https://check.torproject.org/exit-addresses' -O blackips/ipstor.txt >/dev/null 2>&1
egrep -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" blackips/ipstor.txt | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | sed '/#.*/d' | sed '/^$/d' | sort -u > blackips/tmp3 >/dev/null 2>&1

# CAPTURE IPS FROM SYSLOGEMU
echo "Capture ips from syslogemu.log..."
grep -Eo 'SRC=[0-9.]+' /var/log/ulog/syslogemu.log | sed 's:SRC=::' | sort -u > blackips/syslogemu >/dev/null 2>&1
cat /dev/null > /var/log/ulog/syslogemu.log >/dev/null 2>&1

# JOINT AND DEBUGGED
echo "Joint and debugged blackips (exclude whiteips)..."
cat blackips/tmp1 blackips/tmp2 blackips/tmp3 blackips/syslogemu blackips/blackips.txt /etc/acl/blackips.txt | sed '/#.*/d' | sed '/^$/d' | sort -u > blackips/ipsfinal >/dev/null 2>&1
chmod +x blackips/filter.py
python blackips/filter.py blackips/whiteips.txt | grep -Fxvf - blackips/ipsfinal > /etc/acl/blackips.txt
sort -o /etc/acl/blackips.txt -u /etc/acl/blackips.txt -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n /etc/acl/blackips.txt

# LOG
rm -f blackips*
date=`date +%d/%m/%Y" "%H:%M:%S`
echo "<--| Blackips: ejecucion $date |-->" >> /var/log/syslog.log
exit
