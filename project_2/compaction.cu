#include "compaction.cuh"
#include <iostream>

int maxThreadsPerBlock = 128;
cudaEvent_t beginEvent;
cudaEvent_t endEvent;

// global calls
void initCuda (int N) {
	cudaEventCreate(&beginEvent);
	cudaEventCreate(&endEvent);
}

__global__ void naive_scan (float* in_arr, float* scan_arr, int size, int depth) {
	int index = threadIdx.x + blockIdx.x * blockDim.x;
	
	int val = 0;

	int in_index = index;

	if (depth == 1) {
		in_index--;
	}

	if (in_index >= 0 && index < size) {
		int exp_2 = 1;
		for (int i = 1; i < depth; i++) {
			exp_2 *= 2;
		}
		val = in_arr[in_index];
		if (in_index >= exp_2) {
			val += in_arr[in_index - exp_2];
		}
	}

	if (index < size) {
		scan_arr[index] = val;
	}
}

__global__ void shared_scan (float* in_arr, float* scan_arr, int size, int depth) {
	__shared__ float in_arr_s1 [1];	//contains the lower numbers
	//__shared__ float in_arr_s2 [blockDim.x];	//contains the higher numbers

	int index = threadIdx.x + blockIdx.x * blockDim.x;

	int exp_2 = 1;
	for (int i = 1; i < depth; i++) {
		exp_2 *= 2;
	}

	float sValue = 0;

	if (index < size) {
		in_arr_s1[index] = in_arr[index];
	}
	__syncthreads();

	int in_index = index;
	if (depth == 1) {
		in_index--;
	}

	if (in_index >= 0 && index < size) {
		sValue += in_arr_s1[in_index];
		if (in_index >= exp_2) {
			sValue += in_arr_s1[in_index - exp_2];
		}
	}
	//in_arr_s2[index] = in_arr[index];
	if (index < size) {
		scan_arr[index] = sValue;
	}
	__syncthreads();
}

void cudaScan (float* in_arr, float* out_arr, int size) {
	int numBlocks = ceil(size/(float)maxThreadsPerBlock);
	int threadsPerBlock = min(size, maxThreadsPerBlock);
	
	float* arr1, * arr2;
	cudaMalloc((void**)&arr1, size*sizeof(float));
	cudaMalloc((void**)&arr2, size*sizeof(float));
	
	float time;
	int max_depth = ceil(log2((float)size));
	cudaMemcpy(arr1, in_arr, size*sizeof(float), cudaMemcpyHostToDevice);
	cudaEventRecord(beginEvent, 0);
	for (int i = 1; i <= max_depth; i++) {	// not sure why it's ceil(log2(size)) but it works.
		shared_scan<<<numBlocks, maxThreadsPerBlock>>>(arr1, arr2, size, i);
		//cudaThreadSynchronize();	// taking these out causes it to fail occasionally.
		float* temp = arr1;
		arr1 = arr2;
		arr2 = temp;
	}
	cudaEventRecord(endEvent, 0);
	cudaEventSynchronize(endEvent);

	cudaEventElapsedTime(&time, beginEvent, endEvent);
	std::cout << "cudaGPUTime for size " << size << " was " << time << "ms" << std::endl;
	

	cudaMemcpy(out_arr, arr1, size*sizeof(float), cudaMemcpyDeviceToHost);
}

__global__ void scatter (float* in_arr, float* temp_arr, float* scan_arr, float* out_arr, int size) {
	int index = threadIdx.x + blockIdx.x * blockDim.x;

	if (index < size && temp_arr[index] == 1) {
		out_arr[(int)scan_arr[index]] = in_arr[index];
	}
}

__global__ void compute (float* in_arr, float* out_arr, int size) {
	//compute this array based on some function
	int index = threadIdx.x + blockIdx.x * blockDim.x;

	out_arr[index] = index % 2;
}

void cudaStreamCompaction (float* in_arr, float* out_arr, int size) {
	int numBlocks = ceil(size/(float)maxThreadsPerBlock);
	int threadsPerBlock = min(size, maxThreadsPerBlock);
	float* temp_arr, *scan_arr;
	float* arr, *compact_arr;

	cudaMalloc((void**)&temp_arr, size*sizeof(int));
	cudaMalloc((void**)&scan_arr, size*sizeof(int));
	cudaMalloc((void**)&arr, size*sizeof(float));
	cudaMalloc((void**)&compact_arr, size*sizeof(float));

	cudaMemcpy(arr, in_arr, size*sizeof(float), cudaMemcpyHostToDevice);

	compute<<<numBlocks, threadsPerBlock>>>(arr, temp_arr, size);
	cudaScan(arr, scan_arr, size);
	scatter<<<numBlocks, threadsPerBlock>>>(arr, temp_arr, scan_arr, out_arr, size);
	
	cudaMemcpy(out_arr, compact_arr, size*sizeof(float), cudaMemcpyDeviceToHost);
}