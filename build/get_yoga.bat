@echo off
REM ===========================================================================
REM  Fetch Yoga (flexbox layout) into third_party/yoga. Gitignored, so a fresh
REM  checkout needs this once before building with layout support.
REM
REM  NOTE: this must be Rive's fork (rive-app/yoga @ rive_changes_v2_0_1_2), not
REM  upstream facebook/yoga. The runtime stores `YGNode`/`YGStyle` by value
REM  (rive/layout/layout_data.hpp), which the fork exposes as concrete types;
REM  modern upstream Yoga made YGNode opaque (yoga::Node) and won't compile here.
REM ===========================================================================
setlocal ENABLEEXTENSIONS
set "ROOT=%~dp0.."
set "TP=%ROOT%\third_party"
if not exist "%TP%" mkdir "%TP%"

if exist "%TP%\yoga\yoga\Yoga.cpp" (
    echo [get_yoga] yoga already present
) else (
    echo [get_yoga] cloning rive-app/yoga @ rive_changes_v2_0_1_2 ...
    git clone --depth 1 --branch rive_changes_v2_0_1_2 https://github.com/rive-app/yoga "%TP%\yoga" || exit /b 1
)

echo [get_yoga] OK
exit /b 0
