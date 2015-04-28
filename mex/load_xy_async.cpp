#include "mex.h"
#include "mat.h"

#include <thread>
#include <mutex>
#include <condition_variable>

using namespace std;


//// for debugging output
#ifdef VB
  #define LOGMSG mexPrintf
#else
  #define LOGMSG(...)
#endif // VB


//// mat loader: the worker
struct loader {
  // thread stuff
  condition_variable cv_buf;
  mutex              mt_buf;
  bool               is_bufReady;
  // mat file stuff
  mxArray *X;
  mxArray *Y;
  char    filename[2048];

  loader () {
    X = Y = 0;
    is_bufReady = true;
  }

  void load_mat () 
  {
    LOGMSG("In load_mat\n");

    // begin a new thread to load the variables
    thread t( &loader::read_X_Y, this );

    // return immediately
    t.detach();

    LOGMSG("Out load_mat\n");
  }

  void pop_buf (mxArray* &xx, mxArray* &yy) {
    LOGMSG("In pop_buf\n");

    unique_lock<mutex> lock_buf(mt_buf);
    while (!is_bufReady) {
      LOGMSG("pop_buf: wait until last reading done\n");
      cv_buf.wait(lock_buf);
    }

    // pop them
    LOGMSG("pop_buf: deep copy\n");

    LOGMSG("pop_buf: copy X %p\n", X);
    xx = mxDuplicateArray(X);
    LOGMSG("pop_buf: output xx %p\n", xx);

    LOGMSG("pop_buf: copy Y %p\n", Y);
    yy = mxDuplicateArray(Y);
    LOGMSG("pop_buf: output yy %p\n", yy);

    LOGMSG("Out pop_buf\n");
  }

  void clear_buf () 
  {
    LOGMSG("In clear_buf\n");

    if (X!=0) {
      LOGMSG("clear_buf: clear X %p\n", X);
      mxDestroyArray(X);
      X = 0;
    }

    if (Y!=0) {
      LOGMSG("clear_buf: clear Y %p\n", Y);
      mxDestroyArray(Y);
      Y = 0;
    }

    LOGMSG("Out clear_buf\n");
  }

  void read_X_Y () {
    LOGMSG("In read_X_Y\n"); 

    unique_lock<mutex> lock_buf(mt_buf);
    while (!is_bufReady) {
      LOGMSG("read_X_Y: wait until last reading done\n");
      cv_buf.wait(lock_buf);
    }

    // clean the buffer
    clear_buf();

    LOGMSG("read_X_Y: Set bufReady false\n"); 
    is_bufReady = false;

    LOGMSG("read_X_Y: open mat %s\n", filename); 
    MATFile *h = matOpen(filename, "r");

    LOGMSG("read_X_Y: loading X from mat\n"); 
    X = matGetVariable(h, "X"); // TODO: check 
    LOGMSG("read_X_Y: loaded %p\n", X);

    LOGMSG("read_X_Y: make persistence buffer X\n"); 
    mexMakeArrayPersistent(X);

    LOGMSG("read_X_Y: close mat %s\n", filename); 
    matClose(h);

    LOGMSG("read_X_Y: open mat %s\n", filename); 
    h = matOpen(filename, "r");

    LOGMSG("read_X_Y: loading Y from mat\n"); 
    Y = matGetVariable(h, "Y");
    LOGMSG("read_X_Y: loaded %p\n", Y);

    LOGMSG("read_X_Y: make persistence buffer Y\n"); 
    mexMakeArrayPersistent(Y);

    LOGMSG("read_X_Y: close mat %s\n", filename); 
    matClose(h);

    LOGMSG("read_X_Y: Set bufReady true\n"); 
    is_bufReady = true;

    cv_buf.notify_all();

    LOGMSG("Out read_X_Y\n"); 
  }

  //void wait_untilBufReady () {
  //  if (!is_bufReady) {
  //    LOGMSG("Wait until buffer ready\n");
  //    int cnt = 0;
  //    while (true) {
  //      if (is_bufReady) 
  //        break;
  //      else {
  //        if ( (cnt % 100000000) == 0 )
  //          LOGMSG("cnt = %d\n", cnt);
  //        cnt++;
  //      }
  //    }
  //  }
  //
  //  return;
  //}

};

//// the mat loader instance
loader the_loader;

void on_exit ()
{
  LOGMSG("In on_exit\n");

  // clean the buffer
  unique_lock<mutex> lock_buf(the_loader.mt_buf);
  while ( ! the_loader.is_bufReady ) {
    LOGMSG("on_exit: wait until last reading done\n");
    the_loader.cv_buf.wait(lock_buf);
  }
  the_loader.clear_buf();

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

    // get the file name 
    int buflen = mxGetN(vi[0])*sizeof(mxChar)+1;
    //char *filename  = (char*)mxMalloc(buflen);
    
    mxGetString(vi[0], the_loader.filename, buflen); // TODO: check status

    // begin loading and return 
    the_loader.load_mat();

    // register the cleanup function
    mexAtExit( on_exit );

    LOGMSG("Out ni==1\n");
    return;
  }

  // [X,Y] = load_xy_async():  loads the X, Y from buffer
  if (ni==0) {
    LOGMSG("In ni==0\n");

    the_loader.pop_buf(vo[0], vo[1]);

    LOGMSG("Out ni==0\n");
    return;
  }

  mexErrMsgTxt("Incorrect calling arguments\n.");
  return;
}