include_guard()

include(utility.cmake)

#
# Combines multiple static libraries together
#
# See https://cristianadam.eu/20190501/bundling-together-static-libraries-with-cmake/
#
# qc_bundle_static_libraries(
#     <target>
#     UNBUNDLED_LIBRARY <target>
#     BUNDLE_LIBRARIES <target>...
#     [PUBLIC_LINKS <target>...]
#     [PRIVATE_LINKS <target>...]
# )
#
function(qc_bundle_static_libraries target)
    cmake_parse_arguments(
        PARSE_ARGV
        1
        ""
        ""
        "UNBUNDLED_LIBRARY"
        "BUNDLE_LIBRARIES;PUBLIC_LINKS;PRIVATE_LINKS"
    )
    qc_check_args()

    # Verify unbundled library is present
    if(NOT DEFINED _UNBUNDLED_LIBRARY)
        message(FATAL_ERROR "Must provide unbundled library")
    endif()

    # Verify bundle libraries are present
    if(NOT DEFINED _BUNDLE_LIBRARIES)
        message(FATAL_ERROR "Must provide at least one bundle library")
    endif()

    # Verify everything is a target
    foreach(item IN LISTS _UNBUNDLED_LIBRARY _BUNDLE_LIBRARIES _PUBLIC_LINKS _PRIVATE_LINKS)
        if(NOT TARGET ${item})
            message(FATAL_ERROR "`${item}` is not a target")
        endif()
    endforeach()

    # Verify unbundled library is not imported
    get_target_property(is_imported ${_UNBUNDLED_LIBRARY} IMPORTED)
    if(is_imported)
        message(FATAL_ERROR "Unbundled library `${_UNBUNDLED_LIBRARY}` must not be imported")
    endif()

    # Verify all libraries are static
    foreach(target IN LISTS _UNBUNDLED_LIBRARY _BUNDLE_LIBRARIES)
        get_target_property(target_type ${target} TYPE)
        if(NOT target_type STREQUAL "STATIC_LIBRARY")
            if(target_type STREQUAL "UNKNOWN_LIBRARY")
                # TODO: Figure out why Freetype is `UNKOWN_LIBRARY`
                message(WARNING "Target `${target}` has type `UNKNOWN_LIBRARY`")
            else()
                message(FATAL_ERROR "Target `${target}` must have type `STATIC_LIBRARY` but has type `${target_type}`")
            endif()
        endif()
    endforeach()

    # Get list of library files to bundle
    unset(loose_library_files)
    foreach(target IN LISTS _UNBUNDLED_LIBRARY _BUNDLE_LIBRARIES)
       list(APPEND loose_library_files $<TARGET_FILE:${target}>)
    endforeach()

    # Determine filepath for generated bundled library file
    unset(library_file_postfix)
    if(QC_DEBUG)
        get_target_property(library_file_postfix ${_UNBUNDLED_LIBRARY} DEBUG_POSTFIX)
    endif()
    set(bundled_library_file ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${target}${library_file_postfix}${CMAKE_STATIC_LIBRARY_SUFFIX})

    # Combine the libraries
    if(QC_MSVC)
        qc_list_to_pretty_string("${_UNBUNDLED_LIBRARY};${_BUNDLE_LIBRARIES}" bundle_libraries_string)
        find_program(lib_tool lib)
        add_custom_command(
            TARGET ${_UNBUNDLED_LIBRARY}
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E echo "Bundling static libraries ${bundle_libraries_string} into `${target}`..."
            COMMAND ${lib_tool} /NOLOGO /OUT:${bundled_library_file} ${loose_library_files}
            BYPRODUCTS ${bundled_library_file}
            VERBATIM
            COMMAND_EXPAND_LISTS
        )
    else()
        # TODO
        message(FATAL_ERROR "Currently only MSVC is supported for bundling static libraries")
    endif()

    # Create bundled library
    add_library(${target} STATIC IMPORTED GLOBAL)

    # Set imported location and include directory
    get_target_property(include_dirs ${_UNBUNDLED_LIBRARY} INTERFACE_INCLUDE_DIRECTORIES)
    set_target_properties(
        ${target}
        PROPERTIES
            IMPORTED_LOCATION ${bundled_library_file}
            INTERFACE_INCLUDE_DIRECTORIES "${include_dirs}"
    )

    # Add links
    _qc_make_interface_link_libraries_list("${_PUBLIC_LINKS}" "${_PRIVATE_LINKS}" links_list)
    if(DEFINED links_list)
        set_target_properties(${target} PROPERTIES INTERFACE_LINK_LIBRARIES "${links_list}")
    endif()

    # Set C++ standard
    get_target_property(cxx_standard ${_UNBUNDLED_LIBRARY} CXX_STANDARD)
    set_target_properties(${target} PROPERTIES CXX_STANDARD ${cxx_standard})

    # Set debug postfix
    get_target_property(debug_postfix ${_UNBUNDLED_LIBRARY} DEBUG_POSTFIX)
    set_target_properties(${target} PROPERTIES DEBUG_POSTFIX ${debug_postfix})

    # Set link-time optimization
    get_target_property(interprocedural_optimization ${_UNBUNDLED_LIBRARY} INTERPROCEDURAL_OPTIMIZATION)
    set_target_properties(${target} PROPERTIES INTERPROCEDURAL_OPTIMIZATION ${interprocedural_optimization})

    # Set special tag to help with installation later
    set_target_properties(${target} PROPERTIES QC_IS_LOCAL_BUNDLED_LIBRARY TRUE)

    # Make sure the unbundled library is built first
    add_dependencies(${target} ${_UNBUNDLED_LIBRARY})
endfunction()
