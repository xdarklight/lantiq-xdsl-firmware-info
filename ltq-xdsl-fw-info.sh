#!/bin/sh
# Lantiq xDSL firmware analysis script
#
# LICENSE:
# The MIT License (MIT)
#
# Copyright (c) 2015 Martin Blumenstingl
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

PROG_NAME=${0}
FILEPATH=$(pwd)
VERBOSE=0

function show_help() {
	echo -e "${PROG_NAME} usage:\n	-p	Path to the directory in which the firmware files are stored - defaults to 'pwd'\n	-v	Verbose output - defaults to 'off'\n	-h	Show this help"
}

while getopts "p:vh" OPT; do
	case $OPT in
		p)
			FILEPATH="${OPTARG}"
			;;
		v)
			VERBOSE=1
			;;
		h)
			show_help
			exit 0
			;;
		*)
			show_help
			exit 1
			;;
	esac
done

echo find "${FILEPATH}" -type f -name "*.bin"

find "${FILEPATH}" -type f -print0 | while read -d $'\0' FILE
do
	FILENAME=$(basename "${FILE}")
	VERSION_STRINGS=$(strings "${FILE}" | grep "@(#)")
	IFS=$'\n' read -d '' -r -a VERSIONS <<< "${VERSION_STRINGS//@(#)}"

	case ${#VERSIONS[@]} in
		1)
			if [ "${VERBOSE}" -eq "1" ]
			then
				echo "${FILENAME}: Detected non-VDSL firmware (only one version found)"
			fi

			echo "${FILENAME}: ${VERSIONS[0]}"
			;;
		2)
			if [ "${VERBOSE}" -eq "1" ]
			then
				echo "${FILENAME}: Detected combined VDSL firmware (two versions found)"
			fi

			echo "${FILENAME}: VDSL version: ${VERSIONS[0]}, ADSL version: ${VERSIONS[1]}"
			;;
		*)
			echo "${FILENAME}: NO firmware versions found - is this a valid lantiq DSL firmware file?"
			;;
	esac
done
