#/usr/bin/env bash

low_volume=35
high_volume=100

getdefaultsinkname() {
  pacmd stat | awk -F": " '/^Default sink name: /{print $2}'
}

getsinkvol() {
  pactl list sinks | sed '0,/'"$1"'/d' | sed -n '/Volume/{p;q}' | tr -s ' ' | cut -d ' ' -f 5 | sed 's/%$//'
}

getsinkmuted() {
  pactl list sinks | sed '0,/'"$1"'/d' | sed -n '/Mute:/{p;q}' | tr -s ' ' | cut -d ' ' -f 2
}


update() {
  sink="$(getdefaultsinkname)"
  volume="$(getsinkvol "$sink")"
  muted="$(getsinkmuted "$sink")"

  [ "$muted" = 'yes' ] && icon_string='<fn=1></fn>' || icon_string='<fn=1></fn>'
  if [ "$muted" = 'yes' ]; then
    color="#DC322F"
  else
    if [ "$volume" -le "$low_volume" ]; then
      color="#586e75"
    elif [ "$volume" -gt "$high_volume" ]; then
      color="#b58900"
    else
      color="#268bd2"
    fi
  fi
  echo -n "<action=\`pactl set-sink-mute \"$sink\" toggle\` button=2>"
  echo -n "<action=\`pactl set-sink-volume \"$sink\" -5%\` button=3>"
  echo -n "<action=\`pactl set-sink-volume \"$sink\" -1%\` button=5>"
  echo -n "<action=\`pactl set-sink-volume \"$sink\" +5%\` button=1>"
  echo -n "<action=\`pactl set-sink-volume \"$sink\" +1%\` button=4>"
  echo -n "<fc=${color}>$icon_string ${volume}</fc>%"
  echo "</action></action></action></action></action>"
}

pactl subscribe | grep --line-buffered 'sink' | while read line; do
  update
done
