#!/bin/bash

set -eu
set -o pipefail

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ..

. scripts/import-vars.sh
. avg/vars.sh

cd avg

b="\033[0;32m$(tput bold)"
bs="\033[0;32m"
ce="\033[0;31m$(tput bold)"
e="\033[0m$(tput sgr0)"
user=$([ "${USER}" == "root" ] &&  echo "${SUDO_USER}" || echo "${USER}")

agdir="${AVANTGRAPH_DIR}/avantgraph"
builddir="${agdir}/cmake-build-performance"
gitUrl=ssh://git@git.avantgraph.io/ag/avantgraph.git
agBranch=kaj/answergraph

if ((! ${#@})); then
    echo "This repo is currently private! If you are not authorized, you cannot clone and build it. Attempting to build it will remove the binaries present in '${AVANTGRAPH_BINARIES}'."
    echo "Provide any argument to prevent this message."
    echo "Continue? [y/N]"

    res=""
    cntr=20
    while [ -z "${res}" ] && ((${cntr})); do
        echo -ne $(((cntr--)))
        read -n1 -t1 res || true
        echo -ne "\r\033[0K"
    done
    echo "${res}"

    if [ -z "${res}" ]; then
        echo -e "${ce}Error: Timeout!${e}"
        exit 2
    elif ! [[ "${res}" == "y" || "${res}" == "Y" ]]; then
        echo -e "${ce}Error: User abort!${e}"
        exit 1
    fi
fi

curStep=0
maxStep=6

print_header () {
    echo -e "\n${b}["$(((++curStep)))"/${maxStep}] $1${e}"
}

print_header "Installing dependencies"
sudo ./install-dependencies.sh

print_header "Clearing old data"
sudo rm -rdf ${AVANTGRAPH_BINARIES} > /dev/null 2>&1
if [ -d ${agdir} ] && [ $(ls ${agdir} | wc -l) != "0" ]; then
    echo -e "Reuse previous build? [Y/n]"
    res=""
    cntr=5
    while [ -z "${res}" ] && ((${cntr})); do
        echo -ne $(((cntr--)))
        read -n1 -t1 res || true
        echo -ne "\r\033[0K"
    done
    echo "${res}"

    rebuild=$(! [[ "${res}" == "y" || "${res}" == "Y" ]] && echo "1" || echo "0")
    if ((${rebuild})); then
        rm -rdf ${agdir} > /dev/null 2>&1
    else
        cd "${agdir}"
        sudo -u "${user}" git fetch
        sudo -u "${user}" git reset --hard origin/${agBranch}
    fi
else
    rebuild=1
fi
sudo -u "${user}" mkdir -p ${AVANTGRAPH_DIR} ${AVANTGRAPH_BINARIES} ${agdir}
cd "${agdir}"

print_header "Cloning AvantGraph benchmark repo"
if ((${rebuild})); then
    sudo -u "${user}" git clone "${gitUrl}" "${agdir}"
else
    echo "AvantGraph already cloned, skipping step."
fi

print_header "Installing AvantGraph graph load tools"
sudo -u "${user}" mkdir -p "${AVANTGRAPH_BINARIES}/contrib"
sudo -u "${user}" cp "${agdir}/contrib/import_csv.py" "${AVANTGRAPH_BINARIES}/contrib/import_csv.py"

print_header "Building AvantGraph benchmark"
git checkout "${agBranch}"
sudo -u "${user}" cmake -DCMAKE_BUILD_TYPE=Release -S "${agdir}" -B "${builddir}"
sudo -u "${user}" cmake --build "${builddir}" --target avantgraph ag-load-graph ag-index ag-plan ag-exec-multi-threaded -- -j $(nproc)

print_header "Installing AvantGraph benchmark"
sudo -u "${user}" cp "${builddir}/src/tools/load-graph/ag-load-graph" "${AVANTGRAPH_BINARIES}/ag-load-graph"
sudo -u "${user}" cp "${builddir}/src/tools/index/ag-index" "${AVANTGRAPH_BINARIES}/ag-index"
sudo -u "${user}" cp "${builddir}/src/tools/plan/ag-plan" "${AVANTGRAPH_BINARIES}/ag-plan"
sudo -u "${user}" cp "${builddir}/src/tools/execMultiTreaded/ag-exec-multi-threaded" "${AVANTGRAPH_BINARIES}/ag-exec-multi-threaded"

# TMP
sudo -u "${user}" mkdir -p "${AVANTGRAPH_BINARIES}/no-pushdown"
sudo -u "${user}" cp "${builddir}/src/tools/plan/ag-plan" "${AVANTGRAPH_BINARIES}/no-pushdown/ag-plan"
sudo -u "${user}" cp "${builddir}/src/tools/execMultiTreaded/ag-exec-multi-threaded" "${AVANTGRAPH_BINARIES}/no-pushdown/ag-exec-multi-threaded"

exit 0

print_header "Checking out AvantGraph benchmark-no-pushdown"
sudo -u "${user}" git checkout kaj/benchmark-no-pushdown

print_header "Building AvantGraph benchmark-no-pushdown"
sudo -u "${user}" cmake -DCMAKE_BUILD_TYPE=Release -S "${agdir}" -B "${builddir}"
sudo -u "${user}" cmake --build "${builddir}" --target avantgraph ag-load-graph ag-index ag-plan ag-exec-multi-threaded -- -j $(nproc)

print_header "Installing AvantGraph benchmark-no-pushdown"
sudo -u "${user}" mkdir -p "${AVANTGRAPH_BINARIES}/no-pushdown"
sudo -u "${user}" cp "${builddir}/src/tools/plan/ag-plan" "${AVANTGRAPH_BINARIES}/no-pushdown/ag-plan"
sudo -u "${user}" cp "${builddir}/src/tools/execMultiTreaded/ag-exec-multi-threaded" "${AVANTGRAPH_BINARIES}/no-pushdown/ag-exec-multi-threaded"
