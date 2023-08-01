#!/bin/bash

#! notice to delete the macro of clock
# Define the range of values for 'target_iter' and 'num_stage'
target_iter_values=()
for i in {0..1}; do
  target_iter_values+=("$i")
done
num_stage_values=(3 4 5 6)

mma_file_locate="/home/yujin/workspace/cutlass/include/cutlass/gemm/threadblock/mma_multistage.h"
test_file_locate="/home/yujin/workspace/cutlass/examples/47_ampere_gemm_universal_streamk/ampere_gemm_universal_streamk.cu"

binary_name="47_ampere_gemm_universal_streamk"
binary_dir="/home/yujin/workspace/cutlass/build/examples/47_ampere_gemm_universal_streamk"

NCU="/opt/nvidia/nsight-compute/2023.1.0/ncu"

cd $binary_dir

# Loop over 'num_stage' values
for num_stage in "${num_stage_values[@]}"; do
    for target_iter in "${target_iter_values[@]}"; do
        echo "Running with NumStages = $num_stage, target_iter = $target_iter"
        sed -i "s/constexpr int target_iter = [0-9]\+;/constexpr int target_iter = $target_iter;/" $mma_file_locate
        sed -i "s/constexpr int NumStages   = [0-9]\+;/constexpr int NumStages   = $num_stage;/" $test_file_locate
        # Compile the modified files
        make $binary_name > /dev/null
        cuobjdump -sass ./${binary_name} > stage_clock_stage_${num_stage}_target_iter_${target_iter}_2.sass
    done
done
