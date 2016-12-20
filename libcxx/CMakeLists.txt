
# commands for installing libc++ headers to stage dir
file(GLOB_RECURSE headers
     RELATIVE "${PATH64_LIBCXX_SOURCE}/include"
     "${PATH64_LIBCXX_SOURCE}/include/*")

set(libcxx_stage_headers)
set(libcxx_stage_include_dir "${PATH64_STAGE_DIR}/include/c++/v1")

foreach(header ${headers})
    set(stage_header "${libcxx_stage_include_dir}/${header}")
    set(src_header "${PATH64_LIBCXX_SOURCE}/include/${header}")
    add_custom_command(OUTPUT "${stage_header}"
                       COMMAND ${CMAKE_COMMAND} -E copy
                               "${src_header}"
                               "${stage_header}"
                       DEPENDS "${src_header}")
    list(APPEND libcxx_stage_headers "${stage_header}")
endforeach()

add_custom_target(libcxx-headers-stage ALL DEPENDS ${libcxx_stage_headers})
add_dependencies(compiler-stage-libs-CXX libcxx-headers-stage)



function(build_libcxx targ shared)

    set(build_dir "${CMAKE_CURRENT_BINARY_DIR}/build-${targ}")
    if(shared)
        set(build_dir "${build_dir}-shared")
    endif()

    # run cmake 
    set(cmd_line "${CMAKE_COMMAND}" "${PATH64_LIBCXX_SOURCE}" -G "${CMAKE_GENERATOR}")
    list(APPEND cmd_line "-DCMAKE_C_COMPILER=${Path64_BINARY_DIR}/bin/clang")
    list(APPEND cmd_line "-DCMAKE_CXX_COMPILER=${Path64_BINARY_DIR}/bin/clang++")
    list(APPEND cmd_line "-DLIBCXX_CXX_ABI=libcxxrt")
    list(APPEND cmd_line "-DLIBCXX_CXX_ABI_INCLUDE_PATHS=${PATH64_LIBCXXRT_SOURCE}/src")
    list(APPEND cmd_line "-DLLVM_CONFIG_PATH=OFF")

    # select static/shared
    if(NOT shared)
        list(APPEND cmd_line "-DLIBCXX_ENABLE_SHARED=OFF")
    endif()

    get_language_target_flags(c_flags C ${targ})
    list(REMOVE_ITEM c_flags "-g")
    string(REPLACE ";" " " c_flags_str "${c_flags}")

    get_language_target_flags(cxx_flags CXX ${targ})
    list(REMOVE_ITEM cxx_flags "-g")
    string(REPLACE ";" " " cxx_flags_str "${cxx_flags}")

    make_directory("${build_dir}")

    set(target_suffix "${targ}")
    if(shared)
        set(target_suffix "${target_suffix}-shared")
    endif()

    set(arch ${_PATH64_TARGET_LLVM_ARCH_${targ}})

    add_custom_target(libcxx-cmake-${target_suffix}
                      COMMAND ${cmd_line} "-DCMAKE_C_FLAGS:STRING=${c_flags_str} -nodefaultlibs -lc"
                                          "-DCMAKE_CXX_FLAGS:STRING:=${cxx_flags_str} -nodefaultlibs -lc"
                                          "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
                      WORKING_DIRECTORY "${build_dir}")
    add_dependencies(libcxx-cmake-${target_suffix} compiler-stage-CXX)
    path64_add_dependencies_from_multitarget(libcxx-cmake-${target_suffix} cxxrt)


    # run make
    add_custom_target(libcxx-make-${target_suffix}
                      COMMAND ${CMAKE_BUILD_TOOL}
                      WORKING_DIRECTORY "${build_dir}")
    add_dependencies(libcxx-make-${target_suffix} libcxx-cmake-${target_suffix})


    # copy library to stage dir

	set(stage_path "${PATH64_STAGE_DIR}/lib/clang/${CLANG_FULL_VERSION}/lib/${CLANGRT_SYSTEM}/${arch}")

    if(shared)
        if("${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS")
            add_custom_command(OUTPUT "${stage_path}/libc++.so"
                               COMMAND ${CMAKE_COMMAND} -E copy
                                       "${build_dir}/lib/libc++.so"
                                       "${stage_path}/libc++.so")

            install(FILES "${stage_path}/libc++.so"
                    DESTINATION "lib")

        elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
            add_custom_command(OUTPUT "${stage_path}/libc++.1.0.dylib"
                               COMMAND ${CMAKE_COMMAND} -E copy
                                       "${build_dir}/lib/libc++.1.0.dylib"
                                       "${stage_path}/libc++.1.0.dylib")
            add_custom_command(OUTPUT "${stage_path}/libc++.1.dylib"
                               COMMAND ${CMAKE_COMMAND} -E create_symlink
                                       "libc++.1.0.dylib"
                                       "${stage_path}/libc++.1.dylib"
                               DEPENDS "${stage_path}/libc++.1.0.dylib")
            add_custom_command(OUTPUT "${stage_path}/libc++.dylib"
                               COMMAND ${CMAKE_COMMAND} -E create_symlink
                                       libc++.1.dylib
                                       "${stage_path}/libc++.dylib"
                               DEPENDS "${stage_path}/libc++.1.dylib")

            install(FILES "${stage_path}/libc++.1.0.dylib"
                          "${stage_path}/libc++.1.dylib"
                          "${stage_path}/libc++.dylib"
                    DESTINATION "lib")

        else()
            add_custom_command(OUTPUT "${stage_path}/libc++.so.1"
                               COMMAND ${CMAKE_COMMAND} -E copy
                                       "${build_dir}/lib/libc++.so.1.0"
                                       "${stage_path}/libc++.so.1")
            add_custom_command(OUTPUT "${stage_path}/libc++.so"
                               COMMAND ${CMAKE_COMMAND} -E create_symlink
                                       "libc++.so.1"
                                       "${stage_path}/libc++.so"
                               DEPENDS "${stage_path}/libc++.so.1")

            install(FILES "${stage_path}/libc++.so"
                          "${stage_path}/libc++.so.1"
                    DESTINATION "lib")
        endif()

        add_custom_target(libcxx-copy-${target_suffix}
                          DEPENDS "${stage_path}/libc++${CMAKE_SHARED_LIBRARY_SUFFIX}")

    else()
        add_custom_command(OUTPUT "${stage_path}/libc++.a"
                           COMMAND ${CMAKE_COMMAND} -E copy
                                   "${build_dir}/lib/libc++.a"
                                   "${stage_path}/libc++.a")

        install(FILES "${stage_path}/libc++.a"
                DESTINATION "lib")

        add_custom_target(libcxx-copy-${target_suffix} DEPENDS "${stage_path}/libc++.a")
    endif()

    add_dependencies(libcxx-copy-${target_suffix} libcxx-make-${target_suffix})

    # dependencies
    add_dependencies(compiler-stage-libs-CXX libcxx-copy-${target_suffix})
endfunction()


# commands for building libc++ for each target
if(NOT PATH64_USE_SYSTEM_LIBCXX)
    foreach(targ ${PATH64_ENABLE_TARGETS})
        if(PATH64_ENABLE_SHARED)
            build_libcxx(${targ} ON)
        endif()
        build_libcxx(${targ} OFF)
    endforeach()
    install(DIRECTORY "${PATH64_STAGE_DIR}/include/c++/v1"
            DESTINATION "include/c++/v1")
endif()


