# libunwind configuration


include(CheckIncludeFile)
include(CheckFunctionExists)
include(CheckSymbolExists)
include(CheckStructHasMember)
include(CheckTypeSize)
include(CheckCSourceCompiles)

function(check_symbol_type_enum_exists name outvar) # and then list of filenames
    message ( STATUS "looking for ${name} in ${ARGN}")
    check_symbol_exists(${name} ${ARGN} ${outvar})
    if(${outvar})
        return()
    endif()
    message ( STATUS "ARGN ${ARGN}")
    
    set(list)
    foreach (f ${ARGN})
        message ( STATUS "f ${f}")
        check_include_file(${f} HAVE_${f})        
        message ( STATUS "header exists? ${HAVE_${f}}")
        if (${HAVE_${f}})
          set(list "${f};${list}")
          message ( STATUS "list=${list}")
        endif()
    endforeach()
    message ( STATUS "list=${list} name=${name}")
    set(CMAKE_EXTRA_INCLUDE_FILES ${list})
    check_type_size(${name} ${outvar})
    set(CMAKE_EXTRA_INCLUDE_FILES)
    message ( STATUS "result ${outvar} = ${${outvar}}")
    message ( STATUS "")
    
endfunction()

function(check_symbol_type_enum_exists2 name outvar) # and then list of filenames
    unset(${outvar})
    message ( STATUS "")
    message ( STATUS "check_symbol_type_enum_exists ${name} ${outvar} ${ARGV0} ${ARGV1}")
    foreach (f ${ARGN})
        message ( STATUS "file ${f}")
        message ( STATUS "BEGIN symbol")
        check_symbol_exists(${name} ${f} ${outvar})
        message ( STATUS "END symbol")
        if(${outvar})
            return()
        endif()
        message ( STATUS "BEGIN sizetype")
        set(CMAKE_EXTRA_INCLUDE_FILES ${f})
        check_type_size(${name} ${outvar})
        set(CMAKE_EXTRA_INCLUDE_FILES)
        message ( STATUS "END sizetype")
        if(${outvar})
            return()
        endif()
    endforeach()
endfunction()

#Optional Features:
#  --enable-debug          turn on debug support (slows down execution)
#  --enable-cxx-exceptions use libunwind to handle C++ exceptions
#  --enable-debug-frame    Load the ".debug_frame" section if available
#  --enable-block-signals  Block signals before performing mutex operations
#  --enable-conservative-checks
#                          Validate all memory addresses before use
#  --enable-msabi-support  Enables support for Microsoft ABI extensions
#  --enable-minidebuginfo  Enables support for LZMA-compressed symbol tables

if (NOT DEFINED enable_block_signals)
  set(enable_block_signals 1)
endif()
set(CONFIG_BLOCK_SIGNALS ${enable_block_signals})

if(NOT DEFINED enable_debug_frame)
    set(enable_debug_frame 0) # 1 for arm
endif()
set(CONFIG_DEBUG_FRAME ${enable_debug_frame})

set(CONFIG_MSABI_SUPPORT ${enable-msabi-support})

if(NOT DEFINED enable_conservative_checks)
    set(enable_conservative_checks 1) # 1 for arm
endif()
set(CONSERVATIVE_CHECKS ${enable_conservative_checks})
check_include_file(asm/ptrace_offsets.h HAVE_ASM_PTRACE_OFFSETS_H)
check_include_file(atomic_ops.h HAVE_ATOMIC_OPS_H)
check_include_file(byteswap.h HAVE_BYTESWAP_H)

check_symbol_type_enum_exists(PTRACE_CONT       HAVE_DECL_PTRACE_CONT       sys/types.h sys/ptrace.h )
check_symbol_type_enum_exists(PTRACE_POKEDATA   HAVE_DECL_PTRACE_POKEDATA   sys/types.h sys/ptrace.h )
check_symbol_type_enum_exists(PTRACE_POKEUSER   HAVE_DECL_PTRACE_POKEUSER   sys/types.h sys/ptrace.h )
check_symbol_type_enum_exists(PTRACE_SINGLESTEP HAVE_DECL_PTRACE_SINGLESTEP sys/types.h sys/ptrace.h )
check_symbol_type_enum_exists(PTRACE_SYSCALL    HAVE_DECL_PTRACE_SYSCALL    sys/types.h sys/ptrace.h )
check_symbol_type_enum_exists(PTRACE_TRACEME    HAVE_DECL_PTRACE_TRACEME    sys/types.h sys/ptrace.h )
check_symbol_type_enum_exists(PT_CONTINUE       HAVE_DECL_PT_CONTINUE       sys/types.h sys/ptrace.h )
check_symbol_type_enum_exists(PT_GETFPREGS      HAVE_DECL_PT_GETFPREGS      sys/types.h sys/ptrace.h )
check_symbol_type_enum_exists(PT_GETREGS        HAVE_DECL_PT_GETREGS        sys/types.h sys/ptrace.h )
check_symbol_type_enum_exists(PT_IO             HAVE_DECL_PT_IO             sys/types.h sys/ptrace.h )
check_symbol_type_enum_exists(PT_STEP           HAVE_DECL_PT_STEP           sys/types.h sys/ptrace.h )
check_symbol_type_enum_exists(PT_SYSCALL        HAVE_DECL_PT_SYSCALL        sys/types.h sys/ptrace.h )
check_symbol_type_enum_exists(PT_TRACE_ME       HAVE_DECL_PT_TRACE_ME       sys/types.h sys/ptrace.h )

check_include_file(dlfcn.h HAVE_DLFCN_H)
check_symbol_type_enum_exists(dlmodinfo HAVE_DLMODINFO dlfcn.h)
if ("${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS")
  set(HAVE_DL_ITERATE_PHDR OFF)
else()
  check_function_exists(dl_iterate_phdr HAVE_DL_ITERATE_PHDR)
endif()
check_function_exists(dl_phdr_removals_counter HAVE_DL_PHDR_REMOVALS_COUNTER)

check_include_file(elf.h HAVE_ELF_H)
check_include_file(endian.h HAVE_ENDIAN_H)
check_include_file(execinfo.h HAVE_EXECINFO_H)
check_function_exists(getunwind HAVE_GETUNWIND)
check_include_file(ia64intrin.h HAVE_IA64INTRIN_H)
check_include_file(inttypes.h HAVE_INTTYPES_H)
check_library_exists(uca __uc_get_grs "" HAVE_LIBUCA)
check_include_file(link.h HAVE_LINK_H)
if(NOT DEFINED enable_minidebuginfo)
    set(enable_minidebuginfo 0)
endif()
if(enable_minidebuginfo)
  check_library_exists(lzma lzma_mf_is_supported "" HAVE_LZMA)
endif()  
check_include_file(memory.h HAVE_MEMORY_H)
check_function_exists(mincore HAVE_MINCORE)
check_include_file(signal.h HAVE_SIGNAL_H)
check_include_file(stdint.h HAVE_STDINT_H)
check_include_file(stdlib.h HAVE_STDLIB_H)
check_include_file(strings.h HAVE_STRINGS_H)
check_include_file(string.h HAVE_STRING_H)
check_struct_has_member("struct dl_phdr_info" dlpi_subs link.h HAVE_STRUCT_DL_PHDR_INFO_DLPI_SUBS)
check_symbol_type_enum_exists("struct elf_prstatus" HAVE_STRUCT_ELF_PRSTATUS sys/procfs.h )
check_symbol_type_enum_exists("struct prstatus" HAVE_STRUCT_PRSTATUS sys/procfs.h)
check_function_exists(__sync_bool_compare_and_swap HAVE__sync_bool_compare_and_swap)
check_function_exists(__sync_fetch_and_add HAVE__sync_fetch_and_add)
set(HAVE_SYNC_ATOMICS (HAVE__sync_bool_compare_and_swap AND HAVE__sync_fetch_and_add))
check_include_file(sys/elf.h HAVE_SYS_ELF_H)
check_include_file(sys/endian.h HAVE_SYS_ENDIAN_H)
check_include_file(sys/link.h HAVE_SYS_LINK_H)
check_include_file(sys/procfs.h HAVE_SYS_PROCFS_H)
check_include_file(sys/ptrace.h HAVE_SYS_PTRACE_H)
check_include_file(sys/stat.h HAVE_SYS_STAT_H)
check_include_file(sys/types.h HAVE_SYS_TYPES_H)
check_include_file(sys/uc_access.h HAVE_SYS_UC_ACCESS_H)
check_function_exists(ttrace HAVE_TTRACE)
check_include_file(unistd.h HAVE_UNISTD_H)
check_c_source_compiles("int main (){__builtin_unreachable();}" HAVE__BUILTIN_UNREACHABLE)
check_c_source_compiles("int main (){__builtin___clear_cache(0, 0);}" HAVE__BUILTIN___CLEAR_CACHE)
check_c_source_compiles("__thread int a = 42;int main(){}" HAVE___THREAD)
check_type_size("off_t" SIZEOF_OFF_T)

configure_file(config.h.cmake.in
               ${CMAKE_CURRENT_BINARY_DIR}/include/config.h)

configure_file(${libunwind_SOURCE_DIR}/include/libunwind-common.h.in
               ${CMAKE_CURRENT_BINARY_DIR}/include/libunwind-common.h)

configure_file(${libunwind_SOURCE_DIR}/include/libunwind.h.in
               ${CMAKE_CURRENT_BINARY_DIR}/include/libunwind.h)

configure_file(${libunwind_SOURCE_DIR}/include/tdep/libunwind_i.h.in
               ${CMAKE_CURRENT_BINARY_DIR}/include/tdep/libunwind_i.h)

