#!/bin/bash

# Written by Rodrigo Esteves baitsart@gmail.com www.youtube.com/user/baitsart 
# GNU License. You are free to modify and redistribute   # 

lang="en"
if [ -n "$1" ]; then
lang=$( echo "$1" | uniq )
echo "Language `cat /tmp/lang | sed 's/), (/\n/g;s/(//g;s/)//g' | grep "$lang " | cut -d' ' -f2 `"
fi

recording=5
key="AIzaSyBOti4mM-6x9WDnZIjIeyEU21OpBXqWBgw"
PKG_PATH=$(dirname "$(readlink -f "$0")")
microphe_port=1
PROCESS=$$
CMD_RETRY=$(sed -n '101p' ~/.voice_commands/"v-c LANGS"/commands-"$lang" | cut -d "=" -f 2)


if [ -f /tmp/line_of_process ] ; then
PID=$(cat /tmp/process_result)
kill -HUP $PID 2>/dev/null
rm /tmp/line_of_process
> /tmp/result
sh ~/.voice_commands/play_stop.sh
exit
fi

transcribe()
{
echo "
RECOGNIZING THE VOICE"
notify-send "Testing voice command... " "Please wait"

JSON=`curl -s -X POST \
--data-binary @/tmp/voice_"$PID".flac \
--header 'Content-Type: audio/x-flac; rate=16000;' \
'https://www.google.com/speech-api/v2/recognize?output=json&lang='$lang'&key='$key'' | cut -d\" -f8 `
if echo "$JSON" | sed 's/'"'"'/ /g'  | grep -x -q "$CMD_RETRY" ; then
[[ -f /tmp/speech_recognition_prev.tmp ]] || notify-send "No previous command" "Execute it again, please"
mv /tmp/speech_recognition_prev.tmp /tmp/speech_recognition.tmp
/bin/bash ~/.voice_commands/speech_commands.sh "$lang" "$key"
exit 1
fi
if echo "$JSON" | sed 's/'"'"'/ /g'  | grep -q "Your client does not have permission to get URL" ; then
if new_key=$( zenity --entry --text="The key speech-api/v2 google, should be updated.\nPlease enter a new correct key.\nOtherwise the process can not be made" --title="speech-api new key"); then
if
curl -s -X POST \
--data-binary @/tmp/voice_"$PID".flac \
--header 'Content-Type: audio/x-flac; rate=16000;' \
'https://www.google.com/speech-api/v2/recognize?output=json&lang='$lang'&key='$new_key'' | grep "Your client does not have permission to get URL" ; then
notify-send "Wrong key, Message:" "Your client does not have permission to get URL"
exit 0
fi
sed -i 's/'"$key"'/'"$new_key"'/' ~/.voice_commands/play_stop.sh
sh ~/.voice_commands/play_stop.sh
exit 1
fi
exit
fi
echo "$JSON" | sed 's/'"'"'/ /g'  | sed '/^$/d' | tr '[:upper:]' '[:lower:]' > /tmp/speech_recognition.tmp
rm /tmp/voice_"$PID".flac
rm /tmp/result
killall notify-osd 2>/dev/null
/bin/bash ~/.voice_commands/speech_commands.sh "$lang" "$key"
rm /tmp/process_result
if [ -f /tmp/line_of_process ] ; then
rm /tmp/line_of_process
exit
fi
exit 0;
}

pre_recog()
{
if [ -f /tmp/result ] ; then
PID=$(cat /tmp/process_result)
killall rec 2>/dev/null
pacmd set-source-port "$microphe_port" 'analog-input-microphone-internal'
mv /tmp/voice_.flac /tmp/voice_"$PID".flac
killall notify-osd 2>/dev/null
transcribe
fi
}
echo "$PROCESS" > /tmp/process_result

pre_recog

 > /tmp/line_of_process


PID=$(cat /tmp/process_result)
pacmd set-source-port "$microphe_port" 'analog-input-microphone'
killall notify-osd 2>/dev/null
notify-send "Recording..." "talk, please" 
#paly ~/.voice_commands/sounds/"Recording, talk, please.mp3"
pacmd set-source-port "$microphe_port" 'analog-input-microphone-internal'
( rec -r 16000 -d /tmp/voice_.flac ) & pid=$!
( sleep "$recording"s && kill -HUP $pid ) 2>/dev/null & watcher=$!
wait $pid 2>/dev/null && pkill -HUP -P $watcher
killall notify-osd 2>/dev/null
> /tmp/result
pre_recog

exit 0;

