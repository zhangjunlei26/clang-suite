#
# Create a library called "CompilerRT" which includes the source files.

#INCLUDE_DIRECTORIES(
# ${CMAKE_CURRENT_BINARY_DIR}
#)

# Generic functions needed for each architecture
# libcompiler_rt.Generic.a    libcompiler_rt.Optimized.a

# Generic
SET( Generic_SRCS
 absvdi2.c absvsi2.c addvdi3.c addvsi3.c ashldi3.c ashrdi3.c
 clzdi2.c clzsi2.c cmpdi2.c ctzdi2.c ctzsi2.c
 divdi3.c ffsdi2.c
 fixdfdi.c fixsfdi.c fixunsdfdi.c fixunsdfsi.c fixunssfdi.c
 fixunssfsi.c floatdidf.c floatdisf.c floatundidf.c floatundisf.c
 lshrdi3.c moddi3.c muldc3.c muldi3.c
 mulsc3.c mulvdi3.c mulvsi3.c negdi2.c negvdi2.c negvsi2.c
 paritydi2.c paritysi2.c popcountdi2.c popcountsi2.c powidf2.c
 powisf2.c subvdi3.c subvsi3.c ucmpdi2.c udivdi3.c
 udivmoddi4.c umoddi3.c apple_versioning.c eprintf.c
 )

    list(APPEND Generic_SRCS
         adddf3.c
         addsf3.c
         comparedf2.c
         comparesf2.c
         divdc3.c
         divdf3.c
         divmoddi4.c
         divmodsi4.c
         divsc3.c
         divsf3.c
         divsi3.c
#         divxc3.c
         extendsfdf2.c
         fixdfsi.c
         fixsfsi.c
         floatsidf.c
         floatsisf.c
         floatunsidf.c
         floatunsisf.c
         int_util.c
         modsi3.c
         muldf3.c
         mulodi4.c
         mulosi4.c
         muloti4.c
         mulsf3.c
         negdf2.c
         negsf2.c
         powitf2.c
         subdf3.c
         subsf3.c
         trampoline_setup.c
         truncdfsf2.c
         udivmodsi4.c
         udivsi3.c
         umodsi3.c
        )




# Optimized functions for each architecture

# Commenting out for the min until the basics are working first.
# ADD_SUBDIRECTORY( ppc )
#ADD_SUBDIRECTORY( x86_64 )
# ADD_SUBDIRECTORY( i386 )
# ADD_SUBDIRECTORY( arm )

# List of functions needed for each architecture.
SET( SRCS_x86_32
 fixunsxfdi.c fixunsxfsi.c fixxfdi.c floatdixf.c
 floatundixf.c mulxc3.c powixf2.c clear_cache.c
 )

SET( SRCS_x86_64
 absvti2.c addvti3.c ashlti3.c ashrti3.c clzti2.c cmpti2.c
 ctzti2.c divti3.c
 ffsti2.c fixdfti.c fixsfti.c
 fixunsdfti.c fixunssfti.c fixunsxfdi.c fixunsxfsi.c
 fixunsxfti.c fixxfdi.c fixxfti.c floatdixf.c floattidf.c
 floattisf.c floattixf.c floatundixf.c floatuntidf.c
 floatuntisf.c floatuntixf.c lshrti3.c modti3.c multi3.c
 mulvti3.c mulxc3.c negti2.c negvti2.c parityti2.c
 popcountti2.c powixf2.c subvti3.c ucmpti2.c udivmodti4.c
 udivti3.c umodti3.c clear_cache.c
 )
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    list(APPEND SRCS_x86_64 ${CMAKE_CURRENT_SOURCE_DIR}/chkstk.S)
endif()

SET( PPC_Functions
 ppc/divtc3.c 
 ppc/fixtfdi.c 
 ppc/fixunstfdi.c 
 ppc/floatditf.c 
 ppc/floatunditf.c
 ppc/gcc_qadd.c 
 ppc/gcc_qdiv.c 
 ppc/gcc_qmul.c 
 ppc/gcc_qsub.c 
 ppc/multc3.c
# ppc/restFP.S 
# ppc/saveFP.S 
 powixf2.c
 clear_cache.c
 )

SET( ARM_Functions
 adddf3vfp.c addsf3vfp.c bswapdi2.c bswapsi2.c divdf3vfp.c
 divsf3vfp.c eqdf2vfp.c eqsf2vfp.c extendsfdf2vfp.c
 fixdfsivfp.c fixsfsivfp.c fixunsdfsivfp.c fixunssfsivfp.c
 floatsidfvfp.c floatsisfvfp.c floatunssidfvfp.c floatunssisfvfp.c
 gedf2vfp.c gesf2vfp.c gtdf2vfp.c gtsf2vfp.c
 ledf2vfp.c lesf2vfp.c ltdf2vfp.c ltsf2vfp.c
 muldf3vfp.c mulsf3vfp.c
 nedf2vfp.c negdf2vfp.c negsf2vfp.c nesf2vfp.c
 subdf3vfp.c subsf3vfp.c truncdfsf2vfp.c unorddf2vfp.c unordsf2vfp.c
 modsi3.c umodsi3.c udivsi3.c divsi3.c switch.c
 )
SET(AARCH64_Functions
         comparetf2.c
         trunctfdf2.c
         trunctfsf2.c
	 extenddftf2.c
	 extendsftf2.c
	 addtf3.c
	 subtf3.c
	 multf3.c
	 divtf3.c
         divti3.c
         multi3.c
	 udivmodti4.c
         clear_cache.c
         fixtfsi.c
         fixunstfsi.c
         floatsitf.c
         floatunsitf.c
         # ?????
         ppc/fixtfdi.c 
         ppc/fixunstfdi.c 
         ppc/floatditf.c 
         ppc/floatunditf.c
 )

set(SRCS_COMMON)
list(APPEND SRCS_COMMON ${Generic_SRCS})

# isinf function is not implemented on solaris
if(${CMAKE_SYSTEM_NAME} MATCHES "SunOS")
    list(APPEND SRCS_COMMON ${CMAKE_CURRENT_SOURCE_DIR}/isinf.c)
endif()

if(MINGW)
    include_directories("${PATH64_COMPILER_SOURCE}/src/system/include/mingw64")
endif()


path64_set_multitarget_sources_base_path(compiler-rt-static "${PATH64_COMPILER_RT_SOURCE}/lib/builtins")
path64_set_multitarget_sources(compiler-rt-static COMMON ${SRCS_COMMON})
path64_set_multitarget_sources(compiler-rt-static x86_32 ${SRCS_COMMON} ${SRCS_x86_32})
path64_set_multitarget_sources(compiler-rt-static x86_64 ${SRCS_COMMON} ${SRCS_x86_64})
path64_set_multitarget_sources(compiler-rt-static powerpc64 ${SRCS_COMMON} ${PPC_Functions})
path64_set_multitarget_sources(compiler-rt-static powerpc64le ${SRCS_COMMON} ${PPC_Functions})
path64_set_multitarget_sources(compiler-rt-static aarch64 ${SRCS_COMMON} ${AARCH64_Functions})
path64_set_multitarget_property_(compiler-rt-static OUTPUT_NAME "clang_rt.builtins-x86_64")
path64_set_multitarget_property_(compiler-rt-static OUTPUT_DIRECTORY "${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}")
path64_set_multitarget_property_(compiler-rt-static COMPILE_FLAGS "-fPIC")
path64_add_multitarget_library(compiler-rt-static STATIC)
path64_add_dependencies_from_multitarget(compiler-stage-libs-C compiler-rt-static)

if(PATH64_ENABLE_SHARED)
    path64_set_multitarget_sources_base_path(compiler-rt "${PATH64_COMPILER_RT_SOURCE}/lib/builtins")
    path64_set_multitarget_sources(compiler-rt COMMON ${SRCS_COMMON})
    path64_set_multitarget_sources(compiler-rt x86_32 ${SRCS_COMMON} ${SRCS_x86_32})
    path64_set_multitarget_sources(compiler-rt x86_64 ${SRCS_COMMON} ${SRCS_x86_64})
    path64_set_multitarget_sources(compiler-rt powerpc64 ${SRCS_COMMON} ${PPC_Functions})
    path64_set_multitarget_sources(compiler-rt powerpc64le ${SRCS_COMMON} ${PPC_Functions})
    path64_set_multitarget_sources(compiler-rt aarch64 ${SRCS_COMMON} ${AARCH64_Functions})
    path64_set_multitarget_property_(compiler-rt OUTPUT_NAME "clang_rt.builtins-x86_64")
    path64_set_multitarget_property_(compiler-rt OUTPUT_DIRECTORY "${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}")
    path64_set_multitarget_property_(compiler-rt COMPILE_FLAGS "-fPIC")
    path64_set_multitarget_property_(compiler-rt LINK_FLAGS "-fPIC -nodefaultlibs")
    path64_multitarget_link_libraries(compiler-rt c)
    if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
        path64_multitarget_link_libraries(compiler-rt mingw32 mingwex moldname msvcrt advapi32 shell32 user32 kernel32)
    endif()
    path64_add_multitarget_library(compiler-rt SHARED)
    path64_add_multitarget_multitarget_dependencies(compiler-rt)
    path64_add_dependencies_from_multitarget(compiler-stage-libs-C compiler-rt)
endif()

#FOREACH( LOOP_VAR ${Achitectures} )
# See ARCHIVE_OUTPUT_DIRECTORY docs.
#${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}/${LOOP_VAR}
#ENDFOREACH

#ADD_LIBRARY( ${PROJECT_NAME}-Generic STATIC ${Generic_SRCS} )
#ADD_LIBRARY( ${PROJECT_NAME}-i386 STATIC ${i386_Functions} )

# [[debug|optimized|general]
#TARGET_LINK_LIBRARIES( ${PROJECT_NAME} ${PROJECT_NAME}-Common optimized ${PROJECT_NAME}-i386 )

