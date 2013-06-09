#!/bin/bash
clear
echo "    //   ) )"
echo "   //___/ /   ___      ___     / ___                   ___     // //"
echo "  / ___ (   //   ) ) //   ) ) //\ \     //  / /  / / //___) ) // //"
echo " //   | |  //   / / //       //  \ \   //  / /  / / //       // //"
echo "//    | | ((___/ / ((____   //    \ \ ((__( (__/ / ((____   // //"
echo ""
echo "Somebody's Watching You..."
echo "                                                             ^_^"
filename="Rockwell_netstat.csv"
filename2="Rockwell_netstat_ipv6.csv"
MapStats="Rockwell_location_stats.csv"
TotalGeoStats="Rockwell_geo_stats.csv"

CountryTable="Rockwell_Countries.html"
PIDTable="Rockwell_PIDs.html"
databasefolder="databases/"
resourcefolder="resources/"
verbose=true
debug=false
#IPv4Country="GeoIP.dat"
#IPv6Country="GeoIPv6.dat"
IPv4City="GeoLiteCity.dat"
#IPv6City="GeoLiteCityv6.dat"

geoip_check=`dpkg -l geoip-bin | grep ii | awk '{print $2}'`
if [ "$geoip_check" != "geoip-bin" ];then
	echo "[DEBUGGING] checking .$geoip_check. vs .geoip-bin."
	echo "[ERROR] Geoip is NOT installed!"
	echo "[ERROR] please execute: sudo apt-get install geoip-bin"
	exit 1
fi

#if [ -e "$databasefolder$IPv4Country" ]; then
#	echo "[Rockwell] $IPv4Country File exists!"
#	else
#	echo "[ERROR] IPv4 Country Missing! downloading file..."
#	cd $databasefolder
#	wget --quiet http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz
#	gunzip GeoIP.dat.gz
#	cd ..
#	if [ -e "$databasefolder$IPv4Country" ]; then
#		#if $debugging;then
#		echo "[Rockwell] $IPv4Country successfully downloaded!"
#		#fi
#	else
#		echo "[ERROR] Could not obtain file!"
#		exit 1
#	fi
#fi
#if [ -e "$databasefolder$IPv6Country" ]; then
#        echo "[Rockwell] $IPv6Country File exists!"
#        else
#        echo "[ERROR] IPv6 Country Missing! downloading file..."
#        cd $databasefolder
#        wget --quiet http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz
#        gunzip GeoIPv6.dat.gz
#        cd ..
#        if [ -e "$databasefolder$IPv6Country" ]; then
#                #if $debugging;then
#                echo "[Rockwell] $IPv6Country successfully downloaded!"
#                #fi
#        else
#                echo "[ERROR] Could not obtain file!"
#                exit 1
#        fi
#fi
if [ -e "$databasefolder$IPv4City" ]; then
	if $verbose;then
	        echo "[Rockwell] $IPv4City File exists!"
        fi
	else
        echo "[ERROR] IPv4 City Missing! downloading file..."
        cd $databasefolder
        wget --quiet http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz
        gunzip GeoLiteCity.dat.gz
        cd ..
        if [ -e "$databasefolder$IPv4City" ]; then
                if $verbose;then
                	echo "[Rockwell] $IPv4City successfully downloaded!"
                fi
        else
                echo "[ERROR] Could not obtain file!"
                exit 1
        fi
fi
#if [ -e "$databasefolder$IPv6City" ]; then
#        echo "[Rockwell] $IPv6City File exists!"
#        else
#        echo "[ERROR] IPv6 City Missing! downloading file..."
#        cd $databasefolder
#        wget --quiet http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz
#        gunzip GeoLiteCityv6.dat.gz
#        cd ..
#        if [ -e "$databasefolder$IPv6City" ]; then
#                #if $debugging;then
#                echo "[Rockwell] $IPv6City successfully downloaded!"
#                #fi
#        else
#                echo "[ERROR] Could not obtain file!"
#                exit 1
#        fi
#fi
netstat -vatnp | grep -v "0.0.0.0" | awk '{print $4" "$5" "$7 " "$6}' | grep -v "::" | tr ":" " " | awk '{print $1","$2","$3","$4","$5","$6}' > $databasefolder$filename
netstat -vatnp | grep -v "0.0.0.0" | awk '{print $4" "$5" "$7 " "$6}' | grep "::" > $databasefolder$filename2
if $verbose; then
	echo "[Rockwell] $filename created!"
fi

sourceIPs=(`cat $databasefolder$filename | grep "192.168" | tr "," " " | awk '{print $3}' | grep -v "192.168." | grep -v "0.0.0.0" | grep -v "127.0.0.1"`)
adjusted_lines=${#sourceIPs[*]}
adjusted_lines=$(( adjusted_lines - 1 )) #exception handling

echo "[Rockwell] Creating Source IPv4 Stats..."
touch temp
for i in `seq 0 $adjusted_lines`;
do
        geoiplookup -f $databasefolder$IPv4City ${sourceIPs[$i]} | tr -d " " | tr "," " " | tr ":" " " | awk '{print $3","$4","$5}' >> temp
done
cat temp | grep -v "0.0.0.0" | sort | uniq -c | awk '{print $2","$1}' > $databasefolder$MapStats
rm temp

echo "[Rockwell] Creating Total Source IPv4 csv..."
echo "lon_0,lat_0,Country,State/Territory,City,zip,phone,IP,PID/Name" > $databasefolder$TotalGeoStats
for i in `seq 0 $adjusted_lines`;
do
	netpid=`grep "${sourceIPs[$i]}" $databasefolder$filename | tr "," " " | awk '{print $5}' | uniq`
	#echo "[DEBUGGING] This is the IP: ${sourceIPs[$i]}"
	geoiplookup -f $databasefolder$IPv4City ${sourceIPs[$i]} | tr -d " " | tr "," " " | tr ":" " " | awk  -v IP=${sourceIPs[$i]} -v PID=$netpid '{print $8","$7","$3","$4","$5","$6","$9","IP","PID }' >> $databasefolder$TotalGeoStats
done


CountryListing=(`cat $databasefolder$MapStats`)
adjusted_lines2=${#CountryListing[*]}
adjusted_lines2=$(( adjusted_lines2 - 1 )) #exception handling
echo "[Rockwell] Creating $CountryTable ..."
echo "<html><body><table border="1">" > $resourcefolder$CountryTable
echo "<tr><td>Country</td><td>State/Territory</td><td>City</td><td>Connections</td></tr>" >> $resourcefolder$CountryTable
for i in `seq 0 $adjusted_lines2`;
do
	echo "${CountryListing[$i]}" | tr "," " " | awk '{print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td></tr>"}' >> $resourcefolder$CountryTable
done
echo "</table></body></html>" >> $resourcefolder$CountryTable

PIDListing=(`cat $databasefolder$TotalGeoStats`)
adjusted_lines3=${#PIDListing[*]}
adjusted_lines3=$(( adjusted_lines3 - 1 )) #exception handling
echo "[Rockwell] Creating $PIDTable ..."
echo "<html><body><table border="1">" > $resourcefolder$PIDTable
for i in `seq 0 $adjusted_lines3`;
do
        echo "${PIDListing[$i]}" | tr "," " " | awk '{print "<tr><td>"$3"</td><td>"$5"</td><td>"$8"</td><td>"$9"</td></tr>"}' >> $resourcefolder$PIDTable
done
echo "</table></body></html>" >> $resourcefolder$PIDTable

echo ""
echo "[Rockwell] Map is ready! Enjoy your paranoia ;)"
