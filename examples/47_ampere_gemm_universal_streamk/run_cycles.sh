#!/bin/bash

# Define the range of values for 'target_iter' and 'num_stage'
target_iter_values=()
for i in {0..20}; do
  target_iter_values+=("$i")
done
num_stage_values=(3 4 5 6)

mma_file_locate="/home/yujin/workspace/cutlass/include/cutlass/gemm/threadblock/mma_multistage.h"
test_file_locate="/home/yujin/workspace/cutlass/examples/47_ampere_gemm_universal_streamk/ampere_gemm_universal_streamk.cu"

binary_name="47_ampere_gemm_universal_streamk"
binary_dir="/home/yujin/workspace/cutlass/build/examples/47_ampere_gemm_universal_streamk"

thread_block_size="64_64_32"

M=4096
N=4096
K=4096
SPLIT_K=1

args="--m=$M --n=$N --k=$K --split=$SPLIT_K --iterations=10"

NCU="/opt/nvidia/nsight-compute/2023.1.0/ncu"

cd $binary_dir

# Loop over 'num_stage' values
for num_stage in "${num_stage_values[@]}"; do
  file_name=$M-$N-$K-$num_stage-start.txt
    touch $file_name
    # Loop over 'target_iter' values
    for target_iter in "${target_iter_values[@]}"; do
        # Use 'sed' to locate the 'constexpr' lines and replace their values
        sed -i "s/constexpr int target_iter = [0-9]\+;/constexpr int target_iter = $target_iter;/" $mma_file_locate
        sed -i "s/constexpr int NumStages   = [0-9]\+;/constexpr int NumStages   = $num_stage;/" $test_file_locate

        # Compile the modified files
        make $binary_name > /dev/null

        # Run the program with the current values
        echo "Running with target_iter = $target_iter, NumStages = $num_stage"
        # $NCU --target-processes all ./${binary_name} $args > tmp.txt
        ./${binary_name} $args > tmp.txt
        awk '/^diff: /{sum+=$2; count++} END{print sum/count","}' tmp.txt | tee -a $file_name
    done
done
