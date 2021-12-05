include_guard()

include(utility.cmake)

#
# Helper function to generate package install cmake files
#
function(qc_create_package_files package package_type public_links private_links dependencies out_files_list)
    unset(files_list)

    set(qualified_package ${CMAKE_PROJECT_NAME}::${package})

    if(package_type STREQUAL "STATIC_LIBRARY")
        set(library_type "STATIC")
    elseif(package_type STREQUAL "INTERFACE_LIBRARY")
        set(library_type "INTERFACE")
    else()
        set(library_type "UNSUPPORTED")
    endif()

    # Generate `<package>-config.cmake` file

    unset(config_file_content)
    list(LENGTH dependencies dependencies_count)
    if(dependencies_count GREATER 0)
        string(APPEND config_file_content "\
# Dependencies
include(CMakeFindDependencyMacro)")
        foreach(dependency IN LISTS dependencies)
            string(APPEND config_file_content "
find_dependency(${dependency})")
        endforeach()
        string(APPEND config_file_content "

")
    endif()
    string(APPEND config_file_content "\
include(\"\${CMAKE_CURRENT_LIST_DIR}/${package}-targets.cmake\")
")

    set(config_file "${CMAKE_CURRENT_BINARY_DIR}/${package}-config.cmake")
    file(WRITE ${config_file} "${config_file_content}")
    list(APPEND files_list ${config_file})

    # Generate `<package>-targets.cmake` file

    qc_make_interface_link_libraries_list("${public_links}" "${private_links}" links_list)

    set(targets_file_content "\
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
add_library(${qualified_package} ${library_type} IMPORTED)
set_target_properties(${qualified_package} PROPERTIES
	INTERFACE_INCLUDE_DIRECTORIES \"\${install_prefix}/include\"")
    if(DEFINED links_list)
	    string(APPEND targets_file_content "
	INTERFACE_LINK_LIBRARIES \"${links_list}\"")
    endif()
    string(APPEND targets_file_content "
)

# Load information for each installed configuration
file(GLOB config_files \"\${CMAKE_CURRENT_LIST_DIR}/${package}-targets-*.cmake\")
foreach(config_file IN LISTS config_files)
	include(\${config_file})
endforeach()

# Cleanup temporary variables
unset(install_prefix)
")

    set(targets_file "${CMAKE_CURRENT_BINARY_DIR}/${package}-targets.cmake")
    file(WRITE ${targets_file} "${targets_file_content}")
    list(APPEND files_list ${targets_file})

    # Generate `<package>-targets-{debug|release}.cmake` file
    if(NOT package_type STREQUAL "INTERFACE_LIBRARY")
        if(QC_DEBUG)
            set(configuration_string_upper "DEBUG")
            set(configuration_string_lower "debug")
            set(library_file_postfix "${CMAKE_DEBUG_POSTFIX}")
        else()
            set(configuration_string_upper "RELEASE")
            set(configuration_string_lower "release")
            unset(library_file_postfix)
        endif()

        set(targets_configuration_file_content "\
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

        set(targets_configuration_file "${CMAKE_CURRENT_BINARY_DIR}/${package}-targets-${configuration_string_lower}.cmake")
        file(WRITE ${targets_configuration_file} "${targets_configuration_file_content}")
        list(APPEND files_list ${targets_configuration_file})
    endif()

    # Return the file paths
    set(${out_files_list} ${files_list} PARENT_SCOPE)
endfunction()
