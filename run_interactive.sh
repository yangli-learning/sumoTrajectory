#!/bin/bash
######################################################
#                   configuration                    #
######################################################

# path to fcd2pbf binary 
FCD2PBF=../fcd2pbf/build/src/exec/fcd2pbf

# optional: convert trajectories to txt format
#PROCESSPBF=../processpbf/build/src/exec/processpbf
PROCESSPBF=0
DISP_ROUTES=1
######################################################


create_rand_trips()
{
    echo
    read -p "Do you want to generate random trips [Y/n]?" genRand
    genRand=${genRand:-y}
    case $genRand in
	n|N)
	    echo "skipping.."
	    return 1
	    ;;
	y|Y)
	    echo "Creating random trips ..."
	    tag="${fname}_rand"
	    ;;
    esac
    return 0
}

csv_2_flow()
{
    python csv2Route.py $csvname
    #local csvfile=$(basename $csvname)
    local basename="${csvname%.*}"
    flowname="${basename}.xml"
    if [ -f $flowname ];then
	echo "Converted csv file to xml flow format $flowname"
	tag="${fname}_case"
	return 0
    fi
    echo "Error: error converting csv to xml file"
    return 1
}

flow_2_route()
{
    local basename="${flowname%_*}"
    routename="${basename}.rou.xml"
    duarouter --flows=$flowname --net=$netname --output-file=$routename
    return 0
}
write_config()
{
    local defaultcfg="${tag}.cfg"
    echo
    echo "Enter a configuration file name"
    read -e -p "(Press [Enter] to use ${defaultcfg}): " cfgname
    cfgname=${cfgname:-$defaultcfg}
    local config=$"<configuration>
    <input>
        <net-file value=\"${netname}\"/>
        <route-files value=\"${routename}\"/>
        <gui-settings-file value=\"settings.xml\"/>
    </input>

    <time>
        <begin value=\"0\"/>
        <end value=\"3600\"/>
    </time>
    <error-log value=\"sumo_log.txt\"/>
    <time-to-teleport value=\"10\"/>
    <no-warnings value=\"true\"/>
</configuration>"
    echo $config  > $cfgname
    echo "[Set configuration file to $cfgname]"
}
run_sumo()
{
    local defaultFcd="${cfgname%.*}.trace.xml"
    echo
    echo "Enter a trace file name"
    read -e -p "(Press [Enter] to use ${defaultFcd}): " fcdname
    fcdname=${fcdname:-$defaultFcd}
    
    sumo -c $cfgname --fcd-output $fcdname  #region7_case.trace.xml
    echo "[Set trace file to $fcdname]"
    if [ ! -f $fcdname ];then
	echo "Error: can not read fcd file $tracename"
	return 1
    fi
    return 0
}
fcd2pdf()
{
    echo
    if [ "$#" -eq 2 ]; then
	local subsample=$1
	local noise=$2
	local defaultPbf="${cfgname%.*}-ss${subsample}-n${noise}"

	echo "Enter basename for output trajectory files "

	read -e -p "(Press [Enter] to use ${defaultPbf})" pbfname
	pbfname=${pbfname:-$defaultPbf}
	$FCD2PBF -i $fcdname -o $pbfname -s $subsample -n $noise
    else
	local defaultPbf="${cfgname%.*}"

	echo "Enter basename for output trajectory files "

	read -e -p "(Press [Enter] to use ${defaultPbf})" pbfname
	pbfname=${pbfname:-$defaultPbf}
	$FCD2PBF -i $fcdname -o $pbfname
    fi
    chmod 644 ${pbfname}.pbf
}
pbf2txt()
{
    local txtname="${cfgname%.*}.trace.txt"
    $PROCESSPBF -i $pbfname.pbf -c -o $txtname
    echo "wrote txt file to ${txtname}"
    
}
read_route()
{
    # read csv flow file (junction_flows/region8_flows.csv)
    echo
    read -e -p $'Enter flow csv file, or\n[n] to create random trips, \n[q] to skip: \n' csvname
    csvname=${csvname:-q}
    case $csvname in
	n|N)
	    create_rand_trips 
	    [ $? -eq 1 ] && return 1
	    ;;
	q|Q)
            echo "Skipping..."
	    return 1 ;;
	*)
	    if [ ! -f $csvname ]; then
		echo "Error: can not open $csvname"
		return 1
	    fi
	    csv_2_flow 
	    [ $? -eq 1 ] && return 1
	    
	    flow_2_route 
	    [ $? -eq 1 ] && return 1
	    if [ $DISP_ROUTES -eq 1 ]; then
		python visualize_route.py $netname $routename
	    fi
	    ;;
    esac
    echo "[Route file is set to $routename]"
    return 0
}

################### execute script ######################
echo "*******************************************************"
echo "* Interactive script for generating sumo trajectories *"
echo "*******************************************************"
read -e -p "Enter network file path: " networkpath
echo


for f in $networkpath; do
    if [ -f $f ]; then
	echo "Found file $f "
	filename=$(basename "$f")
	ext="${filename##*.}"
	fname="${filename%.*}"
	if [ "$ext" == "osm" ]; then
	    netname="${fname}.net.xml"
	    echo "converting to SUMO network file ${netname}..."
	    netconvert --osm-files $f -o $netname

	else
	    if [ "$ext" == "xml" ]; then
		netname=$f

	    else
		echo "Error: file $filename has invalid extension! "
		continue
	    fi

	fi
	echo "[Network file is set to ${netname}]"
	read_route
	
	[ $? -eq 1 ] && continue
	write_config
	run_sumo
	[ $? -eq 1 ] && continue

	# generate dense trajectories 
	fcd2pdf 
	# generate trajectories with subsample 15, noise 3
	fcd2pdf 15 3
	# generate trajectories with subsample 20, noise 4
	fcd2pdf 20 4

	# if $PROCESSPBF binary is defined, convert trajectories to txt
	if [ -f ${PROCESSPBF} ];then
	    pbf2txt 
	fi
	echo "Success!"
    else
	echo "Error: can not read file $f!"
    fi
done
# if ext = osm, convert osm to xml, otherwise continue
#echo "Enter route file or [n] if no network file available"
#echo "Exiting..."

