
# enzo-suite packages definition

if(NOT "${PATH64_PACKAGE_NAME}" STREQUAL "")
    set(path64_main_package_name "${PATH64_PACKAGE_NAME}")
else()
    set(path64_main_package_name enzo)
endif()

# package arch for tarball suffix
set(path64_main_package_arch)
foreach(targ ${PATH64_ENABLE_TARGETS})
    if(NOT "${path64_main_package_arch}" STREQUAL "")
        set(path64_main_package_arch "${path64_main_package_arch}_")
    endif()
    set(path64_main_package_arch "${path64_main_package_arch}${targ}")
endforeach()


set(path64_rpm_arch x86_64)


include(pack.cmake)

set(pack_arch amd64)
set(pack_maint "Pathscale <support@pathscale.com>")
set(pack_sect devel)
set(pack_group "Development/Languages/C and C++")
set(pack_prio "extra")
set(pack_homepage "http://www.pathscale.com")
set(pack_desc "The PathScale EKOPath compiler suite is designed to generate code for Intel64 and AMD64 processors. The EKOPath environment provides the developer with necessary tools and options to develop highly optimized C, C++, and Fortran applications.")


########################################
# Runtime package

foreach(targ ${PATH64_ENABLE_TARGETS})
    set(arch ${_PATH64_TARGET_ARCH_${targ}})
    set(bits ${_PATH64_TARGET_BITS_${targ}})

    set(dest_dir lib)

    path64_add_package_files(runtime ${dest_dir}
                             ${PATH64_STAGE_DIR}/lib/libgcc${CMAKE_SHARED_LIBRARY_SUFFIX}
			     )

    if(PATH64_ENABLE_CXX AND NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Windows" AND NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
        path64_add_package_files(runtime ${dest_dir}
                                 ${PATH64_STAGE_DIR}/lib/libeh${CMAKE_SHARED_LIBRARY_SUFFIX})
    endif()

    if(PATH64_ENABLE_HMPP OR PATH64_ENABLE_CUDA_ONLY)
        if(PATH64_ENABLE_HSA)
		path64_add_package_files(runtime ${dest_dir}
		                 ${PATH64_STAGE_DIR}/lib/libpshsa-runtime64${CMAKE_SHARED_LIBRARY_SUFFIX}
		                 )
	endif()
        if(NOT PATH64_ENABLE_HSA_ONLY)
		path64_add_package_files(runtime ${dest_dir}
		                 ${PATH64_STAGE_DIR}/lib/libenvyrt${CMAKE_SHARED_LIBRARY_SUFFIX}
		                 )
        endif()
	if(PATH64_ENABLE_HSA OR PATH64_ENABLE_AMD_KFD)
		path64_add_package_files(runtime ${dest_dir}
				${PATH64_STAGE_DIR}/lib/libpshsakmt${CMAKE_SHARED_LIBRARY_SUFFIX}
	                 )
	endif()
    endif()

    if(PATH64_ENABLE_CXX)
        path64_add_package_files(runtime ${dest_dir}
                                 ${PATH64_STAGE_DIR}/lib/libcxxrt${CMAKE_SHARED_LIBRARY_SUFFIX}
                                )

        if(PATH64_BUILD_STDCXX)
            path64_add_package_files(runtime ${dest_dir}
                                     ${PATH64_STAGE_DIR}/lib/libstl${CMAKE_SHARED_LIBRARY_SUFFIX}
                                    )
        endif()

        if(PATH64_ENABLE_LIBCXX AND NOT PATH64_USE_SYSTEM_LIBCXX)
            if("${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS" OR
               "${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
                path64_add_package_files(runtime ${dest_dir}
                                         ${PATH64_STAGE_DIR}/lib/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}
                                        )
            elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
                path64_add_package_files(runtime ${dest_dir}
                                         ${PATH64_STAGE_DIR}/lib/libc++.1.0${CMAKE_SHARED_LIBRARY_SUFFIX}
                                        )
                path64_add_package_symlink(runtime
                                           ${PATH64_STAGE_DIR}/lib/libc++.1.0${CMAKE_SHARED_LIBRARY_SUFFIX}
                                           libc++.1.0${CMAKE_SHARED_LIBRARY_SUFFIX}
                                           ${dest_dir}
                                           libc++.1${CMAKE_SHARED_LIBRARY_SUFFIX})
                path64_add_package_symlink(runtime
                                           ${PATH64_STAGE_DIR}/lib/libc++.1${CMAKE_SHARED_LIBRARY_SUFFIX}
                                           libc++.1${CMAKE_SHARED_LIBRARY_SUFFIX}
                                           ${dest_dir}
                                           libc++${CMAKE_SHARED_LIBRARY_SUFFIX})
            else()
                path64_add_package_files(runtime ${dest_dir}
                                         ${PATH64_STAGE_DIR}/lib/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1
                                        )
                path64_add_package_symlink(runtime
                                           ${PATH64_STAGE_DIR}/lib/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1
                                           libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1
                                           ${dest_dir}
                                           libc++${CMAKE_SHARED_LIBRARY_SUFFIX})
            endif()
        endif()
    endif()
endforeach()

path64_add_package(runtime
                   "${PSC_FULL_VERSION}"
                   "${pack_arch}"
                   "${pack_maint}"
                   "${pack_sect}"
                   "${pack_group}"
                   "${pack_prio}"
                   "${pack_homepage}"
                   "PathScale(tm) EKOPath Compiler Suite runtime libraries"
                   "${pack_desc}"
                   "Runtime libraries"
                   TRUE
                   TRUE
                   TRUE)



########################################
# base package

set(driver_name "pathcc")
if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows" OR "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    set(cxx_driver_name "pathc++")
else()
    set(cxx_driver_name "pathCC")
endif()


# Makes rules for copying driver for specified configuration to
# subdirectory in installbuilder directory
function(copy_driver conf output_var)
    set(input "${PATH64_STAGE_DIR}/bin/pathcc_${conf}")
    set(output_dir "${CMAKE_CURRENT_BINARY_DIR}/installbuilder/driver-${conf}")
    set(output "${output_dir}/${driver_name}")

    file(MAKE_DIRECTORY "${output_dir}")
    add_custom_command(OUTPUT "${output}"
                       COMMAND "${CMAKE_COMMAND}" -E copy "${input}" "${output}"
                       DEPENDS "${input}")
    add_custom_target(driver-installbuilder-${conf} DEPENDS "${output}")
    add_dependencies(installbuilder-deps driver-installbuilder-${conf})

    set(${output_var} "${output}" PARENT_SCOPE)
endfunction()


# sysroots and tools for crosscompiler
foreach(arch ${PATH64_ENABLE_ARCHES})
    if (NOT "${PSC_SYSROOT_${arch}}" STREQUAL "")
        path64_add_package_files(base ${arch}
                                      ${PATH64_STAGE_DIR}/${arch}/sysroot)
    endif()

#    if ("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux" OR NOT "${PSC_LINKER_${arch}}" STREQUAL "")
#        path64_add_package_files(base ${arch}/bin
#                                      ${PATH64_STAGE_DIR}/${arch}/bin/ld)
#    endif()
endforeach()


# postinstall actions for CRT 

path64_get_host_arch(host_arch)

foreach(arch ${PATH64_ENABLE_ARCHES})

    set(ENABLE_32BIT 0)

    foreach(targ ${PATH64_ENABLE_TARGETS})
        set(targ_arch ${_PATH64_TARGET_ARCH_${targ}})
        set(targ_bits ${_PATH64_TARGET_BITS_${targ}})

        if("${targ_arch}" STREQUAL "${arch}")
            
            # copy crt objects from sysroot if set
            if("${PSC_SYSROOT_${targ_arch}}" STREQUAL "")
                set(crt_sysroot "")
            else()
                set(crt_sysroot "\${installdir}/${targ_arch}/sysroot")
            endif()

            if("${bits}" STREQUAL "64")
                set(CRT_PATH_64 "${crt_sysroot}${PSC_CRT_PATH_${targ}}")
            elseif("${bits}" STREQUAL "32")
                set(ENABLE_32BIT 1)
                set(CRT_PATH_32 "${crt_sysroot}${PSC_CRT_PATH_${targ}}")
            else()
                message(FATAL_ERROR "Don't know how to handle '${bits}' bits")
            endif()
        endif()
    endforeach()

    if("${PSC_SYSROOT_${arch}}" STREQUAL "" AND "${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
        set(DETECT_CRT 1)
    else()
        set(DETECT_CRT 0)
    endif()

    set(ARCH ${arch})

#    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/crt_postinstall.xml.cmake.in"
#                   "${CMAKE_CURRENT_BINARY_DIR}/crt_postinstall-${arch}.xml"
#                   @ONLY)

#    file(READ "${CMAKE_CURRENT_BINARY_DIR}/crt_postinstall-${arch}.xml" crt_actions)
#    set(POST_INSTALL_ACTION_LIST "${POST_INSTALL_ACTION_LIST}${crt_actions}\n")
endforeach()



foreach(targ ${PATH64_ENABLE_TARGETS})
    set(arch ${_PATH64_TARGET_ARCH_${targ}})
    set(bits ${_PATH64_TARGET_BITS_${targ}})

    set(dest_dir lib)

#    if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Windows" AND NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
#        path64_add_package_files(base ${dest_dir}
#                                 ${PATH64_STAGE_DIR}/lib/crtendS.o
#                                 ${PATH64_STAGE_DIR}/lib/crtend.o
#                                 ${PATH64_STAGE_DIR}/lib/crtbeginS.o
#                                 ${PATH64_STAGE_DIR}/lib/crtbegin.o)
#
#        path64_add_package_files_no_installer(base ${dest_dir}/system-provided
#                                              ${PATH64_STAGE_DIR}/lib/system-provided/crt1.o
#                                              ${PATH64_STAGE_DIR}/lib/system-provided/crti.o
#                                              ${PATH64_STAGE_DIR}/lib/system-provided/crtn.o)
#    endif()

    if(PATH64_ENABLE_CXX)
        if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Windows" AND NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
            path64_add_package_files(base ${dest_dir}
                                     ${PATH64_STAGE_DIR}/lib/libeh.a)
        endif()
    endif()

#    if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux" AND PATH64_ENABLE_OPENMP)
#        path64_add_package_files(base ${dest_dir}
#                                 ${PATH64_STAGE_DIR}/lib/libomp${CMAKE_SHARED_LIBRARY_SUFFIX}
#				 )
#    endif()
endforeach()

if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux" AND PATH64_ENABLE_OPENMP)
    path64_add_package_files(base include
                             ${PATH64_STAGE_DIR}/include/omp.h)
endif()


path64_set_package_deps(base "runtime")
path64_add_package(base
                   "${PSC_FULL_VERSION}"
                   "${pack_arch}"
                   "${pack_maint}"
                   "${pack_sect}"
                   "${pack_group}"
                   "${pack_prio}"
                   "${pack_homepage}"
                   "PathScale(tm) EKOPath Compiler Suite base package"
                   "${pack_desc}"
                   "Base package"
                   FALSE
                   FALSE
                   FALSE)



########################################
# c package


path64_add_package_files(c bin/
                         "${PATH64_STAGE_DIR}/bin/clang")
path64_add_package_files(c lib/
                         "${PATH64_STAGE_DIR}/lib/clang")

path64_set_package_deps(c "runtime" "base")
path64_add_package(c
                   "${PSC_FULL_VERSION}"
                   "${pack_arch}"
                   "${pack_maint}"
                   "${pack_sect}"
                   "${pack_group}"
                   "${pack_prio}"
                   "${pack_homepage}"
                   "PathScale(tm) EKOPath Compiler Suite C compiler"
                   "${pack_desc}"
                   "C compiler"
                   TRUE
                   TRUE
                   TRUE)



########################################
# c++ package

if(PATH64_ENABLE_CXX)
    path64_add_package_symlink(c++ ${PATH64_STAGE_DIR}/bin/clang++${CMAKE_EXECUTABLE_SUFFIX}
                                   clang${CMAKE_EXECUTABLE_SUFFIX} bin clang++${CMAKE_EXECUTABLE_SUFFIX})
                                   
    path64_add_package_files(c++ include
                                 ${PATH64_STAGE_DIR}/include/cxxabi.h
                            )

    if(PATH64_BUILD_STDCXX)
        path64_add_package_files(c++ include
                                     ${PATH64_STAGE_DIR}/include/stl
                                )
    endif()

    if(PATH64_ENABLE_LIBCXX)
        path64_add_package_files(c++ include
                                     ${PATH64_STAGE_DIR}/include/c++)
    endif()

    foreach(targ ${PATH64_ENABLE_TARGETS})
        set(arch ${_PATH64_TARGET_ARCH_${targ}})
        set(bits ${_PATH64_TARGET_BITS_${targ}})
    
        path64_add_package_files(c++ lib
                                 ${PATH64_STAGE_DIR}/lib/libcxxrt.a
                                )

        if(PATH64_BUILD_STDCXX)
            path64_add_package_files(c++ lib
                                     ${PATH64_STAGE_DIR}/lib/libstl.a)
        endif()

        if(PATH64_ENABLE_LIBCXX AND NOT PATH64_USE_SYSTEM_LIBCXX)
            path64_add_package_files(c++ lib
                                     ${PATH64_STAGE_DIR}/lib/libc++.a)
        endif()
    endforeach()
    path64_set_package_deps(c++ "c")
    path64_add_package(c++
                       "${PSC_FULL_VERSION}"
                       "${pack_arch}"
                       "${pack_maint}"
                       "${pack_sect}"
                       "${pack_group}"
                       "${pack_prio}"
                       "${pack_homepage}"
                       "PathScale(tm) EKOPath Compiler Suite C++ compiler"
                       "${pack_desc}"
                       "C++ compiler"
                       TRUE
                       TRUE
                       TRUE)
endif()


########################################

if(PATH64_ENABLE_PATHAS AND NOT PATH64_ENABLE_DEFAULT_PATHAS)
    path64_set_package_deps(assembler "runtime")

    foreach(targ ${PATH64_ENABLE_TARGETS})
        set(arch ${_PATH64_TARGET_ARCH_${targ}})
        set(dest_dir lib)
        set(src_dir ${PATH64_STAGE_DIR}/lib)

        path64_add_package_files(assembler ${dest_dir} ${src_dir}/pathas2${CMAKE_EXECUTABLE_SUFFIX})
    endforeach()

    path64_add_package(assembler
                       "${PSC_FULL_VERSION}"
                       "${pack_arch}"
                       "${pack_maint}"
                       "${pack_sect}"
                       "${pack_group}"
                       "${pack_prio}"
                       "${pack_homepage}"
                       "PathScale(tm) EKOPath Compiler Suite Assembler"
                       "${pack_desc}"
                       "PathScale Assembler"
                       TRUE
                       TRUE
                       TRUE)
endif()



########################################
# prof package

foreach(targ ${PATH64_ENABLE_TARGETS})
    set(arch ${_PATH64_TARGET_ARCH_${targ}})
    set(bits ${_PATH64_TARGET_BITS_${targ}})

    path64_add_package_files(prof lib
                             ${PATH64_STAGE_DIR}/lib/libpscrt_p.a
                            )

    if(PATH64_ENABLE_MATHLIBS)
        path64_add_package_files(prof lib
                                 ${PATH64_STAGE_DIR}/lib/libmv_p.a
                                 ${PATH64_STAGE_DIR}/lib/libmpath_p.a
                                )
    endif()

    if(PATH64_ENABLE_CXX)
        path64_add_package_files(prof lib
                                 ${PATH64_STAGE_DIR}/lib/libinstr2_p.a)
    endif()

    if(PATH64_ENABLE_FORTRAN)
        path64_add_package_files(prof
                                 lib
                                 ${PATH64_STAGE_DIR}/lib/libpathfortran_p.a)
    endif()

    if(PATH64_ENABLE_HUGEPAGES)
        path64_add_package_files(prof
                                 lib
                                 ${PATH64_STAGE_DIR}/lib/libhugetlbfs-psc_p.a)
    endif()
endforeach()
path64_set_package_deps(prof "base")
if(PATH64_ENABLE_PROFILING)
    path64_add_package(prof
                       "${PSC_FULL_VERSION}"
                       "${pack_arch}"
                       "${pack_maint}"
                       "${pack_sect}"
                       "${pack_group}"
                       "${pack_prio}"
                       "${pack_homepage}"
                       "PathScale(tm) EKOPath Compiler Suite profiling libraries"
                       "${pack_desc}"
                       "Profiling libraries"
                       TRUE
                       TRUE
                       TRUE)
endif()



########################################
# pathdb package

path64_add_package_files(debugger bin
                         ${PATH64_STAGE_DIR}/bin/pathdb${CMAKE_EXECUTABLE_SUFFIX}
                        )
path64_add_package_files(debugger etc
                         ${PATH64_STAGE_DIR}/etc/pathdb-help.xml
                        )
path64_add_package_files(debugger share
                         ${PATH64_STAGE_DIR}/share/emacs.el
                        )
path64_set_package_deps(debugger "runtime")
if(PATH64_ENABLE_PATHDB)
    path64_add_package(debugger
                       "${PSC_FULL_VERSION}"
                       "${pack_arch}"
                       "${pack_maint}"
                       "${pack_sect}"
                       "${pack_group}"
                       "${pack_prio}"
                       "${pack_homepage}"
                       "PathScale(tm) EKOPath Compiler Suite Debugger"
                       "${pack_desc}"
                       "PathScale Debugger"
                       TRUE
                       TRUE
                       TRUE)
endif()



########################################
# RLM

set(OPTIONAL_LICENSE_FILE 1)

if(PATH64_ENABLE_RLM)
    path64_add_package_files(subscriptionmanager bin
                             ${CMAKE_CURRENT_BINARY_DIR}/rlm/bin/pathscale-rlm${CMAKE_EXECUTABLE_SUFFIX}
                             ${CMAKE_CURRENT_BINARY_DIR}/rlm/bin/pathscale${CMAKE_EXECUTABLE_SUFFIX}
                             ${CMAKE_CURRENT_BINARY_DIR}/rlm/bin/rlmutil${CMAKE_EXECUTABLE_SUFFIX}
                            )

    path64_add_package_symlink(subscriptionmanager ${PATH64_STAGE_DIR}/bin/rlmdebug${CMAKE_EXECUTABLE_SUFFIX}
                                                   rlmutil${CMAKE_EXECUTABLE_SUFFIX} bin rlmdebug${CMAKE_EXECUTABLE_SUFFIX})
    path64_add_package_symlink(subscriptionmanager ${PATH64_STAGE_DIR}/bin/rlmstat${CMAKE_EXECUTABLE_SUFFIX}
                                                   rlmutil${CMAKE_EXECUTABLE_SUFFIX} bin rlmstat${CMAKE_EXECUTABLE_SUFFIX})

    file(READ "${CMAKE_CURRENT_SOURCE_DIR}/pathscale-submanager" startup_script)
    string(REPLACE "%PREFIX%" "\${installdir}/bin" startup_script "${startup_script}")

    set(rlmcode)
    set(rlmcode "${rlmcode}<postInstallationActionList>\n")
    set(rlmcode "${rlmcode}    <writeFile>\n")
    set(rlmcode "${rlmcode}        <path>\${installdir}/bin/pathscale-submanager</path>\n")
    set(rlmcode "${rlmcode}        <text>${startup_script}</text>\n")
    set(rlmcode "${rlmcode}    </writeFile>\n")
    set(rlmcode "${rlmcode}    <changePermissions permissions=\"0755\" files=\"\${installdir}/bin/pathscale-submanager\"/>\n")
    set(rlmcode "${rlmcode}    <addFilesToUninstaller>\n")
    set(rlmcode "${rlmcode}        <files>\${installdir}/bin/pathscale-submanager</files>\n")
    set(rlmcode "${rlmcode}    </addFilesToUninstaller>\n")
    set(rlmcode "${rlmcode}    <addUnixService>\n")
    set(rlmcode "${rlmcode}        <name>pathscale-submanager</name>\n")
    set(rlmcode "${rlmcode}        <program>\${installdir}/bin/pathscale-submanager</program>\n")
    set(rlmcode "${rlmcode}    </addUnixService>\n")
    set(rlmcode "${rlmcode}</postInstallationActionList>\n")
    
    set(rlmcode "${rlmcode}<postUninstallationActionList>\n")
    set(rlmcode "${rlmcode}    <removeUnixService>\n")
    set(rlmcode "${rlmcode}        <name>pathscale-submanager</name>\n")
    set(rlmcode "${rlmcode}    </removeUnixService>\n")
    set(rlmcode "${rlmcode}</postUninstallationActionList>\n")

    path64_set_component_custom_code(subscriptionmanager "${rlmcode}")

    path64_set_package_deps(subscriptionmanager "runtime")
    path64_add_package(subscriptionmanager
                       "${PSC_FULL_VERSION}"
                       "${pack_arch}"
                       "${pack_maint}"
                       "${pack_sect}"
                       "${pack_group}"
                       "${pack_prio}"
                       "${pack_homepage}"
                       "PathScale Subscription Manager"
                       "${pack_desc}"
                       "Subscription Manager"
                       TRUE
                       TRUE
                       TRUE)

    if(NOT PATH64_NO_LICENSE_CHECK)
        set(OPTIONAL_LICENSE_FILE 0)
    endif()
endif()




########################################
# Boost package

if(PATH64_ENABLE_BOOST)
    path64_add_package_files(boost extra-libs
                             ${PATH64_STAGE_DIR}/extra-libs/boost-${BOOST_VERSION})
    path64_add_package(boost
                       "${PSC_FULL_VERSION}"
                       "${pack_arch}"
                       "${pack_maint}"
                       "${pack_sect}"
                       "${pack_group}"
                       "${pack_prio}"
                       "${pack_homepage}"
                       "Boost libraries ${BOOST_VERSION} fo PathScale compiler"
                       "${pack_desc}"
                       "Boost libraries"
                       TRUE
                       FALSE
                       TRUE)
endif()


########################################
# pscblas package


if(PATH64_ENABLE_PSCBLAS)
    if("${PSCBLAS_ROOT}" STREQUAL "")
        message(FATAL_ERROR "Path to pscblas root is not specified. Please set PSCBLAS_ROOT variable")
    endif()

    set(pscblas_include "${PSCBLAS_ROOT}/include")
    
    path64_add_package_files(pscblas "include/pscblas"
                             "${pscblas_include}/cblas.h"
                             "${pscblas_include}/f77blas.h"
                             "${pscblas_include}/lapacke_config.h"
                             "${pscblas_include}/lapacke.h"
                             "${pscblas_include}/lapacke_mangling.h"
                             "${pscblas_include}/lapacke_utils.h"
                             "${pscblas_include}/openblas_config.h"
                            )


    set(pscblas_lib "${PSCBLAS_ROOT}/lib")
    set(pscblas_lib_name "libopenblas_haswellp-r0.2.12")

    foreach(targ ${PATH64_ENABLE_TARGETS})
        set(arch ${_PATH64_TARGET_ARCH_${targ}})
        set(bits ${_PATH64_TARGET_BITS_${targ}})

        path64_add_package_files(pscblas "lib"
                                 "${pscblas_lib}/${pscblas_lib_name}.a"
                                 "${pscblas_lib}/${pscblas_lib_name}${CMAKE_SHARED_LIBRARY_SUFFIX}")

        path64_add_package_symlink(pscblas
                                   "${pscblas_lib}/${pscblas_lib_name}.a"
                                   "${pscblas_lib_name}.a"
                                   "lib"
                                   "libopenblas.a")

        path64_add_package_symlink(pscblas
                                   "${pscblas_lib}/${pscblas_lib_name}${CMAKE_SHARED_LIBRARY_SUFFIX}"
                                   "${pscblas_lib_name}${CMAKE_SHARED_LIBRARY_SUFFIX}"
                                   "lib"
                                   "libopenblas${CMAKE_SHARED_LIBRARY_SUFFIX}")
                        
    endforeach()


    path64_add_package(pscblas
                       "${PSC_FULL_VERSION}"
                       "${pack_arch}"
                       "${pack_maint}"
                       "${pack_sect}"
                       "${pack_group}"
                       "${pack_prio}"
                       "${pack_homepage}"
                       "PathScale blas library"
                       "${pack_desc}"
                       "PathScale blas library"
                       TRUE
                       TRUE
                       TRUE)
endif()


path64_finish_packages()

