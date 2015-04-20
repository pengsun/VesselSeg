#include "mex.h"
#include "util3d.hpp"

static const int K = 27;

// yy = get_y_g27s2(mk, ind)
//   mk: [a,b,c]. 255: vessels, 128: background, 0: not interested
//   ind: [M] linear index to the mk
//   yy: [27, M] each elem, 0/1 bg/fg response
void mexFunction(int no, mxArray       *vo[],
                 int ni, mxArray const *vi[])
{
  //// Input
  mxArray const *mk  = vi[0];
  mxArray const *ind = vi[1];
  

  ///// Create Output
  int M = mxGetM(ind) * mxGetN(ind);
  mwSize dims[2];
  dims[0] = K;
  dims[1] = M;
  mxArray *yy = mxCreateNumericArray(2, dims, mxSINGLE_CLASS, mxREAL);


  //// do the job
  uint8_T *p_mk = (uint8_T*) mxGetData(mk);
  const mwSize *sz_mk;
  sz_mk = mxGetDimensions(mk);

  double *p_ind = (double*) mxGetData(ind);
  float  *p_yy  = (float*) mxGetData(yy); 

  // iterate over center points
  #pragma omp parallel for
  for (int m = 0; m < M; ++m) {
    // get the center point
    int ixcen = int( *(p_ind + m) );
    int pntcen[3];
    ix2pnt(sz_mk, ixcen, pntcen);

    // manually set the K (=27) points
    int tmpl[3] = {-2, 0, 2}; // the offset template
    int cnt = 0;              // count, 0,...,26
    for (int i = 0; i < 2; ++i) {
      for (int j = 0; j < 2; ++j) {
        for (int k = 0; k < 2; ++k) {
          // the working offset
          int d[3]; 
          d[0] = tmpl[i]; d[1] = tmpl[j]; d[2] = tmpl[k];
          // value on mask
          uint8_T val; 
          get_val_from_offset(p_mk, sz_mk, pntcen, d,  val);
          // the 
          *(p_yy + cnt + m*K) = (val==255)? 1.0 : 0.0; // 255: fore ground, set 1; otherwise: set 0
          ++cnt;
        } // for k
      } // for j
    } // for i

  } // for m


  //// Set output
  vo[0] = yy;

  return;
}