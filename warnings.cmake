include_guard()

include(utility.cmake)

set(QC_WARNINGS_MSVC
    /Wall   # Start with all warnings
    /wd4061 # enumerator 'identifier' in a switch of enum 'enumeration' is not explicitly handled by a case label
    /wd4514 # 'function': unreferenced inline function has been removed
    /wd4623 # 'derived class': default constructor could not be generated because a base class default constructor is inaccessible
    /wd4626 # 'derived class': assignment operator could not be generated because a base class assignment operator is inaccessible
    /wd4625 # 'derived class': copy constructor could not be generated because a base class copy constructor is inaccessible
    /wd4668 # 'symbol' is not defined as a preprocessor macro, replacing with '0' for 'directives'
    /wd4710 # 'function' : function not inlined
    /wd4711 # function 'function' selected for inline expansion
    /wd4800 # Implicit conversion from 'type' to bool. Possible information loss
    /wd4820 # 'bytes' bytes padding added after construct 'member_name'
    /wd4868 # 'file(line_number)' compiler may not enforce left-to-right evaluation order in braced initialization list
    /wd5024 # 'type': move constructor was implicitly defined as deleted
    /wd5025 # 'type': move assignment operator was implicitly defined as deleted
    /wd5026 # 'type': move constructor was implicitly defined as deleted
    /wd5027 # 'type': move assignment operator was implicitly defined as deleted
    /wd5045 # Compiler will insert Spectre mitigation for memory load if /Qspectre switch specified
    /wd5246 # 'member': the initialization of a subobject should be wrapped in braces
    /permissive-) # Standards conformance mode for MSVC compiler.

set(QC_WARNINGS_CLANG
    -Wall                # Typical baseline
    -Wextra              # More standard warnings
    -Wshadow             # Warn the user if a variable declaration shadows one from a parent context
    -Wnon-virtual-dtor   # Warn the user if a class with virtual functions has a non-virtual destructor. This helps catch hard to track down memory errors
    -Wold-style-cast     # Warn for c-style casts
    -Wcast-align         # Warn for potential performance problem casts
    -Wunused             # Warn on anything being unused
    -Woverloaded-virtual # Warn if you overload (not override) a virtual function
    -Wpedantic           # Warn if non-standard C++ is used
    -Wconversion         # Warn on type conversions that may lose data
    -Wsign-conversion    # Warn on sign conversions
    -Wnull-dereference   # Warn if a null dereference is detected
    -Wdouble-promotion   # Warn if float is implicit promoted to double
    -Wformat=2)          # Warn on security issues around functions that format output (ie printf)

set(QC_WARNINGS_GCC
    ${QC_WARNINGS_CLANG}
    -Wmisleading-indentation # Warn if indentation implies blocks where blocks do not exist
    -Wduplicated-cond        # Warn if if / else chain has duplicated conditions
    -Wduplicated-branches    # Warn if if / else branches have duplicated code
    -Wlogical-op             # Warn about logical operations being used where bitwise were probably wanted
    -Wuseless-cast)          # Warn if you perform a cast to the same type

# Warnings as errors
set(QC_WARNINGS_ERROR_MSVC ${QC_WARNINGS_MSVC} /WX)
set(QC_WARNINGS_ERROR_CLANG ${QC_WARNINGS_CLANG} -Werror)
set(QC_WARNINGS_ERROR_GCC ${QC_WARNINGS_GCC} -Werror)

if(QC_MSVC)
    set(QC_WARNINGS ${QC_WARNINGS_MSVC})
    set(QC_WARNINGS_ERROR ${QC_WARNINGS_ERROR_MSVC})
elseif(QC_CLANG)
    set(QC_WARNINGS ${QC_WARNINGS_CLANG})
    set(QC_WARNINGS_ERROR ${QC_WARNINGS_ERROR_CLANG})
elseif(CMAKE_GCC)
    set(QC_WARNINGS ${QC_WARNINGS_GCC})
    set(QC_WARNINGS_ERROR ${QC_WARNINGS_ERROR_GCC})
endif()
set(QC_WARNINGS ${QC_WARNINGS} PARENT_SCOPE)
set(QC_WARNINGS_ERROR ${QC_WARNINGS_ERROR} PARENT_SCOPE)
