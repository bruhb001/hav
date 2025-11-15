#!/usr/bin/env bash

TEXTFILE="${1:-/usr/share/grok-cli/racerrr.txt}"
ART1="${2:-/usr/share/grok-cli/art1.txt}"
ART2="${3:-/usr/share/grok-cli/art2.txt}"

if [[ ! -f "$TEXTFILE" ]]; then
  echo "Text file '$TEXTFILE' not found" >&2
  exit 1
fi

if [[ ! -f "$ART1" ]] || [[ ! -f "$ART2" ]]; then
  echo "ANSI art files '$ART1' or '$ART2' not found" >&2
  echo "Usage: ./grok.sh racerrr.txt art1.txt art2.txt" >&2
  exit 1
fi

term_cols=80
term_rows=24

get_terminal_size() {
  term_cols=$(tput cols)
  term_rows=$(tput lines)
}


print_centered_block() {
  local arr=("$@")
  get_terminal_size
  local line len pad
  for line in "${arr[@]}"; do
    len=${#line}
    if (( len >= term_cols )); then
      printf '%s\n' "$line"
    else
      pad=$(( (term_cols - len) / 2 ))
      printf '%*s%s\n' "$pad" "" "$line"
    fi
  done
}


type_block_centered() {
  local delay="$1"
  shift
  local arr=("$@")
  get_terminal_size
  local line len pad i
  for line in "${arr[@]}"; do
    len=${#line}
    if (( len < term_cols )); then
      pad=$(( (term_cols - len) / 2 ))
    else
      pad=0
    fi
    printf '%*s' "$pad" ""
    for ((i=0; i<${#line}; i++)); do
      printf '%s' "${line:i:1}"
      sleep "$delay"
    done
    printf '\n'
  done
}


pause_for_enter() {
  local prompt="Press Enter to continue..."
  get_terminal_size
  local len=${#prompt}
  local pad=0
  if (( len < term_cols )); then
    pad=$(( (term_cols - len) / 2 ))
  fi
  printf '%*s%s' "$pad" "" "$prompt"
  read -r
}


animate_validating() {
  clear
  get_terminal_size
  local stages=("Validating" "Validating." "Validating.." "Validating...")
  local row=$(( term_rows / 2 ))
  local iterations=14   # ~4.2 seconds with 0.3s per frame
  local msg len col i

  for ((i=0; i<iterations; i++)); do
    msg=${stages[i % ${#stages[@]}]}
    len=${#msg}
    if (( len < term_cols )); then
      col=$(( (term_cols - len) / 2 ))
    else
      col=0
    fi
    tput cup "$row" "$col"
    printf '%s' "$msg"
    sleep 0.3
  done
  printf '\n'
}

show_random_ansi_art() {
  clear
  get_terminal_size

  local choice
  if (( RANDOM % 2 == 0 )); then
    choice="$ART1"
  else
    choice="$ART2"
  fi


  mapfile -t art < "$choice"

  local line_count=${#art[@]}
  local top_padding=$(( (term_rows - line_count) / 2 ))
  (( top_padding < 0 )) && top_padding=0

  local i


  for ((i=0; i<top_padding; i++)); do
    echo
  done


  for line in "${art[@]}"; do
    printf "%b\n" "$line"
  done


}

mapfile -t sec1 < <(
  awk '
    /#1/ {in1=1; next}
    /#2/ && in1 {exit}
    in1 {print}
  ' "$TEXTFILE"
)

mapfile -t sec2 < <(
  awk '
    /#2 end/ {
      sub(/#2 end/,"")
      sub(/^[[:space:]]+/,"")
      print
      exit
    }
    in2 {
      sub(/^[[:space:]]+/,"")
      print
      next
    }
    /#2/ {
      in2=1
      sub(/#2/,"")
      sub(/^[[:space:]]+/,"")
      print
    }
  ' "$TEXTFILE"
)

mapfile -t sec3 < <(
  awk '
    /#3/ {
      sub(/#3/,"")
      sub(/^[[:space:]]+/,"")
      print
      exit
    }
  ' "$TEXTFILE"
)

########
# Main #
########

clear

print_centered_block "${sec1[@]}"

echo
type_block_centered 0.02 "${sec2[@]}"
echo
pause_for_enter

echo
type_block_centered 0.03 "${sec3[@]}"
sleep 3

animate_validating


show_random_ansi_art
