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
#     [BUNDLE_LIBS <target>...]
#     [CXX_STANDARD <cxx_standard>]
#     [ENABLE_EXCEPTIONS]
#     [ENABLE_RTTI]
#     [DISABLE_AVX]
#     [DISABLE_AVX2]
#     [DISABLE_WERROR]
#     [DISABLE_LTO]
#     [COMPILE_OPTIONS <option>...]
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
        "EXECUTABLE;STATIC_LIBRARY;SHARED_LIBRARY;INTERFACE_LIBRARY;ENABLE_EXCEPTIONS;ENABLE_RTTI;DISABLE_AVX;DISABLE_AVX2;DISABLE_WERROR;DISABLE_LTO"
        "CXX_STANDARD"
        "SOURCE_FILES;PUBLIC_LINKS;PRIVATE_LINKS;INTERFACE_LINKS;BUNDLE_LIBS;COMPILE_OPTIONS")

    qc_check_args()

    set(package ${CMAKE_PROJECT_NAME})

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
    if(library_type)
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
    if(_SOURCE_FILES AND is_interface)
        message(FATAL_ERROR "Interface library must not have source files")
    endif()

    # Verify links
    if(_INTERFACE_LINKS AND NOT is_interface)
        message(FATAL_ERROR "Only interface libraries may have interface links")
    endif()
    foreach(item IN LISTS _PUBLIC_LINKS _PRIVATE_LINKS _INTERFACE_LINKS)
        if(NOT TARGET ${item})
            message(FATAL_ERROR "Link `${item}` is not a target")
        endif()
    endforeach()

    # Verify bundle libs
    if(_BUNDLE_LIBS AND NOT target_type STREQUAL "STATIC_LIBRARY")
        message(FATAL_ERROR "`BUNDLE_LIBS may only be specified for static libraries`")
    endif()
    foreach(bundle_target IN LISTS _BUNDLE_LIBS)
        if(NOT TARGET ${bundle_target})
            message(FATAL_ERROR "Bundle library `${bundle_target}` is not a target")
        else()
            get_target_property(target_type ${bundle_target} TYPE)
            if(NOT target_type STREQUAL "STATIC_LIBRARY")
                message(FATAL_ERROR "Bundle target `${bundle_target}` must have type `STATIC_LIBRARY` but has type `${target_type}`")
            endif()
        endif()
    endforeach()

    # Verify `ENABLE_EXCEPTIONS`
    if(_ENABLE_EXCEPTIONS AND is_interface)
        message(WARNING "`ENABLE_EXCEPTIONS` specified for interface library")
    endif()

    # Verify `ENABLE_RTTI`
    if(_ENABLE_RTTI AND is_interface)
        message(WARNING "`ENABLE_RTTI` specified for interface library")
    endif()

    # Verify `DISABLE_WERROR`
    if(_DISABLE_WERROR AND is_interface)
        message(WARNING "`DISABLE_WERROR` specified for interface library")
    endif()

    # Verify `DISABLE_AVX`
    if(_DISABLE_AVX AND is_interface)
        message(WARNING "`DISABLE_AVX` specified for interface library")
    endif()

    # Verify `DISABLE_AVX2`
    if(_DISABLE_AVX2 AND is_interface)
        message(WARNING "`DISABLE_AVX2` specified for interface library")
    endif()

    # Verify `DISABLE_LTO`
    if(_DISABLE_LTO AND is_interface)
        message(WARNING "`DISABLE_LTO` specified for interface library")
    endif()

    # Verify `COMPILE_OPTIONS`
    if(_COMPILE_OPTIONS AND is_interface)
        message(WARNING "`COMPILE_OPTIONS` specified for interface library")
    endif()

    # Enable RTTI if exceptions are enabled
    if(_ENABLE_EXCEPTIONS)
        set(_ENABLE_RTTI TRUE)
    endif()

    # Check for common directory misnames
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src)
        message(WARNING "Ignoring directory `src`; possible misname of `source`")
    endif()
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/sources)
        message(WARNING "Ignoring directory `sources`; possible misname of `source`")
    endif()
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/includes)
        message(WARNING "Ignoring directory `includes`; possible misname of `include`")
    endif()
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/extern)
        message(WARNING "Ignoring directory `extern`; possible misname of `external`")
    endif()
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/externals)
        message(WARNING "Ignoring directory `externals`; possible misname of `external`")
    endif()
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/externs)
        message(WARNING "Ignoring directory `externs`; possible misname of `external`")
    endif()

    # Find source files if not provided
    set(source_files ${_SOURCE_FILES})
    unset(source_dir)
    if(NOT DEFINED _SOURCE_FILES AND NOT is_interface)
        # Determine source directory
        if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/source)
            set(source_dir ${CMAKE_CURRENT_SOURCE_DIR}/source)
        else()
            set(source_dir ${CMAKE_CURRENT_SOURCE_DIR})
        endif()

        # Find source files in source directory
        if(source_dir EQUAL ${PROJECT_SOURCE_DIR})
            file(GLOB source_files LIST_DIRECTORIES false RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${source_dir}/*.cpp)
        else()
            file(GLOB_RECURSE source_files LIST_DIRECTORIES false RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${source_dir}/*.cpp)
        endif()

        list(LENGTH source_files source_file_count)
        if(source_file_count EQUAL 0)
            message(FATAL_ERROR "No source files found under `${source_dir}`")
        endif()
    endif()

    # Add library or executable
    if(is_executable)
        add_executable(${target} ${source_files})
    else()
        add_library(${target} ${library_type} ${source_files})
    endif()

    # Add root header files
    file(GLOB header_files LIST_DIRECTORIES false RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.hpp)
    if(header_files)
        if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include)
            message(FATAL_ERROR "Found loose header files AND an `include` directory; expected one or the other")
        endif()
        if(is_library)
            if(is_interface)
                set(scope INTERFACE)
            else()
                set(scope PUBLIC)
            endif()
        else()
            set(scope PRIVATE)
        endif()
        target_sources(${target} ${scope} FILE_SET HEADERS FILES ${header_files})
    endif()

    # Add public header files
    if(is_library AND IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include)
        file(GLOB_RECURSE header_files LIST_DIRECTORIES false RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} include/*.hpp)
        if(header_files)
            if(is_interface)
                set(scope INTERFACE)
            else()
                set(scope PUBLIC)
            endif()
            target_sources(${target} ${scope} FILE_SET HEADERS BASE_DIRS include FILES ${header_files})
        endif()
    endif()

    # Add private include directories
    if(NOT is_interface)
        # Include `source` directory
        if(source_dir)
            target_include_directories(${target} PRIVATE ${source_dir})
        endif()

        # Include `external` directory
        if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/external)
            target_include_directories(${target} PRIVATE external)
        endif()
    endif()

    # Do links
    if(_PUBLIC_LINKS)
        target_link_libraries(${target} PUBLIC ${_PUBLIC_LINKS})
    endif()
    foreach(private_link IN LISTS _PRIVATE_LINKS)
        get_target_property(link_type ${private_link} TYPE)
        if(link_type STREQUAL "INTERFACE_LIBRARY" OR private_link IN_LIST _BUNDLE_LIBS)
            # Workaround to avoid private header-only or bundled libraries being added to the link interface
            target_link_libraries(${target} PRIVATE $<BUILD_INTERFACE:${private_link}>)
        else()
            target_link_libraries(${target} PRIVATE ${private_link})
        endif()
    endforeach()
    if(_INTERFACE_LINKS)
        target_link_libraries(${target} INTERFACE ${_INTERFACE_LINKS})
    endif()

    # Set C++ standard
    # Use default if target-level standard not specified
    if(NOT _CXX_STANDARD)
        set(_CXX_STANDARD ${QC_CXX_STANDARD})
    endif()
    set_property(TARGET ${target} PROPERTY CXX_STANDARD ${_CXX_STANDARD})
    set_property(TARGET ${target} PROPERTY CXX_STANDARD_REQUIRED ON)
    set_property(TARGET ${target} PROPERTY CXX_EXTENSIONS OFF) # Disable compiler-specific extensions (-std=c++XX instead of -gnu=c++XX)

    # Set compile definitions
    if (NOT is_interface)
        # Set build type
        if(QC_DEBUG)
            target_compile_definitions(${target} PRIVATE QC_DEBUG)
        endif()
        if(QC_RELEASE)
            target_compile_definitions(${target} PRIVATE QC_RELEASE)
        endif()

        # Set compiler
        if (QC_MSVC)
            target_compile_definitions(${target} PRIVATE QC_MSVC)
        endif()
        if (QC_GCC)
            target_compile_definitions(${target} PRIVATE QC_GCC)
        endif()
        if (QC_CLANG)
            target_compile_definitions(${target} PRIVATE QC_CLANG)
        endif()

        # Set platform
        if (QC_WINDOWS)
            target_compile_definitions(${target} PRIVATE QC_WINDOWS)
        endif()
        if (QC_LINUX)
            target_compile_definitions(${target} PRIVATE QC_LINUX)
        endif()
        if (QC_APPLE)
            target_compile_definitions(${target} PRIVATE QC_APPLE)
        endif()
    endif()

    # Set compile options
    if(NOT is_interface)
        # Set AVX/AVX2
        if(NOT _DISABLE_AVX)
            if(NOT _DISABLE_AVX2)
                if(QC_MSVC)
                    target_compile_options(${target} PRIVATE /arch:AVX2)
                else()
                    target_compile_options(${target} PRIVATE -mavx2)
                endif()
            else()
                if(QC_MSVC)
                    target_compile_options(${target} PRIVATE /arch:AVX)
                else()
                    target_compile_options(${target} PRIVATE -mavx)
                endif()
            endif()
        endif()

        # Set exceptions
        if(_ENABLE_EXCEPTIONS)
            if(QC_MSVC)
                target_compile_options(${target} PRIVATE /EHsc)
            endif()
        else()
            if(QC_MSVC)
                # `/EHsc` is already removed from `CMAKE_CXX_FLAGS`
                target_compile_options(${target} PRIVATE /D_HAS_EXCEPTIONS=0)
            else()
                target_compile_options(${target} PRIVATE -fno-exceptions -fno-unwind-tables)
            endif()
        endif()

        # Set RTTI
        if(NOT _ENABLE_RTTI)
            if(QC_MSVC)
                target_compile_options(${target} PRIVATE /GR-)
            else()
                target_compile_options(${target} PRIVATE -fno-rtti)
            endif()
        endif()

        # Set warnings
        target_compile_options(${target} PRIVATE ${QC_WARNINGS})
        if(NOT _DISABLE_WERROR)
            if(QC_MSVC)
                target_compile_options(${target} PRIVATE /WX)
            else()
                target_compile_options(${target} PRIVATE -Werror -Wfatal-errors)
            endif()
        endif()

        # Set other user-specified options
        target_compile_options(${target} PRIVATE ${_COMPILE_OPTIONS})
    endif()

    # Set precompiled header
    if(source_dir AND EXISTS ${source_dir}/pch.hpp)
        target_precompile_headers(${target} PRIVATE ${source_dir}/pch.hpp)
    endif()

    # Append `-d` to generated debug libraries so they don't collide with release libraries
    if(is_library)
        set_target_properties(${target} PROPERTIES DEBUG_POSTFIX "-d")
    endif()

    # Remove `lib` prefix UNIX likes to add for some reason
    if(is_library)
        set_target_properties(${target} PROPERTIES PREFIX "")
    endif()

    # Enable link-time optimization
    if(NOT is_interface AND QC_RELEASE AND NOT _DISABLE_LTO)
        set_target_properties(${target} PROPERTIES INTERPROCEDURAL_OPTIMIZATION TRUE)
    endif()

    # Define share directory property if the share directory exists
    # TODO: Add to install procedure
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/share)
        set_target_properties(${target} PROPERTIES QC_SHARE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/share)
    endif()

    # Remove build share directory if it exists
    set(build_share_directory ${CMAKE_CURRENT_BINARY_DIR}/share)
    if(EXISTS ${build_share_directory})
        message(DEBUG "Removing build share directory `${build_share_directory}`")
        file(REMOVE_RECURSE ${build_share_directory})
    endif()

    # Make symlinks to the share data of us and our dependencies
    # TODO: Add to install procedure
    foreach(share_data_source IN LISTS target _PUBLIC_LINKS _PRIVATE_LINKS)
        get_target_property(share_directory ${share_data_source} QC_SHARE_DIRECTORY)
        if(share_directory)
            message(STATUS "Creating symlinks for `${share_data_source}`'s share data")

            # Ensure our build share directory exists
            if(NOT EXISTS ${build_share_directory})
                message(DEBUG "Creating build share directory `${build_share_directory}`")
                file(MAKE_DIRECTORY ${build_share_directory})
            endif()

            # Link each thing in the share directory in our build share directory
            file(GLOB data_paths ${share_directory}/*)
            foreach(data_path IN LISTS data_paths)
                cmake_path(GET data_path FILENAME data_filename)
                set(link_path ${build_share_directory}/${data_filename})
                if(EXISTS ${link_path})
                    message(FATAL_ERROR "Share data `${data_filename}` already exists")
                endif()
                message(DEBUG "Linking `${link_path}` -> `${data_path}`")
                file(CREATE_LINK ${data_path} ${link_path} SYMBOLIC)
            endforeach()
        endif()
    endforeach()

    # Bundle libs
    if(_BUNDLE_LIBS)
        if(QC_MSVC)
            # Get list of lib files to bundle
            unset(bundle_libs)
            foreach(bundle_target IN LISTS target _BUNDLE_LIBS)
               list(APPEND bundle_libs $<TARGET_FILE:${bundle_target}>)
            endforeach()

            # Use `lib` command to merge libs
            set(bundle_command lib /NOLOGO /OUT:$<TARGET_FILE:${target}> ${bundle_libs})
        else()
            # Create AR MRI script
            set(mri "open $<TARGET_FILE:${target}>\n")
            foreach(lib IN LISTS _BUNDLE_LIBS)
                string(APPEND mri "addlib $<TARGET_FILE:${lib}>\n")
            endforeach()
            string(APPEND mri "save\n")
            string(APPEND mri "end")

            # Create bash script that uses `ar` to merge libs
            set(script_file ${CMAKE_CURRENT_BINARY_DIR}/bundle-${target}.sh)
            set(script "#!/bin/bash\n\n")
            string(APPEND script "echo \"${mri}\" | ar -M\n")
            file(GENERATE
                OUTPUT ${script_file}
                CONTENT "${script}"
                FILE_PERMISSIONS
                    OWNER_READ OWNER_WRITE OWNER_EXECUTE
                    GROUP_READ GROUP_EXECUTE
                    WORLD_READ WORLD_EXECUTE)

            set(bundle_command "${script_file}")
        endif()

        # Create custom command that will merge lib files each time the target is built
        qc_list_to_pretty_string("${_BUNDLE_LIBS}" bundle_libs_string)
        add_custom_command(
            TARGET ${target}
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E echo "Bundling static libraries ${bundle_libs_string} into `${target}`..."
            COMMAND ${bundle_command}
            VERBATIM
            COMMAND_EXPAND_LISTS)
    endif()
endfunction()
