#!/bin/bash
#file="results.txt"
outputfilename="output.txt"
optimalfile="optimal.txt"
graphfile="graph2.pdf"

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
  echo $T

  echo "$nodes $(echo $TRef $T | awk '{print $1 / $2}')" >> $outputfilename

done

## Optimal Speedup
#rm $optimalfile
#for i in $(seq $lines); do
#	echo "$i $i" >> $optimalfile
#done


#	for i in $(seq $lines); do
#		Tnew=$(sed -n "${i}p" $file | awk -v N=$N '{print $N}')
#		echo "$i $(echo $Told $Tnew | awk '{print $1 / $2}')" >> $outputfilename
#	done
#done
## Optimal Speedup
#rm $optimalfile
#for i in $(seq $lines); do
#	echo "$i $i" >> $optimalfile
#done
#
#resfile1="outputresults2.txt" # Name of result file
#resfile2="outputresults3.txt"
#resfile3="outputresults4.txt"
#optimal=$optimalfile
#plot=$graphfile # Name of file containing plot
#
#gnuplot <<EOF
#set terminal pdf 				# Output format (gif, png or jpeg also work)
#set output "relativeSpeedup.pdf"				# Name of output file
#set ylabel "Relative Speedup" 			# Label of y axis
#set xlabel "Number of Machines"	# Label of x axis
#plot '$resfile1' title "Speedup (local thread in Process)" with linespoints pointtype 5, \
  #'$resfile2' title "Speedup (Split-Merge coop)" with linespoints pointtype 3, \
  #'$resfile3' title "Speedup (all together)" with linespoints pointtype 4, \
  #'$optimal' title "Optimal Speedup" with linespoints pointtype 6
#EOF
