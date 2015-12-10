#!/bin/bash
outputfilename="output.txt"
optimalfile="optimal.txt"

for file in *.out; do
  N=2
  nodes=$(head -n 1 $file | awk -v N=$N '{print $N}')
  if [ 1 -eq $nodes ]; then
    lastLine=$(tail -1 $file)
    TRef=$(echo $lastLine | awk -v N=$N '{print $N}')
  fi
done

# Delete old output file
if [ -e $outputfilename ]; then
  rm $outputfilename
fi

for file in *.out; do

  # Take the second number of a line
  N=2
  nodes=$(head -n 1 $file | awk -v N=$N '{print $N}')
  lastLine=$(tail -1 $file)
  T=$(echo $lastLine | awk -v N=$N '{print $N}')
  echo "$nodes $(echo $TRef $T | awk '{print $1 / $2}')" >> $outputfilename
done

## Optimal Speedup
if [ -e $optimalfile ]; then
  rm $optimalfile
fi

lines=$(cat $outputfilename | wc -l)
N=1
for i in $(seq $lines); do
  k=$(head -n $i $outputfilename | tail -n 1 | awk -v N=$N '{print $N}')
	echo "$k $k" >> $optimalfile
done

#plot=$graphfile # Name of file containing plot
gnuplot <<EOF
set terminal pdf 				# Output format (gif, png or jpeg also work)
set output "relativeSpeedup.pdf"				# Name of output file
set ylabel "Relative Speedup" 			# Label of y axis
set xlabel "Number of Machines"	# Label of x axis
plot '$outputfilename' title "Speedup (local thread in Process)" with linespoints pointtype 5, \
'$optimalfile' title "Optimal Speedup" with linespoints pointtype 6
EOF
