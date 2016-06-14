#!/usr/bin/env bash


# Reset terminal on exit
trap 'tput cnorm; tput sgr0; clear' EXIT

# invisible cursor, no echo
tput civis
stty -echo

o="█"
text="~(˘▾˘~)"
MW=$(tput cols)
MH=$(tput lines)
dir=1 x=$(($(tput cols)/2)) y=$(($(tput lines)/2))
color=3

while sleep 0.05 # GNU specific!
do
    # move and change direction when hitting walls
#    (( x == 0 || x == max_x )) && \
#        ((dir *= -1))
#    (( x += dir ))


    # read all the characters that have been buffered up
    while IFS= read -rs -t 0.0001 -n 1 key
    do
        [[ $key == d ]] && (( x++ )) && text="(~˘▾˘)~"
        [[ $key == a ]] && (( x-- )) && text="~(˘▾˘~)"
        [[ $key == s ]] && (( y++ ))
        [[ $key == w ]] && (( y-- ))
        [[ $key == c ]] && echo "☘"
        [[ $key == " " ]] && color=$((color%7+1))
    	[[ $key == q ]] && exit
    done
	
    # batch up all terminal output for smoother action
    framebuffer=$(
        clear
        tput cup "$y" "$x"
        tput setaf "$color"
        printf "%s" "$text"
    )

    # dump to screen
    printf "%s" "$framebuffer"
done
