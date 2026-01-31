#!/bin/bash

weblate_path="hosted.weblate.org.json"

curl --output $weblate_path 'https://hosted.weblate.org/api/projects/asteroidos/languages/?format=json'

declare -a exceptions=("en" "en_devel")

default_language=$(jq '.[] | select(.code == "en_GB")' $weblate_path)
default_total=$(echo $default_language | jq -r '.total')

jq -r '.[] | [.code, .name, .translated] | @tsv' "$weblate_path" |
while IFS=$'\t' read -r code name translated; do
  for ex in "${exceptions[@]}"; do
    [[ "$ex" == "$code" ]] && continue 2
  done

  threshold=$(($default_total/2))
  if [ $translated -lt $threshold ]; then
    echo "Skipping: Insufficient translations for $code"
    continue
  fi

  conf_path="${code}.conf"

  partly_existing=$(find . -iname "${code}*")
  if [ -n "$partly_existing" ]; then
    continue
  fi

  if [ ! -f "$conf_path" ]; then
    echo "Generating $conf_path"
    cat <<EOF > "$conf_path"
Name=$name
LocaleCode=${code}.utf8
EOF
  fi
done

rm $weblate_path
