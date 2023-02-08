include_guard()

include(GNUInstallDirs)

# Build type constants
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(QC_DEBUG TRUE)
    set(QC_RELEASE FALSE)
else()
    set(QC_DEBUG FALSE)
    set(QC_RELEASE TRUE)
endif()
set(QC_DEBUG ${QC_DEBUG} PARENT_SCOPE)
set(QC_RELEASE ${QC_RELEASE} PARENT_SCOPE)

# Compiler constants
unset(QC_MSVC)
unset(QC_CLANG)
unset(QC_GCC)
if(MSVC)
    set(QC_MSVC TRUE)
elseif(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    set(QC_CLANG TRUE)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(QC_GCC TRUE)
else()
    message(FATAL_ERROR "Compiler not recognized")
endif()
set(QC_MSVC ${QC_MSVC} PARENT_SCOPE)
set(QC_CLANG ${QC_CLANG} PARENT_SCOPE)
set(QC_GCC ${QC_GCC} PARENT_SCOPE)

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
        message(FATAL_ERROR "Missing argument values `${_KEYWORDS_MISSING_VALUES}`")
    endif()
endmacro()

#
# Convert a list to a space-delimited string
#
macro(qc_list_to_space_string list out_string)
    string(REPLACE ";" " " ${out_string} "${list}")
endmacro()

#
# Convert a list to a pretty english oxford list where each element is in ticks
#
# Examples:
#     a     -> `a`
#     a;b   -> `a` and `b`
#     a;b;c -> `a`, `b`, and `c`
#
function(qc_list_to_pretty_string list out_string)
    unset(string)
    list(LENGTH list length)

    if(length EQUAL 1)
        set(string "`${list}`")
    elseif(length EQUAL 2)
        list(GET list 0 first)
        list(GET list 1 second)
        set(string "`${first}` and `${second}`")
    elseif(length GREATER_EQUAL 3)
        math(EXPR length_minus_two "${length} - 2")
        foreach(i RANGE ${length_minus_two})
            list(GET list ${i} element)
            string(APPEND string "`${element}`, ")
        endforeach()
        math(EXPR length_minus_one "${length} - 1")
        list(GET list ${length_minus_one} element)
        string(APPEND string "and `${element}`")
    endif()

    set(${out_string} "${string}" PARENT_SCOPE)
endfunction()

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
function(_qc_make_interface_link_libraries_list public_links private_links out_links_list)
    # Add `$<LINK_ONLY:...>` generator expression to private links
    unset(decorated_private_links)
    foreach(link IN LISTS private_links)
        list(APPEND decorated_private_links "\$<LINK_ONLY:${link}>")
    endforeach()

    set(${out_links_list} ${public_links} ${decorated_private_links} PARENT_SCOPE)
endfunction()
