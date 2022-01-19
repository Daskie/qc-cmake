#
# Common CMake variables and functions
#
# Austin Quick : 2020 - 2021
# https://github.com/Daskie/qc-cmake
#

# TODO: Determine actual minimum version
cmake_minimum_required(VERSION 3.20)

include(utility.cmake)
include(warnings.cmake)
include(setup-target.cmake)
include(setup-install.cmake)
include(bundle-static-libraries.cmake)
