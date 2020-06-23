#!/usr/bin/env bash

if [[ $(command -v jq) ]];then
  echo "jq binary is required to run this program" | exit 1
fi

# get all threads

if [[ ! -f "threads.json" ]];then
  curl -s 'https://www.yuque.com/api/docs?book_id=827169&include_comment_users=true&include_last_editor=true&include_my_collaboration=true&include_schedule_configs=true&include_share=true&include_user=true&limit=100&offset=0&only_order_by_id=true' -o threads.json
fi

# extract thread's title and id
while IFS=$'' read -r line; do titles+=("$line");done < <(jq '.data | .[] | .title' threads.json)
while IFS=$'' read -r line; do ids+=("$line");done < <(jq '.data | .[] | .id' threads.json)

i=0
for id in "${ids[@]}";do
  echo "$id:${titles[$i]}"
  i=$((i+1))
  comment_url="https://www.yuque.com/api/comments?commentable_id=$id&commentable_type=Doc&include_reactions=true&include_to_user=true" 
  comment_json="comment.$id.json"
  # get comments by thread
  if [[ ! -f "$comment_json" ]];then
    curl -s "$comment_url" -o "$comment_json"
  fi

  # parse comment_json
  echo '提问同学统计'
  jq '.data | .[] | if .parent_id == null then .user.name else empty end' "$comment_json" | sort | uniq -c | sort -nr

  echo '参与讨论同学统计'
  jq '.data | .[] | .user.name' "$comment_json" | sort | uniq -c | sort -nr

done
