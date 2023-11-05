#!/bin/bash

bot_token="$1"
inputFile="$2"

regex_channel_ID="(?<=/attachments/)\d+"
regex_cdn_url='https:\/\/cdn\.discordapp\.com[^"]+'
regex_cdn_no_params='https:\/\/cdn\.discordapp\.com\/attachments\/\d+\/\d+\/[^?]+'
regex_ex_value="(?<=\?ex=)[^&]+"

function main () {
    inputFileContent=$(cat "$inputFile")
    
    # find link with oldest expire timestamp
    findOldestURL "$inputFileContent"

    current_timestamp=$(date +%s)
    if [ "$oldestTimestamp" -lt "$current_timestamp" ]; then
        updateURL
        main
    fi
    if [ "$oldestTimestamp" -gt "$current_timestamp" ]; then
        cron_date=$(date -d "@$oldestTimestamp" "+%M %H %d %m %w")
    fi
}

# function getInputFile () {
#     inputFile=$(mktemp)
#     curl https://raw.githubusercontent.com/taku-nm/discord-cdn-refresher/main/inputJson.json > "$inputFile"
# }

function getMessages () {
    messagesJson=$(mktemp)
    curl -H "Authorization: Bot $bot_token" https://discord.com/api/v9/channels/$1/messages > "$messagesJson"
    messagesJsonContent=$(cat "$messagesJson")
}

function findOldestURL () {
    #clear decimal value buffer
    decimal_values=()

    # Get CDN URLs
    URLs=($(echo "$1" | grep -o -P "$regex_cdn_url"))

    # extract expiry value from input
    URL_ex_values=($(echo "$1" | grep -o -P "$regex_ex_value"))

    #convert hex expiry values to decimal
    for ex_value in "${URL_ex_values[@]}"; do
      decimal_value=$(printf "%d" "0x$ex_value")
      decimal_values+=("$decimal_value")
    done

    #sort decimal values
    sorted_values=($(for val in "${decimal_values[@]}"; do echo "$val"; done | sort -n))

    #convert decimal value to hex
    target_ex_value=$(printf "%X" "${sorted_values[0]}")

    #find target url
    for URL in "${URLs[@]}"; do
      if [[ "${URL,,}" == *"?ex=${target_ex_value,,}"* ]]; then
        target_url="$URL"
        break
      fi
    done

    #function output
    oldest_url=$target_url
    oldestTimestamp=${sorted_values[0]}
}

function updateURL () {
    # clean inputLink (grep regex_cdn_no_params)
    clean_input_URL=($(echo "$oldest_url" | grep -o -P "$regex_cdn_no_params"))

    # get channel id
    channel_ID=($(echo "$oldest_url" | grep -o -P "$regex_channel_ID"))

    # get messagesJson
    getMessages "$channel_ID"

    # create messagesURL array
    messagesURLs=($(echo "$messagesJsonContent" | grep -o -P "$regex_cdn_url"))

    # find corresponding messageLink in array by comparing with substring match
    for messagesURL in "${messagesURLs[@]}"; do
        if [[ "${messagesURL,,}" == *"${clean_input_URL,,}"* ]]; then
            new_url="$messagesURL"
            break
        fi
    done

    # sed replace full inputLink with full messageLink
    sed -i "s|$(echo "$oldest_url" | sed 's/[\&/]/\\&/g')|$(echo "$new_url" | sed 's/[\&/]/\\&/g')|g" "$inputFile"
}

# getInputFile
main
echo $cron_date
