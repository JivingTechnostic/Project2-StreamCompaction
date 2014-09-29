#ifndef COMPACTION_H
#define COMPATION_H

void initCuda (int N);
/**
 * Calls an internal function to perform an exclusive prefix sum on the array
**/
void cudaScan (float* in_arr, float* out_arr, int size);
/**
 * Calls an internal function to perform a scatter on the array
**/
void cudaScatter (float* in_arr, float* out_arr, int size);

float* prefixSum (float* arr, int size);

#endif