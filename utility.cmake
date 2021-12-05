include_guard()

include(GNUInstallDirs)

# Build type
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(QC_DEBUG TRUE)
    set(QC_RELEASE FALSE)
else()
    set(QC_DEBUG FALSE)
    set(QC_RELEASE TRUE)
endif()
set(QC_DEBUG ${QC_DEBUG} PARENT_SCOPE)
set(QC_RELEASE ${QC_RELEASE} PARENT_SCOPE)

# Compiler
if(MSVC)
    set(QC_MSVC TRUE)
    set(QC_MSVC ${QC_MSVC} PARENT_SCOPE)
elseif(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    set(QC_CLANG TRUE)
    set(QC_CLANG ${QC_CLANG} PARENT_SCOPE)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(QC_GCC TRUE)
    set(QC_GCC ${QC_GCC} PARENT_SCOPE)
else()
    message(WARNING "Compiler not recognized")
endif()

#
# Check `cmake_parse_arguments` results
#
# qc_check_args()
#
macro(qc_check_args)
    if(DEFINED _UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Invalid arguments `${_UNPARSED_ARGUMENTS}`")
    endif()
    if(DEFINED _KEYWORDS_MISSING_VALUES)
        message(FATAL_ERROR "Arguments missing values `${_KEYWORDS_MISSING_VALUES}`")
    endif()
endmacro()

#
# Parses the tag and optional value from a generator expression
#
# If the generator expression doesn't have a value, e.g. `$<CONFIG>`, `out_value` will be undefined
#
# If the exression is not a valid generator expression, both `out_tag` and `out_value` will be undefined
#
function(qc_parse_generator_expression expression out_tag out_value)
    unset(${out_tag} PARENT_SCOPE)
    unset(${out_value} PARENT_SCOPE)
    if(expression MATCHES "^\\\$<([a-zA-Z0-9_]+)(:(.*))?>\$")
        set(${out_tag} ${CMAKE_MATCH_1} PARENT_SCOPE)
        if(DEFINED CMAKE_MATCH_2 AND NOT CMAKE_MATCH_2 STREQUAL "")
            set(${out_value} ${CMAKE_MATCH_3} PARENT_SCOPE)
        endif()
    endif()
endfunction()

#
# Helper function to generate a list suitable for `INTERFACE_LINK_LIBRARIES` from public and private link targets
#
function(qc_make_interface_link_libraries_list public_links private_links out_links_list)
    # Add `$<LINK_ONLY:...>` generator expression to private links
    list(TRANSFORM private_links PREPEND "\$<LINK_ONLY:" OUTPUT_VARIABLE decorated_private_links)
    list(TRANSFORM decorated_private_links APPEND ">" OUTPUT_VARIABLE decorated_private_links)

    set(${out_links_list} ${public_links} ${decorated_private_links} PARENT_SCOPE)
endfunction()
