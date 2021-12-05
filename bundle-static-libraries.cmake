include_guard()

include(utility.cmake)

#
# Combines multiple static libraries together
#
# See https://cristianadam.eu/20190501/bundling-together-static-libraries-with-cmake/
#
# qc_bundle_static_libraries(
#     <target>
#     BUNDLE_LIBRARIES <target>...
#     [PUBLIC_LINKS <target>...]
#     [PRIVATE_LINKS <target>...]
#     [INSTALLABLE]
#         [WINDOWS_SUB_PROJECT_INSTALL_PREFIX]
# )
#
function(qc_bundle_static_libraries target)
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

    # Verify bundle libraries and public/priate links are targets
    foreach(item IN LISTS _BUNDLE_LIBRARIES _PUBLIC_LINKS _PRIVATE_LINKS)
        if(NOT TARGET ${item})
            message(FATAL_ERROR "`${item}` is not a target")
        endif()
    endforeach()

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


    # Create bundled library
    add_library(${target} STATIC IMPORTED GLOBAL)

    # Set imported location and include directory
    set_target_properties(
        ${target}
        PROPERTIES
            IMPORTED_LOCATION ${bundled_library_file}
            INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR}/include
    )

    # Add links
    qc_make_interface_link_libraries_list("${_PUBLIC_LINKS}" "${_PRIVATE_LINKS}" links_list)
    if(DEFINED links_list)
        set_target_properties(
            ${target}
            PROPERTIES
                INTERFACE_LINK_LIBRARIES "${links_list}"
        )
    endif()

    # Add bundling target as dependency
    add_dependencies(${target} ${target}-bundling)
endfunction()
