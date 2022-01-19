include_guard()

include(utility.cmake)

#
# Sets up a library or executable.
#
# qc_setup_target(
#     <target>
#     {EXECUTABLE|STATIC_LIBRARY|SHARED_LIBRARY}
#     [SOURCE_FILES <file>...]
#     [PUBLIC_LINKS <target>...]
#     [PRIVATE_LINKS <target>...]
#     [CXX_STANDARD <cxx_standard>]
#     [COMPILE_OPTIONS <option>...]
#     [WARNINGS_DONT_ERROR]
#     [NO_LINK_TIME_OPTIMIZATION]
# )
#
# qc_setup_target(
#     <target>
#     INTERFACE_LIBRARY
#     [INTERFACE_LINKS <target>....]
#     [CXX_STANDARD <cxx_standard>]
# )
#
function(qc_setup_target target)
    cmake_parse_arguments(
        PARSE_ARGV
        1
        ""
        "EXECUTABLE;STATIC_LIBRARY;SHARED_LIBRARY;INTERFACE_LIBRARY;WARNINGS_DONT_ERROR;NO_LINK_TIME_OPTIMIZATION"
        "CXX_STANDARD"
        "SOURCE_FILES;PUBLIC_LINKS;PRIVATE_LINKS;INTERFACE_LINKS;COMPILE_OPTIONS"
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
    foreach(item IN LISTS _PUBLIC_LINKS _PRIVATE_LINKS _INTERFACE_LINKS)
        if(NOT TARGET ${item})
            message(FATAL_ERROR "`${item}` is not a target")
        endif()
    endforeach()

    # Verify `COMPILE_OPTIONS`
    if(_COMPILE_OPTIONS AND is_interface)
        message(WARNING "`COMPILE_OPTIONS` specified for interface library")
    endif()

    # Verify `WARNINGS_DONT_ERROR`
    if(_WARNINGS_DONT_ERROR AND is_interface)
        message(WARNING "`WARNINGS_DONT_ERROR` specified for interface library")
    endif()

    # Verify `NO_LINK_TIME_OPTIMIZATION`
    if(_NO_LINK_TIME_OPTIMIZATION AND is_interface)
        message(WARNING "`NO_LINK_TIME_OPTIMIZATION` specified for interface library")
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
                # Not using generator expressions since we generate our own package install files
                ${CMAKE_CURRENT_SOURCE_DIR}/include
        )
    endif()

    # Add additional `external` include directory
    if(NOT is_interface AND IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/external)
        target_include_directories(${target} PRIVATE external)
    endif()

    # Do links
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

    # Set C++ standard
    if(_CXX_STANDARD)
        set(cxx_standard ${_CXX_STANDARD})
    else()
        set(cxx_standard cxx_std_20)
    endif()
    if(is_interface)
        set(cxx_standard_access INTERFACE)
    elseif(is_library)
        set(cxx_standard_access PUBLIC)
    else()
        set(cxx_standard_access PRIVATE)
    endif()
    target_compile_features(${target} ${cxx_standard_access} ${cxx_standard})

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

    # Append `-d` to generated debug libraries so they don't collide with release libraries
    if (is_library)
        set_target_properties(${target} PROPERTIES DEBUG_POSTFIX "-d")
    endif()

    # Enable link-time optimization
    if(NOT is_interface AND QC_RELEASE AND NOT _NO_LINK_TIME_OPTIMIZATION)
        set_target_properties(${target} PROPERTIES INTERPROCEDURAL_OPTIMIZATION TRUE)
    endif()
endfunction()
