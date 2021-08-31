#
# Variable and functions for common CMake use.
#
# Austin Quick
# https://github.com/Daskie/qc-cmake
#

# TODO: Determine actual minimum version
cmake_minimum_required(VERSION 3.17)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

### GENERAL ####################################################################

# Build type
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(QC_DEBUG TRUE)
    set(QC_RELEASE FALSE)
else()
    set(QC_DEBUG FALSE)
    set(QC_RELEASE TRUE)
endif()
set(QC_DEBUG ${QC_DEBUG} PARENT_SCOPE)
set(QC_RELEASE ${QC_RELEASE} PARENT_SCOPE)

# Compiler
if(MSVC)
    set(QC_MSVC TRUE)
    set(QC_MSVC ${QC_MSVC} PARENT_SCOPE)
elseif(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    set(QC_CLANG TRUE)
    set(QC_CLANG ${QC_CLANG} PARENT_SCOPE)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(QC_GCC TRUE)
    set(QC_GCC ${QC_GCC} PARENT_SCOPE)
else()
    message(WARNING "Compiler not recognized")
endif()

### WARNINGS ###################################################################

set(QC_WARNINGS_MSVC
    /W4 # Typical baseline
    /w14242 # 'identifier': conversion from 'type1' to 'type1', possible loss of data
    /w14254 # 'operator': conversion from 'type1:field_bits' to 'type2:field_bits', possible loss of data
    /w14263 # 'function': member function does not override any base class virtual member function
    /w14265 # 'classname': class has virtual functions, but destructor is not virtual instances of this class may not be destructed correctly
    /w14287 # 'operator': unsigned/negative constant mismatch
    /we4289 # Nonstandard extension used: 'variable': loop control variable declared in the for-loop is used outside the for-loop scope
    /w14296 # 'operator': expression is always 'boolean_value'
    /w14311 # 'variable': pointer truncation from 'type1' to 'type2'
    /w14545 # Expression before comma evaluates to a function which is missing an argument list
    /w14546 # Function call before comma missing argument list
    /w14547 # 'operator': operator before comma has no effect; expected operator with side-effect
    /w14549 # 'operator': operator before comma has no effect; did you intend 'operator'?
    /w14555 # Expression has no effect; expected expression with side- effect
    /w14619 # Pragma warning: there is no warning number 'number'
    /w14640 # Enable warning on thread un-safe static member initialization
    /w14826 # Conversion from 'type1' to 'type_2' is sign-extended. This may cause unexpected runtime behavior.
    /w14905 # Wide string literal cast to 'LPSTR'
    /w14906 # String literal cast to 'LPWSTR'
    /w14928 # Illegal copy-initialization; more than one user-defined conversion has been implicitly applied
    /permissive- # Standards conformance mode for MSVC compiler.
)

set(QC_WARNINGS_CLANG
    -Wall # Typical baseline
    -Wextra # More standard warnings
    -Wshadow # Warn the user if a variable declaration shadows one from a parent context
    -Wnon-virtual-dtor # Warn the user if a class with virtual functions has a non-virtual destructor. This helps catch hard to track down memory errors
    -Wold-style-cast # Warn for c-style casts
    -Wcast-align # Warn for potential performance problem casts
    -Wunused # Warn on anything being unused
    -Woverloaded-virtual # Warn if you overload (not override) a virtual function
    -Wpedantic # Warn if non-standard C++ is used
    -Wconversion # Warn on type conversions that may lose data
    -Wsign-conversion # Warn on sign conversions
    -Wnull-dereference # Warn if a null dereference is detected
    -Wdouble-promotion # Warn if float is implicit promoted to double
    -Wformat=2 # Warn on security issues around functions that format output (ie printf)
)

set(QC_WARNINGS_GCC
    ${QC_WARNINGS_CLANG}
    -Wmisleading-indentation # Warn if indentation implies blocks where blocks do not exist
    -Wduplicated-cond # Warn if if / else chain has duplicated conditions
    -Wduplicated-branches # Warn if if / else branches have duplicated code
    -Wlogical-op # Warn about logical operations being used where bitwise were probably wanted
    -Wuseless-cast # Warn if you perform a cast to the same type
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

# Allow warnings to be accessed from parent scope
set(QC_WARNINGS ${QC_WARNINGS} PARENT_SCOPE)
set(QC_WARNINGS_ERROR ${QC_WARNINGS_ERROR} PARENT_SCOPE)

### INSTALL ####################################################################

# See https://cmake.org/cmake/help/git-stage/guide/importing-exporting/index.html

function(_generate_config_template_file)
    set(template "@PACKAGE_INIT@\n")

    if(DEFINED _DEPENDENCIES)
        string(APPEND template "\n# Dependencies\n")
        string(APPEND template "include(CMakeFindDependencyMacro)\n")
        foreach(dependency ${_DEPENDENCIES})
            string(APPEND template "find_dependency(${dependency})\n")
        endforeach()
    endif()

    string(APPEND template "\ninclude(\"\${CMAKE_CURRENT_LIST_DIR}/@PROJECT_NAME@-targets.cmake\")\n")
    string(APPEND template "check_required_components(@PROJECT_NAME@)\n")

    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake.in ${template})
endfunction()

#
# qc_install([DEPENDENCIES <packages>...])
#
function(qc_install)
    cmake_parse_arguments(PARSE_ARGV 0 "" "" "" "DEPENDENCIES")

    if(DEFINED _UNPARSED_ARGUMENTS OR DEFINED _KEYWORDS_MISSING_VALUES)
        message(FATAL_ERROR "Invalid arguments")
    endif()

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

    # Generate config template
    _generate_config_template_file()

    # Create config.cmake files
    configure_package_config_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
        INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
    )

    # Install config.cmake files
    install(
        FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
    )
endfunction()
