#!/bin/bash

# Corryvreckan analysis with EUDAQ support 
#
# Helper setup script
# Run it the first time with the local 
# installation of https://github.com/duartej/dockerfiles-corryvreckan
# 
# jorge.duarte.campderros@cern.ch (CERN/IFCA)
#
function print_usage
{
    echo
    echo "Creates `docker-compose.yml|docker-compose.override.yml` files"
    echo "with some useful services."
    echo "Mandatory argument:"
    echo " <ANALYSIS_DIR>: the host analysis folder which corresponds"
    echo "                 to the `/data` folder in the container"
    echo "Optional argument:"
    echo " [CORRY_DIR]: the host corryvreckan repository folder"
    echo " If no [CORRY_DIR] is given, the corryvreckan source code "
    echo " will be downloaded at `${HOME}/repos/corryvreckan`"
    echo 
    echo "Usage:"
    echo "source setup.sh <ANALYSIS_DIR> [CORRY_DIR]"
    echo
}

# 0. Check the folder introduced by the user
if [ "X" == "X$1" ];
then 
    echo "Needed the path to the local installation of"
    echo "https://gitlab.cern.ch/corryvreckan/corryvreckan"
    echo "and a local host folder to be used as the analysis"
    print_usage
    return -1
fi

ANADIR=$1

# Get the corry repository (if any)
CORRY_REPO=$2

# 1. Check it is running as regular user
if [ "${EUID}" -eq 0 ];
then
    echo "Do not run this as root"
    return -2
fi

# 2. Check if the setup was run:
if [ -e ".setupdone" ];
then
    echo "DO NOT DOING ANYTHING, THE SETUP WAS ALREADY DONE:"
    echo "=================================================="
    cat .setupdone
    return -3
fi

DOCKERDIR=${PWD}
### 4. Download the code if needed:
if [ "X" == "X${CORRY_REPO}" ];
then
    CORRY_REPO=${HOME}/repos/corryvreckan
    mkdir -p ${CORRY_REPO} && cd ${CORRY_REPO}/.. ;
    if [ "X$(command -v git)" == "X" ];
    then
        echo "You will need to install git (https://git-scm.com/)"
        return -1;
    fi
    if [ ! -d "${CORRY_REPO}" ];
    then
        echo "Cloning CORRY into : $(pwd)"
        git clone https://gitlab.cern.ch/corryvreckan/corryvreckan.git corryvreckan
        echo "[WARNING] Corryvreckan in `master` branch"
    fi
else if [ ! -d ${CORRY_REPO} ];
then
    echo "Directory not found: ${CORRY_REPO}"
    return -5
fi
    

# 3. Fill the place-holders of the .templ-docker-compose.yml 
cd ${DOCKERDIR}
# -- copying relevant files
for dc in .templ-docker-compose.yml .templ-docker-compose.override.yml;
do
    finalf=$(echo ${dc}|sed "s/.templ-//g")
    cp $dc $finalf
    sed -i "s#@CODEDIR_CORRY#${CORRY_REPO}#g" $finalf
    sed -i "s#@ANADIR#${}#g" ${ANADIR}
done

# 4. Create a .setupdone file with some info about the
#    setup
cat << EOF > .setupdone
Corryvreckan (EUDAQ 1) docker image and services
------------------------------------------------
Last setup performed at $(date)
dockerfiles-corryvreckan CONTEX DIR: $(realpath $1)
CORRYVRECKAN LOCAL SOURCE CODE     : ${CORRY_REPO}
ANALYSIS LOCAL fOLDER              : ${ANADIR}
EOF
cat .setupdone

