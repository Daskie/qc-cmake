include_guard()
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
