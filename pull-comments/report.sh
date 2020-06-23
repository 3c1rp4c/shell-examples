#!/usr/bin/env bash

declare -A students_ask
declare -A students_comment
declare -a ids
declare -a titles
declare -a discusses
declare -a issues

if [[ $(command -v jq) ]];then
  echo "jq binary is required to run this program" | exit 1
fi

# get all threads

if [[ ! -f "threads.json" ]];then
  curl -s 'https://www.yuque.com/api/docs?book_id=827169&include_comment_users=true&include_last_editor=true&include_my_collaboration=true&include_schedule_configs=true&include_share=true&include_user=true&limit=100&offset=0&only_order_by_id=true' -o threads.json
fi

# extract thread's title and id
# https://github.com/koalaman/shellcheck/wiki/SC2207
while IFS=$'' read -r line;do titles+=("$line");done < <(jq '.data | .[] | .title' threads.json)
while IFS=$'' read -r line;do ids+=("$line");done < <(jq '.data | .[] | .id' threads.json)

watch_list=(
'6886010:"第6~8章 综合讨论区"'
'6533347:"第五章：Web服务器"'
'6114088:"第四章：shell脚本编程基础"'
'5794961:"第三章：Linux服务器系统管理基础"'
'5544420:"第二章 ：Linux 服务器系统使用基础"'
'5277258:"虚拟机使用和 Ubuntu 安装相关问题讨论"'
'5277214:"使用 Git 提交作业到 Github 相关问题讨论"'
'5154321:"第一章 Linux 基础"'
)


i=0
for id in "${ids[@]}";do
  for watch in "${watch_list[@]}";do
    if [[ "$id:${titles[$i]}" == "$watch" ]];then
      comment_url="https://www.yuque.com/api/comments?commentable_id=$id&commentable_type=Doc&include_reactions=true&include_to_user=true" 
      comment_json="comment.$id.json"
      # get comments by thread
      if [[ ! -f "$comment_json" ]];then
        curl -s "$comment_url" -o "$comment_json"
      fi

      # parse comment_json
      # 提问统计
      while IFS=$'' read -r line;do issues+=("$line");done < <(jq '.data | .[] | if .parent_id == null then .user.name else empty end' "$comment_json" | sort | uniq -c | sort -nr)
      for issue in "${issues[@]}";do
        count=$(echo -n "$issue" | awk -F ' ' '{print $1}' | tr -d ' ')
        name=$(echo -n "$issue" | awk -F ' ' '{print $2}' | tr -d '"')
        if [[ -n "${students_ask[$name]}" ]];then
          students_ask[$name]=$((count + ${students_ask[$name]}))
        else
          students_ask[$name]=$count
        fi
      done
      unset issues

      # 讨论统计
      while IFS=$'' read -r line;do discusses+=("$line");done < <(jq '.data | .[] | .user.name' "$comment_json" | sort | uniq -c | sort -nr)
      for discuss in "${discusses[@]}";do
        count=$(echo -n "$discuss" | awk -F ' ' '{print $1}' | tr -d ' ')
        name=$(echo -n "$discuss" | awk -F ' ' '{print $2}' | tr -d '"')
        if [[ -n "${students_comment[$name]}" ]];then
          students_comment[$name]=$((count + ${students_comment[$name]}))
        else
          students_comment[$name]=$count
        fi
      done
      unset discusses

      break
    fi
  done
  i=$((i+1))
done

echo "提问统计 ${#students_ask[@]} 人"
for stu in "${!students_ask[@]}";do
  ask_list="${ask_list}$stu ${students_ask[$stu]}"
done

echo "$ask_list" | tr "" "\n" | sort -nr -k2

echo "参与讨论统计 ${#students_comment[@]} 人"
for stu in "${!students_comment[@]}";do
  comment_list="${comment_list}$stu ${students_comment[$stu]}"
done
echo "$comment_list" | tr "" "\n" | sort -nr -k2
