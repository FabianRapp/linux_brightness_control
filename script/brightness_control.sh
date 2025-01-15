#!/bin/bash

brightness_file="/sys/class/backlight/intel_backlight/brightness"
max_brightness_file="/sys/class/backlight/intel_backlight/max_brightness"

current_brightness=$(cat "$brightness_file")
tmp_ret=$?
if [ $tmp_ret -ne 0 ]; then
	echo "Error: $0: cat: Could not read '$brightness_file'" >&2
	exit $tmp_ret
fi

max_brightness=$(cat "$max_brightness_file")
tmp_ret=$?
if [ $tmp_ret -ne 0 ]; then
	echo "Error: $0: cat: Could not read '$max_brightness_file'" >&2
	exit $tmp_ret
fi

#checks 1 varible
is_integer() {
	re='^[+-]?[0-9]+$'
	if [[ $1 =~ $re ]]; then
		return 0
	else
		return 1
	fi
}

#no args
inc_brightness() {
	current_brightness=$((current_brightness + 1))
}

#no args
dec_brightness() {
	current_brightness=$((current_brightness - 1))
}

#1 args: the change
change_brightness() {
	if ! is_integer $1; then
		echo "Error: $0: Invalid argument: expected an integer, got '$1'" >&2
		usage >&2
		exit 27 #EINVAL
	fi
	current_brightness=$((current_brightness + $1))
}

#1 args: new value (>=0)
set_brightness() {
	if ! is_integer $1 || (($1 < 0)); then
		echo "Error: $0: Invalid argument: expected an integer, got '$1'" >&2
		usage >&2
		exit 27 #EINVAL
	fi
	current_brightness=$1
}

clamp_brightness() {
	if (($current_brightness < 0)); then
		current_brightness=0
	elif (($current_brightness > $max_brightness)); then
		current_brightness=$max_brightness
	fi
}

usage() {
	echo "Usage: $0 [options]"
	echo
	echo "Options:"
	echo "  -h, --h, -help, --help   Show this help message and exit"
	echo "  inc                      Increment the screen brightness by 1"
	echo "  dec                      Decrement the screen brightness by 1"
	echo "  set <integer(>=0)>       Set the brightness to <value>"
	echo "  change <integer>         Change the brightness by <value>"
}

#main
clamp_brightness
if (($# == 0)); then
	echo "Error: $0: no Arguments provided" >&2
	usage >&2
	exit 22 #EINVAL
elif (($# > 2)); then
	echo "Error: $0: more than 2 Arguments provided" >&2
	usage >&2
	exit 7 #E2BIG
elif (($# == 1)); then
	if [ "$1" == 'inc' ]; then
		inc_brightness
	elif [ "$1" == 'dec' ]; then
		dec_brightness
	elif [ "$1" == '-help' ] || [ "$1" == '-h' ] || [ "$1" == '--help' ] || [ "$1" == '--h' ]; then
		usage
		exit 0
	else
		echo "Error: $0: Invalid argument: expected 'inc'/'dec', got '$1'" >&2
		usage >&2
		exit 27 #EINVAL
	fi
elif (($# == 2)); then
	if [ "$1" == 'set' ]; then
		set_brightness $2
	elif [ "$1" == 'change' ]; then
		change_brightness $2
	else
		echo "Error: $0: Invalid argument: expected 'set'/'change', got '$1'" >&2
		usage >&2
		exit 27 #EINVAL
	fi
else
	echo "Error: $0: Invalid arguments" >&2
	usage >&2
	exit 27 #EINVAL
fi

clamp_brightness
echo $current_brightness | sudo tee "$brightness_file" > /dev/null
tmp_ret=$?
if [ $tmp_ret -ne 0 ]; then
	echo "Error: $0: sudo/tee: Could not write to '$brightness_file'" >&2
	exit $tmp_ret
fi

if [ -t 1 ]; then
	echo "Brightness adjusted to $current_brightness"
fi

exit 0
