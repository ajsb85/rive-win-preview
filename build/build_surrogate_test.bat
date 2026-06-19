@echo off
REM Build the out-of-process surrogate activation test (tools\surrogate_test.cpp).
setlocal ENABLEEXTENSIONS
set "ROOT=%~dp0.."
pushd "%ROOT%"
call "%ROOT%\build\env.bat" || (echo env setup failed & popd & exit /b 1)
set "OUT=%ROOT%\build\bin"
if not exist "%OUT%" mkdir "%OUT%"
cl /nologo /MT /O2 /EHsc /std:c++17 /DNOMINMAX /D_CRT_SECURE_NO_WARNINGS ^
   "%ROOT%\tools\surrogate_test.cpp" /Fe"%OUT%\surrogate_test.exe" /Fo"%ROOT%\build\obj\\" ^
   >"%ROOT%\build\surrogate_build.log" 2>&1
if errorlevel 1 (
    echo [build_surrogate_test] BUILD FAILED:
    findstr /c:": error " /c:": fatal error " "%ROOT%\build\surrogate_build.log"
    popd & exit /b 1
)
echo [build_surrogate_test] OK  build\bin\surrogate_test.exe
popd
exit /b 0
