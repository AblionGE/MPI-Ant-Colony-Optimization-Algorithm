#!/bin/bash

outputfilename_parallel="output_parallel.txt"
outputfilename_serial="output_serial.txt"
optimalfile_serial="optimal_serial.txt"
optimalfile_parallel="optimal_parallel.txt"

for random in $(ls .. | grep random | grep .txt);
do
  RANDOM_FILE="../$random"

  # ABSOLUTE SPEEDUP
  # Get serial time
  cd serial
  for results in $(ls | grep slurm);
  do
    temp=$(cat $results | grep $RANDOM_FILE)
    if [ "$temp" != "" ]; then
      N=$(head -n 1 $results | wc -w)
      INDEX=$(head -n 1 | awk -v N=$N '{print $N}')
      RESULT_FILES_SERIAL[$INDEX]=$results
    fi
  done

  for file in $RESULT_FILES_SERIAL;
  do
    N=2
    nodes=$(head -n 1 $file | awk -v N=$N '{print $N}')
    if [ 1 -eq $nodes ]; then
      lastLine=$(tail -1 $file)
      TRefSerial=$(echo $lastLine | awk -v N=$N '{print $N}')
    fi
  done

  cd ..

  # RELATIVE SPEEDUP
  # Get parallel times and draw speedup graphs
  for p in "parallel1" "parallel2" "parallel3";
  do
    cd $p

    for results in $(ls | grep slurm);
    do
      temp=$(cat $results | grep $RANDOM_FILE)
      if [ "$temp" != "" ]; then
        N=$(head -n 1 $results | wc -w)
        INDEX=$(head -n 1 | awk -v N=$N '{print $N}')
        RESULT_FILES_PARALLEL[$INDEX]=$results
      fi
    done

    for file in $RESULT_FILES_PARALLEL;
    do
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

    for file in $RESULT_FILES_PARALLEL;
    do
      # Take the second number of a line
      N=2
      nodes=$(head -n 1 $file | awk -v N=$N '{print $N}')
      lastLine=$(tail -1 $file)
      T=$(echo $lastLine | awk -v N=$N '{print $N}')
      echo "$nodes $(echo $TRef $T | awk '{print $1 / $2}')" >> $outputfilename_parallel
      if [ $nodes -eq 1 ]; then
        T=$TRefSerial
      fi
      echo "$nodes $(echo $TRefSerial $T | awk '{print $1 / $2}')" >> $outputfilename_serial
    done

    ## Optimal Speedup
    if [ -e $optimalfile_serial ]; then
      rm $optimalfile_serial
    fi
    if [ -e $optimalfile_parallel ]; then
      rm $optimalfile_parallel
    fi

    # Serial
    lines=$(cat $outputfilename_serial | wc -l)
    N=1
    for i in $(seq $lines); do
      k=$(head -n $i $outputfilename_serial | tail -n 1 | awk -v N=$N '{print $N}')
      echo "$k $k" >> $optimalfile_serial
    done

    # Parallel
    lines=$(cat $outputfilename_parallel | wc -l)
    N=1
    for i in $(seq $lines); do
      k=$(head -n $i $outputfilename_parallel | tail -n 1 | awk -v N=$N '{print $N}')
      echo "$k $k" >> $optimalfile_parallel
    done

    # Draw Absolute Speedup
    gnuplot <<-EOF
    set terminal pdf 				# Output format (gif, png or jpeg also work)
    set output "AbsoluteSpeedup$random.pdf"				# Name of output file
    set ylabel "Absolute Speedup" 			# Label of y axis
    set xlabel "Number of Machines"	# Label of x axis
    plot '$outputfilename_serial' title "Speedup (local thread in Process)" with linespoints pointtype 5, \
      '$optimalfile_serial' title "Optimal Speedup" with linespoints pointtype 6
EOF

    # Draw Relative Speedup
    gnuplot <<-EOF
    set terminal pdf 				# Output format (gif, png or jpeg also work)
    set output "RelativeSpeedup$random.pdf"				# Name of output file
    set ylabel "Relative Speedup" 			# Label of y axis
    set xlabel "Number of Machines"	# Label of x axis
    plot '$outputfilename_parallel' title "Speedup (local thread in Process)" with linespoints pointtype 5, \
      '$optimalfile_parallel' title "Optimal Speedup" with linespoints pointtype 6
EOF

  done
done

