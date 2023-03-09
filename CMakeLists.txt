#
# Common CMake variables and functions
# https://github.com/daskie/qc-cmake
#

cmake_minimum_required(VERSION 3.23)

# TODO: Add status and debug messages to all this

# Build type constants
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(QC_DEBUG TRUE)
    set(QC_RELEASE FALSE)
else()
    set(QC_DEBUG FALSE)
    set(QC_RELEASE TRUE)
endif()
set(QC_DEBUG ${QC_DEBUG} PARENT_SCOPE)
set(QC_RELEASE ${QC_RELEASE} PARENT_SCOPE)

# Compiler constants
if(MSVC)
    set(QC_MSVC TRUE)
    set(QC_GCC FALSE)
    set(QC_CLANG FALSE)
elseif(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    set(QC_MSVC FALSE)
    set(QC_GCC FALSE)
    set(QC_CLANG TRUE)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(QC_MSVC FALSE)
    set(QC_GCC TRUE)
    set(QC_CLANG FALSE)
else()
    message(FATAL_ERROR "Compiler not recognized")
endif()
set(QC_MSVC ${QC_MSVC} PARENT_SCOPE)
set(QC_CLANG ${QC_CLANG} PARENT_SCOPE)
set(QC_GCC ${QC_GCC} PARENT_SCOPE)

# Platform constants
if(QC_MSVC)
    if(NOT WIN32 OR UNIX)
        message(FATAL_ERROR "Platform assumption invalid")
    endif()
    set(QC_WINDOWS TRUE)
    set(QC_LINUX FALSE)
elseif(QC_GCC OR QC_CLANG)
    if(NOT UNIX OR WIN32 OR APPLE)
        message(FATAL_ERROR "Platform assumption invalid")
    endif()
    set(QC_WINDOWS FALSE)
    set(QC_LINUX TRUE)
endif()
set(QC_WINDOWS ${QC_WINDOWS} PARENT_SCOPE)
set(QC_LINUX ${QC_LINUX} PARENT_SCOPE)

# Default C++ standard version
# May be overridden at package level
SET(QC_CXX_STANDARD 23 PARENT_SCOPE)

# Remove `/EHsc` from default flags so we can explicitly enable or disable exceptions later
if(QC_MSVC)
    string(REPLACE "/EHsc" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} PARENT_SCOPE)
endif()

# Include everything else
include(utility.cmake)
include(warnings.cmake)
include(setup-target.cmake)
include(setup-install.cmake)
