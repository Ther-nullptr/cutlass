#!/bin/bash 

M=4096
N=4096
K=4096
SPLIT_K=1

exec_name=/home/yujin/workspace/cutlass/build/examples/47_ampere_gemm_universal_streamk/47_ampere_gemm_universal_streamk 
args="--m=$M --n=$N --k=$K --split=$SPLIT_K"

# list method: ncu --query-metrics | grep sm__sass_inst_executed_op
# extract method: ncu --query-metrics | grep sm__sass_inst_executed_op | sed 's/^\([^[:blank:]]*\).*/\1,/'
# ncu --query-metrics | grep sm__inst_executed | sed 's/^\([^[:blank:]]*\).*/\1,/'
# ncu --query-metrics | grep sm__sass_data_bytes | sed 's/^\([^[:blank:]]*\).*/\1,/'
metrics="gpc__cycles_elapsed,\
sm__inst_executed_pipe_tensor_op_hmma,\
sm__pipe_tensor_op_hmma_cycles_active,"

metrics+="sm__sass_data_bytes_mem_global_op_ldgsts,\
sm__sass_data_bytes_mem_shared_op_ldgsts,\
sm__sass_inst_executed_op_ldgsts,"

metrics+="l1tex__t_sectors_pipe_lsu_mem_global_op_ld,\
lts__t_sectors_aperture_device,\
dram__bytes_read.sum.per_second,\
sm__sass_l1tex_m_xbar2l1tex_read_bytes_mem_global_op_ldgsts_cache_bypass.sum.per_second,\
lts__t_request_hit_rate.pct,\
lts__t_sector_hit_rate.pct"

# --mode=launch --metrics $metrics
/opt/nvidia/nsight-compute/2023.1.0/ncu  --target-processes all --metrics $metrics $exec_name $args
