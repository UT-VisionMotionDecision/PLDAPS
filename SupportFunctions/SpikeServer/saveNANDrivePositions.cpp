 #include "windows.h"
 #include "winuser.h"
 #include "mex.h"
 void sendF6Key()
 {
	HWND windowHandle = FindWindowW(NULL, L"NAN INSTRUMENTS 0.64 , com1, 115200 ,Local Net");
	PostMessage(windowHandle, WM_KEYDOWN, VK_F6, 0x00400001);
	Sleep(2);
	PostMessage(windowHandle, WM_KEYUP, VK_F6, 0xC0400001);
 }

 void mexFunction(int nlhs, mxArray *plhs[], int nrhs,
                  const mxArray *prhs[])
 {
     sendF6Key();
 }