#
# Variable and functions for common CMake use.
#
# Austin Quick
# https://github.com/Daskie/qc-cmake
#

# TODO: Determine actual minimum version
cmake_minimum_required(VERSION 3.17)

# The CheckIPOSupported module seems to be broken and causes linking errors
#include(CheckIPOSupported)
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

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

### FUNCTIONS ##################################################################

#
# Check `cmake_parse_arguments` results
#
# qc_check_args()
#
macro(qc_check_args)
    if(DEFINED _UNPARSED_ARGUMENTS OR DEFINED _KEYWORDS_MISSING_VALUES)
        message(FATAL_ERROR "Invalid arguments")
    endif()
endmacro()

#
# Sets up certain global setting/variables/optimizations. Should be called once at the top of the project.
#
# qc_setup_general([NO_LINK_TIME_OPTIMIZATION])
#
function(qc_setup_general)
    cmake_parse_arguments(
        PARSE_ARGV
        0
        ""
        "NO_LINK_TIME_OPTIMIZATION"
        ""
        ""
    )
    qc_check_args()

    # Append `-d` to generated debug libs so they don't collide with release libs
   set(CMAKE_DEBUG_POSTFIX -d)

    # Enable link-time optimization
    if(QC_RELEASE AND NOT _NO_LINK_TIME_OPTIMIZATION)
        # The CheckIPOSupported module seems to be broken and causes linking errors
        #check_ipo_supported()
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE PARENT_SCOPE)
    endif()
endfunction()

#
# Sets up a library or executable.
#
# qc_setup_target(
#     <target>
#     LIBRARY
#     {STATIC|SHARED}
#     [PUBLIC_LINKS <target-or-library>....]
#     [PRIVATE_LINKS <target-or-library>....]
#     [COMPILE_OPTIONS <option>...]
#     [WARNINGS_DONT_ERROR]
#     [INSTALLABLE]
#         [INSTALL_DEPENDENCIES <package>...]
#         [WINDOWS_SUB_PROJECT_INSTALL_PREFIX]
# )
#
# qc_setup_target(
#     <target>
#     LIBRARY
#     INTERFACE
#     [INTERFACE_LINKS <target-or-library>....]
#     [INSTALLABLE]
#         [INSTALL_DEPENDENCIES <package>...]
#         [WINDOWS_SUB_PROJECT_INSTALL_PREFIX]
# )
#
# qc_setup_target(
#     <target>
#     EXECUTABLE
#     [PUBLIC_LINKS <target-or-library>....]
#     [PRIVATE_LINKS <target-or-library>....]
#     [COMPILE_OPTIONS <option>...]
#     [WARNINGS_DONT_ERROR]
#     [INSTALLABLE]
#         [INSTALL_DEPENDENCIES <package>...]
#         [WINDOWS_SUB_PROJECT_INSTALL_PREFIX]
# )
#
function(qc_setup_target)
    if(ARGC LESS 1)
        message(FATAL_ERROR "Missing target")
    endif()

    set(target ${ARGV0})

    cmake_parse_arguments(
        PARSE_ARGV
        1
        ""
        "LIBRARY;EXECUTABLE;STATIC;SHARED;INTERFACE;WARNINGS_DONT_ERROR;INSTALLABLE;WINDOWS_SUB_PROJECT_INSTALL_PREFIX"
        ""
        "PUBLIC_LINKS;PRIVATE_LINKS;INTERFACE_LINKS;COMPILE_OPTIONS;INSTALL_DEPENDENCIES"
    )
    qc_check_args()

    # Ensure either library or executable
    if(_LIBRARY STREQUAL _EXECUTABLE)
        message(FATAL_ERROR "Must provide either `LIBRARY` or `EXECUTABLE`")
    endif()

    # Set library type
    unset(library_type)
    if(_STATIC)
        list(APPEND library_type "STATIC")
    endif()
    if(_SHARED)
        list(APPEND library_type "SHARED")
    endif()
    if(_INTERFACE)
        list(APPEND library_type "INTERFACE")
    endif()

    # Verify library type
    list(LENGTH library_type library_type_count)
    if(_LIBRARY)
        if(NOT library_type_count EQUAL 1)
            message(FATAL_ERROR "Library must be specified as one of `STATIC`, `SHARED`, or `INTERFACE`")
        endif()
    else()
        if(NOT library_type_count EQUAL 0)
            message(FATAL_ERROR "Executable must not specify a library type")
        endif()
    endif()

    # Verify links
    if(DEFINED _INTERFACE_LINKS AND NOT library_type STREQUAL "INTERFACE")
        message(FATAL_ERROR "Executable must not have interface links")
    endif()

    # Verify `COMPILE_OPTIONS`
    if(library_type STREQUAL "INTERFACE" AND _COMPILE_OPTIONS)
        message(WARNING "`COMPILE_OPTIONS` specified for interface library")
    endif()

    # Verify `WARNINGS_DONT_ERROR`
    if(library_type STREQUAL "INTERFACE" AND _WARNINGS_DONT_ERROR)
        message(WARNING "`WARNINGS_DONT_ERROR` specified for interface library")
    endif()

    # Validate install arguments
    if(_INSTALL_DEPENDENCIES AND NOT _INSTALLABLE)
        message(WARNING "Install dependencies specified for uninstallable target")
    endif()
    if(_WINDOWS_SUB_PROJECT_INSTALL_PREFIX AND NOT _INSTALLABLE)
        message(WARNING "`WINDOWS_SUB_PROJECT_INSTALL_PREFIX` specified for uninstallable target")
    endif()

    # Aggregate source files
    set(source_dir .)
    unset(source_files)
    if(NOT library_type STREQUAL "INTERFACE")
        # Determine source directory
        if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/source)
            set(source_dir source)
        elseif(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src)
            set(source_dir src)
        endif()

        file(GLOB_RECURSE source_files LIST_DIRECTORIES false RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${source_dir}/*.cpp)

        list(LENGTH source_files source_file_count)
        if(source_file_count EQUAL 0)
            message(FATAL_ERROR "No source files found in source directory `${source_dir}`")
        endif()
    endif()

    # Add library or executable
    if(_LIBRARY)
        add_library(${target} ${library_type} ${source_files})
    else()
        add_executable(${target} ${source_files})
    endif()

    # Set install prefix
    # For some reason using `.` in the normal case breaks things, so we use an empty string and adjust accordingly
    if(_INSTALLABLE AND _WINDOWS_SUB_PROJECT_INSTALL_PREFIX AND WIN32)
        set(install_prefix ${target}/)
        set(install_prefix_alone ${target})
    else()
        unset(install_prefix)
        set(install_prefix_alone ".")
    endif()

    # Set include directory
    if(_LIBRARY)
        if (library_type STREQUAL "INTERFACE")
            set(public_or_interface "INTERFACE")
        else()
            set(public_or_interface "PUBLIC")
        endif()

        target_include_directories(
            ${target}
            ${public_or_interface}
                $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
                $<INSTALL_INTERFACE:${install_prefix}include>
        )
    endif()

    # Add additional `external` include directory
    if(NOT library_type STREQUAL "INTERFACE")
        target_include_directories(${target} PRIVATE external)
    endif()

    # Links
    if(DEFINED _PUBLIC_LINKS)
        target_link_libraries(${target} PUBLIC ${_PUBLIC_LINKS})
    endif()
    if(DEFINED _PRIVATE_LINKS)
        target_link_libraries(${target} PRIVATE ${_PRIVATE_LINKS})
    endif()
    if(DEFINED _INTERFACE_LINKS)
        target_link_libraries(${target} INTERFACE ${_INTERFACE_LINKS})
    endif()

    # Set warnings and other compile options
    if(NOT library_type STREQUAL "INTERFACE")
        if(_WARNINGS_DONT_ERROR)
            set(warnings ${QC_WARNINGS})
        else()
            set(warnings ${QC_WARNINGS_ERROR})
        endif()

        target_compile_options(${target} PRIVATE ${warnings} ${_COMPILE_OPTIONS})
    endif()

    # Set precompiled header
    if(NOT library_type STREQUAL "INTERFACE")
        if(source_dir STREQUAL .)
            set(pch_file pch.hpp)
        else()
            set(pch_file ${source_dir}/pch.hpp)
        endif()
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${pch_file})
            target_precompile_headers(${target} PRIVATE ${pch_file})
        endif()
    endif()

    # Installation stuff
    # See https://cmake.org/cmake/help/git-stage/guide/importing-exporting/index.html
    if(_INSTALLABLE)
        # General install and target setup
        install(
            TARGETS ${target}
            EXPORT ${target}-targets
            LIBRARY DESTINATION ${install_prefix}${CMAKE_INSTALL_LIBDIR}
            ARCHIVE DESTINATION ${install_prefix}${CMAKE_INSTALL_LIBDIR}
            RUNTIME DESTINATION ${install_prefix}${CMAKE_INSTALL_BINDIR}
            INCLUDES DESTINATION ${install_prefix}include
        )

        # Install headers
        install(DIRECTORY include DESTINATION ${install_prefix_alone})

        # Export targets to create importable cmake file
        # Note: namespace is the `CMAKE_PROJECT_NAME` not `PROJECT_NAME`
        install(
            EXPORT ${target}-targets
            NAMESPACE ${CMAKE_PROJECT_NAME}::
            DESTINATION ${install_prefix}${CMAKE_INSTALL_LIBDIR}/cmake/${target}
        )

        # Allow library to be found via find_package

        # Generate config template
        set(template "@PACKAGE_INIT@\n")
        if(DEFINED _INSTALL_DEPENDENCIES)
            string(APPEND template "\n# Dependencies\n")
            string(APPEND template "include(CMakeFindDependencyMacro)\n")
            foreach(dependency ${_INSTALL_DEPENDENCIES})
                string(APPEND template "find_dependency(${dependency})\n")
            endforeach()
        endif()
        string(APPEND template "\ninclude(\"\${CMAKE_CURRENT_LIST_DIR}/@PROJECT_NAME@-targets.cmake\")\n")
        string(APPEND template "check_required_components(@PROJECT_NAME@)\n")
        file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${target}-config.cmake.in ${template})

        # Create config.cmake files
        configure_package_config_file(
            ${CMAKE_CURRENT_BINARY_DIR}/${target}-config.cmake.in
            ${CMAKE_CURRENT_BINARY_DIR}/${target}-config.cmake
            INSTALL_DESTINATION ${install_prefix}${CMAKE_INSTALL_LIBDIR}/cmake/${target}
        )

        # Install config.cmake files
        install(
            FILES ${CMAKE_CURRENT_BINARY_DIR}/${target}-config.cmake
            DESTINATION ${install_prefix}${CMAKE_INSTALL_LIBDIR}/cmake/${target}
        )
    endif()
endfunction()
