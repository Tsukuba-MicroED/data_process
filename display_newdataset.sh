#!/bin/bash

MONITOR_DIR=`readlink -f $1`

export XFORMSTATUSFILE=/home/xtal/xtal/ADXV/xf_status
export ADXV_PATTERN="*.mrcs"

adxv -mrc \
    -autoload \
    -wavelength 0.02508 \
    -distance 405 \
    -delay 500 \
    -pixelsize 0.018 \
    -rings \
    ${MRC} &

while :
do
    LATEST_MDOC=`ls -rt ${MONITOR_DIR}/data/*.mdoc | tail -n 1`
    if [ "${LATEST_MDOC}" = "${CURRENT_MDOC}" ]; then
        sleep 1
        continue
    fi

    CURRENT_MDOC=${LATEST_MDOC}
    MRC=${CURRENT_MDOC%.mdoc}

    ID=`basename ${MRC} | cut -d '_' -f 3`
    echo ${ID}

    echo ${ID} ${MRC} > ${XFORMSTATUSFILE}
    while : 
    do
        ls ${MONITOR_DIR}/View*_${ID}.jpg > /dev/null 2>&1 && break
        sleep 1
    done
    eog -w ${MONITOR_DIR}/View*_${ID}.jpg &
    sleep 10
done

