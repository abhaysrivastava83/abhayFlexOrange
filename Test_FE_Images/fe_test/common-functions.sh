#!/usr/bin/env bash

## pass a test, printing out MSG start with no errors
ERROR=0
PASS=0
FAILED_FUNCS=""
WD="$(pwd)"

#  usage: passed message
function passed {
    local lineno
    lineno=$(caller 0 | awk '{print $1}')
    local function
    function=$(caller 0 | awk '{print $2}')
    local msg="$1"
    if [ -z "$msg" ]; then
        msg="OK"
    fi
    PASS=$((PASS+1))
    echo "PASS: $function:L$lineno - $msg"
}

# fail a test, printing out MSG
#  usage: failed message
function failed {
    local lineno
    lineno=$(caller 0 | awk '{print $1}')
    local function
    function=$(caller 0 | awk '{print $2}')
    local msg="$1"
    FAILED_FUNCS+="$function:L$lineno\n"
    echo "ERROR: $function:L$lineno!"
    echo "   $msg"
    ERROR=$((ERROR+1))
}

# assert string comparison of val1 equal val2, printing out msg
#  usage: assert_equal val1 val2 msg
function assert_equal {
    local lineno
    lineno=`caller 0 | awk '{print $1}'`
    local function
    function=`caller 0 | awk '{print $2}'`
    local msg=$3

    if [ -z "$msg" ]; then
        msg="OK"
    fi
    if [[ "$1" != "$2" ]]; then
        FAILED_FUNCS+="$function:L$lineno\n"
        echo "ERROR: $1 != $2 in $function:L$lineno!"
        echo "  $msg"
        ERROR=$((ERROR+1))
    else
        PASS=$((PASS+1))
        echo "PASS: $function:L$lineno - $msg"
    fi
}

# assert variable is empty/blank, printing out msg
#  usage: assert_empty VAR msg
function assert_empty {
    local lineno
    lineno=`caller 0 | awk '{print $1}'`
    local function
    function=`caller 0 | awk '{print $2}'`
    local msg=$2

    if [ -z "$msg" ]; then
        msg="OK"
    fi
    if [[ ! -z ${!1} ]]; then
        FAILED_FUNCS+="$function:L$lineno\n"
        echo "ERROR: $1 not empty in $function:L$lineno!"
        echo "  $msg"
        ERROR=$((ERROR+1))
    else
        PASS=$((PASS+1))
        echo "PASS: $function:L$lineno - $msg"
    fi
}

# assert the arguments evaluate to true
#  assert_true "message" arg1 arg2
function assert_true {
    local lineno
    lineno=`caller 0 | awk '{print $1}'`
    local function
    function=`caller 0 | awk '{print $2}'`
    local msg=$1
    shift

    $@
    if [ $? -eq 0 ]; then
        PASS=$((PASS+1))
        echo "PASS: $function:L$lineno - $msg"
    else
        FAILED_FUNCS+="$function:L$lineno\n"
        echo "ERROR: test failed in $function:L$lineno!"
        echo "  $msg"
        ERROR=$((ERROR+1))
    fi
}

# assert the arguments evaluate to false
#  assert_false "message" arg1 arg2
function assert_false {
    local lineno
    lineno=`caller 0 | awk '{print $1}'`
    local function
    function=`caller 0 | awk '{print $2}'`
    local msg=$1
    shift

    $@
    if [ $? -eq 0 ]; then
        FAILED_FUNCS+="$function:L$lineno\n"
        echo "ERROR: test failed in $function:L$lineno!"
        echo "  $msg"
        ERROR=$((ERROR+1))
    else
        PASS=$((PASS+1))
        echo "PASS: $function:L$lineno - $msg"
    fi
}


# Print a summary of passing and failing tests and exit
# (with an error if we have failed tests)
#  usage: report_results
function report_results {
    echo "$PASS Tests PASSED"
    if [[ $ERROR -gt 0 ]]; then
        echo
        echo "The following $ERROR tests FAILED"
        echo -e "$FAILED_FUNCS"
        echo "---"
        exit 1
    fi
    exit 0
}

# Control Functions
# =================

# Prints backtrace info
# filename:lineno:function
# backtrace level
function backtrace {
    local level=$1
    local deep
    deep=$((${#BASH_SOURCE[@]} - 1))
    echo "[Call Trace]"
    while [ $level -le $deep ]; do
        echo "${BASH_SOURCE[$deep]}:${BASH_LINENO[$deep-1]}:${FUNCNAME[$deep-1]}"
        deep=$((deep - 1))
    done
}

# Prints line number and "message" then exits
# die $LINENO "message"
function die {
    local exitcode=$?
    set +o xtrace
    local line=$1; shift
    if [ $exitcode == 0 ]; then
        exitcode=1
    fi
    backtrace 2
    err $line "$*"
    # Give buffers a second to flush
    sleep 1
    exit $exitcode
}

# Usage: run_with_timeout N cmd args...
#    or: run_with_timeout cmd args...
# In the second case, cmd cannot be a number and the timeout will be 10 seconds.
run_with_timeout () {
    local time=10
    if [[ $1 =~ ^[0-9]+$ ]]; then time=$1; shift; fi
    # Run in a subshell to avoid job control messages
    ( "$@" &
      child=$!
      # Avoid default notification in non-interactive shell for SIGTERM
      trap -- "" SIGTERM
      ( sleep $time
        kill $child 2> /dev/null ) &
      wait $child
      exit
    )
}

function err {
    local exitcode=$?
    local xtrace
    xtrace=$(set +o | grep xtrace)
    set +o xtrace
    local msg="[ERROR] ${BASH_SOURCE[2]}:$1 $2"
    echo "$msg" 1>&2;
    $xtrace
    return $exitcode
}

function check_test {
    if [ $? -eq 143 ];then
        clean_up
	report_results >> "$WD"/fe_test_report.txt
        die
    fi
}
