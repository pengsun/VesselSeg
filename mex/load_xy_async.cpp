#include "mex.h"
#include "mat.h"
#include <thread>

using namespace std;


static thread worker;
static mxArray *X = 0;
static mxArray *Y = 0;

void read_X_Y (const char *fn);
void clear_buf();

void load_mat (const char * fn) 
{
  mexPrintf("In load_mat\n");

  if (worker.joinable()) { // wait until last loading finishes...
    worker.join(); 
    mexPrintf("wait until last reading done\n");
  }

  // clean the buffer
  clear_buf();

  // begin a new thread to load the variables
  thread t(read_X_Y, fn);

  // return immediately
  worker = move(t);
}

void pop_buf (mxArray* &xx, mxArray* &yy) {
  mexPrintf("In pop_buf\n");
  if (worker.joinable()) 
    worker.join();

  // pop them
  mexPrintf("deep copy\n");
  xx = mxDuplicateArray(X);
  yy = mxDuplicateArray(Y);
}

void clear_buf () 
{
  mexPrintf("In clear_buf\n");
  mxDestroyArray(X);
  mxDestroyArray(Y);
}


void read_X_Y (const char *fn) {
  mexPrintf("In read_X_Y\n");
  // TODO: need a lock here?


  mexPrintf("open mat\n");
  MATFile *h = matOpen(fn, "r");

  mexPrintf("read X, Y\n");
  X = matGetVariable(h, "X"); // TODO: check 
  Y = matGetVariable(h, "Y");

  mexPrintf("close mat\n");
  matClose(h);

  mexPrintf("make persistence buffer X, Y\n");
  mexMakeArrayPersistent(X);
  mexMakeArrayPersistent(Y);
}

void on_exit ()
{
  mexPrintf("In on_exit\n");

  clear_buf();
  worker.~thread();
}


// load_xy_async(fn_mat); loads the the mat file with name fn_mat in a separate thread and returns immediately
// [X,Y] = load_xy_async(); loads the X, Y from buffer 
void mexFunction(int no, mxArray       *vo[],
                 int ni, mxArray const *vi[])
{
  // load_xy_async(fn_mat): load mat file and return immediately
  if (ni==1) {
    // get the file name 
    int buflen = mxGetN(vi[0])*sizeof(mxChar)+1;
    char *filename  = (char*)mxMalloc(buflen);
    mxGetString(vi[0], filename, buflen); // TODO: check status

    // begin loading and return 
    load_mat(filename);
    mexAtExit( on_exit );
    return;
  }

  // [X,Y] = load_xy_async():  loads the X, Y from buffer
  if (ni==0) {
    pop_buf(vo[0], vo[1]);
    return;
  }

  mexErrMsgTxt("Incorrect calling arguments\n.");
  return;
}