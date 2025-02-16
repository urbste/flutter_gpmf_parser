@echo off

:: Create build directory
mkdir build\windows 2>nul

:: Configure and build
cd build\windows
cmake ..\..\windows -G "Visual Studio 17 2022" -A x64
cmake --build . --config Release

:: Copy library to the correct location
mkdir ..\..\build 2>nul
copy /Y Release\gpmf.dll ..\..\build\ 