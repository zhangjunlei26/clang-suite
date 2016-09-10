

set(libunwind_SOURCE_DIR ${PATH64_LIBUNWIND_SOURCE})
include(config.cmake)

set(libunwind_sources_common
    mi/init.c
    mi/flush_cache.c
    mi/mempool.c
    mi/strerror.c
    dwarf/global.c
#    mi/backtrace.c
    mi/dyn-cancel.c
    mi/dyn-info-list.c
    mi/dyn-register.c
    mi/Ldyn-extract.c
    mi/Gdyn-extract.c
#    mi/Ldyn-remote.c
    mi/Gdyn-remote.c
    mi/Lfind_dynamic_proc_info.c
    mi/Gfind_dynamic_proc_info.c
    mi/Lget_accessors.c
#    mi/Gget_accessors.c
    mi/Lget_proc_info_by_ip.c
    mi/Gget_proc_info_by_ip.c
    mi/Lget_proc_name.c
    mi/Gget_proc_name.c
    mi/Lput_dynamic_unwind_info.c
    mi/Gput_dynamic_unwind_info.c
    mi/Ldestroy_addr_space.c
    mi/Gdestroy_addr_space.c
    mi/Lget_reg.c
    mi/Gget_reg.c
    mi/Lset_reg.c
    mi/Gset_reg.c
    mi/Lget_fpreg.c
    mi/Gget_fpreg.c
    mi/Lset_fpreg.c
    mi/Gset_fpreg.c
    mi/Lset_caching_policy.c
    mi/Gset_caching_policy.c
    mi/_ReadULEB.c
    mi/_ReadSLEB.c
    unwind/Backtrace.c
    unwind/DeleteException.c
    unwind/FindEnclosingFunction.c
    unwind/ForcedUnwind.c
    unwind/GetBSP.c
    unwind/GetCFA.c
    unwind/GetDataRelBase.c
    unwind/GetGR.c
    unwind/GetIP.c
    unwind/GetLanguageSpecificData.c
    unwind/GetRegionStart.c
    unwind/GetTextRelBase.c
    unwind/RaiseException.c
    unwind/Resume.c
    unwind/Resume_or_Rethrow.c
    unwind/SetGR.c
    unwind/SetIP.c
    unwind/GetIPInfo.c
    dwarf/Lexpr.c
    dwarf/Gexpr.c
    dwarf/Lfde.c
    dwarf/Gfde.c
    dwarf/Lparser.c
    dwarf/Gparser.c
    dwarf/Lpe.c
    dwarf/Gpe.c
    dwarf/Lstep.c
    dwarf/Gstep.c
    dwarf/Lfind_proc_info-lsb.c
    dwarf/Gfind_proc_info-lsb.c
    dwarf/Lfind_unwind_table.c
    dwarf/Gfind_unwind_table.c
    ${PATH64_COMPILER_RT_SOURCE}/lib/builtins/gcc_personality_v0.c
   )

    list(APPEND libunwind_sources_common ${PATH64_COMPILER_RT_SOURCE}/lib/builtins/int_util.c)

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    list(APPEND libunwind_sources_common os-linux.c)
elseif(CMAKE_SYSTEM_NAME MATCHES "SunOS")
    list(APPEND libunwind_sources_common os-linux.c)
elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
    list(APPEND libunwind_sources_common os-freebsd.c coredump/_UCD_access_reg_freebsd.c)
endif()

set(libunwind_sources_x86_32
    elf32.c
    x86/is_fpreg.c
    x86/regname.c
    x86/Lcreate_addr_space.c
    x86/Gcreate_addr_space.c
    x86/Lget_save_loc.c
    x86/Gget_save_loc.c
    x86/Lglobal.c
    x86/Gglobal.c
    x86/Linit.c
    x86/Ginit.c
    x86/Linit_local.c
    x86/Ginit_local.c
    x86/Linit_remote.c
    x86/Ginit_remote.c
    x86/Lget_proc_info.c
    x86/Gget_proc_info.c
    x86/Lregs.c
    x86/Gregs.c
    x86/Lresume.c
    x86/Gresume.c
    x86/Lstep.c
    x86/Gstep.c
    x86/longjmp.S
    x86/siglongjmp.S
   )

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    list(APPEND libunwind_sources_x86_32
         x86/Los-linux.c
         x86/Gos-linux.c
         x86/getcontext-linux.S
    )
    set_property(SOURCE x86/getcontext-linux.S
                 PROPERTY LANGUAGE C)
endif()



set(libunwind_sources_x86_64
    elf64.c
    x86_64/is_fpreg.c
    x86_64/regname.c
    x86_64/Lcreate_addr_space.c
    x86_64/Gcreate_addr_space.c
    x86_64/Lget_save_loc.c
    x86_64/Gget_save_loc.c
    x86_64/Lglobal.c
    x86_64/Gglobal.c
    x86_64/Linit.c
    x86_64/Ginit.c
    x86_64/Linit_local.c
    x86_64/Ginit_local.c
    x86_64/Linit_remote.c
    x86_64/Ginit_remote.c
    x86_64/Lget_proc_info.c
    x86_64/Gget_proc_info.c
    x86_64/Lregs.c
    x86_64/Gregs.c
    x86_64/Lresume.c
    x86_64/Gresume.c
    x86_64/Lstep.c
    x86_64/Gstep.c
    x86_64/Lstash_frame.c
    x86_64/Gstash_frame.c
    x86_64/Ltrace.c
    x86_64/Gtrace.c
    x86_64/getcontext.S
    x86_64/setcontext.S
    x86_64/longjmp.S
    x86_64/siglongjmp.S
   )


if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    list(APPEND libunwind_sources_x86_64 x86_64/Los-linux.c)
    list(APPEND libunwind_sources_x86_64 x86_64/Gos-linux.c)
elseif(CMAKE_SYSTEM_NAME MATCHES "SunOS")
    list(APPEND libunwind_sources_x86_64 x86_64/Los-solaris.c)
    list(APPEND libunwind_sources_x86_64 x86_64/Gos-solaris.c)
elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "FreeBSD")
    list(APPEND libunwind_sources_x86_64 x86_64/Los-freebsd.c)
    list(APPEND libunwind_sources_x86_64 x86_64/Gos-freebsd.c)
endif()


set(libunwind_sources_powerpc64
    elf64.c
    ppc64/is_fpreg.c
    ppc64/regname.c
    ppc64/Lglobal.c
    ppc64/Gglobal.c
    ppc64/Linit.c
    ppc64/Ginit.c
    ppc64/get_func_addr.c
    ppc64/Lregs.c
    ppc64/Gregs.c
    ppc64/Lresume.c
    ppc64/Gresume.c
    ppc64/Lstep.c
    ppc64/Gstep.c
    ppc64/setcontext.S
    ppc64/Lcreate_addr_space.c
    ppc64/Gcreate_addr_space.c
    ppc/Lget_proc_info.c
    ppc/Lis_signal_frame.c
    ppc/Gis_signal_frame.c
    ppc/Linit_local.c
    ppc/Lget_save_loc.c
    ppc/Linit_remote.c
   )

set(libunwind_sources_aarch64
    elf64.c
    aarch64/is_fpreg.c
    aarch64/regname.c
    aarch64/Lglobal.c
    aarch64/Gglobal.c
    aarch64/Linit.c
    aarch64/Ginit.c
#    aarch64/get_func_addr.c
    aarch64/Lregs.c
    aarch64/Gregs.c
    aarch64/Lresume.c
    aarch64/Gresume.c
    aarch64/Lstep.c
    aarch64/Gstep.c
#    aarch64/setcontext.S
    aarch64/Lcreate_addr_space.c
    aarch64/Gcreate_addr_space.c
    aarch64/Lget_proc_info.c
    aarch64/Gget_proc_info.c
    aarch64/Lis_signal_frame.c
    aarch64/Gis_signal_frame.c
    aarch64/Linit_local.c
    aarch64/Ginit_local.c
    aarch64/Lget_save_loc.c
    aarch64/Gget_save_loc.c
    aarch64/Linit_remote.c
    aarch64/Ginit_remote.c
    aarch64/Lstash_frame.c
    aarch64/Gstash_frame.c
#    aarch64/gen-offsets.c
#    aarch64/siglongjmp.S
   )

set_property(SOURCE x86_64/getcontext.S
                    x86_64/setcontext.S
             PROPERTY LANGUAGE C)

include_directories(${PATH64_LIBUNWIND_SOURCE}/src
                    ${PATH64_LIBUNWIND_SOURCE}/include
                    ${PATH64_LIBUNWIND_SOURCE}/include/tdep
                    ${CMAKE_CURRENT_BINARY_DIR}/include
                   )

if(CMAKE_SYSTEM_PROCESSOR MATCHES "i686" OR CMAKE_SYSTEM_PROCESSOR MATCHES "i386")
    set(target "x8664_32")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64" OR CMAKE_SYSTEM_PROCESSOR MATCHES "amd64")
    set(target "x8664_64")
    include_directories(${PATH64_LIBUNWIND_SOURCE}/include/tdep-x86_64)
elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "ppc64")
    set(target "ppc64")
    include_directories(${PATH64_LIBUNWIND_SOURCE}/include/tdep-ppc64)
elseif (CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    set(target "aarch64")
    include_directories(${PATH64_LIBUNWIND_SOURCE}/include/tdep-aarch64)
else()
    message(FATAL_ERROR "Unknown target")
endif()

add_definitions(-DHAVE_CONFIG_H
                -D_GNU_SOURCE
                -DPIC
               )

path64_set_multitarget_sources_base_path(unwind-static "${PATH64_LIBUNWIND_SOURCE}/src")
path64_set_multitarget_sources(unwind-static COMMON ${libunwind_sources_common})
path64_set_multitarget_sources(unwind-static x86_64 ${libunwind_sources_common}
                                             ${libunwind_sources_x86_64})
path64_set_multitarget_sources(unwind-static x86_32 ${libunwind_sources_common}
                                             ${libunwind_sources_x86_32})
path64_set_multitarget_sources(unwind-static powerpc64 ${libunwind_sources_common}
                                             ${libunwind_sources_powerpc64})
path64_set_multitarget_sources(unwind-static powerpc64le ${libunwind_sources_common}
                                             ${libunwind_sources_powerpc64})
path64_set_multitarget_sources(unwind-static aarch64 ${libunwind_sources_common}
                                             ${libunwind_sources_aarch64})

if("X${CMAKE_BUILD_TYPE}" STREQUAL "XDebug")
    path64_set_multitarget_property_(unwind-static COMPILE_DEFINITIONS DEBUG)
endif()

set(no_fast_stdlib "")
set(anyx86 "")

path64_set_multitarget_property_(unwind-static COMPILE_FLAGS "-fPIC -fexceptions ${no_fast_stdlib}")
path64_set_multitarget_property_for_target(unwind-static x86_64 COMPILE_FLAGS
        "-I${PATH64_LIBUNWIND_SOURCE}/include/tdep-x86_64 ${anyx86}")
path64_set_multitarget_property_for_target(unwind-static x86_32 COMPILE_FLAGS
        "-I${PATH64_LIBUNWIND_SOURCE}/include/tdep-x86 ${anyx86}")

path64_set_multitarget_property_for_target(unwind-static aarch64 COMPILE_FLAGS
        "-I${PATH64_LIBUNWIND_SOURCE}/include/tdep-aarch64")

path64_set_multitarget_property_(unwind-static OUTPUT_NAME "eh")
path64_add_multitarget_library(unwind-static STATIC)
path64_add_dependencies_from_multitarget(compiler-stage-libs-C unwind-static)



if(PATH64_ENABLE_SHARED)
    path64_set_multitarget_sources_base_path(unwind "${PATH64_LIBUNWIND_SOURCE}/src")
    path64_set_multitarget_sources(unwind COMMON ${libunwind_sources_common})
    path64_set_multitarget_sources(unwind x86_64 ${libunwind_sources_common}
                                                 ${libunwind_sources_x86_64})
    path64_set_multitarget_sources(unwind x86_32 ${libunwind_sources_common}
                                                 ${libunwind_sources_x86_32})
    path64_set_multitarget_sources(unwind powerpc64 ${libunwind_sources_common}
                                                    ${libunwind_sources_powerpc64})
    path64_set_multitarget_sources(unwind powerpc64le ${libunwind_sources_common}
                                                      ${libunwind_sources_powerpc64})
    path64_set_multitarget_sources(unwind aarch64 ${libunwind_sources_common}
                                                    ${libunwind_sources_aarch64})

    path64_set_multitarget_property_(unwind COMPILE_FLAGS "-fPIC -fexceptions ${no_fast_stdlib} -std=gnu89")
    path64_set_multitarget_property_for_target(unwind x86_64 COMPILE_FLAGS
            "-I${PATH64_LIBUNWIND_SOURCE}/include/tdep-x86_64 ${anyx86}")
    path64_set_multitarget_property_for_target(unwind x86_32 COMPILE_FLAGS
            "-I${PATH64_LIBUNWIND_SOURCE}/include/tdep-x86 ${anyx86}")
    path64_set_multitarget_property_for_target(unwind ppc64 COMPILE_FLAGS
            "-I${PATH64_LIBUNWIND_SOURCE}/include/tdep-ppc64")
    path64_set_multitarget_property_for_target(unwind aarch64 COMPILE_FLAGS
            "-I${PATH64_LIBUNWIND_SOURCE}/include/tdep-aarch64")

    if("X${CMAKE_BUILD_TYPE}" STREQUAL "XDebug")
        path64_set_multitarget_property_(unwind COMPILE_DEFINITIONS DEBUG)
    endif()
    path64_multitarget_link_libraries(unwind pthread c)
    path64_set_multitarget_property_(unwind OUTPUT_NAME "eh")
    path64_set_multitarget_property_(unwind LINK_FLAGS "-nodefaultlibs -lc")
    path64_add_multitarget_library(unwind SHARED)
    path64_multitarget_link_libraries(unwind pscrt)
    path64_add_multitarget_multitarget_dependencies(unwind compiler-rt pscrt)
    path64_add_dependencies_from_multitarget(compiler-stage-libs-C unwind)
endif()

