@echo off
REM ===========================================================================
REM  Build text_deps.lib -- HarfBuzz (shaping) + SheenBidi (bidi), the two
REM  third-party libraries the Rive runtime needs when compiled WITH_RIVE_TEXT.
REM
REM  Sources are cloned (gitignored) under third_party/:
REM    third_party/harfbuzz   = rive-app/harfbuzz @ rive_13.1.1
REM    third_party/sheenbidi  = Tehreer/SheenBidi  @ v2.6
REM
REM  We compile the upstream single-file amalgamations (harfbuzz.cc, SheenBidi.c)
REM  and DO NOT apply Rive's hb-symbol renames: nothing else in the binary links
REM  HarfBuzz, so plain hb_* symbols match the runtime's font_hb.cpp calls.
REM ===========================================================================
setlocal ENABLEEXTENSIONS
set "ROOT=%~dp0.."
pushd "%ROOT%"
call "%ROOT%\build\env.bat" || (echo env setup failed & popd & exit /b 1)

set "HB=%ROOT%\third_party\harfbuzz"
set "SB=%ROOT%\third_party\sheenbidi"
set "OBJ=%ROOT%\build\obj\text"
if not exist "%OBJ%" mkdir "%OBJ%"

if not exist "%HB%\src\harfbuzz.cc" (echo missing third_party\harfbuzz ^(clone rive-app/harfbuzz @ rive_13.1.1^) & popd & exit /b 1)
if not exist "%SB%\Source\SheenBidi.c" (echo missing third_party\sheenbidi ^(clone Tehreer/SheenBidi @ v2.6^) & popd & exit /b 1)

REM --- HarfBuzz: trimmed feature set mirroring rive's premake5_harfbuzz_v2.lua -
set "HBDEF=/DHB_ONLY_ONE_SHAPER /DHAVE_OT /DHB_DISABLE_DEPRECATED"
set "HBDEF=%HBDEF% /DHB_NO_BUFFER_SERIALIZE /DHB_NO_BUFFER_VERIFY /DHB_NO_BUFFER_MESSAGE"
set "HBDEF=%HBDEF% /DHB_NO_FALLBACK_SHAPE /DHB_NO_WIN1256 /DHB_NO_VERTICAL /DHB_NO_MATH /DHB_NO_BASE"
set "HBDEF=%HBDEF% /DHB_NO_OT_SHAPE_FRACTIONS /DHB_NO_OT_SHAPE_FALLBACK /DHB_NO_LEGACY"
set "HBDEF=%HBDEF% /DHB_NO_LAYOUT_COLLECT_GLYPHS /DHB_NO_LAYOUT_RARELY_USED /DHB_NO_LAYOUT_UNUSED"
set "HBDEF=%HBDEF% /DHB_NO_OT_FONT_GLYPH_NAMES /DHB_NO_HINTING /DHB_NO_NAME /DHB_NO_META /DHB_NO_METRICS"
set "HBDEF=%HBDEF% /DHB_NO_SVG /DHB_NO_AVAR2 /DHB_NO_VAR_HVF /DHB_NO_VAR_COMPOSITES"
set "HBDEF=%HBDEF% /DHB_NO_EXTERN_HELPERS /DHB_NO_SETLOCALE /DHB_NO_MMAP /DHB_NO_ATEXIT /DHB_NO_ERRNO"
set "HBDEF=%HBDEF% /DHB_NO_GETENV /DHB_NO_OPEN /DHB_NO_FACE_COLLECT_UNICODES /DHB_OPTIMIZE_SIZE /DHB_NO_UCD_UNASSIGNED"

echo [build_text_deps] compiling HarfBuzz (amalgamation)...
cl /nologo /c /MT /O2 /EHsc /std:c++17 /GR- /bigobj /w /DNDEBUG /D_CRT_SECURE_NO_WARNINGS /DWIN32 ^
   %HBDEF% /I "%HB%\src" "%HB%\src\harfbuzz.cc" /Fo"%OBJ%\harfbuzz.obj" >"%ROOT%\build\hb_build.log" 2>&1
if errorlevel 1 (
    echo [build_text_deps] HARFBUZZ BUILD FAILED ^(see build\hb_build.log^):
    findstr /c:": error " /c:": fatal error " "%ROOT%\build\hb_build.log"
    popd & exit /b 1
)

echo [build_text_deps] compiling SheenBidi (unity)...
cl /nologo /c /MT /O2 /DNDEBUG /D_CRT_SECURE_NO_WARNINGS /DWIN32 /DSB_CONFIG_UNITY ^
   /I "%SB%\Headers" "%SB%\Source\SheenBidi.c" /Fo"%OBJ%\sheenbidi.obj" >"%ROOT%\build\sb_build.log" 2>&1
if errorlevel 1 (
    echo [build_text_deps] SHEENBIDI BUILD FAILED ^(see build\sb_build.log^):
    findstr /c:": error " /c:": fatal error " "%ROOT%\build\sb_build.log"
    popd & exit /b 1
)

echo [build_text_deps] archiving text_deps.lib...
lib /nologo /OUT:"%ROOT%\build\text_deps.lib" "%OBJ%\harfbuzz.obj" "%OBJ%\sheenbidi.obj" >"%ROOT%\build\text_lib.log" 2>&1
if errorlevel 1 (echo [build_text_deps] LIB FAILED & type "%ROOT%\build\text_lib.log" & popd & exit /b 1)

for %%S in ("%ROOT%\build\text_deps.lib") do echo [build_text_deps] OK  text_deps.lib = %%~zS bytes
popd
exit /b 0
