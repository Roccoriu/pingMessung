#!/bin/bash
# Written by Rocco Ciccone

#-------------------------------------------------------------
# Definition of all variables
#-------------------------------------------------------------

timeout=3
exitCode=0
fileName=$(basename $0 .sh)
logDate=$(date +%Y%m%d)
execTime=$(date +%H:%M:%S)
csvDate=$(date +%Y-%m-%d)
hostname=$(cat /proc/sys/kernel/hostname)

#-------------------------------------------------------------
# Definition of all functions
#-------------------------------------------------------------

function fnHelp {
    echo "$fileName help: [-c]: enter a valid File name from which the hosts are gathered from"
    echo "                        mandatory for execution"
    echo ""
    echo "                  [-l]: specify the logidrectory, in which all the files are created"
    echo "                        mandatory for execution"
    echo ""
    echo "                  [-n]: specifiy the amount of packets which are to be sent to the destination"
    echo "                        optional"
    echo "                        default 3"
    echo ""
    echo "Script was written by Rocco Ciccone"
}

function fnIsNumericValue {

   typeset    FUNC_Value=$1

   # a regex is used to veify that the value passed on is numeric
   typeset    FUNC_NumRegEx="^[+-]?[0-9]+([.][0-9]+)?$"

    if ! [[ $FUNC_Value =~ $FUNC_NumRegEx ]]
     then
        echo "error: [$FUNC_Value] is NOT a number"
        exitCode=8
        exit $exitCode
     fi
}

function fnLogStart {
    echo "start time: $execTime" >> $logDir/$fileName"_"$logDate".log"
    echo "" >> $logDir/$fileName"_"$logDate".log"

    echo "the hosts tested" >> $logDir/$fileName"_"$logDate".log"
    echo "================" >> $logDir/$fileName"_"$logDate".log"

    cat $hostsFile >> $logDir/$fileName"_"$logDate".log"
    echo "" >> $logDir/$fileName"_"$logDate".log"

    echo "================" >> $logDir/$fileName"_"$logDate".log"
    echo "" >> $logDir/$fileName"_"$logDate".log"
}

function fnPing {
    hosts=$1
    pingCount=$2

    while IFS='' read -r host || [[ -n $host ]]; do
        echo "testing $host"
        ping -c $pingCount $host >> $logDir/$fileName"_"$logDate"_pingresult.log"
        if [[ ! $? -eq 0 ]]; then
            exitCode=4
        fi

        logtime=$(date +%H:%M:%S)

        part1=$(cat $logDir/$fileName"_"$logDate"_pingresult.log" | grep packets | sed 's/[A-Za-z% ]*//g' | sed 's/\,/;/g')
        part2=$(cat $logDir/$fileName"_"$logDate"_pingresult.log" | grep rtt | sed 's/[A-Za-z= ]//g' | sed 's/[/]/;/g' | cut -c 4-)
                
        echo -n "$csvDate" >> $logDir/$fileName"_"$logDate".csv"
        echo -n ";$logtime" >> $logDir/$fileName"_"$logDate".csv"
        echo -n ";$hostname" >> $logDir/$fileName"_"$logDate".csv"
        echo -n ";$host" >> $logDir/$fileName"_"$logDate".csv"
        echo -n ";$part1" >> $logDir/$fileName"_"$logDate".csv"
        echo ";$part2" >> $logDir/$fileName"_"$logDate".csv"

        echo "" > $logDir/$fileName"_"$logDate"_pingresult.log"

    done < $hosts

    rm $logDir/$fileName"_"$logDate"_pingresult.log"
}

function fnEndScript {
    endDate=$(date +%H:%M:%S) 
    echo "end time: $endDate" >> $logDir/$fileName"_"$logDate".log"
    echo "exit code: $exitCode" >> $logDir/$fileName"_"$logDate".log"
    echo "" >> $logDir/$fileName"_"$logDate".log"
}

#-------------------------------------------------------------
# gathering the parameters through getopts
#-------------------------------------------------------------

while getopts "c:l:n:h" OPTNAME
do

    case $OPTNAME in

        c)  hostsFile=$OPTARG;;         # defining the hostsFile Variable which stores the name of the config file (Accepts File name with relative and absolute path)

        l)  logDir=$OPTARG;;            # definition of the logdirectory, in which the log file will be written to (accepts absolute and relatibe path)
        
        n)  timeout=$OPTARG;;           # redefinition of the timout variable, incase the user wishes to ping more than 3 times (numeric value)

        h)  fnHelp                      # show Help for the script 
            exitCode=1
            exit $exitCode
            ;;

        *)  echo "ungültiger Option-Parameter: [$myCmdLineArgs]" # if no valid parameter is entered, this will be executed
            exitCode=8
            exit $exitCode
            ;;
    esac

done

#-------------------------------------------------------------
# checking the parameters
#-------------------------------------------------------------

if [[ -z $hostsFile ]]; then
    echo "you have not specified a config file, please do so"
    exitCode=8
    exit $exitCode
fi

if [[ ! -f $hostsFile ]]; then
    echo "$hostsFile is no a valid file, please enter a valid file name and try again"
    exitCode=8
    exit $exitCode
fi

if [[ -z $logDir ]]; then 
    echo "you have not specified a log directory, please do so"
    exitCode=8
    exit $exitCode
fi

if [[ ! -d $logDir ]]; then
    echo "$logDir is no a valid directory, please enter a valid directory and try again"
    exitCode=8
    exit $exitCode
fi

if [[ -n $timeout ]]; then
    fnIsNumericValue $timeout
fi

#-------------------------------------------------------------
# executing the main functions
#-------------------------------------------------------------

fnLogStart
fnPing $hostsFile $timeout
fnEndScript