#!/bin/bash

BASEDIR=$(dirname $(realpath "$0"))

IFS=$'\r\n' eval 'subscriptions=($(cat $BASEDIR/subscriptions.txt))'

while getopts u flag
do
case "${flag}" in
u)
for i in $(seq 0 $((${#subscriptions[@]}-1)))
do
echo "$(echo "${subscriptions[$i]}" | cut -d' ' -f2-)
$(yt-dlp --print-json --flat-playlist $(echo ${subscriptions[$i]} | awk '{print $1}')| jq -r '.title, .id')" | java -jar $BASEDIR/fill_database.jar
done;;
esac
done

IFS=$'\r\n' eval 'channels=($(sqlite3 $BASEDIR/videos.db "SELECT * FROM channel;"))'
declare -A channel_name_to_id
for i in $(seq 0 $((${#channels[@]}-1)))
do
channel_name=$(echo "${channels[$i]}" | cut -d'|' -f2)
channel_name_to_id["$channel_name"]=$(echo "${channels[$i]}" | cut -d'|' -f1)
done
channel=$(printf '%s\n' "${channels[@]}" | cut -d'|' -f2 | fzf)
channel_id=${channel_name_to_id["$channel"]}

IFS=$'\r\n' eval 'videos=($(sqlite3 $BASEDIR/videos.db "SELECT title FROM video WHERE channel_id=$channel_id;"))'
title=$(printf '%s\n' "${videos[@]}" | fzf)
link=$(sqlite3 $BASEDIR/videos.db "SELECT video_link FROM video WHERE channel_id=$channel_id AND title='$title';")

mpv $link

