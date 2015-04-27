#include "mex.h"
#include "mat.h"
#include <thread>
#include <mutex>

using namespace std;

#ifdef VB
  #define LOGMSG mexPrintf
#else
  #define LOGMSG(...)
#endif // VB


// "member" variables
static thread  worker;
static mxArray *X = 0;
static mxArray *Y = 0;
static char    filename[2048];

// "member" functions
void read_X_Y ();

void clear_buf();

void load_mat () 
{
  LOGMSG("In load_mat\n");

  if (worker.joinable()) { // wait until last loading finishes...
    worker.join(); 
    LOGMSG("wait until last reading done\n");
  }

  // clean the buffer
  clear_buf();

  // begin a new thread to load the variables
  thread t(read_X_Y);

  // return immediately
  worker = move(t);

  LOGMSG("Out load_mat\n");
}

void pop_buf (mxArray* &xx, mxArray* &yy) {
  LOGMSG("In pop_buf\n");

  if (worker.joinable()) {
    LOGMSG("wait until buffer filled\n");
    worker.join();
  }

  // pop them
  LOGMSG("deep copy\n");

  mutex mm;
  mm.lock();

  LOGMSG("copy X\n");
  xx = mxDuplicateArray(X);

  LOGMSG("copy Y\n");
  yy = mxDuplicateArray(Y);

  mm.unlock();

  LOGMSG("Out pop_buf\n");
}

void clear_buf () 
{
  LOGMSG("In clear_buf\n");

  mutex mm;
  mm.lock();

  if (X!=0) {
    LOGMSG("clear X\n");
    mxDestroyArray(X);
    X = 0;
  }


  if (Y!=0) {
    LOGMSG("clear Y\n");
    mxDestroyArray(Y);
    Y = 0;
  }

  mm.unlock();

  LOGMSG("Out clear_buf\n");
}

void read_X_Y () {
  mutex mut;
  mut.lock();

  LOGMSG("In read_X_Y\n"); 

  LOGMSG("open mat %s\n", filename); 
  MATFile *h = matOpen(filename, "r");

  LOGMSG("loading X from mat\n"); 
  X = matGetVariable(h, "X"); // TODO: check 

  LOGMSG("make persistence buffer X\n"); 
  mexMakeArrayPersistent(X);

  LOGMSG("close mat %s\n", filename); 
  matClose(h);

  LOGMSG("open mat %s\n", filename); 
  h = matOpen(filename, "r");

  LOGMSG("loading Y from mat\n"); 
  Y = matGetVariable(h, "Y");

  LOGMSG("make persistence buffer Y\n"); 
  mexMakeArrayPersistent(Y);

  LOGMSG("close mat %s\n", filename); 
  matClose(h);

  LOGMSG("Out read_X_Y\n"); 

  mut.unlock();
}

void on_exit ()
{
  LOGMSG("In on_exit\n");

  if (worker.joinable()) {
    LOGMSG("wait untial last reading done\n");
    worker.join();
  }

  clear_buf();

  // need this, or not?
  // worker.~thread();

  LOGMSG("Out on_exit\n");
}


// load_xy_async(fn_mat); loads the the mat file with name fn_mat in a separate thread and returns immediately
// [X,Y] = load_xy_async(); loads the X, Y from buffer 
void mexFunction(int no, mxArray       *vo[],
                 int ni, mxArray const *vi[])
{
  // load_xy_async(fn_mat): load mat file and return immediately
  if (ni==1) {
    LOGMSG("In ni==1\n");

    if (worker.joinable()) { // wait until last loading finishes...
      worker.join(); 
      LOGMSG("wait until last reading done\n");
    }
    
    mutex mx;
    mx.lock();
    // get the file name 
    int buflen = mxGetN(vi[0])*sizeof(mxChar)+1;
    //char *filename  = (char*)mxMalloc(buflen);
    
    mxGetString(vi[0], filename, buflen); // TODO: check status
    mx.unlock();

    // begin loading and return 
    load_mat();
    mexAtExit( on_exit );

    LOGMSG("Out ni==1\n");
    return;
  }

  // [X,Y] = load_xy_async():  loads the X, Y from buffer
  if (ni==0) {
    LOGMSG("In ni==0\n");

    pop_buf(vo[0], vo[1]);

    LOGMSG("Out ni==0\n");
    return;
  }

  mexErrMsgTxt("Incorrect calling arguments\n.");
  return;
}