#include <cuda.h>
#include <iostream>
#include <stdio.h>
#include <Windows.h>
#include "compaction.cuh"

const int size = 65;

float* prefixSum(float* arr, int size);
float* scatter(float* arr, float* temp_arr, float* scan_arr, int size);
void printArray(float* arr, int size);

int main(int argc, char** argv) {

	initCuda(size);
	
	float* arr = new float[size];

	for (int i = 0; i < size; i++) {
		arr[i] = i;
	}
	
	LARGE_INTEGER li;
	QueryPerformanceFrequency(&li);
	double PCFreq = double(li.QuadPart)/1000.0;
	QueryPerformanceCounter(&li);
    __int64 CounterStart = li.QuadPart;

	prefixSum(arr, size);

    QueryPerformanceCounter(&li);
    double time = double(li.QuadPart-CounterStart)/PCFreq;
	printArray(prefixSum(arr, size), size);

	//float time;
	std::cout << "cudaCPUTime for size " << size << " was " << time << "ms" << std::endl;

	float* arr_gpu = new float[size];
	
	cudaScan(arr, arr_gpu, size);
	printArray(arr_gpu, size);
	int a;
	std::cin>>a;
}

float* prefixSum (float* arr, int size) {
	if (size < 1) {
		return NULL;
	}

	float* scan_arr = new float[size];

	scan_arr[0] = 0;

	for (int i = 1; i < size; i++) {
		scan_arr[i] = scan_arr[i-1] + arr[i-1];
	}
	
	return scan_arr;
}

float* scatter (float* arr, int* temp_arr, int* scan_arr, int size) {
	int c = 0;
	for (int i = 0; i < size; i++) {
		if (temp_arr[i] == 1 && scan_arr[i] > c)
			c = scan_arr[i];
	}
	float* scat_arr = new float[c];

	for (int i = 0; i < size; i++) {
		if (temp_arr[i] == 1) {
			scat_arr[scan_arr[i]] = arr[i];
		}
	}
	return scat_arr;
}

void printArray (float* arr, int size) {
	for (int i = 0; i < size; i++) {
		std::cout << arr[i] << " ";
	}
	std::cout << std::endl;
}
