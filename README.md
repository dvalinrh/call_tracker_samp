# call_tracker_samp
Given a kernel function, will provide a sampling of functions that are called from the given function.

Shell script that generates a bpftrace script to track perform a sampling
of functions called after a specific function is entered.

Output will look something like this

@a
 trampoline_handler+47
]: 316

@a
    copy_user_enhanced_fast_string+14
]: 316
@a
    copy_user_enhanced_fast_string+3
]: 194747


 The output is not an accurate count of functions called, but is based on profiling.

 Options
 -c: "command to execute"
 -d: depth of stack to view, default is 1 level.
 -h: help message
 -s: <name>: syscall tracepoint
 -p: <value>: Profile interval
 -k: <name>: kprobe to track
