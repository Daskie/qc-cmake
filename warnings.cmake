include_guard()

include(utility.cmake)

set(QC_WARNINGS_MSVC
    /Wall   # Start with all warnings
    /wd4061 # enumerator 'identifier' in a switch of enum 'enumeration' is not explicitly handled by a case label
    /wd4201 # nonstandard extension used : nameless struct/union
    /wd4324 # 'struct_name' : structure was padded due to __declspec(align())
    /wd4514 # 'function': unreferenced inline function has been removed
    /wd4577 # 'noexcept' used with no exception handling mode specified; termination on exception is not guaranteed. Specify /EHsc
    /wd4623 # 'derived class': default constructor could not be generated because a base class default constructor is inaccessible
    /wd4626 # 'derived class': assignment operator could not be generated because a base class assignment operator is inaccessible
    /wd4625 # 'derived class': copy constructor could not be generated because a base class copy constructor is inaccessible
    /wd4668 # 'symbol' is not defined as a preprocessor macro, replacing with '0' for 'directives'
    /wd4710 # 'function' : function not inlined
    /wd4711 # function 'function' selected for inline expansion
    /wd4738 # storing 32-bit float result in memory, possible loss of performance
    /wd4800 # Implicit conversion from 'type' to bool. Possible information loss
    /wd4820 # 'bytes' bytes padding added after construct 'member_name'
    /wd4866 # 'file(line_number)' compiler may not enforce left-to-right evaluation order for call to operator_name
    /wd4868 # 'file(line_number)' compiler may not enforce left-to-right evaluation order in braced initialization list
    /wd5024 # 'type': move constructor was implicitly defined as deleted
    /wd5025 # 'type': move assignment operator was implicitly defined as deleted
    /wd5026 # 'type': move constructor was implicitly defined as deleted
    /wd5027 # 'type': move assignment operator was implicitly defined as deleted
    /wd5045 # Compiler will insert Spectre mitigation for memory load if /Qspectre switch specified
    /wd5246 # 'member': the initialization of a subobject should be wrapped in braces
    /wd5262 # implicit fall-through occurs here; are you missing a break statement? Use [[fallthrough]] when a break statement is intentionally omitted between cases # TODO: Enable once standard library is clean
    /wd5264 # 'variable-name': 'const' variable is not used # TODO: Enable once standard library is clean
    /permissive-) # Standards conformance mode for MSVC compiler.

set(QC_WARNINGS_CLANG
    -Wall                   # Typical baseline
    -Wextra                 # More standard warnings
    -Wcast-align            # Warn for potential performance problem casts
    -Wconversion            # Warn on type conversions that may lose data
    -Wformat=2              # Warn on security issues around functions that format output (ie printf)
    -Winit-self             # Warn about uninitialized variables that are initialized with themselves
    -Winvalid-pch           # Warn if a precompiled header is found in the search path but cannot be used
    -Wnon-virtual-dtor      # Warn the user if a class with virtual functions has a non-virtual destructor. This helps catch hard to track down memory errors
    -Wnull-dereference      # Warn if a null dereference is detected
    -Wold-style-cast        # Warn for c-style casts
    -Woverloaded-virtual    # Warn if you overload (not override) a virtual function
    -Wpedantic              # Warn if non-standard C++ is used
    -Wredundant-decls       # Warn if anything is declared more than once in the same scope
    -Wshadow                # Warn the user if a variable declaration shadows one from a parent context
    -Wsign-conversion       # Warn on sign conversions
    -Wunused                # Warn on anything being unused
    -Wno-changes-meaning    # Disalbe warning of a name within a class having the same meaning in the complete scope
    -Wno-dangling-reference # Disable dangling reference warning (lots of false positives)
    -Wno-multichar)         # Disable multichar warning

set(QC_WARNINGS_GCC
    ${QC_WARNINGS_CLANG}
    -Wmisleading-indentation # Warn if indentation implies blocks where blocks do not exist
    -Wduplicated-cond        # Warn if if / else chain has duplicated conditions
    -Wduplicated-branches    # Warn if if / else branches have duplicated code
    -Wlogical-op             # Warn about logical operations being used where bitwise were probably wanted
    -Wuseless-cast)          # Warn if you perform a cast to the same type

if(QC_MSVC)
    set(QC_WARNINGS ${QC_WARNINGS_MSVC})
elseif(QC_CLANG)
    set(QC_WARNINGS ${QC_WARNINGS_CLANG})
elseif(QC_GCC)
    set(QC_WARNINGS ${QC_WARNINGS_GCC})
endif()
set(QC_WARNINGS ${QC_WARNINGS} PARENT_SCOPE)
