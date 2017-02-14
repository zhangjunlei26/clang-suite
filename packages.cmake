
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
    set(arch ${_PATH64_TARGET_LLVM_ARCH_${targ}})

    set(noarch_dest_dir lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM})
    set(dest_dir ${noarch_dest_dir}/${arch})

    path64_add_package_files(runtime ${noarch_dest_dir}
                             ${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/libclang_rt.builtins-${arch}.a
                             ${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/libclang_rt.builtins-${arch}${CMAKE_SHARED_LIBRARY_SUFFIX}
			     )
    
    path64_set_sanitizers_for_arch(${arch} ${targ})
    foreach(lib ${PATH64_SANITIZER_LIBS_${targ}})
        path64_add_package_files(runtime ${noarch_dest_dir}
                                 ${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/libclang_rt.${lib}-${arch}.a)
    endforeach()

    if(PATH64_ENABLE_CXX AND NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Windows" AND NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
        path64_add_package_files(runtime ${dest_dir}
                                 ${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch}/libeh${CMAKE_SHARED_LIBRARY_SUFFIX})
    endif()

    if(PATH64_ENABLE_CXX)
        path64_add_package_files(runtime ${dest_dir}
                                 ${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch}/libcxxrt${CMAKE_SHARED_LIBRARY_SUFFIX}
                                )

        if(PATH64_ENABLE_LIBCXX AND NOT PATH64_USE_SYSTEM_LIBCXX)
            if("${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS" OR
               "${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
                path64_add_package_files(runtime ${dest_dir}
                                         ${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch}/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}
                                        )
            elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
                path64_add_package_files(runtime ${dest_dir}
                                         ${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch}/libc++.1.0${CMAKE_SHARED_LIBRARY_SUFFIX}
                                        )
                path64_add_package_symlink(runtime
                                           ${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch}/libc++.1.0${CMAKE_SHARED_LIBRARY_SUFFIX}
                                           libc++.1.0${CMAKE_SHARED_LIBRARY_SUFFIX}
                                           ${dest_dir}
                                           libc++.1${CMAKE_SHARED_LIBRARY_SUFFIX})
                path64_add_package_symlink(runtime
                                           ${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch}/libc++.1${CMAKE_SHARED_LIBRARY_SUFFIX}
                                           libc++.1${CMAKE_SHARED_LIBRARY_SUFFIX}
                                           ${dest_dir}
                                           libc++${CMAKE_SHARED_LIBRARY_SUFFIX})
            else()
                path64_add_package_files(runtime ${dest_dir}
                                         ${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch}/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1
                                        )
                path64_add_package_symlink(runtime
                                           ${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch}/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}.1
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



# postinstall actions for CRT 

path64_get_host_arch(host_arch)

foreach(arch ${PATH64_ENABLE_ARCHES})

    set(ENABLE_32BIT 0)

    foreach(targ ${PATH64_ENABLE_TARGETS})
        set(targ_arch ${_PATH64_TARGET_ARCH_${targ}})
        set(targ_bits ${_PATH64_TARGET_BITS_${targ}})
        set(llvm_arch ${_PATH64_TARGET_LLVM_ARCH_${targ}})

        if("${targ_arch}" STREQUAL "${arch}")
            
            # copy crt objects from sysroot if set
            if("${PSC_SYSROOT_${targ_arch}}" STREQUAL "")
                set(crt_sysroot "")
            else()
                set(crt_sysroot "\${installdir}/${targ_arch}/sysroot")
            endif()

            if("${targ_bits}" STREQUAL "64")
                set(CRT_PATH_64 "${crt_sysroot}${PSC_CRT_PATH_${targ}}")
                set(LLVM_ARCH_64 "${llvm_arch}")
            elseif("${targ_bits}" STREQUAL "32")
                set(ENABLE_32BIT 1)
                set(CRT_PATH_32 "${crt_sysroot}${PSC_CRT_PATH_${targ}}")
                set(LLVM_ARCH_32 "${llvm_arch}")
            else()
                message(FATAL_ERROR "Don't know how to handle '${targ_bits}' bits")
            endif()
        endif()
    endforeach()

    if("${PSC_SYSROOT_${arch}}" STREQUAL "" AND "${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
        set(DETECT_CRT 1)
    else()
        set(DETECT_CRT 0)
    endif()

    # FIXME
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/crt_postinstall.xml.cmake.in"
                   "${CMAKE_CURRENT_BINARY_DIR}/crt_postinstall-${arch}.xml"
                   @ONLY)

    file(READ "${CMAKE_CURRENT_BINARY_DIR}/crt_postinstall-${arch}.xml" crt_actions)
    set(POST_INSTALL_ACTION_LIST "${POST_INSTALL_ACTION_LIST}${crt_actions}\n")
endforeach()

if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    path64_add_package_files(base bin "${CMAKE_CURRENT_SOURCE_DIR}/detect_crt_path.sh")
endif()


foreach(targ ${PATH64_ENABLE_TARGETS})
    set(arch ${_PATH64_TARGET_LLVM_ARCH_${targ}})

    set(dest_dir lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch})

    if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Windows" AND NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
        path64_add_package_files(base ${dest_dir}
                                 ${PATH64_STAGE_DIR}/${dest_dir}/crtendS.o
                                 ${PATH64_STAGE_DIR}/${dest_dir}/crtend.o
                                 ${PATH64_STAGE_DIR}/${dest_dir}/crtbeginS.o
                                 ${PATH64_STAGE_DIR}/${dest_dir}/crtbegin.o)

        path64_add_package_files_no_installer(base ${dest_dir}
                                              ${PATH64_STAGE_DIR}/${dest_dir}/crt1.o
                                              ${PATH64_STAGE_DIR}/${dest_dir}/crti.o
                                              ${PATH64_STAGE_DIR}/${dest_dir}/crtn.o)
    endif()

    if(PATH64_ENABLE_CXX)
        if(NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Windows" AND NOT "${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
            path64_add_package_files(base ${dest_dir}
                                     ${PATH64_STAGE_DIR}/${dest_dir}/libeh.a)
        endif()
    endif()

#    if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux" AND PATH64_ENABLE_OPENMP)
#        path64_add_package_files(base ${dest_dir}
#                                 ${PATH64_STAGE_DIR}/${dest_dir}/libomp${CMAKE_SHARED_LIBRARY_SUFFIX}
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
path64_add_package_files(c lib/clang/${CLANG_FULL_VERSION}
                         "${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/include")

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
    set(dest_dir lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch})

    path64_add_package_symlink(c++ ${PATH64_STAGE_DIR}/bin/clang++${CMAKE_EXECUTABLE_SUFFIX}
                                   clang${CMAKE_EXECUTABLE_SUFFIX} bin clang++${CMAKE_EXECUTABLE_SUFFIX})
                                   
    path64_add_package_files(c++ include/c++/v1
                                 ${PATH64_STAGE_DIR}/include/cxxabi.h
                            )

    if(PATH64_ENABLE_LIBCXX)
        path64_add_package_files(c++ include
                                     ${PATH64_STAGE_DIR}/include/c++)
    endif()

    foreach(targ ${PATH64_ENABLE_TARGETS})
        set(arch ${_PATH64_TARGET_LLVM_ARCH_${targ}})
    
        path64_add_package_files(c++ ${dest_dir}
                                 ${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch}/libcxxrt.a
                                )

        if(PATH64_ENABLE_LIBCXX AND NOT PATH64_USE_SYSTEM_LIBCXX)
            path64_add_package_files(c++ ${dest_dir}
                                     ${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch}/libc++.a)
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


path64_finish_packages()
