#!/bin/bash
set -o posix -o errexit

# from here
# https://askubuntu.com/questions/509795/how-to-write-a-portable-shell-script-with-error-handl
#set MARKDOWN_BLOCK_RUNNING to true colour
readonly local COLOUR_DEFAULT='\033[0;m'
readonly local COLOUR_RED='\033[0;31m'
readonly local COLOUR_GREEN='\033[0;32m'
readonly local COLOUR_YELLOW='\033[0;33m'

# verbosity level
SILENT=0
CRITICAL=1
ERROR=2
WARN=3
NOTICE=4
INFO=5
DEBUG=6

LOGLEVEL=${SILENT}

silent() {
    log ${SILENT} "$COLOUR_YELLOW silent $* ${COLOUR_DEFAULT} \n"
}

critical() {
    log ${CRITICAL} "$COLOUR_YELLOW critical $* ${COLOUR_DEFAULT} \n"
}

error() {
    log ${ERROR} "$COLOUR_RED error ( line: ${BASH_LINENO[*]}) - $* ${COLOUR_DEFAULT} \n"
}

warn() {
    log ${WARN} "$COLOUR_RED warn -- $* ${COLOUR_DEFAULT} \n"
}

notice() {
    log ${NOTICE} "$COLOUR_GREEN notice $* ${COLOUR_DEFAULT} \n"
}

info() {
    log ${INFO} "${COLOUR_DEFAULT} info $* ${COLOUR_DEFAULT} \n"
}

debug() {
    log ${DEBUG} "$COLOUR_YELLOW debug ( line: ${BASH_LINENO[*]}) $* ${COLOUR_DEFAULT} \n"
}

log() {
    if [[ "${LOGLEVEL}" -ge "${1}" ]]; then
        shift
        datestring=$(date +"%Y-%m-%d %H:%M:%S")
        # %b for show color
        printf "%b\n" "$datestring - $*"
    fi
}

# log end

########################################################
# custom script
########################################################

usage() {

    LOGLEVEL=${SILENT}
    printf "usage:\n"
    printf "%s [-d -f -o] -i <file> \n" "${0##*/}"
    printf "%s [--debug --force --output] --input <file> \n" "${0##*/}"
    printf "\t-f | --force overwrite output\n"
    printf "\t-i | --input set markdown file to parse\n"
    printf "\t-o | --output set output file\n"
    printf "\t-v | --verbose [debug,info,notice,warn,error,silent] set debug level\n"
}

# global variable for this script ##################

# flag set with options
GLOBAL_OVERRIDE_ALL_MERMAID_FILE=false

# output folder for generated output
OUTPUT_FOLDER="output"

# sub folder for mermind files
MERMAID_FOLDER="mermind"

# sub folder for images files
IMAGES_FOLDER="images"

# image format for mermaid
MERMAID_OUTPUT_FORMAT="png"

# output file default
MERMAID_OUTPUT_FILE=""

# array for hold all filename for detect double name
declare -a MERMAID_FILENAME=()

# spilt -abc to -a -b -c
# from here
# https://gist.github.com/Decstasy/19814b80a3551b34d78e8be7f3b5e8d8

if (($# < 1)); then
    error "no input option"
    usage
    exit 1
fi

debug "parameter =>$*"

ARGS=()
# split -abc to -a -b -c
for i in "$@"; do
    if [[ "${i:0:1}" == "-" && "${i:1:1}" != "-" ]]; then
        for ((j = 1; j < ${#i}; j++)); do
            ARGS+=("-${i:$j:1}")
        done
    else
        ARGS+=("$i")
    fi
done

debug " count arguments => ${#ARGS[@]} \n"

for ((i = 0; i <= ${#ARGS[@]}; i++)); do
    debug "parse ${ARGS[i]}"
    case "${ARGS[i]}" in
    '') # Skip if element is empty (happens when it's un set before)
        continue
        ;;
    -i | --input) # Use +1 to access next array element and unset it
        debug "option --input trigger"
        MERMAID_INPUT_FILE="${ARGS[i + 1]}"
        debug "MERMAID_INPUT_FILE length=> ${#MERMAID_INPUT_FILE}"
        if [ "${#MERMAID_INPUT_FILE}" -eq 0 ]; then
            error "Input file missing ${MERMAID_INPUT_FILE}"
            printf "Input file missing %s \n" "${MERMAID_INPUT_FILE}"
            exit 1
        fi
        # unset 'ARGS[i]';
        i=$((i + 1))
        continue
        ;;
    -o | --output) # Use +1 to access next array element and unset it
        debug "option --output trigger"
        MERMAID_OUTPUT_FILE="${ARGS[i + 1]}"
        debug "MERMAID_OUTPUT_FILE ${MERMAID_OUTPUT_FILE}"
        debug "MERMAID_OUTPUT_FILE length=> ${#MERMAID_OUTPUT_FILE}"
        if [ "${#MERMAID_OUTPUT_FILE}" -eq 0 ]; then
            error "Output file not available ${MERMAID_OUTPUT_FILE}"
            printf "ERROR: Output file is missing!\n"
            exit 1
        fi
        # unset 'ARGS[i]';
        i=$((i + 1))
        continue
        ;;
    -f | --force) # Parameter without argument
        debug "option --force trigger"
        GLOBAL_OVERRIDE_ALL_MERMAID_FILE=true
        # unset 'ARGS[i]'
        continue
        ;;
    -v | --verbose) # Parameter without argument
        debug "option --debug trigger"
        LOGLEVEL=${DEBUG}
        unset 'ARGS[i]'
        continue
        ;;
    --) # End of arguments
        unset 'ARGS[i]'
        break
        ;;
    *) # Skip unset if our argument has not been matched
        debug "option ${ARGS[i]} NOT FOUND"
        printf "option %s NOT FOUND\n" "${ARGS[i]}"
        usage
        exit 1
        continue
        ;;
    esac
    # TODO check is necessary
    # unset 'ARGS[i]'
done

if [[ "${LOGLEVEL}" -ge "${DEBUG}" ]]; then

    debug "debug"
    info "info"
    notice "notice"
    warn "warn"
    critical "critical"
    error "error"
    silent "silent"
fi

debug "Parameter:"
if [[ "${LOGLEVEL}" -ge "${DEBUG}" ]]; then
    for i in "${ARGS[@]}"; do
        # debug "ARGS[$i] => ${ARGS[$i]}"
        debug "ARGS => >$i<"
    done

    for ((i = 0; i < ${#ARGS[@]}; i++)); do
        debug "ARGS $i => >${ARGS[i]}<"

        debug "ARGS $i + 1=> >${ARGS[$((i + 1))]}<"
    done
fi

info "Log is ON !!!"

debug "input file ${MERMAID_INPUT_FILE}"

if [ ! -f "${MERMAID_INPUT_FILE}" ]; then
    error "Input file not available ${MERMAID_INPUT_FILE}"
    printf "ERROR: Input file not available %s\n" "${MERMAID_INPUT_FILE}"
    exit 1
fi

debug "set MERMAID_OUTPUT_FILE"

debug "set name of MERMAID_OUTPUT_FILE"

if [ "${#MERMAID_OUTPUT_FILE}" -eq 0 ]; then
    debug "NOT ENTER OUTPUT FILE"
    MERMAID_OUTPUT_FILE=${MERMAID_INPUT_FILE}
    MERMAID_OUTPUT_FILE=${MERMAID_OUTPUT_FILE/md/mermaid_replace.md}
else

    # TODO old
    # debug " extract filename from path ${MERMAID_OUTPUT_FILE}"

    # MERMAID_OUTPUT_FILE=$(echo "${MERMAID_OUTPUT_FILE}"| sed "s/.*\///");

    # debug "MERMAID_OUTPUT_FILE => ${MERMAID_OUTPUT_FILE}";

    debug "check filename ${MERMAID_OUTPUT_FILE} end with md"
    if [[ "${MERMAID_OUTPUT_FILE}" =~ ^.*md$ ]]; then

        debug "file name has ending"
    else
        debug "add .md to filename"
        MERMAID_OUTPUT_FILE+=".mermaid_replace.md"
        debug "set output file name => ${MERMAID_OUTPUT_FILE}"
    fi
fi

debug "MERMAID_OUTPUT_FILE => ${MERMAID_OUTPUT_FILE}"

#####################

# function for script ###################

check_mermaid_filename() {
    debug "${FUNCNAME[0]}:+${FUNCNAME[0]}(): start"
    local return_value=1

    if [[ "${MERMAID_FILENAME[*]}" =~ $1 ]]; then
        error "flowchart name  $1 contain in array, please used uniq filename"
        return_value=1
        # TODO move error exit outsite the function
        # TODO no exit inside function
        exit 1
    else
        notice "flowchart name $1 was not used before - OK"
        return_value=0
    fi

    debug "${FUNCNAME[0]}:+${FUNCNAME[0]}(): end with return_value ${return_value}"
    return ${return_value}
}

push_mermaid_filename() {

    debug "${FUNCNAME[0]}:+${FUNCNAME[0]}(): start"

    debug "add mermaid filename $1 to array MERMAID_FILENAME"

    MERMAID_FILENAME=("${MERMAID_FILENAME[@]}" "$1")

    debug "${FUNCNAME[0]}:+${FUNCNAME[0]}(): end"
}

check_file_is_exists_add_should_replace() {
    debug "${FUNCNAME[0]}:+${FUNCNAME[0]}(): start"
    local return_value=1

    if [ -e "$1" ]; then

        debug "file $1 exists"

        if [ "${GLOBAL_OVERRIDE_ALL_MERMAID_FILE}" = true ]; then

            debug "delete file $1"
            debug "GLOBAL_OVERRIDE_ALL_MERMAID_FILE is set to ${GLOBAL_OVERRIDE_ALL_MERMAID_FILE}"

            rm -rf "$1"
            return_value=$?
        fi
    else
        debug "file $1 not exits"
        return_value=0
    fi

    debug "${FUNCNAME[0]}:+${FUNCNAME[0]}(): end with return_value ${return_value}"
    return $return_value
}

convert_file_to_image_and_add_output_file() {

    # TODO check mermaid is installed

    local _MERMAID_COMMAND="./node_modules/.bin/mmdc"
    local _MERMAID_PROPERTIES_FLAG="--puppeteerConfigFile"
    local _MERMAID_PROPERTIES_FILE="puppeteer-config.json"
    local _MERMAID_INPUT_FLAG="--input"
    local _MERMAID_OUTPUT_FLAG="--output"
    local _MERMAID_INPUT_FILE="$1"

    debug "check graph tag is only once in file"

    if [ "$(grep -c graph <"${_MERMAID_INPUT_FILE}")" -eq 1 ]; then
        debug " Ok one graph tag in file"
    else

        error " ERROR: file with two and more graph tag in file"
        printf " ERROR: file with two and more graph tag in file => %s\n" "${_MERMAID_INPUT_FILE}"
        exit 1
    fi

    # take input filename as output filename
    local _MERMAID_OUTPUT_FILE="$2"
    # append filetype
    local _MERMAID_OUTPUT_FILE+=".${MERMAID_OUTPUT_FORMAT}"

    debug "Command: ${_MERMAID_COMMAND} ${_MERMAID_PROPERTIES_FLAG} ${_MERMAID_PROPERTIES_FILE} ${_MERMAID_INPUT_FLAG} ${_MERMAID_INPUT_FILE} ${_MERMAID_OUTPUT_FLAG} ${_MERMAID_OUTPUT_FILE}"

    debug " add line link"
    # "${_MERMAID_COMMAND}" "${_MERMAID_PROPERTIES_FLAG}" "${_MERMAID_PROPERTIES_FILE}" "${_MERMAID_INPUT_FLAG}" "${_MERMAID_INPUT_FILE}" "${_MERMAID_OUTPUT_FLAG}" "${_MERMAID_OUTPUT_FILE}")

    local _rt="$(${_MERMAID_COMMAND} ${_MERMAID_PROPERTIES_FLAG} ${_MERMAID_PROPERTIES_FILE} ${_MERMAID_INPUT_FLAG} ${_MERMAID_INPUT_FILE} ${_MERMAID_OUTPUT_FLAG} ${_MERMAID_OUTPUT_FILE})"

    return $?
}

###################

# TODO check is mermaid install

if [ "${GLOBAL_OVERRIDE_ALL_MERMAID_FILE}" = true ]; then

    if [ -e ${OUTPUT_FOLDER} ]; then
        debug "delete $OUTPUT_FOLDER"
        rm -rf ${OUTPUT_FOLDER}
    else
        debug "output folder ${OUTPUT_FOLDER} not exists"

    fi
fi

if ! check_file_is_exists_add_should_replace "${OUTPUT_FOLDER}/${MERMAID_OUTPUT_FILE}"; then

    debug "GLOBAL_OVERRIDE_ALL_MERMAID_FILE => ${GLOBAL_OVERRIDE_ALL_MERMAID_FILE}"
    error "file exists !! Delete by hand or add -f or --force to your command line for overwrite the files"
    printf "ERROR: file exists %s !! Delete by hand or add -f or --force to your command line for overwrite the files" "${OUTPUT_FOLDER}/${MERMAID_OUTPUT_FILE}"
    exit 1
fi

debug "check output folder is exists"
if [ -e "${OUTPUT_FOLDER}" ]; then

    debug "output folder exists"
else
    debug "folder NOT exists, make output folder"
    mkdir "${OUTPUT_FOLDER}"
    mkdir -p "${OUTPUT_FOLDER}/${IMAGES_FOLDER}"
    mkdir -p "${OUTPUT_FOLDER}/${MERMAID_FOLDER}"

    if [[ ${MERMAID_OUTPUT_FILE} == *"/"* ]]; then
        debug "MERMAID_OUTPUT_FILE ${MERMAID_OUTPUT_FILE} is path"
        debug " determine filename "
        MERMAID_OUTPUT_FILE_NAME=$(echo "${MERMAID_OUTPUT_FILE}" | sed "s/.*\///")
        MERMAID_OUTPUT_FILE_FOLDER=$(echo "${MERMAID_OUTPUT_FILE}" | sed -r "s/(.+)\/.+/\1/")

        debug "Folder => ${MERMAID_OUTPUT_FILE_FOLDER}"
        debug "Name => ${MERMAID_OUTPUT_FILE_NAME}"

        debug " create output folder for custom output file"
        debug "create path => mkdir --parents ${PWD}/${OUTPUT_FOLDER}/${MERMAID_OUTPUT_FILE_FOLDER}"
        mkdir --parents "${PWD}/${OUTPUT_FOLDER}/${MERMAID_OUTPUT_FILE_FOLDER}"
        debug "create file touch ${PWD}/${OUTPUT_FOLDER}/${MERMAID_OUTPUT_FILE_FOLDER}/${MERMAID_OUTPUT_FILE_NAME}"
        touch "${PWD}/${OUTPUT_FOLDER}/${MERMAID_OUTPUT_FILE_FOLDER}/${MERMAID_OUTPUT_FILE_NAME}"

    else
        debug "MERMAID_OUTPUT_FILE ${MERMAID_OUTPUT_FILE} is only filename"
    fi

fi

# flag in or out blog
MARKDOWN_BLOCK_RUNNING=false

# flag for process mermaid
MERMAID_BLOCK_RUNNING=false

# line counter for display in errors message
LINE_COUNTER=0

# FIXME no loop without read
# loop
while read -r line || [[ $line ]]; do

    # debug "Next line=> $line"
    if [[ $line =~ ^\`\`\`.*$ ]]; then

        debug "source block found in line ${LINE_COUNTER} "

        # block close
        if [[ $line =~ ^\`\`\`$ ]]; then

            notice "End of script block found in line ${LINE_COUNTER}"
            debug "End of script block found in line ${LINE_COUNTER}"

            if [ ${MARKDOWN_BLOCK_RUNNING} = false ]; then

                # error
                error "block error without flavor"
                error "Hint: each markdown block must have a flavor for this script :-("

                # TODO set github link here
                error "block without start"
                printf "ERROR: source block has nor flavor line =>%i\n" "${LINE_COUNTER}"
                exit 1

            elif [ ${MERMAID_BLOCK_RUNNING} = true ]; then

                notice "source block with mermaid flavor end"
                debug "source block with mermaid flavor end"

                debug "set MERMAID_BLOCK_RUNNING to false"
                MERMAID_BLOCK_RUNNING=false

                debug "convert block to image"

                debug "get last filename"

                # FIXME No local variable needed
                # TODO old mermaid_filename=${MERMAID_FILENAME[${#MERMAID_FILENAME[@]} - 1]}

                debug "filename ${mermaid_filename}"

                debug "output folder ${OUTPUT_FOLDER}"

                if ! convert_file_to_image_and_add_output_file "${OUTPUT_FOLDER}/${MERMAID_FOLDER}/${mermaid_filename}" "${OUTPUT_FOLDER}/${IMAGES_FOLDER}/${mermaid_filename}"; then
                    exit 1
                fi

                debug " add file link to target mermaid file ./${IMAGES_FOLDER}/${mermaid_filename}"
                printf "![Alt %s](./%s)\n" "${mermaid_filename}" "${IMAGES_FOLDER}/${mermaid_filename}.${MERMAID_OUTPUT_FORMAT}" >>"${OUTPUT_FOLDER}/${MERMAID_OUTPUT_FILE}"

                debug "output folder ${OUTPUT_FOLDER}"

            else

                debug "set flag  MARKDOWN_BLOCK_RUNNING to false"
                MARKDOWN_BLOCK_RUNNING=false

                # FIXME only for security
                debug "set flag MERMAID_BLOCK_RUNNING to false"
                MERMAID_BLOCK_RUNNING=false

                debug " write source block CLOSE to file => ${OUTPUT_FOLDER}/${mermaid_filename}"
                printf "%s\n" "${line}" >>"${OUTPUT_FOLDER}/${MERMAID_OUTPUT_FILE}"

            fi

        else
            notice "source block START found line ${LINE_COUNTER}"
            debug "set MARKDOWN_BLOCK_RUNNING to TRUE"
            MARKDOWN_BLOCK_RUNNING=true

            if [[ ${line} =~ ^\`\`\`mermaid.*$ ]]; then
                debug "mermaid block START found line ${LINE_COUNTER}"

                debug "check mermind process start already"
                if [ ${MERMAID_BLOCK_RUNNING} = true ]; then
                    error "error source block with flavor mermaid already start line ${LINE_COUNTER}"
                    error "please check your input file ${MERMAID_INPUT_FILE}"
                    exit 1
                else

                    debug "parse mermaid argument to array ${line}"
                    read -r -a mermaid_argument <<<"$line"
                    debug "mermaid arguments ${mermaid_argument[*]}"

                    debug " n arguments ${#mermaid_argument[*]}"

                    if [[ ${#mermaid_argument[*]} -ge 2 ]]; then

                        debug "determine to the filename"

                        mermaid_filename=${mermaid_argument[1]}

                        debug "the filename is ${mermaid_filename}"

                        debug "check the mermaid_filename is NOT double used file:${mermaid_filename}"

                        # if check_mermaid_filename "${mermaid_filename}"; then
                        if [ -e "${OUTPUT_FOLDER}/${MERMAID_FOLDER}/${mermaid_filename}" ]; then

                            error "CASE: double filename"
                            error " Action: Please check your block mermaid flavor"
                            error " Hint: only uniq filename allow"
                            printf "ERROR: flowchart name %s already in used \n" "${OUTPUT_FOLDER}/${MERMAID_FOLDER}/${mermaid_filename}"
                            exit 1

                        else

                            # TODO wrong  push_mermaid_filename "${mermaid_filename}"
                            debug "used mermaid output file => ${OUTPUT_FOLDER}/${MERMAID_FOLDER}/${mermaid_filename}"

                        fi

                        # debug "check_file_is_exists_add_should_replace ${OUTPUT_FOLDER}/${MERMAID_FOLDER}/${mermaid_filename}"

                        # if ! check_file_is_exists_add_should_replace "${OUTPUT_FOLDER}/${mermaid_filename}"; then

                        #     debug "File ${OUTPUT_FOLDER}/${mermaid_filename} exists"
                        #     error "File ${OUTPUT_FOLDER}/${mermaid_filename} exists"
                        #     printf "File %s/%s exists" "${OUTPUT_FOLDER}" "${mermaid_filename}"
                        #     exit 1

                        # fi

                        # TODO add resolution flag

                        debug "set MERMAID_BLOCK_RUNNING=true"
                        MERMAID_BLOCK_RUNNING=true

                    else

                        error "please enter the filename after the mermaid block tag"
                        printf "ERROR: Please enter the filename after the mermaid block tag line %s file %i\n" "${LINE_COUNTER}" "${MERMAID_INPUT_FILE}"
                        exit 1
                    fi

                fi

            else
                debug " write source block START to file => ${OUTPUT_FOLDER}/${MERMAID_OUTPUT_FILE}"
                printf "%s\n" "${line}"  >>"${OUTPUT_FOLDER}/${MERMAID_OUTPUT_FILE}";

            fi

        fi

    elif

        [ ${MERMAID_BLOCK_RUNNING} = true ]
    then

        # TODO check folder for mermaid files

        debug "write mermaid source block to file: ${OUTPUT_FOLDER}/${MERMAID_FOLDER}/${mermaid_filename}"

        # OLD  mermaid_filename=${MERMAID_FILENAME[${#MERMAID_FILENAME[@]} - 1]}

        debug "mermaid_filename => ${OUTPUT_FOLDER}/${MERMAID_FOLDER}/${mermaid_filename}"
        debug "add line ${line} to file ${OUTPUT_FOLDER}/${MERMAID_FOLDER}/${mermaid_filename}"
        printf "%s\n" "${line}" >>"${OUTPUT_FOLDER}/${MERMAID_FOLDER}/${mermaid_filename}"

    else

        debug "normal line (${LINE_COUNTER}) ${line} write to file ${OUTPUT_FOLDER}/${MERMAID_OUTPUT_FILE}"
        printf "%s\n" "${line}" >>"${OUTPUT_FOLDER}/${MERMAID_OUTPUT_FILE}"

    fi

    # increase counter
    LINE_COUNTER=$((LINE_COUNTER + 1))
done <"${MERMAID_INPUT_FILE}"

printf "generated output to =>  %s/%s\n" "${OUTPUT_FOLDER}" "${MERMAID_OUTPUT_FILE}"
printf "successful finished\n"
info "successful finished"
debug "successful finished"
exit 0
