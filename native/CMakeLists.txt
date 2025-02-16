cmake_minimum_required(VERSION 3.10)
project(gpmf_parser C)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Set position independent code
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Add source files
add_library(gpmf_parser SHARED
    src/gpmf_parser.c
    src/GPMF_parser.c
    src/GPMF_mp4reader.c
    src/GPMF_utils.c
)

# Set include directories
target_include_directories(gpmf_parser PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Set output name
set_target_properties(gpmf_parser PROPERTIES
    OUTPUT_NAME "gpmf_parser"
    PREFIX "lib"
) 