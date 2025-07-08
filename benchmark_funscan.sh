#!/bin/bash

# Paths and settings
INPUT="samples.csv"
CONFIG="base.config"
PROFILES=("singularity" "docker" "conda" "podman")
OUTDIR_PREFIX="funscan_out"
RESULTS_LOG="benchmark_summary.log"

# Clear previous log
echo -e "Profile\tStart\tEnd\tDuration(min)\tMaxMem(MB)\tCPU(%)" > $RESULTS_LOG

# Loop through each profile
for PROFILE in "${PROFILES[@]}"; do
  echo "Running profile: $PROFILE"

  OUTDIR="${OUTDIR_PREFIX}_${PROFILE}"
  LOGFILE="log_${PROFILE}.txt"
  
  # Start time
  START=$(date +%s)

  # Run pipeline with resource/time monitoring
  /usr/bin/time -f "\nMAXMEM(KB): %M\nCPU(%): %P" -o $LOGFILE \
  nextflow run nf-core/funcscan \
    -profile $PROFILE \
    --input $INPUT \
    --outdir $OUTDIR \
    --run_amp_screening \
    --run_arg_screening \
    --run_bgc_screening \
    -c $CONFIG \
    -resume

  # End time
  END=$(date +%s)
  DURATION_MIN=$(( (END - START) / 60 ))

  # Parse memory and CPU
  MAXMEM=$(grep "MAXMEM(KB)" $LOGFILE | awk '{print $2}')
  MAXMEM_MB=$((MAXMEM / 1024))
  CPU=$(grep "CPU(%)" $LOGFILE | awk '{print $2}')

  # Write summary
  echo -e "${PROFILE}\t${START}\t${END}\t${DURATION_MIN}\t${MAXMEM_MB}\t${CPU}" >> $RESULTS_LOG
done

echo "✅ Benchmark completed. See: $RESULTS_LOG"
