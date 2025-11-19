#!/bin/bash

for mode in gpu cpu ; do 
    for depth in 50 75 100 ; do
        for scale in {1..9} ; do
        
            # Generate name of experiment
            name="dg_${scale}x${scale}x${depth}_${mode}"

            # Modify name for current run
            if [[ ${mode} == "cpu" ]] ; then
                 name="${name}_dt_scaling_intel_02_blocking"
                 #name="${name}_dt_scaling_O2"
            else
                 name="${name}_dt_scaling_O2"
            fi
            echo "Working on ${name}, ${scale}x${scale}x${depth} case" 

            # Copy dg into new dir named after experiment
            cp -r double_gyre/ ${name}

            # cd into that dir, set up and submit run
            cd ${name}
            ./setup_new_run_variable_dt.sh ${scale} ${depth}

            # Parameters from Alistair to allow runs with more layers
            # Update domains_stack_size to prevent memory issues:
            sed -i 's/&fms_nml/&\n    domains_stack_size = 320000/' input.nml
            echo '#override COORD_CONFIG = "linear"' >> MOM_override
            echo 'DENSITY_RANGE = 2.0' >> MOM_override

            if [[ ${mode} == "cpu" ]] ; then
                # calculate number of processors needed to make sure each processor runs 32x32 scale cells
                num_procs=$(( ${scale} **2 ))
                echo -e "\t $0: Using ${num_procs} processors"

                # Blocking clocks, if desired
                sed -i "s/clock_flags='NONE'/clock_flags='SYNC'/" input.nml

                # INTEL
                sbatch --ntasks=${num_procs} --partition=cimes --nodes=1 --sockets-per-node=1 --oversubscribe --output="job_output_files/${name}_%j.job" --job-name="${name}" --time=1:00:00 --wrap="source /scratch/cimes/uw4770/MOM6-examples/build/ocean_only_cpu/linux-intel.env ; srun -n ${num_procs} /scratch/cimes/uw4770/MOM6-examples/build/ocean_only_cpu/MOM6"

            else
                # Current gpu baseline based on ED's small imporvements branch
                sbatch -A gfdlport -p u1-h100 -q gpuwf --mem-per-gpu=40G --ntasks=1 --output="job_output_files/${name}_%j.job" --job-name="${name}"  --gres=gpu:h100:1 --time=1:00:00 --wrap="source /home/Utheri.Wagura/MOM6-examples/ocean_only/double_gyre/runtime_env.sh ; srun -n 1 /home/Utheri.Wagura/MOM6-examples/ocean_only/build_gpu_small_improvements_O2/MOM6"

            fi
            cd ..
            echo -e "\n"
            sleep 2
        done 
    done
done

