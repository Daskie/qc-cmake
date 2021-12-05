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
function(qc_setup_target target)
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
