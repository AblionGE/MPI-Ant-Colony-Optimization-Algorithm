#!/bin/zsh

MAX_NODES=0
OUTPUT_PARALLEL1="comparison1.txt"
OUTPUT_PARALLEL2="comparison2.txt"
OUTPUT_PARALLEL3="comparison3.txt"

for random in $(ls . | grep random | grep .txt)
do
  FILE="../$random"

  # Serial Files
  cd serial
  for results in $(ls | grep slurm)
  do
    temp=$(cat $results | grep $FILE)
    if [ "$temp" != "" ]; then
      N=$(head -n 6 $results | tail -n 1 | wc -w)
      SERIALCOST=$(head -n 6 $results | tail -n 1 | awk -v N=$N '{print $N}')
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
      if [ "$P1_SERIAL[$INDEX]" -eq "" ]; then
        P1_SERIAL[$INDEX]=0
      fi
      if [ "$INDEX" -gt "$MAX_NODES" ]; then
        MAX_NODES=$INDEX
      fi
      N=$(head -n 6 $results | tail -n 1 | wc -w)
      PARALLEL1COST[$INDEX]=$(head -n 6 $results | tail -n 1 | awk -v N=$N '{print $N}')
      if [ "$PARALLEL1COST[$INDEX]" -gt "$SERIALCOST" ]; then
        SERIAL_P1[$INDEX]=$(echo "$SERIAL_P1[$INDEX] + 1" | bc)
      elif [ "$PARALLEL1COST[$INDEX]" -lt "$SERIALCOST" ]; then
        P1_SERIAL[$INDEX]=$(echo "$P1_SERIAL[$INDEX] + 1" | bc)
      fi
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
      if [ "$SERIAL_P2[$INDEX]" -eq "" ]; then
        SERIAL_P2[$INDEX]=0
      fi
      if [ "$P2_SERIAL[$INDEX]" -eq "" ]; then
        P2_SERIAL[$INDEX]=0
      fi
      if [ $INDEX -gt $MAX_NODES ]; then
        MAX_NODES=$INDEX
      fi
      N=$(head -n 6 $results | tail -n 1 | wc -w)
      PARALLEL2COST[$INDEX]=$(head -n 6 $results | tail -n 1 | awk -v N=$N '{print $N}')
      if [ "$PARALLEL2COST[$INDEX]" -gt "$SERIALCOST" ]; then
        SERIAL_P2[$INDEX]=$(echo "$SERIAL_P2[$INDEX] + 1" | bc)
      elif [ "$PARALLEL2COST[$INDEX]" -lt "$SERIALCOST" ]; then
        P2_SERIAL[$INDEX]=$(echo "$P2_SERIAL[$INDEX] + 1" | bc)
      fi
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
      if [ "$SERIAL_P3[$INDEX]" -eq "" ]; then
        SERIAL_P3[$INDEX]=0
      fi
      if [ "$P3_SERIAL[$INDEX]" -eq "" ]; then
        P3_SERIAL[$INDEX]=0
      fi
      if [ $INDEX -gt $MAX_NODES ]; then
        MAX_NODES=$INDEX
      fi
      N=$(head -n 6 $results | tail -n 1 | wc -w)
      PARALLEL3COST[$INDEX]=$(head -n 6 $results | tail -n 1 | awk -v N=$N '{print $N}')
      if [ "$PARALLEL3COST[$INDEX]" -gt "$SERIALCOST" ]; then
        SERIAL_P3[$INDEX]=$(echo "$SERIAL_P3[$INDEX] + 1" | bc)
      elif [ "$PARALLEL2COST[$INDEX]" -lt "$SERIALCOST" ]; then
        P3_SERIAL[$INDEX]=$(echo "$P3_SERIAL[$INDEX] + 1" | bc)
      fi
    fi
  done
  cd ..

  echo "$SERIALCOST $PARALLEL1COST" >> $OUTPUT_PARALLEL1
  echo "$SERIALCOST $PARALLEL2COST" >> $OUTPUT_PARALLEL2
  echo "$SERIALCOST $PARALLEL3COST" >> $OUTPUT_PARALLEL3

done

echo "$OUTPUT_PARALLEL1" >> $OUTPUT_PARALLEL1
echo "Summary" >> $OUTPUT_PARALLEL1
echo "Serial beats Parallel : $SERIAL_P1" >> $OUTPUT_PARALLEL1
echo "Parallel beats Serial : $P1_SERIAL" >> $OUTPUT_PARALLEL1
echo "" >> $OUTPUT_PARALLEL1

echo "$OUTPUT_PARALLEL2" >> $OUTPUT_PARALLEL2
echo "Summary" >> $OUTPUT_PARALLEL2
echo "Serial beats Parallel : $SERIAL_P2" >> $OUTPUT_PARALLEL2
echo "Parallel beats Serial : $P2_SERIAL" >> $OUTPUT_PARALLEL2
echo "" >> $OUTPUT_PARALLEL2

echo "$OUTPUT_PARALLEL3" >> $OUTPUT_PARALLEL3
echo "Summary" >> $OUTPUT_PARALLEL3
echo "Serial beats Parallel : $SERIAL_P3" >> $OUTPUT_PARALLEL3
echo "Parallel beats Serial : $P3_SERIAL" >> $OUTPUT_PARALLEL3
echo "" >> $OUTPUT_PARALLEL3
