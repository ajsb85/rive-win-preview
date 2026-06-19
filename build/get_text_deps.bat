@echo off
REM ===========================================================================
REM  Fetch the text dependencies (HarfBuzz + SheenBidi) into third_party/.
REM  They are gitignored, so a fresh checkout needs this once before building
REM  with text support. Pinned to the same revisions Rive's premake uses.
REM ===========================================================================
setlocal ENABLEEXTENSIONS
set "ROOT=%~dp0.."
set "TP=%ROOT%\third_party"
if not exist "%TP%" mkdir "%TP%"

if exist "%TP%\harfbuzz\src\harfbuzz.cc" (
    echo [get_text_deps] harfbuzz already present
) else (
    echo [get_text_deps] cloning rive-app/harfbuzz @ rive_13.1.1 ...
    git clone --depth 1 --branch rive_13.1.1 https://github.com/rive-app/harfbuzz "%TP%\harfbuzz" || exit /b 1
)

if exist "%TP%\sheenbidi\Source\SheenBidi.c" (
    echo [get_text_deps] sheenbidi already present
) else (
    echo [get_text_deps] cloning Tehreer/SheenBidi @ v2.6 ...
    git clone --depth 1 --branch v2.6 https://github.com/Tehreer/SheenBidi "%TP%\sheenbidi" || exit /b 1
)

echo [get_text_deps] OK
exit /b 0
