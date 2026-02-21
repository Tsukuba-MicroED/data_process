#!/bin/bash

echo Entered in mrcs2mrc.sh

. /usr/local/xtal/DIALS/dials-latest/dials

SCRIPTDIR=$(dirname $(readlink -f $0))
MDOC=$(readlink -f $1)
STACKFILE=${MDOC%.mdoc}
FILENAME=$(basename ${STACKFILE})
PREFIX=${FILENAME%.*}
MRCFILE=/dev/shm/${PREFIX}.mrcs

TARGETDIR=$2
if [ "${TARGETDIR}" = "" ]; then
	TARGETBASEDIR=.
	TARGETDIR=${TARGETBASEDIR}/${PREFIX}
else
	TARGETDIR=$(readlink -f $2)
	TARGETBASEDIR=$(dirname ${TARGETDIR})
fi

if [ -d ${TARGETDIR} ]; then
	echo ${FILENAME} is already transfered.
	exit 1
fi

if [ "${STACKFILE#*.}" = "tif" ]; then
	tif2mrc ${STACKFILE} ${MRCFILE}
else
	cp ${STACKFILE} ${MRCFILE}
fi

mkdir ${TARGETDIR}
echo ${TARGETDIR} has been created.

cd ${TARGETDIR}
/usr/bin/time -p dials.python ${SCRIPTDIR}/mrcs2mrc.py ${MRCFILE}
cp ${MDOC} .
rm ${MRCFILE}

cd ..
${SCRIPTDIR}/process_auto.sh ${PREFIX}/${PREFIX}.mrcs.mdoc P1_auto &

