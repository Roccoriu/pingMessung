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
pass='number1 number2 number3 number4 number5 number6 number7 number8 number9 number10 number11 number12 number13 number14 number15 number16'
chk='number16'
tableHeaders="Execution_Date;Execution_Time;Host;target;packets_sent;packets_recieved;errors;percent_lost;Time;rtt_min;rtt_avg;rtt_max;rtt_mdev"

#-------------------------------------------------------------
# Definition of the color codes for usage with echo -e
#-------------------------------------------------------------

default='\033[0m'
red='\033[0;31m'
green='\033[0;32m'
orange='\033[0;33m'
purple='\033[0;35m'
cyan='\033[0;36m'

lred='\033[1;31m'
lgreen='\033[1;32m'
yellow='\033[1;33m'
lblue='\033[1;34m'
lpurple='\033[1;35m'
lcyan='\033[1;36m'
white='\033[1;37m'

#-------------------------------------------------------------
# Definition of all functions
#-------------------------------------------------------------

function fnHelp {
    echo -e "${green}$fileName${default} help: ${green}[-c]:${default} enter a valid File name from which the hosts are gathered from"
    echo -e "                     mandatory for execution"
    echo -e ""
    echo -e "               ${green}[-l]:${default} specify the logidrectory, in which all the files are created"
    echo -e "                     mandatory for execution"
    echo -e ""
    echo -e "               ${green}[-n]:${default} specifiy the amount of packets which are to be sent to the destination"
    echo -e "                     optional"
    echo -e "                     default 3"
    echo -e ""
    echo -e "Script was written by Rocco Ciccone"
}

function fnIsNumericValue {

   typeset    FUNC_Value=$1

   # a regex is used to veify that the value passed on is numeric
   typeset    FUNC_NumRegEx="^[+-]?[0-9]+([.][0-9]+)?$"

    if [[ ! $FUNC_Value =~ $FUNC_NumRegEx ]]
     then
        echo -e "${red}error: ${yellow}[$FUNC_Value] ${red}is NOT a number${default}"
        exitCode=8
        exit $exitCode
     fi
}

function fnLogStart {
    clear
    echo -en "${green}writing log to: "
    if [[ ${logDir:0:2} == "./" ]]; then

        if [[ ${logDir:$((${#logDir}-1)):1} == "/" ]]; then
            echo -e "${yellow}$(pwd)$(echo -n $logDir | cut -c 2-)$(basename $logFile${default})"
        else
            echo -e "${yellow}$(pwd)$(echo -n $logDir | cut -c 2-)/$(basename $logFile${default})" 
        fi

    else

        if [[ ${logDir:$((${#logDir}-1)):1} == "/" ]]; then
            echo -e "${yellow}$logDir$(echo -n $logDir | cut -c 2-)$(basename $logFile${default})"
        else 
            echo -e "${yellow}$logDir$(echo -n $logDir | cut -c 2-)/$(basename $logFile${default})"
        fi

    fi

    echo -e "start time: $execTime" >> $logFile
    echo -e "" >> $logFile

    echo -e "the hosts tested" >> $logFile
    echo -e "================" >> $logFile

    cat $hostsFile >> $logFile
    #echo -e "" >> $logFile

    echo -e "================" >> $logFile
    echo -e "" >> $logFile
}

function fnPing {
    hosts=$1
    pingCount=$2
    echo "==============="

    if [[ ! -f $csvFile ]]; then
        echo -e "$tableHeaders" >> $csvFile 
    fi
    
    if ! grep -q $tableHeaders $csvFile; then
        echo -e "$tableHeaders" >> $csvFile 
    fi

    while IFS='' read -r host || [[ -n $host ]]; do
        echo -e -n "${yellow}testing $host:${default} "
        ping -c $pingCount $host >> $workFile &
        
        PID=$!

        #i=1
        #sp="/-\|"
        #echo -n ' '
        if [[ -d /proc/$PID ]]; then
            #printf "\b${sp:i++%${#sp}:1}"
            #sleep 0.1
            echo -ne "\033[1;33m\033[7m\033[?25l"

            for i in $pass ; do
                
                    mTimeout=$( echo print $timeout/ 16. | python)
                    sleep ${mTimeout}s
                

                if [[ "$i" == "$chk" ]]; then
                    break
                else
                    echo -n " "
                fi
            done

            wait $PID
            mCode=$?
            echo -ne "\r\033[0m\033[K\033[?25h"

            if [[ ! $mCode -eq 0 ]]; then
                result="failed"
                echo -e "${red}$result${default}: $host"
                exitCode=4
            else 
                result="done"
                echo -e "${green}$result${default}  : $host"
            fi
            
        fi

        logtime=$(date +%H:%M:%S)

        part1=$(cat $workFile | grep packets | sed 's/[A-Za-z%+ ]*//g' | sed 's/\,/;/g')
        part2=$(cat $workFile | grep rtt | sed 's/[A-Za-z= ]//g' | sed 's/[/]/;/g' | cut -c 4-)

        echo -e -n "$csvDate" >> $csvFile
        echo -e -n ";$logtime" >> $csvFile
        echo -e -n ";$hostname" >> $csvFile
        echo -e -n ";$host" >> $csvFile
        
        IFS=';' read -r -a mArr <<< $part1

        if [[ ${#mArr[@]} -lt 5 ]]; then
            #echo -e -n ";$part1" >> $csvFile

            mPart1=";${mArr[0]};${mArr[1]};0;${mArr[2]};${mArr[3]}"
            echo -e -n "$mPart1" >> $csvFile
        fi

        if [[ ${#mArr[@]} -ge 5 ]]; then
            echo -e -n ";$part1" >> $csvFile
        fi

        if [[ -z $part2 ]]; then
            echo -e ";-.---;-.---;-.---;-.---" >> $csvFile
        else 
            echo -e ";$part2" >> $csvFile
        fi
        echo -e "" > $workFile
        #echo -e " : ${green}done${default}"

    done < $hosts

    rm $workFile
    echo -e ""
}

function fnEndScript {
    endDate=$(date +%H:%M:%S) 
    echo -e "end time: $endDate" >> $logFile
    echo -e "exit code: $exitCode" >> $logFile
    echo -e "" >> $logFile
}

#-------------------------------------------------------------
# gathering the parameters through getopts
#-------------------------------------------------------------

while getopts "c:l:n:hx" OPTNAME
do

    case $OPTNAME in

        c)  hostsFile=$OPTARG;;         # defining the hostsFile Variable which stores the name of the config file (Accepts File name with relative and absolute path)

        l)  logDir=$OPTARG;;            # definition of the logdirectory, in which the log file will be written to (accepts absolute and relatibe path)
        
        n)  timeout=$OPTARG;;           # redefinition of the timout variable, incase the user wishes to ping more than 3 times (numeric value)

        h)  fnHelp                      # show Help for the script 
            exitCode=1
            exit $exitCode
            ;;

        x) set -x ;;

        *)  echo -e "${yellow}ungültiger Option-Parameter: ${red}[${@:OPTIND-1:1}]${default}" # if no valid parameter is entered, this will be executed
            exitCode=8
            exit $exitCode
            ;;
    esac

done

#-------------------------------------------------------------
# checking the parameters
#-------------------------------------------------------------

if [[ -z $hostsFile ]]; then
    echo -e "${red}you have not specified a config file, please do so${default}"
    exitCode=8
    exit $exitCode
fi

if [[ ! -f $hostsFile ]]; then
    echo -e "${red}$hostsFile${yellow}is no a valid file, please enter a valid file name and try again${default}"
    exitCode=8
    exit $exitCode
fi

if [[ -z $logDir ]]; then 
    echo -e "${red}you have not specified a log directory, please do so${default}"
    exitCode=8
    exit $exitCode
fi

if [[ ! -d $logDir ]]; then
    echo -e "${red}$logDir${yellow} is no a valid directory, please enter a valid directory and try again${default}"
    exitCode=8
    exit $exitCode
fi

if [[ -n $timeout ]]; then
    fnIsNumericValue $timeout
fi

#-------------------------------------------------------------
# setting variable for File names for easier usage
#-------------------------------------------------------------

logFile="${logDir}/${fileName}_${logDate}.log"
workFile="${logDir}/${fileName}_${logDate}_pingresult.log"
csvFile="${logDir}/${fileName}_${logDate}.csv"

#-------------------------------------------------------------
# executing the main functions
#-------------------------------------------------------------

fnLogStart
fnPing $hostsFile $timeout
fnEndScript