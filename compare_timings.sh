#!/bin/zsh

MAX_NODES=0
OUTPUT_PARALLEL1="comparison1_timing.txt"
OUTPUT_PARALLEL2="comparison2_timing.txt"
OUTPUT_PARALLEL3="comparison3_timing.txt"
OUTPUT_PARALLEL1_SPEEDUP_ABSOLUTE="comparison1_absolute_speedup.txt"
OUTPUT_PARALLEL2_SPEEDUP_ABSOLUTE="comparison2_absolute_speedup.txt"
OUTPUT_PARALLEL3_SPEEDUP_ABSOLUTE="comparison3_absolute_speedup.txt"
OUTPUT_PARALLEL1_SPEEDUP_RELATIVE="comparison1_relative_speedup.txt"
OUTPUT_PARALLEL2_SPEEDUP_RELATIVE="comparison2_relative_speedup.txt"
OUTPUT_PARALLEL3_SPEEDUP_RELATIVE="comparison3_relative_speedup.txt"

for random in $(ls . | grep random | grep .txt)
do
  FILE="../$random"

  # Serial Files
  cd serial
  for results in $(ls | grep slurm)
  do
    temp=$(cat $results | grep $FILE)
    if [ "$temp" != "" ]; then
      N=$(head -n 7 $results | tail -n 1 | wc -w)
      SERIALTIME=$(head -n 7 $results | tail -n 1 | awk -v N=$N '{print $N}')
    fi
  done
  cd ..

  cd parallel1 
  for results in $(ls | grep slurm)
  do
    temp=$(cat $results | grep $FILE)
    if [ "$temp" != "" ]; then
      N=$(head -n 1 $results | wc -w)
      INDEX=$(head -n 1 $results | awk -v N=$N '{print $N}')
      if [ "$SERIAL_P1[$INDEX]" -eq "" ]; then
        SERIAL_P1[$INDEX]=0
      fi
      N=$(head -n 7 $results | tail -n 1 | wc -w)
      PARALLEL1TIME[$INDEX]=$(head -n 7 $results | tail -n 1 | awk -v N=$N '{print $N}')
      PARALLEL1ABSOLUTE[$INDEX]=$(echo $SERIALTIME / $PARALLEL1TIME[$INDEX] | bc -l)
      PARALLEL1RELATIVE[$INDEX]=$(echo $PARALLEL1TIME[1] / $PARALLEL1TIME[$INDEX] | bc -l)
    fi
  done
  cd ..

  cd parallel2 
  for results in $(ls | grep slurm)
  do
    temp=$(cat $results | grep $FILE)
    if [ "$temp" != "" ]; then
      N=$(head -n 1 $results | wc -w)
      INDEX=$(head -n 1 $results | awk -v N=$N '{print $N}')
      if [ $INDEX -gt $MAX_NODES ]; then
        MAX_NODES=$INDEX
      fi
      N=$(head -n 7 $results | tail -n 1 | wc -w)
      PARALLEL2TIME[$INDEX]=$(head -n 7 $results | tail -n 1 | awk -v N=$N '{print $N}')
      PARALLEL2ABSOLUTE[$INDEX]=$(echo $SERIALTIME / $PARALLEL2TIME[$INDEX] | bc -l)
      PARALLEL2RELATIVE[$INDEX]=$(echo $PARALLEL2TIME[1] / $PARALLEL2TIME[$INDEX] | bc -l)
    fi
  done
  cd ..

  cd parallel3 
  for results in $(ls | grep slurm)
  do
    temp=$(cat $results | grep $FILE)
    if [ "$temp" != "" ]; then
      N=$(head -n 1 $results | wc -w)
      INDEX=$(head -n 1 $results | awk -v N=$N '{print $N}')
      if [ $INDEX -gt $MAX_NODES ]; then
        MAX_NODES=$INDEX
      fi
      N=$(head -n 7 $results | tail -n 1 | wc -w)
      PARALLEL3TIME[$INDEX]=$(head -n 7 $results | tail -n 1 | awk -v N=$N '{print $N}')
      PARALLEL3ABSOLUTE[$INDEX]=$(echo $SERIALTIME / $PARALLEL3TIME[$INDEX] | bc -l)
      PARALLEL3RELATIVE[$INDEX]=$(echo $PARALLEL3TIME[1] / $PARALLEL3TIME[$INDEX] | bc -l)
    fi
  done
  cd ..

  echo "$SERIALTIME $PARALLEL1TIME" >> $OUTPUT_PARALLEL1
  echo "$PARALLEL1ABSOLUTE" >> $OUTPUT_PARALLEL1_SPEEDUP_ABSOLUTE
  echo "$PARALLEL1RELATIVE" >> $OUTPUT_PARALLEL1_SPEEDUP_RELATIVE
  echo "$SERIALTIME $PARALLEL2TIME" >> $OUTPUT_PARALLEL2
  echo "$PARALLEL2ABSOLUTE" >> $OUTPUT_PARALLEL2_SPEEDUP_ABSOLUTE
  echo "$PARALLEL2RELATIVE" >> $OUTPUT_PARALLEL2_SPEEDUP_RELATIVE
  echo "$SERIALTIME $PARALLEL3TIME" >> $OUTPUT_PARALLEL3
  echo "$PARALLEL3ABSOLUTE" >> $OUTPUT_PARALLEL3_SPEEDUP_ABSOLUTE
  echo "$PARALLEL3RELATIVE" >> $OUTPUT_PARALLEL3_SPEEDUP_RELATIVE

done

echo "$OUTPUT_PARALLEL1" >> $OUTPUT_PARALLEL1
echo "" >> $OUTPUT_PARALLEL1

echo "$OUTPUT_PARALLEL2" >> $OUTPUT_PARALLEL2
echo "" >> $OUTPUT_PARALLEL2

echo "$OUTPUT_PARALLEL3" >> $OUTPUT_PARALLEL3
echo "" >> $OUTPUT_PARALLEL3
