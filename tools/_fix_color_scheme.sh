#!/bin/sh
#
# Written in 2016 by Sergei Eremenko <https://github.com/SmartFinn>
#
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication along
# with this software. If not, see
# <http://creativecommons.org/publicdomain/zero/1.0/>.
#
# Description:
#  This script looks in the SVG files for certain colors and replaces
#  them with the corresponding stylesheet class. Fixes a color scheme
#  after Inkscape.
#
# Limitations:
#  - works only with one element per line
#
# Usage:
#  _fix_color_scheme.sh FILE...

set -e

# Papirus, Papirus-Dark, Papirus-Light, and ePapirus
add_class() {
	# add the class if a value matches:
	sed -i -r \
		-e '/([^-]color|fill|stop-color|stroke):(#444444|#dfdfdf|#6e6e6e|#ffffff)/I s/(style="[^"]+")/\1 class="ColorScheme-Text"/' \
		-e '/([^-]color|fill|stop-color|stroke):#4285f4/I s/(style="[^"]+")/\1 class="ColorScheme-Highlight"/' \
		-e '/([^-]color|fill|stop-color|stroke):#4caf50/I s/(style="[^"]+")/\1 class="ColorScheme-PositiveText"/' \
		-e '/([^-]color|fill|stop-color|stroke):#ff9800/I s/(style="[^"]+")/\1 class="ColorScheme-NeutralText"/' \
		-e '/([^-]color|fill|stop-color|stroke):#f44336/I s/(style="[^"]+")/\1 class="ColorScheme-NegativeText"/' \
		"$@"
}

# Symbolic
add_class_symbolic() {
	# add classes if a color matches and a class is missing:
	sed -i -r \
		-e '/class=/! { /([^-]color|fill|stop-color|stroke):#4caf50/I s/(style="[^"]+")/\1 class="success"/ }' \
		-e '/class=/! { /([^-]color|fill|stop-color|stroke):#ff9800/I s/(style="[^"]+")/\1 class="warning"/ }' \
		-e '/class=/! { /([^-]color|fill|stop-color|stroke):#f44336/I s/(style="[^"]+")/\1 class="error"/ }' \
		"$@"
}

remove_colorscheme_class() {
	# remove class to avoid duplicates
	# 1. remove class="ColorScheme-*" if currentColor is missing
	# 2. remove class="ColorScheme-*" if color property is set
	sed -i -r \
		-e '/class="ColorScheme-/ { /:currentColor/! s/[ ]class="ColorScheme-[^"]+"// }' \
		-e '/class="ColorScheme-/ { /[^-]color:[^";]+/ s/[ ]class="ColorScheme-[^"]+"// }' \
		"$@"
}

replace_hex_to_current_color() {
	# if class exist:
	#   - remove color
	#   - replace fill=#HEXHEX to fill=currentColor
	sed -i -r \
		-e '/class="ColorScheme-/ s/([^-])color:#([[:xdigit:]]{3}|[[:xdigit:]]{6});?/\1/' \
		-e '/class="ColorScheme-/ s/fill:#([[:xdigit:]]{3}|[[:xdigit:]]{6});?/fill:currentColor;/' \
		-e '/class="ColorScheme-/ s/stroke:#([[:xdigit:]]{3}|[[:xdigit:]]{6});?/stroke:currentColor;/' \
		-e '/class="ColorScheme-/ s/stop-color:#([[:xdigit:]]{3}|[[:xdigit:]]{6});?/stop-color:currentColor;/' \
		"$@"
}

for file in "$@"; do
	# continue if it's a file
	[ -f "$file" ] || continue

	if grep -q -i '\.ColorScheme-Text' "$file"; then
		# the file has a color scheme

		remove_colorscheme_class "$file"

		if grep -q -i 'color:\(#444444\|#dfdfdf\|#6e6e6e\|#ffffff\)' "$file"; then
			# it's Papirus, Papirus-Dark, Papirus-Light or ePapirus
			add_class "$file"
		else
			echo "'$file' has unknown colors!" >&2
		fi

		replace_hex_to_current_color "$file"
	else
		case "$file" in
			*-symbolic.svg|*-symbolic-rtl.svg|*-symbolic@symbolic.svg|*-symbolic-rtl@symbolic.svg)
				# it's symbolic icon
				add_class_symbolic "$file"
				;;
			*)
				continue
				;;
		esac
	fi
done
