cmake_minimum_required(VERSION 2.8.0)

# blacklisted versions of cmake
if(CMAKE_VERSION STREQUAL "2.8.11" )
	message(FATAL_ERROR "Blacklisted version of cmake detected. Please use a newer or different version")
endif()

INCLUDE(CheckCXXCompilerFlag)

# TODO: detect clang version from sources
set(CLANG_FULL_VERSION "3.7.0")

# Whatever arbitrary number you'd like in 3 string format eg 3.9.99
IF(NOT PSC_FULL_VERSION)
    SET(PSC_FULL_VERSION "6.0.9" CACHE STRING "Defaulting to version 6.0.9")
ENDIF()

option(PATH64_ENABLE_CXX "Enables C++" ON)
option(PATH64_ENABLE_OPENMP "Enable OpenMP" ON)
option(PATH64_USE_SYSTEM_LIBCXX "Use system libc++" OFF)
option(PATH64_ENABLE_LIBCXX "Enable libc++ - Forced on if LIBCXX_DEFAULT is true" ON)
option(PATH64_ENABLE_BOOST "Enable boost libraries" OFF)
option(PATH64_ENABLE_PSCBLAS "Include pscblas library into packages" OFF)
option(PATH64_ENABLE_PACKAGE_MODE "Enables building package that works on all variants of an arch" ON)
option(PATH64_ENABLE_SHARED "Enable shared library support" ON)

# use shared llvm library in packaging mode
if(PATH64_ENABLE_PACKAGE_MODE AND UNIX AND NOT DEFINED PATH64_ENABLE_SHARED_LLVM)
    set(PATH64_ENABLE_SHARED_LLVM ON)
endif()

# Build debug by default
if("${CMAKE_BUILD_TYPE}" STREQUAL "")
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING
                         "Choose the type of build, options are: Debug Release RelWithDebInfo"
                         FORCE)
endif()

# Forbid invalid build types
if(NOT (("${CMAKE_BUILD_TYPE}" STREQUAL "Release") OR
        ("${CMAKE_BUILD_TYPE}" STREQUAL "RelWithDebInfo") OR
        ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")))
    message( FATAL_ERROR "Invalid CMAKE_BUILD_TYPE specified" )
endif()



######################################################################
# Component description

# Repositories
set(github "git@github.com")
set(psllvm_repo "${github}:pathscale/psllvm.git")
set(psllvm_branch "llvm-suite")
set(binutils_repo "${github}:pathscale/binutils.git")
set(psclang_repo "${github}:pathscale/psclang-ng.git")
set(psclang_branch "llvm-suite")
set(compiler-rt_repo "http://llvm.org/git/compiler-rt.git")
set(libunwind_repo "git://git.sv.gnu.org/libunwind.git")
set(libcxxrt_repo "${github}:pathscale/libcxxrt.git")
set(openmp-llvm_repo "${github}:llvm-mirror/openmp.git")
set(libcxx_repo "http://llvm.org/git/libcxx.git")
set(nvblas_repo "${github}:pathscale/nvblas.git")

# Cmake var names
set(psllvm_var LLVM)
set(binutils_var BINUTILS)
set(psclang_var PSCLANG)
set(compiler-rt_var COMPILER_RT)
set(libunwind_var LIBUNWIND)
set(libcxxrt_var LIBCXXRT)
set(openmp-llvm_var OPENMP_LLVM)
set(libcxx_var LIBCXX)

# Component sources dir
set(comp_sources "${CMAKE_CURRENT_SOURCE_DIR}/ekopath")


# Clones component if not cloned yet
function(clone_component comp comp_dir)
    if(EXISTS "${comp_dir}")
        return()
    endif()

    message(STATUS "Cloning component ${comp} to '${comp_dir}'...")

    if(${${comp}_repo_hg})
        # cloning mercurial
        execute_process(COMMAND hg clone ${${comp}_repo} ${comp_dir}
                        RESULT_VARIABLE res)
    else()
        # cloning git
        execute_process(COMMAND git clone ${${comp}_repo} ${comp_dir}
                        RESULT_VARIABLE res)
    endif()

    if(NOT ${res} EQUAL 0)
        message(FATAL_ERROR "Can't clone ${comp} sources")
    endif()

    if(NOT "${${comp}_branch}" STREQUAL "")
        # checking out branch
        execute_process(COMMAND git checkout ${${comp}_branch}
                        RESULT_VARIABLE res)

        if(NOT ${res} EQUAL 0)
            message(FATAL_ERROR "Can't checkout '${${comp}_branch}' for ${comp} sources")
        endif()
    endif()

endfunction()


# Updates component (runs git pull --rebase)
function(update_component comp comp_dir)

    message(STATUS "Updating component ${comp} in '${comp_dir}'...")

    if(NOT EXISTS "${comp_dir}")
        message(FATAL_ERROR "Directory '${comp_dir}' for component ${comp} does not exist")
    endif()

    execute_process(COMMAND git pull --rebase
                    WORKING_DIRECTORY "${comp_dir}"
                    RESULT_VARIABLE res)

    if(NOT ${res} EQUAL 0)
        message(FATAL_ERROR "git pull failed for component ${comp}")
    endif()
endfunction()


# Checks component source directory. Clones/updates sources if needed.
# set PATH64_${comp}_var}
function(check_component comp)
    set(comp_src_var PATH64_${${comp}_var}_SOURCE)
    set(comp_src "${${comp_src_var}}")

    if("${comp_src}" STREQUAL "")
        # path to sources not specified

        # clone/update pslcnag inside llvm
        if("${comp}" STREQUAL "psclang")
            set(comp_src "${comp_sources}/psllvm/tools/clang")
        else()
            set(comp_src "${comp_sources}/${comp}")
        endif()
    endif()

    # cloning component if needed
    if(PATH64_CLONE_SOURCES)
        clone_component(${comp} "${comp_src}")
    endif()

    # updating component if needed
    if(PATH64_UPDATE_SOURCES)
        update_component(${comp} "${comp_src}")
    endif()

    message(STATUS "Using ${comp} sources from '${comp_src}'")
    set(${comp_src_var} "${comp_src}" PARENT_SCOPE)
endfunction()


######################################################################

option(PATH64_BUILD_32 "Build 32-bit version" OFF)

if(PATH64_BUILD_32)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m32")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -m32")
    set(CMAKE_EXE_LINKER_FLAGS "-m32 ${CMAKE_EXE_LINKER_FLAGS}")
    set(CMAKE_MODULE_LINKER_FLAGS "-m32")
    set(CMAKE_SHARED_LINKER_FLAGS "-m32 ${CMAKE_SHARED_LINKER_FLAGS}")
elseif(${CMAKE_SYSTEM_NAME} MATCHES "SunOS")
    # Forching build for 64-bit and disabling atexit on osol
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m64 -fno-use-cxa-atexit")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m64 -fno-use-cxa-atexit")
    set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -m64")
    set(CMAKE_EXE_LINKER_FLAGS "-m64 ${CMAKE_EXE_LINKER_FLAGS}")
    set(CMAKE_MODULE_LINKER_FLAGS "-m64")
    set(CMAKE_SHARED_LINKER_FLAGS "-m64 ${CMAKE_SHARED_LINKER_FLAGS}")
endif()
if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(CMAKE_C_ARCHIVE_FINISH "<CMAKE_RANLIB> -c <TARGET>")
    set(CMAKE_CXX_ARCHIVE_FINISH ${CMAKE_C_ARCHIVE_FINISH})
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -undefined dynamic_lookup")
endif()

if( CXX_SUPPORTS_NO_NESTED_ANON_TYPES_FLAG )
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-nested-anon-types" )
endif()


# Use C++11 for building
set(CMAKE_CXX_FLAGS "-std=c++11 ${CMAKE_CXX_FLAGS}")


# Caution! this needs to be reworked to distiguish pathcc from gcc or stardard clang.
# Now assuming we are building on OSX only with gcc or standard clang.
# So one day we'll try to build pathcc with patchcc on OSX, so then please change this IF
 
if("${CMAKE_C_COMPILER_ID}" STREQUAL "PathScale")

    # linking pathscale runtime statically
    set(test_static_pathscale_file "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/test_static_pathscale.c")
    file(WRITE "${test_static_pathscale_file}" "#include <stdio.h>
                             int main(void)
                             {
                                 return printf(\"\");
                             }
                             ")

    message(STATUS "Checking for -static-pathscale support")
    try_run(SUPPORT_STATIC_PATHSCALE SUPPORT_STATIC_PATHSCALE_BUILD
	    ${CMAKE_BINARY_DIR} ${test_static_pathscale_file}
	    CMAKE_FLAGS -DLINK_LIBRARIES:STRING=-static-pathscale
	    OUTPUT_VARIABLE output)
    if(SUPPORT_STATIC_PATHSCALE_BUILD AND SUPPORT_STATIC_PATHSCALE EQUAL 0)
	message(STATUS "Checking for -static-pathscale support -- found ")
	set(c_flags "-static-pathscale")
	set(cxx_flags "-static-pathscale")
    else()
	set(c_flags "-nodefaultlibs -Wl,-Bstatic -lmv -lmpath -leh -lgcc -lpscrt -Wl,-Bdynamic")
	set(cxx_flags "-nodefaultlibs -Wl,-Bstatic -lmv -lmpath ${STL_LINK_FLAG} -lcxxrt -leh -lgcc -lpscrt -Wl,-Bdynamic -lpthread -lm")
	if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
	    # there is no libdl on freebsd, and it is not needed on solaris and mac
	    set(cxx_flags "${cxx_flags} -ldl")
	endif()
    endif()

    set(cxx_flags "-std=c++11 ${cxx_flags}")

    set(CMAKE_C_LINK_EXECUTABLE "${CMAKE_C_LINK_EXECUTABLE} ${c_flags}")
    set(CMAKE_C_CREATE_SHARED_LIBRARY "${CMAKE_C_CREATE_SHARED_LIBRARY} ${c_flags}")

    set(CMAKE_CXX_LINK_EXECUTABLE "${CMAKE_CXX_LINK_EXECUTABLE} ${cxx_flags}")
    set(CMAKE_CXX_CREATE_SHARED_LIBRARY "${CMAKE_CXX_CREATE_SHARED_LIBRARY} ${cxx_flags}")

    set(linker_flags "-Wl,-s -fbootstrap-hack")
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} ${linker_flags}")
    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} ${linker_flags}")
    set(CMAKE_MODULE_LINKER_FLAGS_RELEASE "${CMAKE_MODULE_LINKER_FLAGS_RELEASE} ${linker_flags}")
endif()


# Use -mno-ms-bitfields option for mingw
if(MINGW)
    add_definitions(-mno-ms-bitfields)
endif()


set(source_file "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/hash-style.c")
file(WRITE "${source_file}" "#include <stdio.h>
                             int main(void)
                             {
                                 return printf(\"\");
                             }
                             ")

message(STATUS "Checking for --hash-style=gnu support")
try_run(SUPPORT_HASH_STYLE_GNU SUPPORT_HASH_STYLE_GNU_BUILD
        ${CMAKE_BINARY_DIR} ${source_file}
        CMAKE_FLAGS -DLINK_LIBRARIES:STRING=-Wl,--hash-style=gnu
        OUTPUT_VARIABLE output)
if(SUPPORT_HASH_STYLE_GNU_BUILD AND SUPPORT_HASH_STYLE_GNU EQUAL 0)
    set(hash_style_supported TRUE)
    message(STATUS "Checking for --hash-style=gnu support -- found ")
else()
    set(hash_style_supported FALSE)
    message(STATUS "Checking for --hash-style=gnu support -- not found ")
    file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
         "Checking support for --hash-style=gnu support failed with the following output:\n"
         "${output}\n")
endif()

# use --hash-style=both option to build portable packages
if(hash_style_supported)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--hash-style=both")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--hash-style=both")
    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -Wl,--hash-style=both")
endif()


set(CMAKE_SKIP_RPATH TRUE)
set(PATH64_STAGE_DIR ${CMAKE_CURRENT_BINARY_DIR}/Xcompiler)
set(Path64_BINARY_DIR "${PATH64_STAGE_DIR}")


add_custom_target(path64-stage ALL)

set(components)
list(APPEND components psllvm)
list(APPEND components psclang)

if(PATH64_ENABLE_BINUTILS)
    list(APPEND components binutils)
endif()

list(APPEND components compiler-rt)

if(PATH64_ENABLE_CXX)
    if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Windows" AND NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
        list(APPEND components libunwind)
    endif()

    list(APPEND components libcxxrt)
    list(APPEND components libcxx)
endif()

if(PATH64_ENABLE_OPENMP)
    list(APPEND components openmp-llvm)
endif()

# check boost source
if(PATH64_ENABLE_BOOST)
    if("${PATH64_BOOST_SOURCE}" STREQUAL "")
        message(FATAL_ERROR "PATH64_BOOST_SOURCE is not specified")
    endif()

    if (NOT IS_DIRECTORY "${PATH64_BOOST_SOURCE}")
        message(FATAL_ERROR "'${PATH64_BOOST_SOURCE}' is not a directory")
    endif()
endif()

check_component(psllvm)

foreach(comp ${components})
    check_component(${comp})
endforeach()

# Including multitarget stuff from compiler sources
include(targets.cmake)

#add_subdirectory("${PATH64_LLVM_SOURCE}" "Xcompiler")

foreach(comp ${components})
    # don't add clang subdirectory
    if(NOT "${comp}" STREQUAL "psclang")
        add_subdirectory(${comp})
    endif()
endforeach()

include(packages.cmake)

