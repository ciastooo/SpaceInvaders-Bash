#!/bin/bash
# Piotr Wontka 167951
tput civis	# hiding cursor

###################################
# zmienne:
map_height=16	# map's height
map_width=30	# map's width

player_x=8	# player X position on the bottom of the map

player_bullet_x=$player_x	# bullet X position
player_bullet_y=$map_height	# bullet Y position (if it equals map_height then we can shoot)

enemies_y=1	# height at which enemies are currently on
enemies_x=0 # width at which enemies are currently on (if enemies_x*3 is grater thanor equal to map_width then we move all rows of enemies to enemies_y+1 )
enemies_direction=true	# true = moving right; false = moving left
enemies_1=( false false false false false false )	# first row of enemies
enemies_2=( false false false false false false )	# second row of enemies
enemies_3=( false false false false false false )	# third row of enemies

##################################

while getopts w:h:r: option
do
	regexp="^-?[0-9]+$"
	if ! [[ $OPTARG =~ $regexp ]]; then
		echo "Wrong parameter \"${option}\" type - it should be numeric"
		tput cvvis	# showing cursor
		exit 0
	else
		case "${option}" in
			w) 
				console_w=`tput cols`
				if (( $OPTARG < 30 || $OPTARG > $console_w-1 )); then
					echo "Width must be greater than 30 and lower than console width ($(($console_w-1)))"
					tput cvvis	# showing cursor
					exit 0
				else
					map_width=$OPTARG
				fi;;
			h) 
				console_h=`tput lines`
				if (( $OPTARG < 16 || $OPTARG > console_h-2 )); then
					echo "Height must be greater than 16 and lower than console height ($(($console_h-2)))"
					tput cvvis	# showing cursor
					exit 0
				else
					map_height=$OPTARG
					player_bullet_y=$map_height
				fi;;
			r) if (( $OPTARG < 1 || $OPTARG > 3 )); then
					echo "Number of enemy rows must be greater than 1 and lower than 3"
					tput cvvis	# showing cursor
					exit 0
				else
					case "$OPTARG" in
						1) enemies_1=( true true true true true true );;
						2) enemies_1=( true true true true true true )
						   enemies_2=( true true true true true true );;
						3) enemies_1=( true true true true true true )
						   enemies_2=( true true true true true true )
						   enemies_3=( true true true true true true );;
					esac
				fi;;
		esac
	fi
done

#################################

clear
echo "Piotr Wontka 167951"
echo "Space Invaders"
echo "Controls:"
echo "	a - move left; d - move right; s - shoot; q - quit"
echo "Press any key to continue"
read -s -n 1

function draw_player() {
	tput cup $map_height 0
	printf "%80s" " "
	tput cup $map_height $player_x
	printf "^"
}

function draw_bullet() {
	if (( $player_bullet_y != $map_height )); then
		if (( $player_bullet_y == 0 )); then
			player_bullet_y=$map_height
		else
			tput cup $player_bullet_y $player_bullet_x
			printf " "
			player_bullet_y=$(($player_bullet_y-1))
			tput cup $player_bullet_y $player_bullet_x
			printf "*"
		fi
	fi
}

function draw_enemies_row() {	# returning index of killed enemy
	row_number=$1	# current number row of enemies
	shift
	row=( `echo $@` )
	killed=8
	enemy_y=$(($row_number*2+$enemies_y))
	tput cup $enemy_y 0
	printf "%80s" " "
	tput cup $(($enemy_y-1)) 0
	printf "%80s" " "
	for i in `seq 0 5`
	do
		if [[ ${row[$i]} == true ]]; then
			enemy_x=$(($i*4+$enemies_x))
			if (( $enemy_y == $player_bullet_y && $enemy_x <= $player_bullet_x && $enemy_x+2 >= $player_bullet_x )); then
				killed=$i
				player_bullet_y=$map_height
				tput cup $enemy_y $enemy_x
				printf "   "
			else
				tput cup $enemy_y $enemy_x
				printf "|M|"
			fi
		fi
	done
	return $killed
}

function tick() {
	(sleep 0.5 && kill -ALRM $$) &

	if [[ $enemies_direction == "true" ]]; then
		if (( $enemies_x+20 >= $map_width )); then	# if enemies are at the right border of the map (15 is the position of last enemy)
			enemies_x=$(($map_width-20))
			enemies_direction=false	# changing moving direction
			enemies_y=$(($enemies_y+1))
		else
			enemies_x=$(($enemies_x+1))
		fi
	else
		if (( $enemies_x <= 0 )); then	# if enemies are at the left border of the map
			enemies_x=0
			enemies_direction=true	# changing moving direction
			enemies_y=$(($enemies_y+1))
		else
			enemies_x=$(($enemies_x-1))
		fi
	fi	
	draw_player
	if [[ " ${enemies_3[@]} " =~ " true " ]]; then
		if (( $enemies_y+4 == $map_height )); then
			clear
			echo "PRZEGRANA!"
			tput cvvis	# showing cursor
			trap exit ALRM
			sleep 1
			exit 0
		fi
		draw_enemies_row 2 ${enemies_3[@]}
		enemies_3[$?]=false
	fi
	if [[ " ${enemies_2[@]} " =~ " true " ]]; then
		if (( $enemies_y+2 == $map_height )); then
			clear
			echo "PRZEGRANA!"
			tput cvvis	# showing cursor
			trap exit ALRM
			sleep 1
			exit 0
		fi
		draw_enemies_row 1 ${enemies_2[@]}
		enemies_2[$?]=false
	fi
	if [[ " ${enemies_1[@]} " =~ " true "  ]]; then
		if (( $enemies_y == $map_height )); then
			clear
			echo "PRZEGRANA!"
			tput cvvis	# showing cursor
			trap exit ALRM
			sleep 1
			exit 0
		fi
		draw_enemies_row 0 ${enemies_1[@]}
		enemies_1[$?]=false
	elif (( $enemies_y == $map_height )); then
		clear
		echo "WYGRANA!"
		tput cvvis	# showing cursor
		trap exit ALRM
		sleep 1
		exit 0
	fi
	draw_bullet
}

trap tick ALRM

clear
tick

while :
do
	read -s -n 1 key
	case $key in
		"a")
			if (( $player_x > 0 )); then 
				player_x=$((player_x-1))
			fi;;
		"d")
			if (( $player_x < $map_width )); then 
				player_x=$((player_x+1))
			fi;;			
		"s")
			if (( $player_bullet_y == $map_height )); then
				player_bullet_y=$(($map_height-1))
				player_bullet_x=$player_x
			fi;;
		"q")
			tput cvvis	# showing cursor
			trap exit ALRM
			clear
			sleep 1
			exit 0;;
		*) ;;
	esac
	draw_player
done
