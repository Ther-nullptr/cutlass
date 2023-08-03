#!/bin/bash 
# B=1
# M=4096
# N=4096
# K=4096
# SPLIT_K=1
B=32
M=2048
N=128
K=8192
BLOCK_M=64
BLOCK_N=64
BLOCK_K=32
GROUP_M=8
NUM_STAGES=10
NUM_WARPS=4

#exec_name=/home/yujin/workspace/cutlass/build/examples/47_ampere_gemm_universal_streamk/47_ampere_gemm_universal_streamk 
exec_name="python /home/yujin/workspace/triton/python/tutorials/03-2-batched-matrix-multiplication-ncu-profiling.py"
#args="--m=$M --n=$N --k=$K --split=$SPLIT_K"
args="--b $B --m $M --n $N --k $K --block-m $BLOCK_M --block-n $BLOCK_N --block-k $BLOCK_K --group-m $GROUP_M --num-stages $NUM_STAGES --num-warps $NUM_WARPS"

# list method: ncu --query-metrics | grep sm__sass_inst_executed_op
# extract method: ncu --query-metrics | grep sm__sass_inst_executed_op | sed 's/^\([^[:blank:]]*\).*/\1,/'
# ncu --query-metrics | grep sm__inst_executed | sed 's/^\([^[:blank:]]*\).*/\1,/'
# ncu --query-metrics | grep sm__sass_data_bytes | sed 's/^\([^[:blank:]]*\).*/\1,/'
metrics="l1tex__t_sectors_pipe_lsu_mem_global_op_ld,\
lts__t_sectors_aperture_device,\
dram__bytes_read.sum.per_second,\
l1tex__m_xbar2l1tex_read_bytes.sum.per_cycle_active,\
l1tex__m_xbar2l1tex_read_bytes.sum.pct_of_peak_sustained_active,\
l1tex__m_xbar2l1tex_read_bytes.sum.peak_sustained,\
l1tex__m_xbar2l1tex_read_bytes.sum.per_second,\
lts__t_sector_hit_rate.pct,\
launch__waves_per_multiprocessor"

# --mode=launch --metrics $metrics
/opt/nvidia/nsight-compute/2023.1.0/ncu --target-processes all --metrics $metrics $exec_name $args
