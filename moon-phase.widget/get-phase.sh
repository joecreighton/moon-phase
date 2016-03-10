#!/bin/sh
#
# syntax: get-phase [city] [region] [country] [IPLookup]
# returns: customized JSON data set of moon data from USNO
#

# setup curl
CURL="curl --connect-timeout 5 -s"

# USNO API ID is optional but let's pass one so they know, as requested
USNOID=UberMoon

# we need to write a text table to a file
ILLUMTAB="moon-phase.widget/illumtab.txt"

do_fail()
{
  cat << !
{ "error": true, "message": "$1" }
!
  exit
}

# pull passed vars
if [ "$#" -eq 3 ]; then
  IPLookup="false"
  city=$1; region=$2; country=$3

  # failsafe!
  if [ -z "$city" -a -z "$region" -a -z "$country" ]; then
    IPLookup="true"
  fi
else
  IPLookup="true"
fi

# find our coords based on IP
if [ "$IPLookup" = "true" ]; then
  coords=`$CURL http://freegeoip.net/csv/`

  if [ -z "$coords" ]; then
    : # noop
  elif [ "$coords" = "Try again later" ]; then
    : # noop
  else
    city=`echo $coords | awk -F"," '{ print $6 }'`
    region=`echo $coords | awk -F"," '{ print $5 }'`
    country=`echo $coords | awk -F"," '{ print $3 }'`
    latitude=`echo $coords | awk -F"," '{ print $9 }'`
    longitude=`echo $coords | awk -F"," '{ print $10 }'`
  fi
fi

# encode spaces
city=`echo $city | sed 's/ /%20/g'`
region=`echo $region | sed 's/ /%20/g'`
country=`echo $country | sed 's/ /%20/g'`

# if freegeoip fails, or if requested, find our coords based on location
if [ -z "$coords" -o "$IPLookup" = "false" -o "$coords" = "Try again later" ]; then
  BASEURL="https://maps.googleapis.com/maps/api/geocode/json"
  coords=`$CURL "${BASEURL}?address=${city},${region},${country}&sensor=false"`
  if [ -z "$coords" ]; then
    do_fail "failed to reach googleapis.com geocode API"
  fi
  latlong=`echo $coords | awk -F"\"location\" :" '{ print $2 }'`
  latitude=`echo $latlong | sed 's/,/ /g' | awk '{ print $4 }'`
  longitude=`echo $latlong | sed 's/,/ /g' | awk '{ print $7 }'`
fi

# get the illumination table using the form
# http://aa.usno.navy.mil/data/docs/MoonFraction.php
# as designed, tz must be positive, tz_sign indicates E (1) or W (-1) of GMT
# *note: the same results seem to appear when tz is presented as (-)HH.##

# timezone (-)HH.00 as integer floating point
TZ=`date +%z | sed 's/..$/.&/'`

# date details for parsing the table
YYYY=`date +%Y`
MM=`date +%m`
DD=`date +%d`
HH=`date +%H`

cp /dev/null $ILLUMTAB
BASEURL="http://aa.usno.navy.mil/cgi-bin/aa_moonill2.pl?form=2"
$CURL "${BASEURL}&year=${YYYY}&task=${HH}&tz=${TZ}" > $ILLUMTAB

if [ ! -s $ILLUMTAB ]; then
  do_fail "failed to reach USNO illumination table"
fi

# get the illumination for today
col=`expr $MM + 1`
row=`grep "^ ${DD}" $ILLUMTAB`
illum=`echo $row | awk '{ print $'$col' }' | sed 's/0\.//'`
/bin/rm $ILLUMTAB

# attach cardinals
if [ "$(echo "${latitude} > 0" | bc)" -eq 1 ]; then
  latitude=`echo "${latitude}N"`
else
  latitude=`echo "${latitude}S" | sed 's/-//'`
fi
if [ "$(echo "${longitude} > 0" | bc)" -eq 1 ]; then
  longitude=`echo "${longitude}E"`
else
  longitude=`echo "${longitude}W" | sed 's/-//'`
fi

# get moon data using coordinates and timezone
# docs at http://aa.usno.navy.mil/data/docs/api.php
today=`date "+%m/%d/%Y"`
now=`date "+%H:%M"`
BASEURL="http://api.usno.navy.mil/rstt/oneday?ID=${USNOID}&date=${today}&time=${now}"
astrodata=`$CURL "${BASEURL}&coords=${latitude},${longitude}&tz=${TZ}"`

# too many arguments to test sooo...
count=`echo $astrodata | wc -w`
if [ $count -lt 30 ]; then
  do_fail "failed to get expected USNO results"
fi

#
# final cusomizations
#

# leading zeros are bad form (see digit definiton at json.org)
# JSON.parse will break attempting to parse timezones with the
# format (-)0#.## used above.  To fix, wrap it in quotes and
# remove the decimal to make any math later on easier

astrodata=`echo $astrodata |\
 sed 's/"tz":\(\-*\)\(0\)\([0-9]\)\.\([0-9]\)\([0-9]\)/"tz":\"\\1\\2\\3\\4\\5"/'`

# append the more accurate value from USNO illumination table
astrodata=`echo $astrodata |\
 sed 's/ \}$/, \"illum\":\"'"${illum}"'\" }/'`

# append our location in case we did an IPLookup
astrodata=`echo $astrodata |\
 sed 's/ \}$/, \"city\": \"'${city}'\", \"region\": \"'${region}'\", \"country\": \"'${country}'\" }/'`

# unencode spaces
astrodata=`echo $astrodata | sed 's/%20/ /g'`

echo $astrodata

