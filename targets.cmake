# message() string listing allowed target architectures.
set(_PATH64_SUPPORTED_TARGETS_STRING "Supported architectures are:
  x86_32
  x86_64
  mips_32
  mips_64
  powerpc64
  powerpc64le
  arm
  aarch64")

# Target information table, keyed by entries of PATH64_ENABLE_TARGETS.
# Reference table entries with ${_PATH64_TARGET_ARCH_${arch}}.

# we need to pass appropriate system suffix for target, or otherwise
# clang is not going to define __sun on Solaris
if("${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS")
    set(system_suffix "solaris")
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    set(system_suffix "apple-darwin13.1.0")
else()
    set(system_suffix "linux-gnu")
endif()

set(_PATH64_TARGET_ARCH_x86_32 x8664)
set(_PATH64_TARGET_FLAGS_x86_32 -target i686-${system_suffix})
set(_PATH64_TARGET_BITS_x86_32 32)
set(_PATH64_TARGET_ABI_x86_32 ABI_M32)
set(_PATH64_TARGET_LLVM_ARCH_x86_32 i386)

set(_PATH64_TARGET_ARCH_x86_64 x8664)
set(_PATH64_TARGET_FLAGS_x86_64 -target x86_64-${system_suffix})
set(_PATH64_TARGET_BITS_x86_64 64)
set(_PATH64_TARGET_ABI_x86_64 ABI_M64)
set(_PATH64_TARGET_LLVM_ARCH_x86_64 x86_64)

# use -march=anyx86 for x8664 target in package mode
if(PATH64_ENABLE_PSCRUNTIME AND "${CMAKE_C_COMPILER_ID}" STREQUAL "PathScale" AND PATH64_ENABLE_PACKAGE_MODE)
    list(APPEND _PATH64_TARGET_FLAGS_x86_64 "-march=anyx86")
endif()


set(_PATH64_TARGET_ARCH_mips_32 mips)
set(_PATH64_TARGET_FLAGS_mips_32 -target mips32)
set(_PATH64_TARGET_BITS_mips_32 32)
set(_PATH64_TARGET_ABI_mips_32 ABI_N32)
set(_PATH64_TARGET_LLVM_ARCH_mips_32 mips)

set(_PATH64_TARGET_ARCH_mips_64 mips)
set(_PATH64_TARGET_FLAGS_mips_64 -target mips64)
set(_PATH64_TARGET_BITS_mips_64 64)
set(_PATH64_TARGET_ABI_mips_64 ABI_64)
set(_PATH64_TARGET_LLVM_ARCH_mips_64 mips64)

set(_PATH64_TARGET_ARCH_arm arm)
set(_PATH64_TARGET_FLAGS_arm -target arm64)
set(_PATH64_TARGET_BITS_arm 64)
set(_PATH64_TARGET_ABI_arm ABI_ARM_ver1)
set(_PATH64_TARGET_LLVM_ARCH_arm aarch64)

set(_PATH64_TARGET_ARCH_aarch64 aarch64)
set(_PATH64_TARGET_FLAGS_aarch64 -target aarch64)
set(_PATH64_TARGET_BITS_aarch64 64)
set(_PATH64_TARGET_ABI_aarch64 ABI_AARCH64)
set(_PATH64_TARGET_LLVM_ARCH_aarch64 aarch64)

set(_PATH64_TARGET_ARCH_powerpc64 powerpc64)
set(_PATH64_TARGET_FLAGS_powerpc64 -target powerpc64)
set(_PATH64_TARGET_BITS_powerpc64 64)
set(_PATH64_TARGET_ABI_powerpc64 ABI_PPC64BE)
set(_PATH64_TARGET_LLVM_ARCH_powerpc64 powerpc64)

set(_PATH64_TARGET_ARCH_powerpc64le powerpc64)
set(_PATH64_TARGET_FLAGS_powerpc64le -target powerpc64le)
set(_PATH64_TARGET_BITS_powerpc64le 64)
set(_PATH64_TARGET_ABI_powerpc64le ABI_PPC64LE)
set(_PATH64_TARGET_LLVM_ARCH_powerpc64le powerpc64le)


# setting _PATH64_TARGET_FLAGS_STR_<targ> variables
foreach(targ ${PATH64_ENABLE_TARGETS})
    string(REPLACE ";" " " _PATH64_TARGET_FLAGS_STR_${targ} "${_PATH64_TARGET_FLAGS_${targ}}")
endforeach()


# Architecture flags
set(_PATH64_ARCH_FLAGS_x8664 "-DTARG_X8664")
set(_PATH64_ARCH_FLAGS_mips "-DTARG_MIPS")     # TODO: fix it
set(_PATH64_ARCH_FLAGS_rsk6 "-DTARG_RSK6")     # TODO: fix it
set(_PATH64_ARCH_FLAGS_arm "-DTARG_ST -DTARG_ARM -DTARG_BIGENDIAN -DBE_EXPORTED= -DTARGINFO_EXPORTED= -DSUPPORTS_SELECT -DMUMBLE_ARM_BSP")     # TODO: fix it
set(_PATH64_ARCH_FLAGS_aarch64 "-DTARG_AARCH64")
set(_PATH64_ARCH_FLAGS_powerpc64 "-DTARG_PPC64 -DTARG_ANY") # sub-total sub-fucking sub-hack. Instead of TARG_ANY we need to implement native stuff in b_swap.c

set(FORTRAN_SOURCE_EXTENSIONS f F f77 F77 f90 F90 for For FOR f95 F95)


# Returns the Path64 canonical name for specified architecture
function(path64_canonical_arch ret arch)
    if    (${arch} MATCHES "x86.*64|amd64|AMD64")
        set(${ret} "x86_64" PARENT_SCOPE)
    elseif(${arch} MATCHES "x86|i[3-6]86")
        set(${ret} "x86_32" PARENT_SCOPE)
    elseif(${arch} MATCHES "mips.*64")
        set(${ret} "mips_64" PARENT_SCOPE)
    elseif(${arch} MATCHES "mips.*32")
        set(${ret} "mips_32" PARENT_SCOPE)
    elseif(${arch} MATCHES "rsk6.*64")
        set(${ret} "rsk6_64" PARENT_SCOPE)
    elseif(${arch} MATCHES "rsk6.*32")
        set(${ret} "rsk6_32" PARENT_SCOPE)
    elseif(${arch} MATCHES "arm")
        set(${ret} "arm" PARENT_SCOPE)
    elseif(${arch} MATCHES "aarch64")
        set(${ret} "aarch64" PARENT_SCOPE)
    elseif(${arch} MATCHES "ppc64le")
        set(${ret} "powerpc64le" PARENT_SCOPE)
    elseif(${arch} MATCHES "ppc64")
        set(${ret} "powerpc64" PARENT_SCOPE)
    else()
        set(${ret} "${arch}" PARENT_SCOPE)
    endif()
endfunction()


# Returns target for host system
function(path64_get_host_target res_var)
    if(NOT "${PATH64_HOST_TARGET}" STREQUAL "")
        set(${res_var} "${PATH64_HOST_TARGET}" PARENT_SCOPE)
    else()
        path64_canonical_arch(arch ${CMAKE_SYSTEM_PROCESSOR})
        set(${res_var} ${arch} PARENT_SCOPE)
    endif()
endfunction()


if(NOT PATH64_ENABLE_TARGETS)
    if("${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS" OR
       "${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")

        # defaulting to x86_64 on solaris and windows
        set(PATH64_ENABLE_TARGETS "x86_64")
    endif()
endif()
    
# Defaulting to host target if PATH64_ENABLE_TARGETS is not specified
if(NOT PATH64_ENABLE_TARGETS)
    path64_get_host_target(PATH64_ENABLE_TARGETS)
    message(STATUS "Defaulting to ${PATH64_ENABLE_TARGETS} target")
endif()


# Building list of enabled architectures
set(PATH64_ENABLE_ARCHES)
set(_targets "")
set(_sep "")
    
foreach(targ ${PATH64_ENABLE_TARGETS})
    set(targ_arch ${_PATH64_TARGET_ARCH_${targ}})

    if(NOT targ_arch)
        message(FATAL_ERROR "'${targ}' is not among supported architectures.
${_PATH64_SUPPORTED_TARGETS_STRING}
Please edit PATH64_ENABLE_TARGETS to list only valid architectures.
")
    endif()

    list(FIND PATH64_ENABLE_ARCHES ${targ_arch} res)
    if(${res} EQUAL -1)
        list(APPEND PATH64_ENABLE_ARCHES ${targ_arch})
    endif()

    set(_targets "${_targets}${_sep}${targ}")
    set(_sep ", ")
endforeach()


foreach(targ ${PATH64_ENABLE_TARGETS})
    set(arch ${_PATH64_TARGET_LLVM_ARCH_${targ}})
    file(MAKE_DIRECTORY ${Path64_BINARY_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch})
endforeach()


# First list element is the default.
# TODO: test for the the native build environment and make that the default target
list(GET PATH64_ENABLE_TARGETS 0 PATH64_DEFAULT_TARGET)
message(STATUS
  "Building support for targets ${_targets}.  Default is ${PATH64_DEFAULT_TARGET}.")
message(STATUS "PATH64_ENABLE_ARCHES: ${PATH64_ENABLE_ARCHES}")


# Returns target bits
function(path64_get_target_bits res_var targ)
   set(${res_var} ${_PATH64_TARGET_BITS_${targ}} PARENT_SCOPE)
endfunction()


# Returns target arch
function(path64_get_target_arch res_var targ)
   set(${res_var} ${_PATH64_TARGET_ARCH_${targ}} PARENT_SCOPE)
endfunction()


# Returns architecture for host system
function(path64_get_host_arch res_var)
    path64_get_host_target(targ)
    set(${res_var} ${_PATH64_TARGET_ARCH_${targ}} PARENT_SCOPE)
endfunction()


if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    set(crt_objects crt1.o crti.o crtn.o gcrt1.o Scrt1.o)
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS")
    set(crt_objects crt1.o crti.o crtn.o gcrt1.o)
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "FreeBSD")
    set(crt_objects crt1.o crti.o crtn.o gcrt1.o)
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    set(crt_objects crt1.o )
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    set(crt_objects crt1.o dllcrt1.o crtbegin.o crtend.o)

    # copy mingw libraries to runtime directory on windows
    set(crt_objects ${crt_objects} libmingw32.a libmingwex.a libmoldname.a
                                   libmsvcrt.a libadvapi32.a libshell32.a
                                   libuser32.a libkernel32.a)
else()
    message(FATAL_ERROR "Unsupported platform")
endif()


#p detecting CRT paths for all targets
foreach(targ ${PATH64_ENABLE_TARGETS})
    set(crt_path_name "PSC_CRT_PATH_${targ}")
    set(crt_path "${${crt_path_name}}")

    path64_get_target_arch(arch "${targ}")
    path64_get_host_arch(host_arch)
    set(llvm_arch ${_PATH64_TARGET_LLVM_ARCH_${targ}})

    # try detect crt path for host arch if not specified
    if("${crt_path}" STREQUAL "")
        if("${arch}" STREQUAL "${host_arch}")

            # selecting target flag
            if(${_PATH64_TARGET_BITS_${targ}} EQUAL 64)
                set(target_flags "-m64")
            else()
                set(target_flags "-m32")
            endif()

            execute_process(COMMAND "${CMAKE_C_COMPILER}" ${target_flags} "-print-file-name=crt1.o"
                            RESULT_VARIABLE res
                            ERROR_VARIABLE  err  # expected error for non-cross-compiling GNU
                            OUTPUT_VARIABLE crt_path)
            string(REPLACE "\n" "" crt_path "${crt_path}")
            if(res EQUAL 0 AND NOT "${crt_path}" STREQUAL "")
                get_filename_component(crt_path "${crt_path}" ABSOLUTE)
                if(EXISTS "${crt_path}")
                    get_filename_component(crt_path "${crt_path}" PATH)
                    set(${crt_path_name} "${crt_path}")
                endif()
            endif()
        endif()

        if("${${crt_path_name}}" STREQUAL "")
            message(FATAL_ERROR "Can't detect CRT path for '${targ}' target. Please set PSC_CRT_PATH_${targ} variable")
        else()
            message(STATUS "crt path for '${targ}' target: '${${crt_path_name}}'")
        endif()
    endif()

    foreach(obj ${crt_objects})
        set(output "${Path64_BINARY_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${llvm_arch}/${obj}")
        add_custom_command(OUTPUT "${output}"
                           COMMAND "${CMAKE_COMMAND}" -E copy "${PSC_SYSROOT_${arch}}${crt_path}/${obj}" "${output}")
        list(APPEND crt_deps "${output}")

        install(FILES "${output}" DESTINATION "lib/clang/${CLANG_FULL_VERSION}/${CLANGRT_SYSTEM}/${llvm_arch}")
    endforeach()
endforeach()
add_custom_target(compiler-stage-crt DEPENDS ${crt_deps})


# Replaces substring in all strings in list
function(list_string_replace lst pattern replace)
    set(res)
    foreach(str ${${lst}})
        string(REPLACE ${pattern} ${replace} new_str ${str})
        list(APPEND res ${new_str}) 
    endforeach()

    set(${lst} ${res} PARENT_SCOPE)
endfunction()


# Returns file name extension
function(path64_get_file_ext res fname)
    set(ext ${fname})

    while(1)
        get_filename_component(ex ${ext} EXT)

        string(LENGTH "${ex}" exlength)
        if(${exlength} EQUAL 0)
            set(${res} ${ext} PARENT_SCOPE)
            return()
        endif()

        math(EXPR exlength "${exlength} - 1")
        string(SUBSTRING ${ex} 1 ${exlength} ext)
    endwhile()

    set(${res} ${ext} PARENT_SCOPE)
endfunction()


# Returns file name base
function(path64_get_file_base res fn)
    get_filename_component(fname ${fn} NAME)
    path64_get_file_ext(ext ${fname})

    string(LENGTH ${fname} fname_length)
    string(LENGTH ${ext} ext_length)
    math(EXPR base_length "${fname_length} - ${ext_length} - 1")
    string(SUBSTRING "${fname}" 0 ${base_length} base)
    set(${res} ${base} PARENT_SCOPE)
endfunction()


# Replaces in list of strings:
# 1) All @PATTERN@ patterns with ${pattern_val}
# 2) All @PATTERN{name} patterns with name-${pattern_val}
function(list_string_replace_patterns lst pattern pattern_val)
    set(alist ${${lst}})
    list_string_replace(alist "@${pattern}@" ${pattern_val})

    set(new_lst)
    foreach(x ${alist})
        string(REGEX REPLACE "@${pattern}{(.+)}" "\\1-${pattern_val}" new_x ${x})
        list(APPEND new_lst ${new_x})
    endforeach()

    set(${lst} ${new_lst} PARENT_SCOPE)
endfunction()


function(list_string_replace_arch lst arch)
    set(blist ${${lst}})
    list_string_replace_patterns(blist "ARCH" ${arch})
    set(${lst} ${blist} PARENT_SCOPE)
endfunction()


# Returns multitarget cmake target name for specified target
function(path64_get_multitarget_cmake_target res_var name target)
    set(${res_var} ${name}-${target} PARENT_SCOPE)
endfunction()


# Checks that target with specified name exists
function(path64_check_target_exists tname)
    if(NOT _PATH64_TARGET_ARCH_${tname})
        message(FATAL_ERROR "Target with name '${tname}' does not exist")
    endif()
endfunction()


# Checks that arch with specified name exists
function(path64_check_arch_exists aname)
    if(NOT _PATH64_ARCH_FLAGS_${aname})
        message(FATAL_ERROR "Architecture with name '${aname}' does not exist")
    endif()
endfunction()


# Returns true if specified target is enabled
function(path64_is_target_enabled res_var targ)
    list(FIND PATH64_ENABLE_TARGETS ${targ} res)
    if(res EQUAL -1)
        set(${res_var} false PARENT_SCOPE)
    else()
        set(${res_var} true PARENT_SCOPE)
    endif()
endfunction()


# Returns true if specified architecture is enabled
function(path64_is_arch_enabled res_var arch)
    list(FIND PATH64_ENABLE_ARCHES ${arch} res)
    if(res EQUAL -1)
        set(${res_var} false PARENT_SCOPE)
    else()
        set(${res_var} true PARENT_SCOPE)
    endif()
endfunction()


# Sets sources for specified target in multitarget source list
function(path64_set_multitarget_sources name target)
    string(COMPARE EQUAL "${target}" "COMMON" res)
    if(NOT res)
        path64_check_target_exists("${target}")
    endif()

    set(path64_multitarget_sources_${name}_${target} ${ARGN} PARENT_SCOPE)
endfunction()


# Sets base path to sources for multitarget source list
function(path64_set_multitarget_sources_base_path name)
    set(path64_multitarget_sources_base_${name} ${ARGN} PARENT_SCOPE)
endfunction()


# I think this should be deleted
# There's a bug in top level cmake file that if this is ON it breaks Fortran
option(PATH64_USE_SYSTEM_COMPILER_FOR_TARGET_LIBS
       "Use system compiler for building target libraries" OFF)


if(PATH64_USE_SYSTEM_COMPILER_FOR_TARGET_LIBS)
    set(path64_compiler_C "${CMAKE_C_COMPILER}")
    set(path64_compiler_CXX "${CMAKE_CXX_COMPILER}")
    set(path64_compiler_amp "${CMAKE_CXX_COMPILER}")
    set(path64_compiler_Fortran "${CMAKE_Fortran_COMPILER}")
else()
    # path64 compilers for languages
    set(path64_compiler_C "${Path64_BINARY_DIR}/bin/clang")
    set(path64_compiler_CXX "${Path64_BINARY_DIR}/bin/clang++")
endif()


# Returns compiler for specified language
function(path64_get_compiler_for_language res lang use_sys)
    if(${use_sys})
        set(${res} "${CMAKE_${lang}_COMPILER}" PARENT_SCOPE)
    else()
        set(${res} "${path64_compiler_${lang}}" PARENT_SCOPE)
    endif()
endfunction()


# Returns flags for compiling language for target
function (get_language_target_flags res lang targ)
    set(flags)

    # Compiler ABI.
    string(REPLACE " " ";" arch_flags_list "${_PATH64_ARCH_FLAGS_${arch}}")
    set(flags ${_PATH64_TARGET_FLAGS_${targ}})
    list(APPEND flags ${arch_flags_list})

    # Getting directory compile definitions
    get_property(compile_defs DIRECTORY PROPERTY COMPILE_DEFINITIONS)
    foreach(def ${compile_defs})
        list(APPEND flags "-D${def}")
    endforeach()

    # Gettings language flags
    string(REPLACE " " ";" lang_flags "${CMAKE_${lang}_FLAGS}")
    foreach(flag ${lang_flags})
        # skipping -march= flags
        if (NOT "${flag}" MATCHES "-march=")
            list(APPEND flags "${flag}")
        endif()
    endforeach()
    
    # Getting include directories
    get_property(incl_dirs DIRECTORY PROPERTY INCLUDE_DIRECTORIES)
    foreach(dir ${incl_dirs})
        list(APPEND flags "-I${dir}")
    endforeach()

    # Getting build type flags
    if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        set(build_type_flags_str "${CMAKE_${lang}_FLAGS_DEBUG}")
    elseif("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
        set(build_type_flags_str "${CMAKE_${lang}_FLAGS_RELEASE}")
    elseif("${CMAKE_BUILD_TYPE}" STREQUAL "relwithdebinfo")
        set(build_type_flags_str "${CMAKE_${lang}_FLAGS_RELWITHDEBINFO}")
    endif()
    string(REPLACE " " ";" build_type_flags "${build_type_flags_str}")
    foreach(flag ${build_type_flags})
        # skipping -march= flags
        if (NOT "${flag}" MATCHES "-march=")
            list(APPEND flags "${flag}")
        endif()
    endforeach()

    set(${res} "${flags}" PARENT_SCOPE)
endfunction()


# Adds library for specified target
function(path64_add_library_for_target name target type src_base_path)
    path64_check_target_exists(${target})

    # Compiler ABI.
    set(arch ${_PATH64_TARGET_LLVM_ARCH_${targ}})

    set(build_lib_dir "${path64_multitarget_property_${name}_OUTPUT_DIRECTORY}")
    if("${build_lib_dir}" STREQUAL "")
        set(build_lib_dir ${Path64_BINARY_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch})
    endif()

    make_directory("${build_lib_dir}")
    set(install_lib_dir lib)

    # Replacing @TARGET@ with target name in source names
    set(sources ${ARGN})
    list_string_replace(sources "@TARGET@" ${target})

#    add_library (${name} ${type} ${sources})
#    set_property(TARGET ${name} PROPERTY COMPILE_FLAGS ${arch_flag})
#    set_property(TARGET ${name} PROPERTY LINK_FLAGS ${arch_flag})
#
#    set_property(TARGET ${name} PROPERTY LIBRARY_OUTPUT_DIRECTORY ${build_lib_dir})
#    set_property(TARGET ${name} PROPERTY ARCHIVE_OUTPUT_DIRECTORY ${build_lib_dir})

    # Searching header dependencies
    set(header_deps)
    foreach(src ${sources})
        path64_get_file_ext(src_ext ${src})
        if("${src_ext}" STREQUAL "h")
            list(APPEND header_deps ${src})
        endif()
    endforeach()

    set(compiler-deps)
    set(use_sys_compiler ${path64_use_system_compiler_for_multitarget_${name}})

    # Adding rules for compiling sources
    set(objects)
    set(rel_objects)
    foreach(src ${sources})
        # Getting source language
        
        path64_get_file_ext(src_ext ${src})
        list(FIND FORTRAN_SOURCE_EXTENSIONS "${src_ext}" res)
        if(NOT res EQUAL -1)
            set(src_lang "Fortran")
        else()
            get_property(src_lang SOURCE ${src} PROPERTY LANGUAGE)
            if(NOT src_lang)
                # Trying get language from extension
                foreach(lang C CXX Fortran)
                    foreach(lang_ext ${CMAKE_${lang}_SOURCE_FILE_EXTENSIONS})
                        if("${lang_ext}" STREQUAL "${src_ext}")
                            set(src_lang ${lang})
                            break()
                        endif()
                    endforeach()
                    if(src_lang)
                        break()
                    endif()
                endforeach()

                # Special case for assembler
                if("${src_ext}" STREQUAL "S" OR "${src_ext}" STREQUAL "s")
                    set(src_lang C)
                endif()
            endif()
        endif()

        # special case for headers
        if(NOT "${src_ext}" STREQUAL "h")
            set(last_src_lang ${src_lang})

            if(NOT src_lang)
                message(FATAL_ERROR "Can not determine language for ${src}")
            endif()
    
            # Getting source compile definitions
            get_property(src_compile_defs_list SOURCE ${src} PROPERTY COMPILE_DEFINITIONS)
            set(src_compile_defs_flags)
            foreach(def ${src_compile_defs_list})
                list(APPEND src_compile_defs_flags "-D${def}")
            endforeach()
    
            # Getting source compile flags
            get_property(src_flags_list SOURCE ${src} PROPERTY COMPILE_FLAGS)
            string(REPLACE " " ";" src_flags "${src_flags_list}")
    
            # Getting target compile flags
            string(REPLACE " " ";" target_flags
                    "${path64_multitarget_property_${name}_COMPILE_FLAGS} ${path64_multitarget_property_${name}_${target}_COMPILE_FLAGS}")

            # Gettings language flags for target
            get_language_target_flags(lang_flags ${src_lang} ${target})
    
            # Getting target compile definitions
            set(target_compile_defs)
            foreach(def ${path64_multitarget_property_${name}_COMPILE_DEFINITIONS})
                list(APPEND target_compile_defs "-D${def}")
            endforeach()
    
            # Getting additional object dependencies
            get_property(obj_depends_rel SOURCE ${src} PROPERTY OBJECT_DEPENDS)
            set(obj_depends)
            foreach(dep ${obj_depends_rel})
                list(APPEND obj_depends ${CMAKE_CURRENT_BINARY_DIR}/${name}-${targ}/${dep})
            endforeach()

            # Getting additional object outputs
            get_property(obj_outputs_rel SOURCE ${src} PROPERTY OBJECT_OUTPUTS)
            set(obj_outputs)
            foreach(out ${obj_outputs_rel})
                list(APPEND obj_outputs ${CMAKE_CURRENT_BINARY_DIR}/${name}-${targ}/${out})
            endforeach()

            # Getting full path to source
            set(oname ${src})
            if(NOT EXISTS ${src})
                # Trying use base path
                if(NOT "${src_base_path}" STREQUAL "")
                    if(EXISTS "${src_base_path}/${src}")
                        set(src "${src_base_path}/${src}")
                    else()
                        message(FATAL_ERROR "Can not find ${src_base_path}/${src} source")
                    endif()
                else()
                    # Trying path relative to current source dir
                    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${src}")
                        set(src "${CMAKE_CURRENT_SOURCE_DIR}/${src}")
                    else()
                        message(FATAL_ERROR "Can not find ${src} source")
                    endif()
                endif()
            endif()

            if(IS_ABSOLUTE "${oname}")
                if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
                    # Removing drive in oname
                    string(LENGTH "${oname}" str_len)
                    math(EXPR str_len "${str_len} - 3")
                    string(SUBSTRING "${oname}" 3 ${str_len} oname)
                else()
                    # Removing first slash in oname
                    string(LENGTH "${oname}" str_len)
                    math(EXPR str_len "${str_len} - 1")
                    string(SUBSTRING "${oname}" 1 ${str_len} oname)
                endif()             
            endif()

            # Getting object output name and making path to it
            string(REPLACE "." "_" oname_mangled ${oname})
            set(object_rel_name "${oname_mangled}.o")
            set(object_name "${CMAKE_CURRENT_BINARY_DIR}/${name}-${targ}/${object_rel_name}")
            get_filename_component(object_path ${object_name} PATH)
            file(MAKE_DIRECTORY ${object_path})

            # Removing conflicting options frm lang_flags
            set(oflags -O0 -O1 -O2 -O3)
            foreach(oflag ${oflags})
                list(FIND target_flags ${oflag} res)
                if(NOT ${res} EQUAL -1)
                    list(REMOVE_ITEM lang_flags ${oflags})
                    break()
                endif()
            endforeach()          

            path64_get_compiler_for_language(compiler "${src_lang}" "${use_sys_compiler}")

            add_custom_command(OUTPUT ${object_name} ${obj_outputs}
                               COMMAND ${compiler} -c -o ${object_rel_name}
                                       ${src_flags}
                                       ${lang_flags}
                                       ${target_flags}
                                       ${compile_defs_flags}
                                       ${src_compile_defs_flags}
                                       ${target_compile_defs}
                                       ${src}
                                       ${build_type_flags}
                               DEPENDS ${src} ${header_deps} ${obj_depends}
                               WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${name}-${targ})
            list(APPEND rel_objects "${object_rel_name}")
            list(APPEND objects ${object_name})
            list(FIND compiler-deps "compiler-stage-${src_lang}" res)
            if(res EQUAL -1)
                list(APPEND compiler-deps "compiler-stage-${src_lang}")
            endif()
        endif()
    endforeach()

    if(path64_multitarget_property_${name}_OUTPUT_NAME)
        set(oname ${path64_multitarget_property_${name}_OUTPUT_NAME})
    else()
        set(oname ${name})
    endif()

    # Adding rule for linking
    if("X${type}" STREQUAL "XSTATIC")
        set(library_file
            "${build_lib_dir}/${CMAKE_STATIC_LIBRARY_PREFIX}${oname}${CMAKE_STATIC_LIBRARY_SUFFIX}")

        path64_get_host_arch(host_arch)
        set(cmd ${CMAKE_AR} -cr ${library_file} ${rel_objects})
        if("X${CMAKE_BUILD_TYPE}" STREQUAL "XRelease" AND
           NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS" AND
           "${host_arch}" STREQUAL "${arch}")

            list(APPEND cmd "\;")
            list(APPEND cmd strip -S ${library_file})
        endif()

        add_custom_command(OUTPUT ${library_file}
                           COMMAND ${cmd}
                           DEPENDS ${objects}
                           WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${name}-${targ})
    elseif("X${type}" STREQUAL "XSHARED")
        string(REPLACE " " ";" target_link_flags "${path64_multitarget_property_${name}_LINK_FLAGS}")
        set(library_file
            "${build_lib_dir}/${CMAKE_SHARED_LIBRARY_PREFIX}${oname}${CMAKE_SHARED_LIBRARY_SUFFIX}")

        set(link_libs_flags)
        foreach(lib ${path64_multitarget_link_libraries_${name}})
            if("${lib}" MATCHES "-l*")
                list(APPEND link_libs_flags "${lib}")
            else()
                list(APPEND link_libs_flags "-l${lib}")
            endif()
        endforeach()

        if("X${CMAKE_BUILD_TYPE}" STREQUAL "XRelease")
            list(APPEND link_libs_flags "-s")
        endif()

        if(path64_multitarget_property_${name}_LINKER_LANGUAGE)
            set(link_lang ${path64_multitarget_property_${name}_LINKER_LANGUAGE})
        else()
            set(link_lang ${last_src_lang})
        endif()

        list(FIND compiler-deps "compiler-stage-${link_lang}" res)
        if(res EQUAL -1)
            list(APPEND compiler-deps "compiler-stage-${link_lang}")
        endif()

        path64_get_compiler_for_language(compiler "${link_lang}" "${use_sys_compiler}")
	message ( STATUS "GET_LANGUAGE_TARGET_FLAGS ${link_lang} ${target}" )
	get_language_target_flags(targ_flags ${link_lang} ${target})

        if(hash_style_supported)
            set(hash_style_flag "-Wl,--hash-style=sysv")
        endif()

        set(install_name_flags)
        if("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
            set(install_name_flags "-install_name" "@rpath/${CMAKE_SHARED_LIBRARY_PREFIX}${oname}${CMAKE_SHARED_LIBRARY_SUFFIX}")
        endif()

        add_custom_command(OUTPUT ${library_file}
                           COMMAND ${compiler} -shared -o ${library_file}
                                   ${install_name_flags}
                                   -L "${build_lib_dir}"
                                   ${targ_flags}
                                   ${target_link_flags}
                                   ${rel_objects}
                                   ${link_libs_flags}
                                   ${hash_style_flag}
                           DEPENDS ${objects}
                           WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${name}-${targ})
    else()
        message(FATAL_ERROR "Unknown library type: ${type}")
    endif()

    add_custom_target(${name}-${targ} ALL
                      DEPENDS ${library_file})

    if(NOT PATH64_USE_SYSTEM_COMPILER_FOR_TARGET_LIBS)
        add_dependencies(${name}-${targ} ${compiler-deps})
    endif()

    install(FILES ${library_file}
            DESTINATION ${install_lib_dir})

#    install(TARGETS ${name}
#      LIBRARY DESTINATION ${install_lib_dir}
#      ARCHIVE DESTINATION ${install_lib_dir})

endfunction()


# Adds library for all enabled targets
function(path64_add_multitarget_library name type)
    set(src_list_name path64_multitarget_sources_${name})
    set(src_base_path "${path64_multitarget_sources_base_${name}}")
    foreach(targ ${PATH64_ENABLE_TARGETS})
        if(${src_list_name}_${targ})
            path64_add_library_for_target(${name} ${targ} ${type} "${src_base_path}"
                                          ${${src_list_name}_${targ}})
        else()
            path64_add_library_for_target(${name} ${targ} ${type} "${src_base_path}"
                                          ${${src_list_name}_COMMON})
        endif()
        #set_property(TARGET ${tg_name} PROPERTY OUTPUT_NAME ${name})
    endforeach()
endfunction()


# Sets property for multitarget
function(path64_set_multitarget_property_ name prop)
    foreach(targ ${PATH64_ENABLE_TARGETS})
        set(path64_multitarget_property_${name}_${prop} ${ARGN} PARENT_SCOPE)
    endforeach()
endfunction()


# Sets target specific property for multitarget
function(path64_set_multitarget_property_for_target name targ prop)
    set(path64_multitarget_property_${name}_${targ}_${prop} ${ARGN} PARENT_SCOPE)
endfunction()


# Adds link libraries to multitarget
function(path64_multitarget_link_libraries name)
    foreach(targ ${PATH64_ENABLE_TARGETS})
        set(path64_multitarget_link_libraries_${name} ${ARGN} PARENT_SCOPE)
    endforeach()
endfunction()


# Adds dependencies for multitarget from multitarget
function(path64_add_multitarget_multitarget_dependencies name)
    foreach(targ ${PATH64_ENABLE_TARGETS})
        foreach(dep ${ARGN})
            add_dependencies(${name}-${targ} ${dep}-${targ})
        endforeach()
    endforeach()
endfunction()


# Adds dependencies from multitarget
function(path64_add_dependencies_from_multitarget name)
    foreach(targ ${PATH64_ENABLE_TARGETS})
        foreach(dep ${ARGN})
       add_dependencies(${name} ${dep}-${targ})
        endforeach()
    endforeach()
endfunction()


# Adds dependencies for multitarget
function(path64_add_multitarget_dependencies name)
    foreach(targ ${PATH64_ENABLE_TARGETS})
        foreach(dep ${ARGN})
            add_dependencies(${name}-${targ} ${dep})
        endforeach()
    endforeach()
endfunction()


function(path64_set_use_system_compiler_for_multitarget name)
    set(path64_use_system_compiler_for_multitarget_${name} TRUE PARENT_SCOPE)
endfunction()

