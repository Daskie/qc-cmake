include_guard()

include(utility.cmake)

#-------------------------------------------------------------------------------

function(_qc_generate_package_config_file dependencies out_file)
    set(package ${CMAKE_PROJECT_NAME})

    set(file_content "\
#
# Generated config file for package `${package}`
#

")
    # Add `find_dependency` for each dependency
    list(LENGTH dependencies dependencies_count)
    if(dependencies_count GREATER 0)
        string(APPEND file_content "\
# Dependencies
include(CMakeFindDependencyMacro)")
        foreach(dependency IN LISTS dependencies)
            string(APPEND file_content "
find_dependency(${dependency})")
        endforeach()
        string(APPEND file_content "

")
    endif()
    string(APPEND file_content "\
include(\"\${CMAKE_CURRENT_LIST_DIR}/${package}-targets.cmake\")
")

    # Write out the generated package config file
    set(file "${CMAKE_CURRENT_BINARY_DIR}/${package}-config.cmake")
    file(WRITE ${file} "${file_content}")
    set(${out_file} ${file} PARENT_SCOPE)
endfunction()

#-------------------------------------------------------------------------------

function(_qc_generate_package_targets_file targets per_target_public_links per_target_private_links out_file)
    set(package ${CMAKE_PROJECT_NAME})

    set(file_content "\
#
# Generated target import file for package `${package}`
#

# Protect against multiple inclusion
foreach(target ${targets})
    if(TARGET ${package}::\${target})
    	return()
    endif()
endforeach()

# Compute the installation prefix relative to this file.
get_filename_component(install_prefix \${CMAKE_CURRENT_LIST_DIR} PATH)
get_filename_component(install_prefix \${install_prefix} PATH)
get_filename_component(install_prefix \${install_prefix} PATH)
if(install_prefix STREQUAL \"/\")
	set(install_prefix \"\")
endif()

")
    foreach(target public_links_var private_links_var IN ZIP_LISTS targets per_target_public_links per_target_private_links)
        set(public_links ${${public_links_var}})
        set(private_links ${${private_links_var}})

        get_target_property(target_type ${target} TYPE)
        if(target_type STREQUAL "STATIC_LIBRARY")
            set(library_type "STATIC")
        elseif(target_type STREQUAL "INTERFACE_LIBRARY")
            set(library_type "INTERFACE")
        else()
            set(library_type "UNSUPPORTED")
        endif()

        _qc_make_interface_link_libraries_list("${public_links}" "${private_links}" links_list)

        string(APPEND file_content "\
# Create imported target `${target}`
add_library(${package}::${target} ${library_type} IMPORTED)
set_target_properties(${package}::${target} PROPERTIES
	INTERFACE_INCLUDE_DIRECTORIES \"\${install_prefix}/${CMAKE_INSTALL_INCLUDEDIR}\"")
        if(DEFINED links_list)
	        string(APPEND file_content "
	INTERFACE_LINK_LIBRARIES \"${links_list}\"")
        endif()
    string(APPEND file_content "
)

")
    endforeach()
    string(APPEND file_content "\
# Clear files to check list to be populated by the configuration files
unset(files_to_check)

# Load information for each installed configuration
file(GLOB config_files \"\${CMAKE_CURRENT_LIST_DIR}/${package}-targets-*.cmake\")
foreach(config_file IN LISTS config_files)
	include(\${config_file})
endforeach()

# Check that files exist
foreach(file IN LISTS files_to_check)
    if(NOT EXISTS \${file})
	    message(FATAL_ERROR \"Expected to find file `\${file}` for package `${package}`\")
    endif()
endforeach()

# Cleanup variables
unset(install_prefix)
unset(files_to_check)
")

    set(file "${CMAKE_CURRENT_BINARY_DIR}/${package}-targets.cmake")
    file(WRITE ${file} "${file_content}")
    set(${out_file} ${file} PARENT_SCOPE)
endfunction()

#-------------------------------------------------------------------------------

function(_qc_generate_package_targets_configuration_file targets out_file)
    set(package ${CMAKE_PROJECT_NAME})

    if(QC_DEBUG)
        set(configuration_string_upper "DEBUG")
        set(configuration_string_lower "debug")
    else()
        set(configuration_string_upper "RELEASE")
        set(configuration_string_lower "release")
    endif()

    set(file_content "\
#
# Generated target configuration import file for package: `${package}` configuration `${configuration_string_lower}`
#
")
    foreach(target IN LISTS targets)
        get_target_property(target_type ${target} TYPE)
        if(target_type STREQUAL "STATIC_LIBRARY")
            if(QC_DEBUG)
                get_target_property(debug_postfix ${target} DEBUG_POSTFIX)
            else()
                unset(debug_postfix)
            endif()

            set(library_file \${install_prefix}/${CMAKE_INSTALL_LIBDIR}/${CMAKE_STATIC_LIBRARY_PREFIX}${target}${debug_postfix}${CMAKE_STATIC_LIBRARY_SUFFIX})
            string(APPEND file_content "
# Import target `${target}`
set_property(TARGET ${package}::${target} APPEND PROPERTY IMPORTED_CONFIGURATIONS ${configuration_string_upper})
set_target_properties(${package}::${target} PROPERTIES
	IMPORTED_LINK_INTERFACE_LANGUAGES_${configuration_string_upper} \"CXX\"
	IMPORTED_LOCATION_${configuration_string_upper} \"${library_file}\"
)
list(APPEND files_to_check \"${library_file}\")
")
    endif()
    endforeach()

    set(file "${CMAKE_CURRENT_BINARY_DIR}/${package}-targets-${configuration_string_lower}.cmake")
    file(WRITE ${file} "${file_content}")
    set(${out_file} ${file} PARENT_SCOPE)
endfunction()

#-------------------------------------------------------------------------------

#
# Helper function to generate package install cmake files
#
function(qc_create_package_files targets per_target_public_links per_target_private_links dependencies out_files_list)
    unset(files_list)

    set(package ${CMAKE_PROJECT_NAME})

    # Generate `<package>-config.cmake` file
    _qc_generate_package_config_file("${dependencies}" config_file)
    list(APPEND files_list ${config_file})

    # Generate `<package>-targets.cmake` file
    _qc_generate_package_targets_file("${targets}" "${per_target_public_links}" "${per_target_private_links}" targets_file)
    list(APPEND files_list ${targets_file})

    # Check if any of the targets are static libraries
    set(any_static_libraries FALSE)
    foreach(target IN LISTS targets)
        get_target_property(target_type ${target} TYPE)
        if(target_type STREQUAL "STATIC_LIBRARY")
            set(any_static_libraries TRUE)
        endif()
    endforeach()

    # Generate `<package>-targets-{debug|release}.cmake` file
    if(any_static_libraries)
        _qc_generate_package_targets_configuration_file("${targets}" targets_configuration_file)
        list(APPEND files_list ${targets_configuration_file})
    endif()

    # Return the file paths
    set(${out_files_list} ${files_list} PARENT_SCOPE)
endfunction()
