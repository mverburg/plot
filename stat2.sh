#!/bin/bash
# usage: stat2.sh [delay] [number of samples]
# ${PARAMETER:-WORD} -> If PARAMETER is unset or null, the shell expands WORD and substitutes the result. The value of PARAMETER is not changed.
IN_FILE=$1;
OUT_FILE_NAME=${2:-"`pwd`"/vmstat"`date +%Y%m%d-%H%M`.gif"};

# prepare vmstat output for parsing by gnuplot by:
# - deleting first three lines
# - removing superfluous spaces
cat $IN_FILE | sed -e 1,3d -e 's/^ //' -e 's/ \+/ /g' > /tmp/vmstatlog.$$

# procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu----- 
#  1  2      3      4      5      6    7    8     9    10   11   12 13 14 15 16 17
#  r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st 

# Find graph range
MAX_CS=$(cut -f 12 -d ' ' < /tmp/vmstatlog.$$ | sort -n -r | head -n 1);
MIN_CS=$(cut -f 12 -d ' ' < /tmp/vmstatlog.$$ | sort -n | head -n 1);
MAX_IO_IN=$(cut -f 9 -d ' ' < /tmp/vmstatlog.$$ | sort -n -r | head -n 1);
MIN_IO_IN=$(cut -f 9 -d ' ' < /tmp/vmstatlog.$$ | sort -n | head -n 1);
MAX_IO_OUT=$(cut -f 10 -d ' ' < /tmp/vmstatlog.$$ | sort -n -r | head -n 1);
MIN_IO_OUT=$(cut -f 10 -d ' ' < /tmp/vmstatlog.$$ | sort -n | head -n 1);
if [ "$MAX_IO_IN" -gt "$MAX_IO_OUT" ]; then MAX_IO=$MAX_IO_IN; else MAX_IO=$MAX_IO_OUT; fi 
#if [ "$MAX_IO_IN" -gt "$MAX_IO_OUT" ]; then 
#  MAX_IO=$MAX_IO_IN; 
#else 
#  MAX_IO=$MAX_IO_OUT; 
#fi 

if [ "$MIN_IO_IN" -lt "$MIN_IO_OUT" ]; then 
  MIN_IO=$MIN_IO_IN; 
else 
  MIN_IO=$MIN_IO_OUT; 
fi
NUM_CPU=`cat /proc/cpuinfo|grep processor|wc -l`;

echo "MAX_IO_IN:$MAX_IO_IN MAX_IO_OUT:$MAX_IO_OUT MIN_IO_IN:$MIN_IO_IN MIN_IO_OUT:$MIN_IO_OUT"
/usr/bin/gnuplot -persist <<- EOF
# global configuration
set terminal gif size 820,640              # output dimensions
set output "/tmp/vmstatlog.$$.gif"         # output location
set size 1,1                               # set workspace
set origin 0,0                             # set lower left corner of workspace
set multiplot                              # muliple plots in one image
set grid                                   # show grid
set xrange [0:$NUM_RECORDS]                # set range of x-axis
set nokey                                  # turn of legend


# 1. Graph - CPU time (user time(column 13) and system time(column 14))
set size 1,0.25                            # adjust chart size
set origin 0,0                             # location of the chart 
set yrange [0:100]                         # y range
set label "CPU load [%]" at screen 0.5,0.2 center       
set key
plot "/tmp/vmstatlog.$$" using 13 title "user" with lines, \
 "/tmp/vmstatlog.$$" using 14 title "system" with lines
set nokey

# 2. chart - running processes (column 1 listing vmstat)
set size 1,0.25
set origin 0,0.25
set autoscale y
set label "Runnable processes" at screen 0.5,0.45 center
plot "/tmp/vmstatlog.$$" using 1 with lines, \
  $NUM_CPU title "CPUs" lc rgb "red" lw 2


# 3 chart - context switching (column 12 statement vmstat)
ycs=($MAX_CS-$MIN_CS)/5
set size 1,0.25
set origin 0,0.5
set autoscale y
set ytics ycs
set label 1 "Context switches [cws/s]" at screen 0.5,0.7 center
plot "/tmp/vmstatlog.$$" using 12 with lines

# 4 chart - i / o statistics for columns 9 (bytes in) and 10 (bytes out))
ycs=($MAX_IO-$MIN_IO)/5
set size 1,0.25
set origin 0,0.75
set autoscale y
set ytics ycs
set key
set label "I/O activity [block/s]" at screen 0.5,0.95 center
plot "/tmp/vmstatlog.$$" using 9 title "in" with lines, \
  "/tmp/vmstatlog.$$" using 10 title "out" with lines
set nokey

EOF
#/usr/bin/gnome-open /tmp/vmstatlog.$$.gif
echo "moving file to $OUT_FILE_NAME"
mv /tmp/vmstatlog.$$.gif $OUT_FILE_NAME
