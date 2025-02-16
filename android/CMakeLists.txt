cmake_minimum_required(VERSION 3.10.2)

# Set the project name
project(gpmf)

# Set the C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Add source files
set(GPMF_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/src/GPMF_parser.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/src/GPMF_utils.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/src/GPMF_mp4reader.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/src/gpmf_parser.c
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/src/gpmf_bindings.c
)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/../native/src
)

# Create the shared library
add_library(gpmf SHARED ${GPMF_SOURCES})

# Link against required libraries
target_link_libraries(gpmf
    android
    log
) 