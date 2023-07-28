#include <cuda.h>
#include <stdio.h>
#include <stdlib.h>
#include "deviceQuery.h"
#include <tuple>

constexpr int WarpsStart = 1;
constexpr int WarpsEnd = 32768;   // maxium number of warps on GPU

constexpr int ThreadsPerWarp = 32;
constexpr int IterCount = 1024;   // number of iterations of pointer chasing per thread.


constexpr int ThreadsMax = WarpsEnd * ThreadsPerWarp;
// maximum size of pointer-chasing array. 32 * 1024 * 32768 = 1GB
// Make sure ArraySizeMax > 2 * L2_SIZE 
constexpr uint64_t ArraySizeMax = IterCount * ThreadsPerWarp * WarpsEnd; 

constexpr int MaxWarpPerBlock = 32;


struct Param_Struct {
  Param_Struct() {
    startClk = (uint32_t *)malloc(WarpsEnd * sizeof(uint32_t));
    stopClk = (uint32_t *)malloc(WarpsEnd * sizeof(uint32_t));
    dsink = (uint64_t *)malloc(WarpsEnd * sizeof(uint64_t));

    gpuErrchk(cudaMalloc(&startClk_g, WarpsEnd * sizeof(uint32_t)));
    gpuErrchk(cudaMalloc(&stopClk_g, WarpsEnd * sizeof(uint32_t)));
    gpuErrchk(cudaMalloc(&dsink_g, WarpsEnd * sizeof(uint64_t)));
  }

  ~Param_Struct() {
    free(startClk);
    free(stopClk);
    free(dsink);

    gpuErrchk(cudaFree(startClk_g));
    gpuErrchk(cudaFree(stopClk_g));
    gpuErrchk(cudaFree(dsink_g));
  }

  void memcpyd2h() {
    gpuErrchk(cudaMemcpy(startClk, startClk_g, WarpsEnd * sizeof(uint32_t),
                         cudaMemcpyDeviceToHost));
    gpuErrchk(cudaMemcpy(stopClk, stopClk_g, WarpsEnd * sizeof(uint32_t),
                         cudaMemcpyDeviceToHost));
    gpuErrchk(cudaMemcpy(dsink, dsink_g, WarpsEnd * sizeof(uint64_t),
                          cudaMemcpyDeviceToHost));
  }
  uint32_t getDuration(){
    uint32_t duration = 0;
    for(int i = 0; i < WarpsEnd; i++)
    {
      uint32_t temp = stopClk[i] - startClk[i];
      if(temp > duration)
        duration = temp;
    }
    return duration;
  }

  uint32_t *startClk;
  uint32_t *stopClk;
  uint64_t *dsink;

  uint32_t *startClk_g;
  uint32_t *stopClk_g;
  uint64_t *dsink_g;
};

__global__ void mem_lat(uint64_t *pointer_chasing_array, uint32_t *startClk_g, uint32_t *stopClk_g, uint64_t *dsink_g) {
  // thread index
  uint32_t tid = threadIdx.x + threadIdx.y * blockDim.x;
  uint32_t uid = blockIdx.x * blockDim.x * blockDim.y + tid;
  uint32_t wid = uid / ThreadsPerWarp;

  uint64_t ptr = (uint64_t)pointer_chasing_array + uid * sizeof(uint64_t); 
  uint64_t ptr1 = 0, ptr0 = 0;

  uint32_t start = 0;
  // start timing
  asm volatile("mov.u32 %0, %%clock;" : "=r"(start)::"memory");

  // initialize the pointers with the start address
  // Here, we use cache volatile modifier to ignore the L2 cache
  // TODO on Ampere it seems .cv modifier is not effective
  asm volatile("{\t\n"
                "ld.global.cv.u64 %0, [%1];\n\t"
                "}"
                : "=l"(ptr1)
                : "l"(ptr)
                : "memory");

  // pointer-chasing IterCount times
  // Here, we use cache volatile modifier to ignore the L2 cache
  for (uint32_t i = 0; i < IterCount - 1; i++) {
    asm volatile("{\t\n"
                  "ld.global.cv.u64 %0, [%1];\n\t"
                  "}"
                  : "=l"(ptr0)
                  : "l"(ptr1)
                  : "memory");
    ptr1 = ptr0; // swap the register for the next load
    // if(uid == 0) printf("Step %d\n", i);
    // printf("uid = %d, ptr0 = %lx, ptr1 = %lx\n", uid, ptr0, ptr1);
  }
  // TODO bar.sync is used to avoid compiler rearranging the move clock before ld.global. If there other ways to do this?
  // synchronize all threads
  asm volatile("bar.sync 0;");

  uint32_t stop = 0;
  // stop timing
  asm volatile("mov.u32 %0, %%clock;" : "=r"(stop)::"memory");

  // write time and data back to memory
  if(uid % ThreadsPerWarp == 0)
  {
    // printf("uid = %d, start = %u, stop = %u\n", uid, start, stop);
    startClk_g[wid] = start;
    stopClk_g[wid] = stop;
    dsink_g[wid] = ptr1;
  }
}

// TODO this function has bug. It is replaced by CPU initialization
// Initialize pointer chasing array of ArraySizeMax in global memory with ThreadsMax threads
// __global__ void initPointerArray(uint64_t * array)
// {
//   // thread index
//   uint32_t tid = threadIdx.x + threadIdx.y * blockDim.x;
//   uint32_t uid = blockIdx.x * blockDim.x * blockDim.y + tid;
//   // initialize pointer-chasing array by CPU to avoid messing up nsight-compute counters

//   for(int i = 0; i < (IterCount - 1); i += 1)
//     array[i * ThreadsMax + uid] = (uint64_t)array + (i + ThreadsMax) * sizeof(uint64_t);
//   array[(IterCount - 1) * ThreadsMax + uid] = (uint64_t)array + uid * sizeof(uint64_t);
// }

template <int NumWarps>
void measureMemLat (Param_Struct & param) {
  unsigned array_size =  ArraySizeMax; 
  uint64_t *pointer_chasing_array_g;
  gpuErrchk(cudaMalloc(&pointer_chasing_array_g, array_size * sizeof(uint64_t)));

  // initPointerArray<<<WarpsEnd/MaxWarpPerBlock, ThreadsPerWarp * MaxWarpPerBlock>>>(pointer_chasing_array_g);
  // gpuErrchk(cudaPeekAtLastError());

  // initialize pointer-chasing array by CPU to avoid messing up nsight-compute counters
  uint64_t * pointer_chasing_array = (uint64_t *)malloc(array_size * sizeof(uint64_t));
  for (uint32_t i = 0; i < (array_size - ThreadsMax); i += 1)
    pointer_chasing_array[i] = (uint64_t)pointer_chasing_array_g + (i + ThreadsMax) * sizeof(uint64_t);
  // initialize the tail to reference to the head of the array
  for (uint32_t i = (array_size - ThreadsMax); i < array_size; i += 1)
    pointer_chasing_array[i] = (uint64_t)pointer_chasing_array_g + (i - (array_size - ThreadsMax)) * sizeof(uint64_t);
  gpuErrchk(cudaMemcpy(pointer_chasing_array_g, pointer_chasing_array, array_size * sizeof(uint64_t),
                       cudaMemcpyHostToDevice));
    
  // kernel launch
  dim3 grid(NumWarps > MaxWarpPerBlock ? NumWarps / MaxWarpPerBlock : 1);
  dim3 block(ThreadsPerWarp, NumWarps > MaxWarpPerBlock ? MaxWarpPerBlock : NumWarps);

  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);
  cudaEventRecord(start);
  mem_lat<<<grid, block>>>(pointer_chasing_array_g, param.startClk_g, param.stopClk_g, param.dsink_g);

  gpuErrchk(cudaPeekAtLastError());
  cudaEventRecord(stop);
  cudaEventSynchronize(stop);
  float milliseconds = 0;
  cudaEventElapsedTime(&milliseconds, start, stop);
  
  param.memcpyd2h();

  float lat = (float)(param.getDuration()) / (float)(IterCount);
  float bw = (float)(IterCount * NumWarps * ThreadsPerWarp * sizeof(uint64_t)) / (float)(milliseconds * 1e6);
  int outstanding_bytes = NumWarps * ThreadsPerWarp * sizeof(uint64_t);
  printf("%d,%f,%f\n", outstanding_bytes, lat, bw);
  // printf("INFO: Measuring memory latency with %d warps\n", NumWarps); 
  // printf("Mem latency = %12.4f cycles \n", lat);
  // printf("Kernel time = %f ms\n", milliseconds);
  // printf("Mem Bandwidth = %f GB/s \n", bw);
  // printf("Clk number per Warp= %u \n", param.getDuration());
  gpuErrchk(cudaFree(pointer_chasing_array_g));
  free(pointer_chasing_array);
}

template <int NumWarps>
struct MemLatFunction {
  static void call(Param_Struct &param) {
    measureMemLat<NumWarps>(param);
  }
};


template <int WarpsStart, int WarpsEnd>
struct GenerateMemLat {
  static auto generate() {
    if constexpr (WarpsStart < WarpsEnd) {
          return std::tuple_cat(
              std::tuple<void (*)(Param_Struct &)>{
                &MemLatFunction<WarpsStart>::call},
              GenerateMemLat<WarpsStart * 2, WarpsEnd>::generate());
    } else {
      return std::tuple<>();
    }
  }
};

template <typename... Functions, std::size_t... Is>
void callAllFunctionsImpl(const std::tuple<Functions...> &functionList,
                          Param_Struct &param,
                          std::index_sequence<Is...>) {
  ((std::get<Is>(functionList))(param), ...);
}

template <typename... Functions>
void callAllFunctions(const std::tuple<Functions...> &functionList,
                      Param_Struct &param) {
  callAllFunctionsImpl(functionList, param,
                       std::index_sequence_for<Functions...>{});
}

int main() {

  intilizeDeviceProp(0);
  Param_Struct param;
  auto functionList = GenerateMemLat<WarpsStart, WarpsEnd>::generate();
  printf("OutstandingRequests(B),Latency(ns),Bandwidth(GB/s)\n");
  callAllFunctions(functionList, param);

  return 0;
}
