#!/bin/bash

b="\033[0;32m$(tput bold)"
bs="\033[0;32m"
ce="\033[0;31m$(tput bold)"
e="\033[0m$(tput sgr0)"

all=0
first=1
mode=0
dir=""
prefix=""
enFiles=()
disFiles=()
for arg in "$@"; do
    if (( $first == 1 )); then
        first=0
        dir="${arg}"
        continue
    fi

    if [[ "$arg" == "--enable-all" ]]; then
        if (( $all != 0 )); then
            echo -e "${ce}Error: Invalid mode selected: ${arg}${e}"
            exit 1
        fi
        all=1
    elif [[ "$arg" == "--disable-all" ]]; then
        if (( $all != 0 )); then
            echo -e "${ce}Error: Invalid mode selected: ${arg}${e}"
            exit 1
        fi
        all=2
    elif [[ "$arg" == "--enable="* ]]; then
        if (( $all == 0 )); then
            all=3
        fi
        enFiles+=("${prefix}"$(echo "${arg:9}" | sed "s/,/ ${prefix}/g"))
    elif [[ "$arg" == "--disable="* ]]; then
        if (( $all == 0 )); then
            all=3
        fi
        disFiles+=("${prefix}"$(echo "${arg:10}" | sed "s/,/ ${prefix}/g"))
    elif [[ "$arg" == "--pre="* ]]; then
        prefix="${arg:6}"
    elif [[ "$arg" == "--help" ]]; then
        echo "USAGE: ./$(basename $0) [dir] [OPTIONS]"
        echo ""
        echo "[DIR]: The plan directory to apply the changes to."
        echo "[OPTIONS]:"
        echo "  --help              Displays this help and exists afterwards."
        echo "  --enable-all        Enables all plans. Must be used before '--enable' or '--disable'."
        echo "  --disable-all       Disable all plans. Must be used before '--enable' or '--disable'."
        echo "  --enable=<P1>,...   Enables the plans 'P1.plan.ipr', etc."
        echo "  --disable=<P1>,...  Disable the plans 'P1.plan.ipr', etc."
        echo "  --pre=<V>           Prefix used for all files denoted by '--enable' or '--disable'."
        echo "                      Can be set multiple times, and only works for arguments afterwards."
        exit 0
    else
        echo -e "${ce}Unknown argument: '${arg}'${e}"
        echo "Use '--help' for more info."
        exit 1
    fi
done

if (( first == 1 )); then
    echo -e "${ce}Error: No directory provided!${e}"
    exit 1
fi

enable_file () {
    oldName=$1
    newName=$1
    while [[ ${newName::1} == "_" ]]; do
        newName=${newName:1}
    done
    echo "Enabled ${newName}"
    mv "${dir}/${oldName}" "${dir}/${newName}"
}

disable_file () {
    name=$1
    if [[ ${name::1} != "_" ]]; then
        echo "Disabled ${name}"
        mv "${dir}/${name}" "${dir}/_${name}"
    fi
}

if (( $all == 1 )); then
    # Enable all files.
    for p in ${dir}/_*.plan.ipr; do
        if ! [ -f "${p}" ]; then
            continue
        fi
        name=$(basename "${p}")
        enable_file "${name}"
    done
elif (( $all == 2 )); then
    # Disable all files.
    for p in ${dir}/[^_]*.plan.ipr; do
        if ! [ -f "${p}" ]; then
            continue
        fi
        name=$(basename "${p}")
        disable_file "${name}"
    done
elif (( $all != 3 )); then
    echo -e "${ce}Error: no mode selected!${e}"
    exit 1
fi

# Enable the required files.
for n in ${enFiles[@]}; do
    p="${dir}/_${n}.plan.ipr"
    if ! [ -f "${p}" ]; then
        continue
    fi
    name=$(basename "${p}")
    enable_file "${name}"
done

# Disable the required files.
for n in ${disFiles[@]}; do
    p="${dir}/${n}.plan.ipr"
    if ! [ -f "${p}" ]; then
        continue
    fi
    name=$(basename "${p}")
    disable_file "${name}"
done
