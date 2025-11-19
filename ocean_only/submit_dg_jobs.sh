#!/bin/bash

for mode in gpu cpu ; do 
    for depth in 10 ; do
        for grid in 32 64 96 128 160 192 224 256 288 ; do
            # Generate name of experiment
            name="dg_${grid}x${grid}x${depth}_${mode}"

            if [[ ${mode} == "cpu" ]] ; then 
                 name="${name}_O0_jik_all_but_coef"
                 #name="${name}_O0"
            else
                 name="${name}_O0_recompiled"
            fi
            echo "Working on ${name}, ${grid}x${grid}x${depth} case" 
            
            # Copy dg into new dir named after experiment
            cp -r double_gyre/ ${name}

            # cd into that dir, set up and submit run
            cd ${name}
            ./setup_new_run.sh ${grid} ${depth}

            if [[ ${mode} == "cpu" ]] ; then 
                # calculate number of processors needed to make sure each processor runs 32x32 grid cells
                num_procs=$(( (${grid} / 32) **2 ))
                echo -e "\t $0: Using ${num_procs} processors"

                # Update domains_stack_size to prevent memory issues:
                sed -i 's/&fms_nml/&\n    domains_stack_size = 320000/' input.nml

                sbatch --ntasks=${num_procs} --output="job_output_files/${name}_%j.job" --job-name="${name}" --time=1:00:00 --wrap="source /scratch/cimes/uw4770/MOM6-examples/build/ocean_only_cpu/linux-intel.env ; srun -n ${num_procs} /scratch/cimes/uw4770/MOM6-examples/build/ocean_only_cpu/MOM6" 
            else

                sbatch --nodes=1 --output="job_output_files/${name}_%j.job" --job-name="${name}"  --gres=gpu:1 --time=01:00:00 --wrap="source /scratch/cimes/uw4770/MOM6-examples/build/fms_nv/linux-nvidia.env ; srun -n 1 /scratch/cimes/uw4770/MOM6-examples-gpu/ocean_only/build_gpu_jik_vertvisc_nvfortran_O0/MOM6" 

            fi
            cd ..
            echo -e "\n"
            sleep 2
        done done done
