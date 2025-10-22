#Generate alacritty.toml colour configuration from .Xdefaults *VT100*color settings.

xdefaults_file="${1:-$HOME/.Xdefaults}"
xrgb_file="/etc/X11/rgb.txt"

extract_vt100_colours() {
  local colour_array=()
  local i

  if [[ ! -f "$xdefaults_file" ]]; then
    echo "Error: .Xdefaults file not found at $xdefaults_file" >&2
    return 1
  fi

  readarray -t colour_array < <(
    grep -E '^\*VT100\*(foreground|background|color[0-9]{1,2}):' "$xdefaults_file" |
      grep -v '^!' |
      awk -F '*' '{print $NF}' |
      sed 's/[[:space:]]//;s/[[:space:]]*$//'
  )

  for i in "${!colour_array[@]}"; do
    echo ${colour_array[$i]}
  done
}

map_rgb_colours() {
  local x_colours_text=("$@")
  local x_colours_rgb=()
  local colour_type
  local colour_string
  for i in ${!x_colours_text[@]}; do
    col=${x_colours_text[$i]}
    colour_type="${col%:*}"
    colour_string="${col#*:}"
    readarray -t rgb_array < <(grep $'\t'"${colour_string}"$ "$xrgb_file" | awk '{print $1" "$2" "$3}')
    hex=$(printf "#%02x%02x%02x" ${rgb_array[0]} ${rgb_array[1]} ${rgb_array[2]})
    x_colours_rgb[i]=${col}:${hex}
    echo ${x_colours_rgb[$i]}
  done
}

generate_alacritty_config() {
  local colours=("$@")
  local colour_value=()
  local colour_str=()
  local indx
  local rgb_value
  local colour_name
  local foreground=16
  local background=17

  for c in "${colours[@]}"; do
    idx=${c%%:*}
    if [[ "$idx" = "foreground" ]]; then
      idx=$foreground
    elif [[ "$idx" = "background" ]]; then
      idx=$background
    else
      idx=${idx#color}
    fi
    rgb_value=${c##*:}
    colour_name=${c%:*}
    colour_name=${colour_name#*:}

    colour_str[idx]=$colour_name
    colour_value[idx]=$rgb_value
  done

  cat <<EOF
#colour names from /etc/X11/rgb.txt
[colors.primary]
  background = '${colour_value[background]}' #${colour_str[background]}
  foreground = '${colour_value[foreground]}' #${colour_str[foreground]}

[colors.normal]
  black =   '${colour_value[0]}' #${colour_str[0]}
  red =     '${colour_value[1]}' #${colour_str[1]}
  green =   '${colour_value[2]}' #${colour_str[2]}
  yellow =  '${colour_value[3]}' #${colour_str[3]}
  blue =    '${colour_value[4]}' #${colour_str[4]}
  magenta = '${colour_value[5]}' #${colour_str[5]}
  cyan =    '${colour_value[6]}' #${colour_str[6]}
  white =   '${colour_value[7]}' #${colour_str[7]}

[colors.bright]
  black =   '${colour_value[8]}' #${colour_str[8]}
  red =     '${colour_value[9]}' #${colour_str[9]}
  green =   '${colour_value[10]}' #${colour_str[10]}
  yellow =  '${colour_value[11]}' #${colour_str[11]}
  blue =    '${colour_value[12]}' #${colour_str[12]}
  magenta = '${colour_value[13]}' #${colour_str[13]}
  cyan =    '${colour_value[14]}' #${colour_str[14]}
  white =   '${colour_value[15]}' #${colour_str[15]}
EOF
}

mapfile -t xdef_colours < <(extract_vt100_colours)
mapfile -t xdef_colours_rgb < <(map_rgb_colours "${xdef_colours[@]}")
generate_alacritty_config "${xdef_colours_rgb[@]}"
