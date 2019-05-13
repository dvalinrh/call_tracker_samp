#!/bin/bash

#
# Shell script that generates a bpftrace script to track perform a sampling
# of functions called after a specific function is entered.
#
# Output will look something like this
#
#@a[
#    trampoline_handler+47
#]: 43
#@a[
#    copy_user_enhanced_fast_string+14
#]: 316
#@a[
#    copy_user_enhanced_fast_string+3
#]: 194747
#
# The output is not an accurate count of functions called, but is based on profiling.
#
# Options
# -c: "command to execute"  
# -d: depth of stack to view, default is 1 level.  
# -h: help message
# -s: <name>: syscall tracepoint
# -p: <value>: Profile interval
# -k: <name>: kprobe to track


DEPTH=1
PROFILE=9999

usage()
{
        echo Usage
        echo "-c command to execute"
	echo "-d depth of stack (default == 1)"
        echo "-h help message"
	echo "-s <name>: syscall tracepoint"
	echo "-k <name>: kprobe tracking"
	echo "-p <value>: Profile interval>"
        exit -1
}

while getopts "hc:p:d:s:k:" opt; do
	case ${opt} in
		c )
			COMMAND=${OPTARG}
		;;
		d )
			DEPTH=${OPTARG}
		;;
		p )
			PROFILE=${OPTARG}
		;;
		h )
			usage
    		;;
		s )
			SYSCALL_TP=${OPTARG};
		;;
		k )
			KPROBE=${OPTARG}
  	esac
done

if [[ -z ${COMMAND} ]]; then
	echo need to designate command to run
	usage
fi

if [[ -z ${SYSCALL_TP} ]] && [[ -z ${KPROBE} ]]; then
	echo Need to designate either a syscall trace point or kernel probe
	usage
fi

printf "#%c/usr/local/bin/bpftrace\n" '!' > temp.bt
if [[ -z ${SYSCALL_TP} ]]; then
	printf "kprobe:%s\n" ${KPROBE} >> temp.bt
else
	printf "tracepoint:syscalls:sys_enter_%s\n" ${SYSCALL_TP} >> temp.bt
fi
printf "{\n" >> temp.bt
printf "\t@track[tid] = 1;\n" >> temp.bt
printf "}\n" >> temp.bt

if [[ -z ${SYSCALL_TP} ]]; then
	printf "kretprobe:%s\n" ${KPROBE} >> temp.bt
else
	printf "tracepoint:syscalls:sys_exit_%s\n" ${SYSCALL_TP} >> temp.bt
fi
printf "{\n" >> temp.bt
printf "\tdelete(@track[tid]);\n" >> temp.bt
printf "}\n" >> temp.bt

printf "profile:us:%d\n" ${PROFILE} >> temp.bt
printf "\t/ @track[tid] == 1 /\n" >> temp.bt
printf "{\n" >> temp.bt
printf "\t@a[kstack(%d)] = count()\n" ${DEPTH} >> temp.bt
printf "}\n" >> temp.bt

printf "END\n" >> temp.bt
printf "{\n" >> temp.bt
printf "\tclear(@track);\n" >> temp.bt
printf "}\n" >> temp.bt

chmod 755 temp.bt
bpftrace -c "${COMMAND}" ./temp.bt
