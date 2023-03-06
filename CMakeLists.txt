#
# Common CMake variables and functions
# https://github.com/daskie/qc-cmake
#

cmake_minimum_required(VERSION 3.23)

# TODO: Add status and debug messages to all this

include(utility.cmake)
include(warnings.cmake)
include(setup-target.cmake)
include(setup-install.cmake)

# Default C++ standard version
# May be overridden at package level
SET(QC_CXX_STANDARD 23 PARENT_SCOPE)

# Remove `/EHsc` from default flags so we can explicitly enable or disable exceptions later
if(QC_MSVC)
    string(REPLACE "/EHsc" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} PARENT_SCOPE)
endif()
