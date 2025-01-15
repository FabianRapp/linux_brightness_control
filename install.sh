#!/bin/bash

if [ "$(which tee 2>/dev/null)" != "/usr/bin/tee" ]; then
	echo "Error: install.sh: (brightness_control.sh): 'tee' not found at /usr/bin/tee."
  exit 1
fi

script_dir="$PWD/script"

in_bashrc="$(grep "$script_dir" "$HOME/.bashrc" 2>/dev/null)"
if [ -z "$in_bashrc" ]; then
	echo >>"$HOME/.bashrc" "PATH=\$PATH:$script_dir"
fi

in_zshrc="$(grep "$script_dir" "$HOME/.zshrc" 2>/dev/null)"
if [ -z "$in_zshrc" ]; then
	echo >>"$HOME/.zshrc" "PATH=\$PATH:$script_dir"
fi

#allows writing to the brightness setting via tee
brightness_file='/sys/class/backlight/intel_backlight/brightness'
tee_bin='/usr/bin/tee'
visudo_addition="$USER ALL=(ALL) NOPASSWD: $tee_bin $brightness_file"

new_sudoers_file="/etc/sudoers.d/brightness_control"

echo "Creating $new_sudoers_file with the following content:"
echo "$visudo_addition"

echo "$visudo_addition" | sudo tee "$new_sudoers_file" >/dev/null
sudo chmod 440 "$new_sudoers_file"

sudo visudo --check

echo 'Install of brightness_control complete.'
echo 'To activate installation for the current shell session, run:'
echo 'source ~/.bashrc'
echo or
echo 'source ~/.zshrc'
