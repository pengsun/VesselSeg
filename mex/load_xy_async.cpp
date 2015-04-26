#include "mex.h"
#include "mat.h"
#include <thread>

using namespace std;

void read_X_Y (const char *fn,  mxArray** X, mxArray** Y) {
  // TODO: need a lock here?
  MATFile *h = matOpen(fn, "r");
  *X = matGetVariable(h, "X"); // TODO: check 
  *Y = matGetVariable(h, "Y");
  matClose(h);

  mexMakeArrayPersistent(*X);
  mexMakeArrayPersistent(*Y);
}

struct mat_loader {
  thread worker;  
  mxArray *X, *Y;

  mat_loader () {
    X = mxCreateDoubleMatrix(0,0,mxREAL);
    Y = mxCreateDoubleMatrix(0,0,mxREAL);
  }

  void load (const char * fn) {
    // clean the buffer
    clear_buf();

    // begin a new thread to load the variables
    thread t(read_X_Y,  fn, &(this->X), &(this->Y));

    // return immediately
    this->worker = move(t);
  }

  void pop_buf (mxArray* &X, mxArray* &Y) {
    if (worker.joinable()) 
      worker.join();

    // pop them: do nothing but return them to Matalb who takes the control
    X = this->X;
    Y = this->Y;
  }

  void clear_buf () {
    if (worker.joinable()) // wait until last loading finishes...
      worker.join(); 

    mxDestroyArray(X);
    mxDestroyArray(Y);
  }

};

static mat_loader the_loader;

void on_exit ()
{
  the_loader.clear_buf();
  the_loader.worker.~thread();
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
    char *buf  = mxMalloc(buflen);
    mxGetString(vi[0], buf, buflen); // TODO: check status

    // begin loading and return 
    the_loader.load(buf);
    mexAtExit( on_exit );
    return;
  }

  // [X,Y] = load_xy_async():  loads the X, Y from buffer
  if (ni==0) {
    the_loader.pop_buf(vo[0], vo[1]);
    return;
  }

  mexErrMsgTxt("Incorrect calling arguments\n.");
  return;
}