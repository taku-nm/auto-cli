#!/bin/bash

bot_token="$1"
inputFile="$2"
commit_message="$3"

regex_channel_ID="(?<=/attachments/)\d+"
regex_cdn_url='https:\/\/cdn\.discordapp\.com[^"]+'
regex_cdn_no_params='https:\/\/cdn\.discordapp\.com\/attachments\/\d+\/\d+\/[^?]+'
regex_ex_value="(?<=\?ex=)[^&]+"

function main () {

    inputFileContent=$(cat "$inputFile")
    
    # find link with oldest expire timestamp
    findOldestURL "$inputFileContent"

    # if link expires in a day, replace it
    current_timestamp=$(date +%s)
    compared_timestamp=$(($current_timestamp + 86400))
    echo "Current Timestamp: $current_timestamp" 1>&2
    echo "Compared Timestamp: $compared_timestamp" 1>&2
    echo "Oldest Timestamp: $oldestTimestamp" 1>&2
    if [ "$oldestTimestamp" -lt "$compared_timestamp" ]; then
        echo "detected expired timestamp" 1>&2
        updateURL
        main
    fi

    # target schedule 1 day before link expires
    # if scheduled within 700 seconds, wait and then replace, to avoid tight scheduling
    targetTimestamp=$(($oldestTimestamp - 86400))
    timeDifference=$(($targetTimestamp - $current_timestamp))
    echo "Time difference: $timeDifference" 1>&2
    if [ "$timeDifference" -le "700" ]; then
        echo "Timestamp within range" 1>&2
        if [ "$timeDifference" -gt "0" ]; then
            echo "Sleeping..." 1>&2
            sleep $(($timeDifference + 10))
        fi
        updateURL "overwrite"
        main
    fi

    # if above two conditions aren't met, set schedule to target and commit
    if [ "$timeDifference" -gt "700" ]; then
        echo "Scheduling..." 1>&2
        cron_date=$(date -d "@$targetTimestamp" "+%M %H %d %m")
        echo "$cron_date *"
    fi
}

function getMessages () {
    messagesJson=$(mktemp)
    curl -H "Authorization: Bot $bot_token" https://discord.com/api/v9/channels/$1/messages?limit=100 > "$messagesJson"
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
    
    old_channel_ID=$channel_ID

    # get channel id
    channel_ID=($(echo "$oldest_url" | grep -o -P "$regex_channel_ID"))

    if [[ "$channel_ID" != "$old_channel_ID" ]]; then
        # get messagesJson
        sleep 10
        getMessages "$channel_ID"
    fi

    if [[ "$1" == "overwrite" ]]; then
        getMessages "$channel_ID"
    fi

    # create messagesURL array
    messagesURLs=($(echo "$messagesJsonContent" | grep -o -P "$regex_cdn_url"))

    # clear found state
    found=false

    # find corresponding messageLink in array by comparing with substring match
    for messagesURL in "${messagesURLs[@]}"; do
        if [[ "${messagesURL,,}" == *"${clean_input_URL,,}"* ]]; then
            new_url="$messagesURL"
            found=true
            # sed replace full inputLink with full messageLink
            sed -i "s|$(echo "$oldest_url" | sed 's/[\&/]/\\&/g')|$(echo "$new_url" | sed 's/[\&/]/\\&/g')|g" "$inputFile"
            break
        fi
    done

    if [ "$found" = false ]; then
        echo 1>&2
        echo "FATAL: Condition not met in the loop. No link found?" 1>&2
        echo Input URL: $clean_input_URL 1>&2
        echo 1>&2
        exit 404
    fi
}

git config --global user.email "actions@github.com" &> /dev/null
git config --global user.name "GitHub Actions" &> /dev/null
main
git add "$inputFile" &> /dev/null
git commit -m "$commit_message" &> /dev/null
git push origin HEAD &> /dev/null