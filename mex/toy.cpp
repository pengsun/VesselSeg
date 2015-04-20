#include "mex.h"
#include <omp.h>


void mexFunction(int no, mxArray       *vo[],
                 int ni, mxArray const *vi[])
{
  

  int k = 0;
  int b = 3;
  #pragma omp parallel for
  for (int i = 0; i < 75; i++) {

    for (int j = 0; j<3; ++j) {
      mexPrintf("thread %d, count: %d \n", i, i+j);
    }
    mexPrintf("\n");
  }


  k = 4;
  b = k + 2;
  for (int i = 0; i < 75; i++) {

    for (int j = 0; j<3; ++j) {
      mexPrintf("thread %d, count: %d \n", i, i+j);
    }
    mexPrintf("\n");
  }

  return;
}