#
# Variable and functions for common CMake use.
#
# Austin Quick
# https://github.com/Daskie/qc-cmake
#

# TODO: Determine actual minimum version
cmake_minimum_required(VERSION 3.20)

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
    if(DEFINED _UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Invalid arguments `${_UNPARSED_ARGUMENTS}`")
    endif()
    if(DEFINED _KEYWORDS_MISSING_VALUES)
        message(FATAL_ERROR "Arguments missing values `${_KEYWORDS_MISSING_VALUES}`")
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

    # Append `-d` to generated debug libraries so they don't collide with release libraries
   set(CMAKE_DEBUG_POSTFIX -d PARENT_SCOPE)

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
#     {EXECUTABLE|STATIC_LIBRARY|SHARED_LIBRARY}
#     [SOURCE_FILES <file>...]
#     [PUBLIC_LINKS <target>...]
#     [PRIVATE_LINKS <target>...]
#     [COMPILE_OPTIONS <option>...]
#     [WARNINGS_DONT_ERROR]
#     [INSTALLABLE]
#         [INSTALL_DEPENDENCIES <package>...]
#         [WINDOWS_SUB_PROJECT_INSTALL_PREFIX]
# )
#
# qc_setup_target(
#     <target>
#     INTERFACE_LIBRARY
#     [INTERFACE_LINKS <target>....]
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
        "EXECUTABLE;STATIC_LIBRARY;SHARED_LIBRARY;INTERFACE_LIBRARY;WARNINGS_DONT_ERROR;INSTALLABLE;WINDOWS_SUB_PROJECT_INSTALL_PREFIX"
        ""
        "SOURCE_FILES;PUBLIC_LINKS;PRIVATE_LINKS;INTERFACE_LINKS;COMPILE_OPTIONS;INSTALL_DEPENDENCIES"
    )
    qc_check_args()

    # Set target and library type
    unset(target_type)
    unset(library_type)
    if(_EXECUTABLE)
        list(APPEND target_type "EXECUTABLE")
    endif()
    if(_STATIC_LIBRARY)
        list(APPEND target_type "STATIC_LIBRARY")
        set(library_type "STATIC")
    endif()
    if(_SHARED_LIBRARY)
        list(APPEND target_type "SHARED_LIBRARY")
        set(library_type "SHARED")
    endif()
    if(_INTERFACE_LIBRARY)
        list(APPEND target_type "INTERFACE_LIBRARY")
        set(library_type "INTERFACE")
    endif()

    # Verify target type
    list(LENGTH target_type target_type_count)
    if(NOT target_type_count EQUAL 1)
        message(FATAL_ERROR "Must only provide one target type: `EXECUTABLE`, `STATIC_LIBRARY`, `SHARED_LIBRARY`, or `INTERFACE_LIBRARY`")
    endif()

    # Set helper flags
    set(is_interface FALSE)
    if(DEFINED library_type)
        set(is_executable FALSE)
        set(is_library TRUE)
        if(library_type STREQUAL "INTERFACE")
            set(is_interface TRUE)
        endif()
    else()
        set(is_executable TRUE)
        set(is_library FALSE)
    endif()

    # Verify source files
    if(DEFINED _SOURCE_FILES AND is_interface)
        message(FATAL_ERROR "Interface library must not have source files")
    endif()

    # Verify links
    if(DEFINED _INTERFACE_LINKS AND NOT is_interface)
        message(FATAL_ERROR "Only interface libraries may have interface links")
    endif()

    # Verify `COMPILE_OPTIONS`
    if(_COMPILE_OPTIONS AND is_interface)
        message(WARNING "`COMPILE_OPTIONS` specified for interface library")
    endif()

    # Verify `WARNINGS_DONT_ERROR`
    if(_WARNINGS_DONT_ERROR AND is_interface)
        message(WARNING "`WARNINGS_DONT_ERROR` specified for interface library")
    endif()

    # Validate install arguments
    if(_INSTALL_DEPENDENCIES AND NOT _INSTALLABLE)
        message(WARNING "Install dependencies specified for uninstallable target")
    endif()
    if(_WINDOWS_SUB_PROJECT_INSTALL_PREFIX AND NOT _INSTALLABLE)
        message(WARNING "`WINDOWS_SUB_PROJECT_INSTALL_PREFIX` specified for uninstallable target")
    endif()

    # Find source files if not provided
    set(source_files ${_SOURCE_FILES})
    if(NOT DEFINED _SOURCE_FILES AND NOT is_interface)
        # Determine source directory
        if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/source)
            file(GLOB_RECURSE source_files LIST_DIRECTORIES false RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} source/*.cpp)
        elseif(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src)
            file(GLOB_RECURSE source_files LIST_DIRECTORIES false RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} src/*.cpp)
        else()
            file(GLOB source_files LIST_DIRECTORIES false RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.cpp)
        endif()

        list(LENGTH source_files source_file_count)
        if(source_file_count EQUAL 0)
            message(FATAL_ERROR "No source files found under `${CMAKE_CURRENT_SOURCE_DIR}`")
        endif()
    endif()

    # Add library or executable
    if(is_executable)
        add_executable(${target} ${source_files})
    else()
        add_library(${target} ${library_type} ${source_files})
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
    if(is_library)
        if (is_interface)
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
    if(NOT is_interface)
        target_include_directories(${target} PRIVATE external)
    endif()

    # Links
    if(DEFINED _PUBLIC_LINKS)
        target_link_libraries(${target} PUBLIC ${_PUBLIC_LINKS})
    endif()
    foreach(private_link IN LISTS _PRIVATE_LINKS)
        get_target_property(link_type ${private_link} TYPE)
        if(link_type STREQUAL "INTERFACE_LIBRARY")
            # Workaround to avoid private header-only libraries being added to the link interface
            target_link_libraries(${target} PRIVATE $<BUILD_INTERFACE:${private_link}>)
        else()
            target_link_libraries(${target} PRIVATE ${private_link})
        endif()
    endforeach()
    if(DEFINED _INTERFACE_LINKS)
        target_link_libraries(${target} INTERFACE ${_INTERFACE_LINKS})
    endif()

    # Set warnings and other compile options
    if(NOT is_interface)
        if(_WARNINGS_DONT_ERROR)
            set(warnings ${QC_WARNINGS})
        else()
            set(warnings ${QC_WARNINGS_ERROR})
        endif()

        target_compile_options(${target} PRIVATE ${warnings} ${_COMPILE_OPTIONS})
    endif()

    # Set precompiled header
    if(NOT is_interface)
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/source/pch.hpp)
            target_precompile_headers(${target} PRIVATE source/pch.hpp)
        elseif(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src/pch.hpp)
            target_precompile_headers(${target} PRIVATE src/pch.hpp)
        elseif(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/pch.hpp)
            target_precompile_headers(${target} PRIVATE pch.hpp)
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
            foreach(dependency IN LISTS _INSTALL_DEPENDENCIES)
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

#
# Helper function to generate a list suitable for `INTERFACE_LINK_LIBRARIES` from public and private link targets
#
function(_qc_create_interface_link_libraries_list out_links_list public_links private_links)
    # Add `$<LINK_ONLY:...>` generator expression to private links
    list(TRANSFORM private_links PREPEND "\$<LINK_ONLY:" OUTPUT_VARIABLE decorated_private_links)
    list(TRANSFORM decorated_private_links APPEND ">" OUTPUT_VARIABLE decorated_private_links)

    set(${out_links_list} ${public_links} ${decorated_private_links} PARENT_SCOPE)
endfunction()

#
# Helper function to generate package install cmake files
#
function(_qc_create_package_files out_files_list package public_links private_links)
    set(qualified_package ${CMAKE_PROJECT_NAME}::${package})

    # Strip the public and private links down to just their namespaces to use as package dependencies
    string(REGEX REPLACE "::[^;]+" "" package_dependencies "${public_links}" "${private_links}")
    list(REMOVE_DUPLICATES package_dependencies)

    # Add namespace onto any unqualified links (assuming they must come from current package)
    list(TRANSFORM public_links PREPEND "${CMAKE_PROJECT_NAME}::" REGEX "^[^:]+\$")
    list(TRANSFORM private_links PREPEND "${CMAKE_PROJECT_NAME}::" REGEX "^[^:]+\$")

    _qc_create_interface_link_libraries_list(links_list "${public_links}" "${private_links}")

    # Generate `<package>-config.cmake` file
    set(config_file_content)
    list(LENGTH package_dependencies package_dependencies_count)
    if(package_dependencies_count GREATER 0)
        string(APPEND config_file_content "# Dependencies\ninclude(CMakeFindDependencyMacro)\n")
        foreach(dependency IN LISTS package_dependencies)
            string(APPEND config_file_content "find_dependency(${dependency})\n")
        endforeach()
        string(APPEND config_file_content "\n")
    endif()
    string(APPEND config_file_content "include(\"\${CMAKE_CURRENT_LIST_DIR}/${package}-targets.cmake\")\n")

    # Generate `<package>-targets.cmake` file
    set(targets_file_content
"\
# Protect against multiple inclusion
if (TARGET ${qualified_package})
	return()
endif()

# Compute the installation prefix relative to this file.
get_filename_component(install_prefix \${CMAKE_CURRENT_LIST_DIR} PATH)
get_filename_component(install_prefix \${install_prefix} PATH)
get_filename_component(install_prefix \${install_prefix} PATH)
if(install_prefix STREQUAL \"/\")
	set(install_prefix \"\")
endif()

# Create imported target
add_library(${qualified_package} STATIC IMPORTED)
set_target_properties(${qualified_package} PROPERTIES
	INTERFACE_INCLUDE_DIRECTORIES \"\${install_prefix}/include\"
	INTERFACE_LINK_LIBRARIES \"${links_list}\"
)

# Load information for each installed configuration
file(GLOB config_files \"\${CMAKE_CURRENT_LIST_DIR}/${package}-targets-*.cmake\")
foreach(config_file IN LISTS config_files)
	include(\${config_file})
endforeach()

# Cleanup temporary variables
unset(install_prefix)
")

    if(QC_DEBUG)
        set(configuration_string_upper "DEBUG")
        set(configuration_string_lower "debug")
        set(library_file_postfix "${CMAKE_DEBUG_POSTFIX}")
    else()
        set(configuration_string_upper "RELEASE")
        set(configuration_string_lower "release")
        set(library_file_postfix)
    endif()

    # Generate `<package>-targets-{debug|release}.cmake` file
    set(targets_configuration_file_content
"\
set(library_file \"\${install_prefix}/${CMAKE_INSTALL_LIBDIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${package}${library_file_postfix}${CMAKE_STATIC_LIBRARY_SUFFIX}\")

# Import target for configuration `${configuration_string_lower}`
set_property(TARGET ${qualified_package} APPEND PROPERTY IMPORTED_CONFIGURATIONS ${configuration_string_upper})
set_target_properties(${qualified_package} PROPERTIES
	IMPORTED_LINK_INTERFACE_LANGUAGES_${configuration_string_upper} \"CXX\"
	IMPORTED_LOCATION_${configuration_string_upper} \${library_file}
)

# Ensure the library file exists
if(NOT EXISTS \${library_file})
	message(FATAL_ERROR \"Expected to find library file `\${library_file}` for target `${qualified_package}`\")
endif()

unset(library_file)
")

    set(config_file "${CMAKE_CURRENT_BINARY_DIR}/${package}-config.cmake")
    set(targets_file "${CMAKE_CURRENT_BINARY_DIR}/${package}-targets.cmake")
    set(targets_configuration_file "${CMAKE_CURRENT_BINARY_DIR}/${package}-targets-${configuration_string_lower}.cmake")

    # Write files to disk
    file(WRITE ${config_file} "${config_file_content}")
    file(WRITE ${targets_file} "${targets_file_content}")
    file(WRITE ${targets_configuration_file} "${targets_configuration_file_content}")

    # Return the file paths
    set(${out_files_list} ${config_file} ${targets_file} ${targets_configuration_file} PARENT_SCOPE)
endfunction()

#
# Combines multiple static libraries together
#
# See https://cristianadam.eu/20190501/bundling-together-static-libraries-with-cmake/
#
# qc_bundle_static_libraries(
#     <target>
#     BUNDLE_LIBRARIES <target>...
#     PUBLIC_LINKS <target>...
#     PRIVATE_LINKS <target>...
#     [INSTALLABLE]
#         [WINDOWS_SUB_PROJECT_INSTALL_PREFIX]
# )
#
function(qc_bundle_static_libraries)
    if(ARGC LESS 1)
        message(FATAL_ERROR "Missing target")
    endif()

    set(target ${ARGV0})

    cmake_parse_arguments(
        PARSE_ARGV
        1
        ""
        "INSTALLABLE;WINDOWS_SUB_PROJECT_INSTALL_PREFIX"
        ""
        "BUNDLE_LIBRARIES;PUBLIC_LINKS;PRIVATE_LINKS"
    )
    qc_check_args()

    # Verify bundle libraries
    if(NOT DEFINED _BUNDLE_LIBRARIES)
        message(FATAL_ERROR "Must provide at least one bundle library")
    endif()

    # Validate install arguments
    if(_WINDOWS_SUB_PROJECT_INSTALL_PREFIX AND NOT _INSTALLABLE)
        message(WARNING "`WINDOWS_SUB_PROJECT_INSTALL_PREFIX` specified for uninstallable target")
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

    # Get list of library files from each bundle target
    unset(bundle_library_files)
    foreach(bundle_target IN LISTS _BUNDLE_LIBRARIES)
        get_target_property(target_type ${bundle_target} TYPE)
        if(NOT target_type STREQUAL "STATIC_LIBRARY")
            if(target_type STREQUAL "UNKNOWN_LIBRARY")
                # TODO: Figure out why Freetype is `UNKOWN_LIBRARY`
                message(WARNING "Bundle target `${bundle_target}` has type `UNKNOWN_LIBRARY`")
            else()
                message(FATAL_ERROR "Bundle target `${bundle_target}` must have type `STATIC_LIBRARY` but has type `${target_type}`")
            endif()
        endif()
       list(APPEND bundle_library_files $<TARGET_FILE:${bundle_target}>)
    endforeach()

    # Determine filepath for generated bundled library file
    unset(library_file_postfix)
    if(QC_DEBUG)
        set(library_file_postfix ${CMAKE_DEBUG_POSTFIX})
    endif()
    set(bundled_library_file ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${target}${library_file_postfix}${CMAKE_STATIC_LIBRARY_SUFFIX})

    # Combine the libraries
    if (QC_MSVC)
        find_program(lib_tool lib)
        add_custom_command(
            COMMAND ${lib_tool} /NOLOGO /OUT:${bundled_library_file} ${bundle_library_files}
            OUTPUT ${bundled_library_file}
            COMMENT "Bundling static libraries into ${target}..."
            VERBATIM
            COMMAND_EXPAND_LISTS
        )
    else()
        # TODO
        message(FATAL_ERROR "Currently only MSVC is supported for bundling static libraries")
    endif()

    # Create target for generating bundled library
    add_custom_target(${target}-bundling ALL DEPENDS ${bundled_library_file})
    add_dependencies(${target}-bundling ${_BUNDLE_LIBRARIES})

    _qc_create_interface_link_libraries_list(links_list "${_PUBLIC_LINKS}" "${_PRIVATE_LINKS}")

    # Create bundled library
    add_library(${target} STATIC IMPORTED GLOBAL)
    set_target_properties(
        ${target}
        PROPERTIES
            IMPORTED_LOCATION ${bundled_library_file}
            INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR}/include
            INTERFACE_LINK_LIBRARIES "${links_list}"
    )
    add_dependencies(${target} ${target}-bundling)

    # Installation stuff
    # See https://cmake.org/cmake/help/git-stage/guide/importing-exporting/index.html
    if(_INSTALLABLE)
        _qc_create_package_files(package_files ${target} "${_PUBLIC_LINKS}" "${_PRIVATE_LINKS}")

        # Install bundled library file
        install(
            FILES ${bundled_library_file}
            DESTINATION ${install_prefix}${CMAKE_INSTALL_LIBDIR}
        )

        # Install include directory
        install(
            DIRECTORY include
            DESTINATION ${install_prefix_alone}
        )

        # Install package cmake files
        install(
            FILES ${package_files}
            DESTINATION ${install_prefix}${CMAKE_INSTALL_LIBDIR}/cmake/${target}
        )
    endif()
endfunction()
