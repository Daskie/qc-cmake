include_guard()

include(utility.cmake)

#
# Sets up certain global setting/variables/optimizations. Should be called once at the top of the project
#
# qc_setup_general([NO_LINK_TIME_OPTIMIZATION])
#
function(qc_setup_general)
    cmake_parse_arguments(
        PARSE_ARGV
        0
        ""
        "NO_LINK_TIME_OPTIMIZATION"
        ""
        ""
    )
    qc_check_args()

    # Append `-d` to generated debug libraries so they don't collide with release libraries
   set(CMAKE_DEBUG_POSTFIX -d PARENT_SCOPE)

    # Enable link-time optimization
    if(QC_RELEASE AND NOT _NO_LINK_TIME_OPTIMIZATION)
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE PARENT_SCOPE)
    endif()
endfunction()
