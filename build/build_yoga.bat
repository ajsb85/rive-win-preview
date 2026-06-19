@echo off
REM ===========================================================================
REM  Build yoga.lib -- Rive's fork of Yoga (flexbox layout), the dependency the
REM  runtime needs when compiled WITH_RIVE_LAYOUT. Source is cloned (gitignored)
REM  under third_party/yoga by get_yoga.bat.
REM
REM  Compiles the same translation units as rive's premake5_yoga_v2.lua. We do
REM  NOT apply the YG-symbol renames: nothing else links Yoga, so plain YG*
REM  symbols match the runtime's layout_component.cpp calls.
REM ===========================================================================
setlocal ENABLEEXTENSIONS
set "ROOT=%~dp0.."
pushd "%ROOT%"
call "%ROOT%\build\env.bat" || (echo env setup failed & popd & exit /b 1)

set "YG=%ROOT%\third_party\yoga"
set "OBJ=%ROOT%\build\obj\yoga"
if not exist "%OBJ%" mkdir "%OBJ%"
if not exist "%YG%\yoga\Yoga.cpp" (echo missing third_party\yoga ^(run get_yoga.bat^) & popd & exit /b 1)

echo [build_yoga] compiling Yoga...
cl /nologo /c /MP /MT /O2 /EHsc /std:c++17 /GR- /w /DNDEBUG /D_CRT_SECURE_NO_WARNINGS /DWIN32 /DYOGA_EXPORT= ^
   /I "%YG%" /Fo"%OBJ%\\" ^
   "%YG%\yoga\Utils.cpp" "%YG%\yoga\YGConfig.cpp" "%YG%\yoga\YGLayout.cpp" ^
   "%YG%\yoga\YGEnums.cpp" "%YG%\yoga\YGNodePrint.cpp" "%YG%\yoga\YGNode.cpp" ^
   "%YG%\yoga\YGValue.cpp" "%YG%\yoga\YGStyle.cpp" "%YG%\yoga\Yoga.cpp" ^
   "%YG%\yoga\event\event.cpp" "%YG%\yoga\log.cpp" >"%ROOT%\build\yoga_build.log" 2>&1
if errorlevel 1 (
    echo [build_yoga] BUILD FAILED ^(see build\yoga_build.log^):
    findstr /c:": error " /c:": fatal error " "%ROOT%\build\yoga_build.log"
    popd & exit /b 1
)

echo [build_yoga] archiving yoga.lib...
lib /nologo /OUT:"%ROOT%\build\yoga.lib" "%OBJ%\*.obj" >"%ROOT%\build\yoga_lib.log" 2>&1
if errorlevel 1 (echo [build_yoga] LIB FAILED & type "%ROOT%\build\yoga_lib.log" & popd & exit /b 1)

for %%S in ("%ROOT%\build\yoga.lib") do echo [build_yoga] OK  yoga.lib = %%~zS bytes
popd
exit /b 0
