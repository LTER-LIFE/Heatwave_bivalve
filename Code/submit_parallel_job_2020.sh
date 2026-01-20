#!/bin/sh
#SBATCH --job-name=ricky-par
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=30G
#SBATCH --time=12:00:00
#SBATCH --mail-user=qi.liu@nioz.nl

# perform run in the correct directory 
rundir=${HOME}/ricky_proj
cd ${rundir}
echo "Simulation will run in directory: ${rundir}" 

# setting the environment
source ~/.bashrc.conda3
conda activate rickyR

module load openblas 

# turnoff openblas multithreading 
export OMP_NUM_THREADS=1

starttime=`date +%s`
echo $starttime

# run script in parallel 
Rscript ${rundir}/multicore_ensemble_2020.R

endtime=`date +%s`
echo $endtime
echo "run time is: $((endtime-starttime))"
