#!/bin/bash

#! notice to delete the macro of clock
# Define the range of values for 'target_iter' and 'num_stage'
num_stage_values=(3 4 5 6)

mma_file_locate="/home/yujin/workspace/cutlass/include/cutlass/gemm/threadblock/mma_multistage.h"
test_file_locate="/home/yujin/workspace/cutlass/examples/47_ampere_gemm_universal_streamk/ampere_gemm_universal_streamk.cu"

binary_name="47_ampere_gemm_universal_streamk"
binary_dir="/home/yujin/workspace/cutlass/build/examples/47_ampere_gemm_universal_streamk"

M=2048
N=128
K=8192
SPLIT_K=1

args="--m=$M --n=$N --k=$K --split=$SPLIT_K --iterations=1"

NCU="/opt/nvidia/nsight-compute/2023.1.0/ncu"

# metrics="gpc__cycles_elapsed,\
# sm__inst_executed_pipe_tensor_op_hmma,\
# sm__pipe_tensor_op_hmma_cycles_active,"

# metrics+="sm__sass_data_bytes_mem_global_op_ldgsts,\
# sm__sass_data_bytes_mem_shared_op_ldgsts,\
# sm__sass_inst_executed_op_ldgsts,"

metrics="l1tex__t_sectors_pipe_lsu_mem_global_op_ld,\
lts__t_sectors_aperture_device,\
dram__bytes_read.sum.per_second,\
l1tex__m_xbar2l1tex_read_bytes.sum.per_cycle_active,\
l1tex__m_xbar2l1tex_read_bytes.sum.pct_of_peak_sustained_active,\
l1tex__m_xbar2l1tex_read_bytes.sum.peak_sustained,\
l1tex__m_xbar2l1tex_read_bytes.sum.per_second,\
lts__t_sector_hit_rate.pct"

cd $binary_dir

# Loop over 'num_stage' values
for num_stage in "${num_stage_values[@]}"; do
    sed -i "s/constexpr int NumStages   = [0-9]\+;/constexpr int NumStages   = $num_stage;/" $test_file_locate
    # Compile the modified files
    make $binary_name > /dev/null
    # Run the program with the current values
    echo "Running with NumStages = $num_stage"
    # $NCU --target-processes all ./${binary_name} $args # | egrep -n "Block Limit Registers|Block Limit Shared Mem|Theoretical Occupancy|Achieved Occupancy|Waves Per SM"
    $NCU --target-processes all --metrics $metrics ./${binary_name} $args
done
