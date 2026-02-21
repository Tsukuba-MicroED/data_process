#!/bin/bash
#
# monitor_dataset.sh
#

NPROC=2

MONITOR_DIR=/nfs/microED/proc_trigger

SCRIPTDIR=$(dirname $(readlink -f $0))

while :
do
	for i in ${MONITOR_DIR}/*.txt
	do
		if [ ${i} = "${MONITOR_DIR}/*.txt" ]; then
			#echo "no file"
			break
		fi
		# \\192.168.1.10\cryoarm200\microED\231217_102500\data\231217_114500_282_001.mrcs
		LINE1=$(sed -n 1p ${i} | sed 's/\\/\//g')
		LINE1=${LINE1::-1}
		MRC=${LINE1/\/192\.168\.1\.10\/cryoarm200/nfs}
		MDOC=${MRC}.mdoc
		FILENAME=$(basename ${MRC})
		PREFIX=${FILENAME%.*}
		LINE2=$(sed -n 2p ${i} | sed 's/\\/\//g')
		LINE2=${LINE2::-1}
		VIEWIMAGE=${LINE2/\/192\.168\.1\.10\/cryoarm200/nfs}

		PRODIR=$(dirname ${MDOC})/../process
		if [ ! -d ${PRODIR} ]; then
			mkdir -p ${PRODIR}
		fi
		cd ${PRODIR}

		echo ${SCRIPTDIR}/mrcs2mrc.sh ${MDOC}
		${SCRIPTDIR}/stack2mrc.sh ${MDOC}
		if [ $? == 0 ]; then
			cp ${VIEWIMAGE} ${PREFIX}
			mv ${i} ${MONITOR_DIR}/processed
			echo "Processing of ${i} has been completed."
			echo "${i} has been moved to the directory processed."
		else
			mv ${i} ${MONITOR_DIR}/unprocessed
			echo "Error during processing ${i}"
			echo "${i} has been moved to the directory unprocessed." 
		fi
	done
	sleep 10
done

