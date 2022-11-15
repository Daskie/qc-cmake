include_guard()

include(utility.cmake)

set(QC_WARNINGS_MSVC
    /W4     # Typical baseline
    /w14062 # Ensure all enum switch cases are handled
    /w14242 # 'identifier': conversion from 'type1' to 'type1', possible loss of data
    /w14254 # 'operator': conversion from 'type1:field_bits' to 'type2:field_bits', possible loss of data
    /w14263 # 'function': member function does not override any base class virtual member function
    /w14265 # 'classname': class has virtual functions, but destructor is not virtual instances of this class may not be destructed correctly
    /w14287 # 'operator': unsigned/negative constant mismatch
    /we4289 # Nonstandard extension used: 'variable': loop control variable declared in the for-loop is used outside the for-loop scope
    /w14296 # 'operator': expression is always 'boolean_value'
    /w14311 # 'variable': pointer truncation from 'type1' to 'type2'
    /w14545 # Expression before comma evaluates to a function which is missing an argument list
    /w14546 # Function call before comma missing argument list
    /w14547 # 'operator': operator before comma has no effect; expected operator with side-effect
    /w14549 # 'operator': operator before comma has no effect; did you intend 'operator'?
    /w14555 # Expression has no effect; expected expression with side- effect
    /w14619 # Pragma warning: there is no warning number 'number'
    /w14640 # Enable warning on thread un-safe static member initialization
    /w14826 # Conversion from 'type1' to 'type_2' is sign-extended. This may cause unexpected runtime behavior.
    /w14905 # Wide string literal cast to 'LPSTR'
    /w14906 # String literal cast to 'LPWSTR'
    /w14928 # Illegal copy-initialization; more than one user-defined conversion has been implicitly applied
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
