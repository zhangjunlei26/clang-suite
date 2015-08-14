

set(headers_dir "")

function(build_openmp_llvm targ)

    set(build_dir "${CMAKE_CURRENT_BINARY_DIR}/build-${targ}")
    set(cmd_line "${CMAKE_COMMAND}" "${PATH64_OPENMP_LLVM_SOURCE}/runtime" -G "${CMAKE_GENERATOR}")
    set(BASE_COMP_NAME "path")
    set(OMP_C_CXX_FLAGS "-std=c++0x")

    list(APPEND cmd_line "-DLIBOMP_COPY_EXPORTS=FALSE")

    # run cmake 
    if("${targ}" STREQUAL "powerpc64")
      set(libomp_oss-bgq_var LIBOMP_OSS-BGQ)
      set(libomp_oss-bgq_repo "${github}:jeffhammond/libomp_oss-bgq.git")
      check_component(libomp_oss-bgq)
      list(APPEND cmd_line "-DLIBOMP_ARCH=ppc64")
      list(APPEND cmd_line "-Darch=ppc64")
      # skip bgpathcc checking because of LD stupidity on bg/q. It heavily depends on commandline order.
      list(APPEND cmd_line "-DCMAKE_C_COMPILER_FORCED=1")
      list(APPEND cmd_line "-DCMAKE_CXX_COMPILER_FORCED=1")
    # list(APPEND cmd_line "-DPATH64_LIBOMP_OSS-BGQ_SOURCE:STRING=${PATH64_LIBOMP_OSS-BGQ_SOURCE}")
    # list(APPEND cmd_line "-DLIBOMP_FILENAME=libomp.so")
    elseif("${targ}" STREQUAL "powerpc64le")
      list(APPEND cmd_line "-DLIBOMP_ARCH=ppc64le")
      list(APPEND cmd_line "-Darch=ppc64le")
      list(APPEND cmd_line "-DCMAKE_C_FLAGS_RELEASE=-O2 -DNDEBUG")
      list(APPEND cmd_line "-DCMAKE_CXX_FLAGS_RELEASE=-O2 -DNDEBUG")
    elseif("${targ}" STREQUAL "aarch64")
      list(APPEND cmd_line "-DLIBOMP_ARCH=aarch64")
      list(APPEND cmd_line "-Darch=aarch64")
    else()
      list(APPEND cmd_line "-DLIBOMP_ARCH=32e") # x86_64
      list(APPEND cmd_line "-Darch=32e")
    endif()

    path64_get_target_arch(arch ${targ})
    path64_get_target_bits(bits ${targ})

    set(anyx86 "")
    set(no_fast_stdlib "")
    set(OMP_C_CXX_FLAGS "${OMP_C_CXX_FLAGS} -Wf,-Wno-unused-value -Wf,-Wno-deprecated-register -fno-exceptions -msse2 -x c++ ${no_fast_stdlib} ${anyx86}")
    set(LIBOMP_FILENAME "libomp.so")
    # suppress warnings about unrecognised directives in libopenmp
    set(OMP_FORTRAN_FLAGS "-Wf,-m0" )
    # make mfef95 use a lowercase name for the .mod file
    set(OMP_FORTRAN_FLAGS "${OMP_FORTRAN_FLAGS} -Hcsm" )

    list(APPEND cmd_line "-DCMAKE_C_COMPILER=${Path64_BINARY_DIR}/bin/clang")
    list(APPEND cmd_line "-DCMAKE_CXX_COMPILER=${Path64_BINARY_DIR}/bin/clang++")
#    list(APPEND cmd_line "-DCMAKE_Fortran_COMPILER=${Path64_BINARY_DIR}/bin/${BASE_COMP_NAME}f90")
    list(APPEND cmd_line "-DCMAKE_ASM_COMPILER=${Path64_BINARY_DIR}/bin/${BASE_COMP_NAME}cc")
    list(APPEND cmd_line "-DLIBOMP_CFLAGS:STRING=${OMP_C_CXX_FLAGS}")
    list(APPEND cmd_line "-DLIBOMP_CXXFLAGS:STRING=${OMP_C_CXX_FLAGS}")
    list(APPEND cmd_line "-DLIBOMP_FFLAGS:STRING=${OMP_FORTRAN_FLAGS}")
    list(APPEND cmd_line "-DLIBOMP_ASMFLAGS=-x assembler-with-cpp")
    list(APPEND cmd_line "-DLIBOMP_LDFLAGS=-L${PATH64_STAGE_DIR}/lib/${PSC_FULL_VERSION}/${arch}/${bits} -msse2")
#    list(APPEND cmd_line "-DLIBOMP_FORTRAN_MODULES=on")
    list(APPEND cmd_line "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")

    make_directory("${build_dir}")

    set(target_suffix "${targ}")

    add_custom_target(openmp-cmake-${target_suffix}
                      COMMAND ${cmd_line}
                      WORKING_DIRECTORY "${build_dir}")
    # Need the full runtime available to build openmp
    add_dependencies(openmp-cmake-${target_suffix} compiler-stage-libs-C compiler-stage-libs-CXX compiler-stage-libs-Fortran)


    # run make
    add_custom_target(openmp-make-${target_suffix}
                      COMMAND ${CMAKE_BUILD_TOOL}
                      WORKING_DIRECTORY "${build_dir}")
    add_dependencies(openmp-make-${target_suffix} openmp-cmake-${target_suffix})


    # copy library to stage dir

    add_custom_command(OUTPUT ${PATH64_STAGE_DIR}/lib/${PSC_FULL_VERSION}/${arch}/${bits}/${LIBOMP_FILENAME}
                       COMMAND ${CMAKE_COMMAND} -E copy
                               ${build_dir}/src/${LIBOMP_FILENAME}
                               ${PATH64_STAGE_DIR}/lib/${PSC_FULL_VERSION}/${arch}/${bits}/${LIBOMP_FILENAME}
                       DEPENDS  ${build_dir}/src/${LIBOMP_FILENAME})

#    add_custom_command(OUTPUT "${PATH64_STAGE_DIR}/lib/${PSC_FULL_VERSION}/${arch}/${bits}/OMP_LIB.mod"
#                       COMMAND "${CMAKE_COMMAND}" -E copy
#                               "${build_dir}/src/omp_lib.mod"
#                               "${PATH64_STAGE_DIR}/lib/${PSC_FULL_VERSION}/${arch}/${bits}/OMP_LIB.mod"
#                       DEPENDS "${build_dir}/src/omp_lib.mod")

    add_custom_target(openmp-copy-${target_suffix} ALL
                      DEPENDS
                      "${PATH64_STAGE_DIR}/lib/${PSC_FULL_VERSION}/${arch}/${bits}/${LIBOMP_FILENAME}")
#                      "${PATH64_STAGE_DIR}/lib/${PSC_FULL_VERSION}/${arch}/${bits}/OMP_LIB.mod")

    add_dependencies(openmp-copy-${target_suffix} openmp-make-${target_suffix})
    add_dependencies(compiler-stage-extra-libs-CXX openmp-copy-${target_suffix})

    set(headers_dir "${build_dir}/src" PARENT_SCOPE)   # use any the header from any arch

    install(FILES
                "${PATH64_STAGE_DIR}/lib/${PSC_FULL_VERSION}/${arch}/${bits}/${LIBOMP_FILENAME}"
#                "${PATH64_STAGE_DIR}/lib/${PSC_FULL_VERSION}/${arch}/${bits}/OMP_LIB.mod"
            DESTINATION "lib/${PSC_FULL_VERSION}/${arch}/${bits}")

endfunction()


# commands for building libopenmp for each target
foreach(targ ${PATH64_ENABLE_TARGETS})
    build_openmp_llvm(${targ})
endforeach()


# copy headers to include directory

if("${headers_dir}" STREQUAL "")
    message(FATAL_ERROR "Can't find headers dir for openmp")
endif()

set(headers "omp.h")

set(openmp_stage_headers)
set(openmp_stage_include_dir "${PATH64_STAGE_DIR}/include")

foreach(header ${headers})
    set(stage_header "${openmp_stage_include_dir}/${header}")
    set(src_header "${headers_dir}/${header}")
    add_custom_command(OUTPUT "${stage_header}"
                       COMMAND ${CMAKE_COMMAND} -E copy
                               "${src_header}"
                               "${stage_header}")
    list(APPEND openmp_stage_headers "${stage_header}")
endforeach()

add_custom_target(openmp-headers-stage ALL DEPENDS ${openmp_stage_headers})

foreach(targ ${PATH64_ENABLE_TARGETS})
    add_dependencies(openmp-headers-stage openmp-make-${targ})
endforeach()

add_dependencies(compiler-stage-extra-libs-CXX openmp-headers-stage)

