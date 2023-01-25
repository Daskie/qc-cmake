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
                if(target_type STREQUAL "UNKNOWN_LIBRARY")
                    # TODO: Figure out why Freetype is `UNKOWN_LIBRARY`
                    message(WARNING "Bundle target `${bundle_target}` has type `UNKNOWN_LIBRARY`")
                else()
                    message(FATAL_ERROR "Bundle target `${bundle_target}` must have type `STATIC_LIBRARY` but has type `${target_type}`")
                endif()
            endif()
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

    # Check for anything in the include directory that isn't a subdirectory named after the package
    file(GLOB include_items RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/include include/*)
    foreach(item IN LISTS include_items)
        if(NOT item STREQUAL package)
            message(WARNING "Unexpected include directory item will be ignored: ${item}")
        endif()
    endforeach()

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
    if(is_library AND IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/${package})
        file(GLOB_RECURSE header_files LIST_DIRECTORIES false RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} include/${package}/*.hpp)
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
    if(source_dir AND EXISTS ${source_dir}/pch.hpp)
        target_precompile_headers(${target} PRIVATE ${source_dir}/pch.hpp)
    endif()

    # Append `-d` to generated debug libraries so they don't collide with release libraries
    if(is_library)
        set_target_properties(${target} PROPERTIES DEBUG_POSTFIX "-d")
    endif()

    # Enable link-time optimization
    if(NOT is_interface AND QC_RELEASE AND NOT _NO_LINK_TIME_OPTIMIZATION)
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
        # Get list of library files to bundle
        unset(bundle_libs)
        foreach(bundle_target IN LISTS target _BUNDLE_LIBS)
           list(APPEND bundle_libs $<TARGET_FILE:${bundle_target}>)
        endforeach()

        # Merge the lib files
        if(QC_MSVC)
            qc_list_to_pretty_string("${_BUNDLE_LIBS}" bundle_libs_string)
            find_program(lib_tool lib)
            add_custom_command(
                TARGET ${target}
                POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E echo "Bundling static libraries ${bundle_libs_string} into `${target}`..."
                COMMAND ${lib_tool} /NOLOGO /OUT:$<TARGET_FILE:${target}> ${bundle_libs}
                VERBATIM
                COMMAND_EXPAND_LISTS)
        else()
            # TODO
            message(FATAL_ERROR "Currently only MSVC is supported for bundling static libraries")
        endif()
    endif()
endfunction()
