#!/usr/bin/env bash
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
	read -d '' HELP_TEXT <<"EOF"
	-p	Path to the directory in which the firmware files are stored - defaults to 'pwd'
	-v	Enable verbose output - defaults to 'off'
	-h	Show this help
EOF

	printf "%s usage:\n%s\n" "${PROG_NAME}" "${HELP_TEXT}"
}

function parse_firmware_features() {
	local FW_VERSION="${1}"
	local FW_DETAILS=(${FW_VERSION//./ })

	unexport_firmware_features

	export APPLICATION_TYPE_STR=""
	export RELEASE_STATUS_STR=""
	export PLATFORM_STR=""

	export PLATFORM="${FW_DETAILS[0]//[^0-9]/}"
	export FEATURE_SET="${FW_DETAILS[1]}"
	export MAJOR_VERSION="${FW_DETAILS[2]}"
	export MINOR_VERSION="${FW_DETAILS[3]}"
	export RELEASE_STATUS="${FW_DETAILS[4]}"
	export APPLICATION_TYPE="${FW_DETAILS[5]}"

	export VERSION_STR="${FEATURE_SET}.${MAJOR_VERSION}.${MINOR_VERSION}"

	case ${APPLICATION_TYPE} in
		0)
			APPLICATION_TYPE_STR="ADSL Annex B/J"
			;;
		1)
			APPLICATION_TYPE_STR="ADSL Annex A"
			;;
		2)
			APPLICATION_TYPE_STR="ADSL Annex B"
			;;
		3)
			APPLICATION_TYPE_STR="Reserved 1"
			;;
		4)
			APPLICATION_TYPE_STR="Reserved 2"
			;;
		5)
			APPLICATION_TYPE_STR="VDSL over POTS"
			;;
		6)
			APPLICATION_TYPE_STR="VDSL over IDSN"
			;;
		7)
			APPLICATION_TYPE_STR="VDSL over ISDN incl. vectoring support"
			;;
		*)
			APPLICATION_TYPE_STR="UNKNOWN application type (${APPLICATION_TYPE})"
			;;
	esac

	case ${PLATFORM} in
		1)
			PLATFORM_STR="AMAZON"
			;;
		2)
			PLATFORM_STR="DANUBE"
			;;
		3)
			PLATFORM_STR="AMAZON-SE"
			;;
		4)
			PLATFORM_STR="ARX100"
			;;
		5)
			PLATFORM_STR="VRX200"
			;;
		6)
			PLATFORM_STR="ARX300"
			;;
		7)
			PLATFORM_STR="VRX300"
			;;
		9)
			PLATFORM_STR="VINAX1X (Vinax Revision 1.1 - 1.3)"
			;;
		*)
			PLATFORM_STR="UNKNOWN platform (${PLATFORM})"
			;;
	esac

	case ${RELEASE_STATUS} in
		0)
			RELEASE_STATUS_STR="Release"
			;;
		1)
			RELEASE_STATUS_STR="Pre-Release"
			;;
		2)
			RELEASE_STATUS_STR="Development"
			;;
		*)
			RELEASE_STATUS_STR="UNKONWN release status (${RELEASE_STATUS})"
			;;
	esac
}

function unexport_firmware_features() {
	unset APPLICATION_TYPE_STR
	unset RELEASE_STATUS_STR
	unset PLATFORM_STR

	unset PLATFORM
	unset FEATURE_SET
	unset MAJOR_VERSION
	unset MINOR_VERSION
	unset RELEASE_STATUS
	unset APPLICATION_TYPE

	unset VERSION_STR
}

function print_firmware_features() {
	printf "%s for %s, version: %s" \
		"${APPLICATION_TYPE_STR}" \
		"${PLATFORM_STR}" \
		"${VERSION_STR}"
}

function print_firmware_features_verbose() {
	printf "	PLATFORM: %s\n" "${PLATFORM}"
	printf "	PLATFORM_STR: %s\n" "${PLATFORM_STR}"
	printf "	APPLICATION_TYPE: %s\n" "${APPLICATION_TYPE}"
	printf "	APPLICATION_TYPE_STR: %s\n" "${APPLICATION_TYPE_STR}"
	printf "	VERSION_STR: %s\n" "${VERSION_STR}"
	printf "	RELEASE_STATUS: %s\n" "${RELEASE_STATUS}"
	printf "	RELEASE_STATUS_STR: %s\n" "${RELEASE_STATUS_STR}"
}

function get_sha1sum() {
	sha1sum "${1}" | cut -d' ' -f1
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

find "${FILEPATH}" -type f -print0 | while read -d $'\0' FILE
do
	FILENAME=$(basename "${FILE}")
	VERSION_STRINGS=$(strings "${FILE}" | grep "@(#)")
	IFS=$'\n' read -d '' -r -a VERSIONS <<< "${VERSION_STRINGS//@(#)}"

	case ${#VERSIONS[@]} in
		1)
			read -r -n 4 FILE_HEADER < "${FILE}"

			if [ "${FILE_HEADER//[^ELF]/}" = "ELF" ]
			then
				printf "%s: Driver / tool version %s" \
					"${FILENAME}" \
					"${VERSIONS[0]}"
			else
				parse_firmware_features "${VERSIONS[0]}"

				if [ "${VERBOSE}" -eq "1" ]
				then
					printf "filename: %s\nversion: %s\nsha1sum: %s\n" \
						"${FILENAME}" \
						"${VERSIONS[0]}" \
						"$(get_sha1sum "${FILE}")"
					print_firmware_features_verbose
				else
					printf "%s: " "${FILENAME}"
					print_firmware_features
				fi
			fi

			printf "\n"
			;;
		2)
			parse_firmware_features "${VERSIONS[0]}"

			if [ "${VERBOSE}" -eq "1" ]
			then
				printf "filename: %s\nversion: %s\nsha1sum: %s\n" \
					"${FILENAME}" \
					"${VERSIONS[0]}-${VERSIONS[1]}" \
					"$(get_sha1sum "${FILE}")"
				echo "Firmware1:"
				print_firmware_features_verbose
			else
				printf "%s: " "${FILENAME}"
				print_firmware_features
			fi

			parse_firmware_features "${VERSIONS[1]}"

			if [ "${VERBOSE}" -eq "1" ]
			then
				echo "Firmware2:"
				print_firmware_features_verbose
			else
				printf " | "
				print_firmware_features
			fi

			printf "\n"
			;;
		*)
			if [ "${VERBOSE}" -eq "1" ]
			then
				printf "%s: NO firmware versions found - is this a valid lantiq DSL firmware file?\n" \
					"${FILENAME}"
			fi
			;;
	esac

	unexport_firmware_features
done
