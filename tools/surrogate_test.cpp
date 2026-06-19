// surrogate_test.cpp — Replicate Explorer's out-of-process activation.
//
//   surrogate_test <input.riv>
//
// Unlike preview_test (which LoadLibrary's the DLL into this process), this uses
// CoCreateInstance with CLSCTX_LOCAL_SERVER, so COM honors the CLSID's AppID +
// DllSurrogate and loads RivePeek.dll inside prevhost.exe — exactly as the Shell
// does. It then drives Initialize/SetWindow/DoPreview against a visible host
// window. If the .riv animates in that window, the surrogate path works.
#define NOMINMAX
#include <windows.h>
#include <shobjidl.h>
#include <shlwapi.h>
#include <cstdio>

#include "../src/guids.hpp"

#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "user32.lib")

int wmain(int argc, wchar_t** argv) {
    if (argc < 2) { wprintf(L"usage: surrogate_test <input.riv>\n"); return 2; }

    CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

    // LOCAL_SERVER => activate through the prevhost.exe surrogate (like Explorer).
    IPreviewHandler* preview = nullptr;
    HRESULT hr = CoCreateInstance(CLSID_RivePreviewHandler, nullptr,
                                  CLSCTX_LOCAL_SERVER,
                                  IID_PPV_ARGS(&preview));
    if (FAILED(hr)) {
        wprintf(L"FAIL: CoCreateInstance(LOCAL_SERVER) = 0x%08lx\n", hr);
        wprintf(L"  (this is the activation Explorer uses; failure here = the "
                L"surrogate cannot host the handler)\n");
        return 1;
    }
    wprintf(L"ok: handler activated in prevhost.exe surrogate (0x%08lx)\n", hr);

    IInitializeWithStream* init = nullptr;
    if (FAILED(preview->QueryInterface(&init))) { wprintf(L"FAIL: QI init\n"); return 1; }

    IStream* stream = nullptr;
    hr = SHCreateStreamOnFileEx(argv[1], STGM_READ | STGM_SHARE_DENY_WRITE, 0,
                                FALSE, nullptr, &stream);
    if (FAILED(hr)) { wprintf(L"FAIL: open stream 0x%08lx\n", hr); return 1; }
    hr = init->Initialize(stream, STGM_READ);
    wprintf(L"%s: Initialize 0x%08lx\n", SUCCEEDED(hr) ? L"ok" : L"FAIL", hr);

    // Visible host window standing in for Explorer's preview pane.
    WNDCLASSW wc = {};
    wc.lpfnWndProc = DefWindowProcW;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpszClassName = L"RivePeekSurrogateHost";
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    RegisterClassW(&wc);
    HWND host = CreateWindowW(L"RivePeekSurrogateHost", L"RivePeek surrogate preview",
                              WS_OVERLAPPEDWINDOW | WS_VISIBLE, CW_USEDEFAULT,
                              CW_USEDEFAULT, 560, 600, nullptr, nullptr, wc.hInstance, nullptr);
    RECT rc = {10, 10, 530, 530};
    hr = preview->SetWindow(host, &rc);
    wprintf(L"%s: SetWindow 0x%08lx\n", SUCCEEDED(hr) ? L"ok" : L"FAIL", hr);
    hr = preview->DoPreview();
    wprintf(L"%s: DoPreview 0x%08lx\n", SUCCEEDED(hr) ? L"ok" : L"FAIL", hr);

    wprintf(L"Showing preview for 4 seconds (a window should display the .riv)...\n");
    DWORD end = GetTickCount() + 4000;
    MSG msg;
    while ((int)(end - GetTickCount()) > 0) {
        while (PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE)) {
            TranslateMessage(&msg); DispatchMessage(&msg);
        }
        Sleep(10);
    }

    preview->Unload();
    if (stream) stream->Release();
    if (init) init->Release();
    preview->Release();
    DestroyWindow(host);
    wprintf(L"PASS: surrogate (prevhost.exe) activation + preview pipeline worked.\n");
    CoUninitialize();
    return 0;
}
