#!/bin/bash
# 
# makehtml.sh - make a simple html page for a directory of dials processing
#

PRODIR=$1
IFSORG=$IFS

if [ "$PRODIR" = "" ]; then
	PRODIR=$(pwd)
else
	PRODIR=$(readlink -f ${PRODIR})
fi

cd ${PRODIR}

echo "<HTML>"
echo "<BODY>"

echo "<h2>Summary of ${PRODIR}</h2>"
echo "<p>ATLAS</p>"
echo "<img src=../../atlas_snap.jpg width=\"480px\"/>"

echo "<table border=\"1\">"
echo "  <tr>"
echo "    <td>ID</td><td>View</td><td>Diffraction</td><td>Find spots</td><td>Index</td><td>Refine</td>"
echo "    <td>Integarte</td><td>Symmetry</td><td>Scale</td><td>Symmetry (filtered)</td><td>Scale (filtered)</td>"
echo "  </tr>"


count=0
for i in `ls -dt */`
do
	DATASETID=${i::-1}
	if [ ! -e ${DATASETID}/dials.index.log ]; then
		continue
	fi

	ITEM_NUM=$(echo ${DATASETID} | cut -f 3 -d "_")
	view_picture=$(ls ../${DATASETID}/View*.jpg)
	diff_picture=$(ls ${DATASETID}/diffraction.jpg)
	
	echo "  <tr>"
	echo "    <td>$DATASETID</td>"
	echo "    <td><img src="$view_picture" width=\"280px\"/></td>"
	echo "    <td><img src="$diff_picture" width=\"280px\"/></td>"

        #Find spots
        txt=`grep -A12 "Histogram" ${DATASETID}/dials.find_spots.log`
        if [[ ${txt} =~ .*--.* ]]; then
            echo "    <td>NG</td>"
        else
            echo "    <td><pre>${txt}</pre></td>"
        fi

        #Indexing
	indexlog=${DATASETID}/dials.index.log
	if [ -e ${DATASETID}/indexed.expt ]; then
		sg=`grep "Space group" ${indexlog} | tail -n 1`
		cell=(`grep "Unit cell" ${indexlog} | tail -n 1`)
		echo "    <td><pre>"
		echo "SG: ${sg:17}"
		echo "Unit_cell: "
		echo "    a   = ${cell[2]::-1}"
		echo "    b   = ${cell[3]::-1}"
		echo "    c   = ${cell[4]::-1}"
		echo "  alpha = ${cell[5]::-1}"
		echo "  beta  = ${cell[6]::-1}"
		echo "  gamma = ${cell[7]}"
		echo "    </pre></td>"
	else
		echo "    <td>NG</td>"
		echo "    <td/><td/><td/><td/><td/><td/>"
		continue
	fi

	#Refine
	if [ -e ${DATASETID}/refined.expt ]; then
		echo "    <td>OK</td>"
	else
		echo "    <td>NG</td>"
		echo "    <td/><td/><td/><td/><td/>"
		continue
	fi

	#Integrate
	if [ -e ${DATASETID}/integrated.expt ]; then
		echo "    <td>OK</td>"
	else
		echo "    <td>NG</td>"
		echo "    <td/><td/><td/><td/>"
		continue
	fi

	#Symmetry
	symmetrylog=${DATASETID}/dials.symmetry.log
	if [ -e ${DATASETID}/symmetrized.expt ]; then
		sg=`grep "Best solution" ${symmetrylog} | tail -n 1`
		cell=(`grep "Unit cell" ${symmetrylog} | tail -n 1`)
		echo "    <td><pre>"
		echo "SG: ${sg:15}"
		echo "Unit_cell: "
		echo "    a   = ${cell[2]::-1}"
		echo "    b   = ${cell[3]::-1}"
		echo "    c   = ${cell[4]::-1}"
		echo "  alpha = ${cell[5]::-1}"
		echo "  beta  = ${cell[6]::-1}"
		echo "  gamma = ${cell[7]}"
		echo "    </pre></td>"
	else
		echo "    <td>NG</td>"
		echo "    <td/><td/><td/>"
		continue
	fi

	#Scaling
	scalelog=${DATASETID}/dials.scale.log
        if [ -e ${DATASETID}/scaled.expt ]; then
		isigma=`grep "^I/sigma" ${scalelog} | sed -e "s/.............................................//"`
		RESO=$(awk '/cc_ano/ {f=1; b=999; next}
				f==1 && $13 > 0.3 {b = $2;}
				f==1 && $13 <= 0.3 {printf b; exit}' ${scalelog})
		IFS=$'\n'
		summary=(`grep -A13 "Summary of merging statistics" ${scalelog}`)
		IFS=$IFSORG
		echo "    <td><pre>"
		echo "Max. reso.: ${RESO}"
		echo ""
		echo "       ${summary[1]:45}"
		echo "Hreso: ${summary[2]:45}"
		echo "Lreso: ${summary[3]:45}"
		echo "Compl: ${summary[4]:45}"
		echo "Multi: ${summary[5]:45}"
		echo "I/sig: ${summary[6]:45}"
		echo "Rmerg: ${summary[7]:45}"
		echo "Rmeas: ${summary[8]:45}"
		echo "Rpim:  ${summary[9]:45}"
		echo "CC1/2: ${summary[10]:45}"
		echo "N obs: ${summary[11]:45}"
		echo "N uni: ${summary[12]:45}</pre>"
		echo "    </td>"
        else
		echo "    <td>NG</td>"
		echo "    <td/><td/>"
		continue
        fi

        #Symmetry
        symmetrylog=${DATASETID}/dials.symmetry_not_blank.log
        if [ -e ${DATASETID}/symmetrized_not_blank.expt ]; then
                sg=`grep "Best solution" ${symmetrylog} | tail -n 1`
                cell=(`grep "Unit cell" ${symmetrylog} | tail -n 1`)
                echo "    <td><pre>"
                echo "SG: ${sg:15}"
                echo "Unit_cell: "
                echo "    a   = ${cell[2]::-1}"
                echo "    b   = ${cell[3]::-1}"
                echo "    c   = ${cell[4]::-1}"
                echo "  alpha = ${cell[5]::-1}"
                echo "  beta  = ${cell[6]::-1}"
                echo "  gamma = ${cell[7]}"
                echo "    </pre></td>"
        else
                echo "    <td>NG</td>"
                echo "    <td/>"
                continue
        fi

        #Scaling
        scalelog=${DATASETID}/dials.scale_not_blank.log
        if [ -e ${DATASETID}/scaled_not_blank.expt ]; then
                isigma=`grep "^I/sigma" ${scalelog} | sed -e "s/.............................................//"`
                RESO=$(awk '/cc_ano/ {f=1; b=999; next}
                                f==1 && $13 > 0.3 {b = $2;}
                                f==1 && $13 <= 0.3 {printf b; exit}' ${scalelog})
                IFS=$'\n'
                summary=(`grep -A13 "Summary of merging statistics" ${scalelog}`)
		IFS=$IFSORG
                echo "    <td><pre>"
                echo "Max. reso.: ${RESO}"
                echo ""
                echo "       ${summary[1]:45}"
                echo "Hreso: ${summary[2]:45}"
                echo "Lreso: ${summary[3]:45}"
                echo "Compl: ${summary[4]:45}"
                echo "Multi: ${summary[5]:45}"
                echo "I/sig: ${summary[6]:45}"
                echo "Rmerg: ${summary[7]:45}"
                echo "Rmeas: ${summary[8]:45}"
                echo "Rpim:  ${summary[9]:45}"
                echo "CC1/2: ${summary[10]:45}"
                echo "N obs: ${summary[11]:45}"
                echo "N uni: ${summary[12]:45}</pre>"
                echo "    </td>"
        else
                echo "    <td>NG</td>"
                continue
        fi

	echo "  </tr>"
	count=$((count+1))
done
echo "</table>"
echo "</BODY>"
echo "</HTML>"


