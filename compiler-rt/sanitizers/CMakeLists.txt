function(path64_set_sanitizers_for_arch arch targ)
    # compiler-rt doesn't seem to support SunOS at all atm
    if (${CMAKE_SYSTEM_NAME} MATCHES "SunOS")
        return()
    endif()

    set(include_libs)
    # keep in sync with arch logic in ekopath/compiler-rt/cmake/config-ix.cmake
    if (${arch} STREQUAL "x86_64")
        list(APPEND include_libs
            asan asan_cxx asan-preinit              # ASAN
            cfi cfi_diag                            # CFI
            dfsan                                   # DFSAN
            esan                                    # ESAN
            lsan                                    # LSAN
            msan msan_cxx                           # MSAN
            profile                                 # PROFILE
            safestack                               # SAFESTACK
            scudo                                   # SCUDO
            stats stats_client                      # SANITIZER_COMMON
            tsan tsan_cxx                           # TSAN
            ubsan_standalone ubsan_standalone_cxx   # UBSAN
        )
        # specific to x86_64 Linux
        if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
            list(APPEND include_libs dd dyndd)
        endif()
    elseif (${arch} STREQUAL "i386")
        list(APPEND include_libs
            asan asan_cxx asan-preinit              # ASAN
            cfi cfi_diag                            # CFI
            profile                                 # PROFILE
            safestack                               # SAFESTACK
            stats stats_client                      # SANITIZER_COMMON
            ubsan_standalone ubsan_standalone_cxx   # UBSAN
        )
    elseif (${arch} STREQUAL "mips")
        list(APPEND include_libs
            asan asan_cxx asan-preinit              # ASAN
            cfi cfi_diag                            # CFI
            esan                                    # ESAN
            profile                                 # PROFILE
            safestack                               # SAFESTACK
            ubsan_standalone ubsan_standalone_cxx   # UBSAN
        )
    elseif (${arch} STREQUAL "mips64")
        list(APPEND include_libs
            asan asan_cxx asan-preinit              # ASAN
            cfi cfi_diag                            # CFI
            dfsan                                   # DFSAN
            esan                                    # ESAN
            lsan                                    # LSAN
            msan msan_cxx                           # MSAN
            profile                                 # PROFILE
            safestack                               # SAFESTACK
            stats stats_client                      # SANITIZER_COMMON
            tsan tsan_cxx                           # TSAN
            ubsan_standalone ubsan_standalone_cxx   # UBSAN
        )
    elseif (${arch} STREQUAL "aarch64")
        list(APPEND include_libs
            asan asan_cxx asan-preinit              # ASAN
            dfsan                                   # DFSAN
            lsan                                    # LSAN
            msan msan_cxx                           # MSAN
            profile                                 # PROFILE
            safestack                               # SAFESTACK
            stats stats_client                      # SANITIZER_COMMON
            tsan tsan_cxx                           # TSAN
            ubsan_standalone ubsan_standalone_cxx   # UBSAN
        )
    elseif (${arch} MATCHES "powerpc64*") # both LE and BE
        list(APPEND include_libs
            asan asan_cxx asan-preinit              # ASAN
            msan msan_cxx                           # MSAN
            profile                                 # PROFILE
            stats stats_client                      # SANITIZER_COMMON
            tsan tsan_cxx                           # TSAN
            ubsan_standalone ubsan_standalone_cxx   # UBSAN
        )
    endif()

    if (NOT ${CMAKE_SYSTEM_NAME} MATCHES "Linux")
        # Linux-specific sanitizers
        list(REMOVE_ITEM include_libs
            cfi cfi_diag                            # CFI
            dfsan                                   # DFSAN
            esan                                    # ESAN
            msan msan_cxx                           # MSAN
            scudo                                   # SCUDO
        )
    endif()
    if (NOT ${CMAKE_SYSTEM_NAME} MATCHES "Linux|FreeBSD")
        list(REMOVE_ITEM include_libs
            lsan                                    # LSAN
        )
    endif()

    set(PATH64_SANITIZER_LIBS_${targ} "${include_libs}" PARENT_SCOPE)
endfunction()


function(build_clangrt_sanitizers)
    # compiler-rt doesn't seem to support SunOS at all atm
    if (${CMAKE_SYSTEM_NAME} MATCHES "SunOS")
        return()
    endif()

    set(build_dir "${CMAKE_CURRENT_BINARY_DIR}/build")

    # run cmake 
    set(cmd_line "${CMAKE_COMMAND}" "${PATH64_COMPILER_RT_SOURCE}" -G "${CMAKE_GENERATOR}")
    list(APPEND cmd_line "-DCMAKE_C_COMPILER=${Path64_BINARY_DIR}/bin/clang")
    list(APPEND cmd_line "-DCMAKE_CXX_COMPILER=${Path64_BINARY_DIR}/bin/clang++")
    list(APPEND cmd_line "-DCOMPILER_RT_BUILD_BUILTINS=OFF")
    list(APPEND cmd_line "-DCOMPILER_RT_BUILD_XRAY=OFF")
    list(APPEND cmd_line "-DLLVM_CONFIG_PATH=${CMAKE_BINARY_DIR}/psllvm/__build/bin/llvm-config")
    list(APPEND cmd_line "-DCMAKE_C_FLAGS=")
    list(APPEND cmd_line "-DCMAKE_CXX_FLAGS=")
    if (APPLE)
        set(OSX_ARCHES)
        foreach(targ ${PATH64_ENABLE_TARGETS})
            list(APPEND OSX_ARCHES ${_PATH64_TARGET_LLVM_ARCH_${targ}})
        endforeach()
        list(APPEND cmd_line "-DDARWIN_osx_ARCHS=${OSX_ARCHES}")
    endif()

    make_directory("${build_dir}")

    add_custom_target(compiler-rt-sanitizers-cmake
                      COMMAND ${cmd_line}
                      WORKING_DIRECTORY "${build_dir}")
    add_dependencies(compiler-rt-sanitizers-cmake compiler-stage-libs-CXX llvm-config)


    # run make
    add_custom_target(compiler-rt-sanitizers-make
                      COMMAND ${CMAKE_BUILD_TOOL}
                      WORKING_DIRECTORY "${build_dir}")
    add_dependencies(compiler-rt-sanitizers-make compiler-rt-sanitizers-cmake)


    # copy libraries to stage dir
    set(stage_path "${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}")
    add_custom_target(compiler-rt-sanitizers-copy
                      COMMAND ${CMAKE_COMMAND} -E copy
                              "${build_dir}/lib/${CLANGRT_SYSTEM}/*.a"
                              "${stage_path}/"
                      DEPENDS compiler-rt-sanitizers-make)
	add_dependencies(compiler-stage-extra-libs-CXX compiler-rt-sanitizers-copy)
endfunction()

build_clangrt_sanitizers()
