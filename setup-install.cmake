include_guard()

include(create-package-files.cmake)
include(utility.cmake)

function(_qc_qualify_targets targets out_qualified_targets)
    unset(qualified_targets)

    foreach(target IN LISTS targets)
        if(NOT target MATCHES "::")
            get_target_property(is_imported ${target} IMPORTED)
            get_target_property(is_local_bundled_library ${target} QC_IS_LOCAL_BUNDLED_LIBRARY)
            if(NOT is_imported OR is_local_bundled_library)
                string(PREPEND target "${CMAKE_PROJECT_NAME}::")
            endif()
        endif()
        list(APPEND qualified_targets ${target})
    endforeach()

    set(${out_qualified_targets} ${qualified_targets} PARENT_SCOPE)
endfunction()

function(_qc_extract_public_private_links_from_target target out_public_links out_private_links)
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
    _qc_qualify_targets("${public_links}" qualified_public_links)
    _qc_qualify_targets("${private_links}" qualified_private_links)

    list(REMOVE_DUPLICATES qualified_public_links)
    list(REMOVE_DUPLICATES qualified_private_links)

    set(${out_public_links} ${qualified_public_links} PARENT_SCOPE)
    set(${out_private_links} ${qualified_private_links} PARENT_SCOPE)
endfunction()

#
# Sets up the install commands for the given targets
#
# qc_setup_install(
#     TARGETS <target>...
#     [DEPENDENCIES <package>...]
# )
#
function(qc_setup_install)
    cmake_parse_arguments(
        PARSE_ARGV
        0
        ""
        ""
        ""
        "TARGETS;DEPENDENCIES"
    )
    qc_check_args()

    # Validate targets
    if(NOT DEFINED _TARGETS)
        message(FATAL_ERROR "Must provide targets")
    endif()
    foreach(target IN LISTS _TARGETS)
        get_target_property(target_type ${target} TYPE)
        if(NOT target_type STREQUAL "STATIC_LIBRARY" AND NOT target_type STREQUAL "INTERFACE_LIBRARY")
            message(FATAL_ERROR "Target `${target}`'s type `${target_type}` is not currently supported")
        endif()
    endforeach()

    # Get links from each target
    set(i 0)
    unset(per_target_public_links)
    unset(per_target_private_links)
    foreach(target IN LISTS _TARGETS)
        _qc_extract_public_private_links_from_target(${target} public_links_${i} private_links_${i})

        list(APPEND per_target_public_links public_links_${i})
        list(APPEND per_target_private_links private_links_${i})

        math(EXPR i "${i} + 1")
    endforeach()

    qc_create_package_files("${_TARGETS}" "${per_target_public_links}" "${per_target_private_links}" "${_DEPENDENCIES}" package_files)

    # Install library files
    foreach(target IN LISTS _TARGETS)
        get_target_property(target_type ${target} TYPE)
        if(target_type STREQUAL "STATIC_LIBRARY")
            install(
                FILES $<TARGET_FILE:${target}>
                DESTINATION ${CMAKE_INSTALL_LIBDIR}
            )
        endif()
    endforeach()

    # Install include directory
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include)
        install(
            DIRECTORY include/ # Trailing slash means everything WITHIN the directory is copied rather than the directory itself being copied
            DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        )
    else()
        message(WARNING "No `include` directory found to install for package `${CMAKE_PROJECT_NAME}`")
    endif()

    # Install package cmake files
    install(
        FILES ${package_files}
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${CMAKE_PROJECT_NAME}
    )
endfunction()
