#include "mex.h"
#include "mat.h"
#include <thread>
#include <mutex>

using namespace std;


static thread  worker;
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

  mexPrintf("Out load_mat\n");
}

void pop_buf (mxArray* &xx, mxArray* &yy) {
  mexPrintf("In pop_buf\n");

  if (worker.joinable()) {
    mexPrintf("wait until buffer filled\n");
    worker.join();
  }

  // pop them
  mexPrintf("deep copy\n");

  mutex mm;
  mm.lock();

  mexPrintf("copy X\n");
  xx = mxDuplicateArray(X);

  mexPrintf("copy Y\n");
  yy = mxDuplicateArray(Y);

  mm.unlock();

  mexPrintf("Out pop_buf\n");
}

void clear_buf () 
{
  mexPrintf("In clear_buf\n");

  mutex mm;
  mm.lock();

  mexPrintf("clear X\n");
  mxDestroyArray(X);

  mexPrintf("clear Y\n");
  mxDestroyArray(Y);
  mm.unlock();

  mexPrintf("Out clear_buf\n");
}


void read_X_Y (const char *fn) {
  mexPrintf("In read_X_Y\n");
  // TODO: need a lock here?
  mutex mut;
  mut.lock();

  mexPrintf("open mat\n");
  MATFile *h = matOpen(fn, "r");

  mexPrintf("load X, Y from mat\n");
  X = matGetVariable(h, "X"); // TODO: check 
  Y = matGetVariable(h, "Y");

  mexPrintf("close mat\n");
  matClose(h);

  mexPrintf("make persistence buffer X, Y\n");
  mexMakeArrayPersistent(X);
  mexMakeArrayPersistent(Y);

  mut.unlock();
  mexPrintf("Out read_X_Y\n");
}

void on_exit ()
{
  mexPrintf("In on_exit\n");

  clear_buf();
  worker.~thread();

  mexPrintf("Out on_exit\n");
}


// load_xy_async(fn_mat); loads the the mat file with name fn_mat in a separate thread and returns immediately
// [X,Y] = load_xy_async(); loads the X, Y from buffer 
void mexFunction(int no, mxArray       *vo[],
                 int ni, mxArray const *vi[])
{
  // load_xy_async(fn_mat): load mat file and return immediately
  if (ni==1) {
    mexPrintf("In ni==1\n");

    // get the file name 
    int buflen = mxGetN(vi[0])*sizeof(mxChar)+1;
    char *filename  = (char*)mxMalloc(buflen);
    mxGetString(vi[0], filename, buflen); // TODO: check status

    // begin loading and return 
    load_mat(filename);
    mexAtExit( on_exit );

    mexPrintf("Out ni==1\n");
    return;
  }

  // [X,Y] = load_xy_async():  loads the X, Y from buffer
  if (ni==0) {
    mexPrintf("In ni==0\n");

    pop_buf(vo[0], vo[1]);

    mexPrintf("Out ni==0\n");
    return;
  }

  mexErrMsgTxt("Incorrect calling arguments\n.");
  return;
}