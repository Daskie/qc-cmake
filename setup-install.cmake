include_guard()

include(create-package-files.cmake)
include(utility.cmake)

#
# Sets up the install commands for the given target
#
# qc_setup_install(
#     <target>
#     [DEPENDENCIES <package>...]
#     [WINDOWS_SUB_PROJECT_INSTALL_PREFIX]
# )
#
function(qc_setup_install target)
    cmake_parse_arguments(
        PARSE_ARGV
        1
        ""
        "WINDOWS_SUB_PROJECT_INSTALL_PREFIX"
        ""
        "DEPENDENCIES"
    )
    qc_check_args()

    get_target_property(target_type ${target} TYPE)
    if(NOT target_type STREQUAL "STATIC_LIBRARY" AND NOT target_type STREQUAL "INTERFACE_LIBRARY")
        message(FATAL_ERROR "Target `${target}`'s type `${target_type}` is not yet supported")
    endif()

    # Set install prefix
    # For some reason using `.` in the normal case breaks things, so we use an empty string and adjust accordingly
    if(_WINDOWS_SUB_PROJECT_INSTALL_PREFIX AND WIN32)
        set(install_prefix ${target}/)
    else()
        unset(install_prefix)
    endif()

    # Get links from target
    get_target_property(links ${target} INTERFACE_LINK_LIBRARIES)
    if(links STREQUAL "links-NOTFOUND")
        unset(links)
    endif()

    # Parse links list into public and private lists
    unset(public_links)
    unset(private_links)
    foreach(link IN LISTS links)
        qc_parse_generator_expression(${link} tag value)
        if(NOT DEFINED tag)
            list(APPEND public_links ${link})
        else()
            if(tag STREQUAL "LINK_ONLY")
                qc_parse_generator_expression(${value} inner_tag inner_value)
                if(NOT DEFINED inner_tag)
                    list(APPEND private_links ${value})
                elseif(NOT inner_tag STREQUAL "BUILD_INTERFACE")
                    message(FATAL_ERROR "Unexpected link generator expression `${value}`")
                endif()
            else()
                message(FATAL_ERROR "Unrecognized generator expression tag `${tag}`")
            endif()
        endif()
    endforeach()

    # Add namespace to any internal targets without one
    unset(qualified_public_links)
    unset(qualified_private_links)
    foreach(link IN LISTS public_links)
        get_target_property(is_imported ${link} IMPORTED)
        if(NOT is_imported AND NOT link MATCHES "::")
            string(PREPEND link "${CMAKE_PROJECT_NAME}::")
        endif()
        list(APPEND qualified_public_links ${link})
    endforeach()
    foreach(link IN LISTS private_links)
        get_target_property(is_imported ${link} IMPORTED)
        if(NOT is_imported AND NOT link MATCHES "::")
            string(PREPEND link "${CMAKE_PROJECT_NAME}::")
        endif()
        list(APPEND qualified_private_links ${link})
    endforeach()
    set(public_links ${qualified_public_links})
    set(private_links ${qualified_private_links})
    list(REMOVE_DUPLICATES public_links)
    list(REMOVE_DUPLICATES private_links)

    qc_create_package_files(${target} ${target_type} "${public_links}" "${private_links}" "${_DEPENDENCIES}" package_files)

    # Install library file
    if(target_type STREQUAL "STATIC_LIBRARY")
        install(
            FILES $<TARGET_FILE:${target}>
            DESTINATION ${install_prefix}${CMAKE_INSTALL_LIBDIR}
        )
    endif()

    # Install include directory
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include)
        install(
            DIRECTORY include/ # Trailing slash means everything WITHIN the directory is copied rather than the directory itself being copied
            DESTINATION ${install_prefix}include
        )
    else()
        message(WARNING "No `include` directory found to install for target `${target}`")
    endif()

    # Install package cmake files
    install(
        FILES ${package_files}
        DESTINATION ${install_prefix}${CMAKE_INSTALL_LIBDIR}/cmake/${target}
    )
endfunction()
