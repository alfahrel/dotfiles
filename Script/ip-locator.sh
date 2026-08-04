#!/bin/bash
response=$(curl -s "http://ip-api.com/json${IP}?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,query")

if [ $? -ne 0 ]; then
    echo "Error: Could not reach ip-api.com. Check your internet connection."
    exit 1
fi

censor_ip() {
    local ip="$1"
    echo "$ip" | sed 's/\([0-9]*\.[0-9]*\)\.\(.*\)/\1.X.X/'
}

if command -v jq &> /dev/null; then
    status=$(echo "$response" | jq -r '.status')
    if [ "$status" = "fail" ]; then
        msg=$(echo "$response" | jq -r '.message')
        echo "Error: $msg"
        exit 1
    fi

    FULL_IP=$(echo "$response" | jq -r '.query')
    CENSORED_IP=$(censor_ip "$FULL_IP")

    echo ""
    echo "IP Address   : $CENSORED_IP"
    echo "Country      : $(echo "$response" | jq -r '.country')"
    echo "Country ID   : $(echo "$response" | jq -r '.countryCode')"
    echo "Region       : $(echo "$response" | jq -r '.regionName')"
    echo "City         : $(echo "$response" | jq -r '.city')"
    echo "Postal Code  : $(echo "$response" | jq -r '.zip')"
    echo "Coordinates  : $(echo "$response" | jq -r '.lat'), $(echo "$response" | jq -r '.lon')"
    echo "Timezone     : $(echo "$response" | jq -r '.timezone')"
    echo "ISP          : $(echo "$response" | jq -r '.isp')"
    echo "Org          : $(echo "$response" | jq -r '.org')"
    echo "AS           : $(echo "$response" | jq -r '.as')"
    echo ""
else
    echo "Install 'jq' for formatted output."
    echo ""
    echo "Raw JSON:"
    echo "$response" | tr ',' '\n' | sed 's/[{}"]//g'
fi
