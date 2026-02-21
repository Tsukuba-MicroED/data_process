#!/bin/bash
# This script is for automated data processing for CRYOARM200 in Tsukuba University.
# This script is developed based on the script developed by Dr. Nakane.
# https://github.com/GKLabIPR/MicroED
#
# Usage:
# $ process_auto.sh <mdoc file> <parent directory for process>
#
# 2024/10/16 YY StartAngle in mdoc file is read and put it as oscillation parameter in import step.
#               Generate diffraction.jpg in the processed directory
# 2025/02/07 YY dials.export and dials.merge were added after dials.scale to output an unmerged and
#               merged mtz files. The logfile of dials.merge is used to get the Wilson B factor.

. /usr/local/xtal/DIALS/dials-latest/dials

SCRIPTDIR=$(dirname $(readlink -f $0))

# Calibrated on 2024/3/14
declare -A CL_TABLE=(
    [250]="264"
    [300]="315"
    [400]="408"
    ["500"]="509"
    ["600"]="609"
    ["800"]="822"
    ["1000"]="1015"
    ["1200"]="1222"
    ["1500"]="1520"
    ["2000"]="2030"
)
declare -A DMIN_TABLE=(
    [250]="0.45"
    [300]="0.50"
    [400]="0.55"
    ["500"]="0.70"
    ["600"]="0.85"
    ["800"]="1.15"
    ["1000"]="1.40"
    ["1200"]="1.65"
    ["1500"]="2.25"
    ["2000"]="3.0"
)


MDOC=`readlink -f $1`
PRODIRBASE=$2

PREFIX=$(basename ${MDOC%.mdoc})
PREFIX=$(basename ${PREFIX%.*})
DATADIR=$(dirname ${MDOC})

if [ "${PRODIRBASE}" = "" ]; then
    PRODIRBASE=`pwd`
fi
PRODIR=${PRODIRBASE}/${PREFIX}
REPORTDIR=`readlink -f ${PRODIRBASE}`

function make_report() {
	cd ${REPORTDIR}
	${SCRIPTDIR}/makehtml.sh . > report.html
	exit
}

if [ -d ${PRODIR} ]; then
    echo "${PREFIX} was already processed."
    exit 1
fi

NIMAGE=$(ls ${DATADIR}/*mrc.gz | wc -l)
N_MID=`echo ${NIMAGE} | awk '{printf("%03d", $1/2)}'`

CAMERA_LENGTH=$(grep CameraLength ${MDOC} | awk '{printf($3)}')
START_ANGLE=$(grep StartAngle ${MDOC} | awk '{printf($3)}')
TILT_WIDTH=$(grep TiltWidth ${MDOC} | awk '{printf($3)}')

DMIN=${DMIN_TABLE[${CAMERA_LENGTH::-1}]}
DMIN_SYMCHECK=$(echo "scale=1; ${DMIN}-0.3" | bc | sed 's/^\./0./')

BEAM_CENTER=$(dials.python ${SCRIPTDIR}/find_beam_center.py ${DATADIR}/${PREFIX}_${N_MID}.mrc.gz)
BEAM_CENTER_XY=${BEAM_CENTER%,*}

MASKSIZE=30
GAIN_FINDSPOTS=0.5
GLOBAL_THRESHOLD=1
DMIN_FINDSPOTS=15
FILTERSLIT=$(grep FilterSlitAndLoss ${MDOC} | awk '{printf($3)}')
if [ "${FILTERSLIT}" = "0" ]; then
    # No filter
    MASKSIZE=50
    GAIN_FINDSPOTS=1
    GLOBAL_THRESHOLD=5
    DMIN_FINDSPOTS=${DMIN}
fi

mkdir -p ${PRODIR}
DATADIR_R=$(realpath --relative-to=${PRODIR} ${DATADIR})
echo ${PRODIR} ${DATADIR} ${DATADIR_R}
cd ${PRODIR}

/usr/local/xtal/ADXV/adxv -sa ${DATADIR}/${PREFIX}_${N_MID}.mrc.gz diffraction.jpg

dials.import template=${DATADIR_R}/${PREFIX}_###.mrc.gz \
    fast_slow_beam_centre=${BEAM_CENTER_XY} \
    pixel_size=0.018,0.018 \
    distance=${CL_TABLE[${CAMERA_LENGTH::-1}]} \
    panel.gain=75 \
    goniometer.axis=0.7933,-0.6088,0 \
    geometry.scan.oscillation=${START_ANGLE::-1},${TILT_WIDTH::-1}

dials.generate_mask imported.expt \
    untrusted.circle=${BEAM_CENTER_XY},${MASKSIZE} \
    output.experiment=imported_masked.expt

dials.find_spots imported_masked.expt \
	global_threshold=${GLOBAL_THRESHOLD} \
	gain=${GAIN_FINDSPOTS} \
	d_min=${DMIN_FINDSPOTS} \
	nproc=4

dials.index imported_masked.expt strong.refl detector.fix=distance || make_report

dials.refine indexed.expt indexed.refl scan_varying=False detector.fix=distance || make_report

dials.refine refined.expt refined.refl scan_varying=True detector.fix=distance || make_report

dials.integrate refined.expt refined.refl nproc=4 prediction.d_min=${DMIN} || make_report

dials.check_indexing_symmetry integrated.{expt,refl} d_min=${DMIN_SYMCHECK} d_max=6 grid=2
dials.symmetry integrated.{expt,refl}
dials.scale integrated.{expt,refl} d_min=${DMIN}
dials.export scaled.{expt,refl}
dials.merge scaled.{expt,refl}


# Filter blank
dials.python ${SCRIPTDIR}/filter_blanks.py integrated.{expt,refl}
dials.check_indexing_symmetry not_blank.{expt,refl} \
    d_min=${DMIN_SYMCHECK} d_max=6 grid=2 \
    output.log=dials.check_indexing_symmetry_not_blank.log

dials.symmetry not_blank.{expt,refl} \
    output.log=dials.symmetry_not_blank.log \
    output.experiments=symmetrized_not_blank.expt \
    output.reflections=symmetrized_not_blank.refl \
    output.html=dials.symmetry_not_blank.html

dials.scale not_blank.{expt,refl} d_min=${DMIN} \
    output.log=dials.scale_not_blank.log \
    output.experiments=scaled_not_blank.expt \
    output.reflections=scaled_not_blank.refl \
    output.html=dials.scale_not_blank.html \
    output.json=dials.scale_not_blank.json

dials.export scaled_not_blank.{expt,refl} \
   output.log=dials.export_not_blank.log \
   output.mtz=scaled_not_blank.mtz \

dials.merge scaled_not_blank.{expt,refl} \
   output.log=dials.merge_not_blank.log \
   output.mtz=merged_not_blank.mtz

# Export for KAMO
mkdir exported
cd exported
dials.export ../integrated.expt ../integrated.refl format=xds_ascii
cd ..

mkdir exported_not_blank
cd exported_not_blank
dials.export ../not_blank.expt ../not_blank.refl format=xds_ascii

cd ../..
${SCRIPTDIR}/list.sh > STATS.txt
${SCRIPTDIR}/list.sh _not_blank > STATS_not_blank.txt
#${SCRIPTDIR}/list.sh | sort -k 2 -r > STATS.txt
#${SCRIPTDIR}/list.sh _not_blank | sort -k 2 -r > STATS_not_blank.txt


make_report
