cmake_minimum_required(VERSION 3.22.1)
project(gpmf_parser)

# Set source path variables
set(GPMF_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/native/src)

# Add library
add_library(gpmf
            SHARED
            ${GPMF_SOURCE_DIR}/gpmf_bindings.c
            ${GPMF_SOURCE_DIR}/GPMF_parser.c
            ${GPMF_SOURCE_DIR}/GPMF_mp4reader.c
            ${GPMF_SOURCE_DIR}/GPMF_utils.c)

# Include directories
target_include_directories(gpmf PRIVATE
                         ${GPMF_SOURCE_DIR})

# Find required libraries
find_library(MATH_LIBRARY m)

# Link libraries
target_link_libraries(gpmf PRIVATE ${MATH_LIBRARY})

# Set installation paths
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

# Install the native library
install(
    TARGETS gpmf
    LIBRARY DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}/bin"
) 