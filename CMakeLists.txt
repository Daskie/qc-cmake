#
# Variable and functions for common CMake use.
#
# Austin Quick
# https://github.com/Daskie/qc-cmake
#

cmake_minimum_required(VERSION 3.17)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

### GENERAL ####################################################################

# Compiler
if(MSVC)
    set(QC_MSVC TRUE)
elseif(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    set(QC_CLANG TRUE)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(QC_GCC TRUE)
else()
    message(WARNING "Compiler not recognized")
endif()

### WARNINGS ###################################################################

set(QC_WARNINGS_MSVC
    /W4 # Baseline reasonable warnings
    /w14242 # 'identifier': conversion from 'type1' to 'type1', possible loss of data
    /w14254 # 'operator': conversion from 'type1:field_bits' to 'type2:field_bits', possible loss of data
    /w14263 # 'function': member function does not override any base class virtual member function
    /w14265 # 'classname': class has virtual functions, but destructor is not virtual instances of this class may not
    # be destructed correctly
    /w14287 # 'operator': unsigned/negative constant mismatch
    /we4289 # nonstandard extension used: 'variable': loop control variable declared in the for-loop is used outside
    # the for-loop scope
    /w14296 # 'operator': expression is always 'boolean_value'
    /w14311 # 'variable': pointer truncation from 'type1' to 'type2'
    /w14545 # expression before comma evaluates to a function which is missing an argument list
    /w14546 # function call before comma missing argument list
    /w14547 # 'operator': operator before comma has no effect; expected operator with side-effect
    /w14549 # 'operator': operator before comma has no effect; did you intend 'operator'?
    /w14555 # expression has no effect; expected expression with side- effect
    /w14619 # pragma warning: there is no warning number 'number'
    /w14640 # Enable warning on thread un-safe static member initialization
    /w14826 # Conversion from 'type1' to 'type_2' is sign-extended. This may cause unexpected runtime behavior.
    /w14905 # wide string literal cast to 'LPSTR'
    /w14906 # string literal cast to 'LPWSTR'
    /w14928 # illegal copy-initialization; more than one user-defined conversion has been implicitly applied
    /permissive- # standards conformance mode for MSVC compiler.
)

set(QC_WARNINGS_CLANG
    -Wall
    -Wextra # reasonable and standard
    -Wshadow # warn the user if a variable declaration shadows one from a parent context
    -Wnon-virtual-dtor # warn the user if a class with virtual functions has a non-virtual destructor. This helps
    # catch hard to track down memory errors
    -Wold-style-cast # warn for c-style casts
    -Wcast-align # warn for potential performance problem casts
    -Wunused # warn on anything being unused
    -Woverloaded-virtual # warn if you overload (not override) a virtual function
    -Wpedantic # warn if non-standard C++ is used
    -Wconversion # warn on type conversions that may lose data
    -Wsign-conversion # warn on sign conversions
    -Wnull-dereference # warn if a null dereference is detected
    -Wdouble-promotion # warn if float is implicit promoted to double
    -Wformat=2 # warn on security issues around functions that format output (ie printf)
)

set(QC_WARNINGS_GCC
    ${QC_WARNINGS_CLANG}
    -Wmisleading-indentation # warn if indentation implies blocks where blocks do not exist
    -Wduplicated-cond # warn if if / else chain has duplicated conditions
    -Wduplicated-branches # warn if if / else branches have duplicated code
    -Wlogical-op # warn about logical operations being used where bitwise were probably wanted
    -Wuseless-cast # warn if you perform a cast to the same type
)

# Warnings as errors
set(QC_WARNINGS_ERROR_MSVC ${QC_WARNINGS_MSVC} /WX)
set(QC_WARNINGS_ERROR_CLANG ${QC_WARNINGS_CLANG} -Werror)
set(QC_WARNINGS_ERROR_GCC ${QC_WARNINGS_GCC} -Werror)

if(QC_MSVC)
    set(QC_WARNINGS ${QC_WARNINGS_MSVC})
    set(QC_WARNINGS_ERROR ${QC_WARNINGS_ERROR_MSVC})
elseif(QC_CLANG)
    set(QC_WARNINGS ${QC_WARNINGS_CLANG})
    set(QC_WARNINGS_ERROR ${QC_WARNINGS_ERROR_CLANG})
elseif(CMAKE_GCC)
    set(QC_WARNINGS ${QC_WARNINGS_GCC})
    set(QC_WARNINGS_ERROR ${QC_WARNINGS_ERROR_GCC})
endif()

### INSTALL ####################################################################

# See https://cmake.org/cmake/help/git-stage/guide/importing-exporting/index.html

function(qc_install)
    # General install and target setup
    install(
        TARGETS ${PROJECT_NAME}
        EXPORT ${PROJECT_NAME}-targets
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        INCLUDES DESTINATION include
    )

    # Install headers
    install(DIRECTORY include DESTINATION .)

    # Export targets to create importable cmake file
    install(
        EXPORT ${PROJECT_NAME}-targets
        NAMESPACE ${CMAKE_PROJECT_NAME}::
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
    )

    # Allow library to be found via find_package

    # Create config.cmake files
    configure_package_config_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/Config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
        INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
    )

    # Install config.cmake files
    install(
        FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
    )
endfunction()
