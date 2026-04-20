#!/bin/bash

# Configuration
API_KEY="eb235674bb746629cb773fb77ba13c75"
CITY="Surakarta"
COUNTRY_CODE="IDN"

# Weather icons mapping
get_weather_icon() {
    case "$1" in
        "01d") echo "☀️" ;;
        "01n") echo "🌙" ;;
        "02d") echo "⛅" ;;
        "02n") echo "☁️" ;;
        "03d"|"03n"|"04d"|"04n") echo "☁️" ;;
        "09d"|"09n") echo "🌧️" ;;
        "10d") echo "🌦️" ;;
        "10n") echo "🌧️" ;;
        "11d"|"11n") echo "⛈️" ;;
        "13d"|"13n") echo "❄️" ;;
        "50d"|"50n") echo "🌫️" ;;
        *) echo "🌡️" ;;
    esac
}

# Fetch weather data
get_weather() {
    local url="https://api.openweathermap.org/data/2.5/weather?q=${CITY},${COUNTRY_CODE}&appid=${API_KEY}&units=metric"
    
    # Fetch data with curl
    local response=$(curl -s --connect-timeout 10 "$url")
    
    # Check if curl failed
    if [ $? -ne 0 ] || [ -z "$response" ]; then
        echo '{"text":"🌡️ --°C","tooltip":"No internet connection. Retrying...","class":"weather-error"}'
        exit 1
    fi
    
    # Check for API error
    if echo "$response" | grep -q '"cod":"404"'; then
        echo '{"text":"🌡️ --°C","tooltip":"City not found","class":"weather-error"}'
        exit 1
    fi
    
    # Parse JSON using jq or grep/sed
    if command -v jq &> /dev/null; then
        # Using jq (recommended)
        local temp=$(echo "$response" | jq -r '.main.temp' | xargs printf "%.0f")
        local feels_like=$(echo "$response" | jq -r '.main.feels_like' | xargs printf "%.0f")
        local description=$(echo "$response" | jq -r '.weather[0].description' | sed 's/\b\(.\)/\u\1/')
        local icon_code=$(echo "$response" | jq -r '.weather[0].icon')
        local humidity=$(echo "$response" | jq -r '.main.humidity')
        local wind_speed=$(echo "$response" | jq -r '.wind.speed')
    else
        # Using grep/sed (fallback)
        local temp=$(echo "$response" | grep -o '"temp":[^,]*' | head -1 | cut -d':' -f2 | xargs printf "%.0f")
        local feels_like=$(echo "$response" | grep -o '"feels_like":[^,]*' | head -1 | cut -d':' -f2 | xargs printf "%.0f")
        local description=$(echo "$response" | grep -o '"description":"[^"]*"' | head -1 | cut -d'"' -f4)
        local icon_code=$(echo "$response" | grep -o '"icon":"[^"]*"' | head -1 | cut -d'"' -f4)
        local humidity=$(echo "$response" | grep -o '"humidity":[^,}]*' | head -1 | cut -d':' -f2)
        local wind_speed=$(echo "$response" | grep -o '"speed":[^,}]*' | head -1 | cut -d':' -f2)
    fi
    
    # Get weather icon
    local icon=$(get_weather_icon "$icon_code")
    
    # Capitalize first letter of description
    description="$(echo "${description:0:1}" | tr '[:lower:]' '[:upper:]')${description:1}"
    
    # Format output
    local text="${icon} ${temp}°C •"
    local tooltip="${description}\\nTemperature: ${temp}°C\\nFeels like: ${feels_like}°C\\nHumidity: ${humidity}%\\nWind: ${wind_speed} m/s"
    
    # Output JSON
    echo "{\"text\":\"${text}\",\"tooltip\":\"${tooltip}\",\"class\":\"weather\"}"
}

# Main
get_weather
