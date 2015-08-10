

if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    set(LINK_COPY copy_if_different)
else()
    set(LINK_COPY create_symlink)
endif()


# Custom command for creating symlinks
function(make_symlink_custom_command dir target output)
    if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
        set(target_path "${dir}/${target}")
    else()
        set(target_path "${target}")
    endif()

    add_custom_command(OUTPUT "${output}"
                       DEPENDS "${target}"
                       COMMAND "${CMAKE_COMMAND}" -E "${LINK_COPY}" "${target_path}" "${output}")
endfunction()


# Fake targets for compiler stage
ADD_CUSTOM_TARGET(compiler-stage ALL)               # compiler core
ADD_CUSTOM_TARGET(compiler-stage-C ALL)             # C compiler
ADD_CUSTOM_TARGET(compiler-stage-CXX ALL)           # CXX compiler
ADD_CUSTOM_TARGET(compiler-stage-cuda ALL)          # cuda compiler
ADD_CUSTOM_TARGET(compiler-stage-amp ALL)           # AMP compiler
ADD_CUSTOM_TARGET(compiler-stage-Fortran ALL)       # Fortran compiler
ADD_CUSTOM_TARGET(compiler-stage-libs-C ALL)        # C compiler with libs
ADD_CUSTOM_TARGET(compiler-stage-libs-CXX ALL)      # CXX compiler with libs
ADD_CUSTOM_TARGET(compiler-stage-libs-cuda ALL)     # cuda libraries
ADD_CUSTOM_TARGET(compiler-stage-libs-amp ALL)      # amp libraries
ADD_CUSTOM_TARGET(compiler-stage-libs-Fortran ALL)  # Fortran compiler with libs
ADD_CUSTOM_TARGET(compiler-stage-extra-libs-CXX ALL)# CXX compiler with libs + extra libs
ADD_DEPENDENCIES(compiler-stage-C compiler-stage)
ADD_DEPENDENCIES(compiler-stage-CXX compiler-stage-C)
ADD_DEPENDENCIES(compiler-stage-cuda compiler-stage-CXX)
ADD_DEPENDENCIES(compiler-stage-Fortran compiler-stage)
ADD_DEPENDENCIES(compiler-stage-libs-C compiler-stage-C)
ADD_DEPENDENCIES(compiler-stage-libs-CXX compiler-stage-CXX compiler-stage-libs-C)
ADD_DEPENDENCIES(compiler-stage-libs-Fortran compiler-stage-Fortran)
ADD_DEPENDENCIES(compiler-stage-extra-libs-CXX compiler-stage-libs-CXX)


set(LLVM_BUILT_FROM_ENZO ON)
set(LLVM_COMPILER_IS_GCC_COMPATIBLE ON)

# selecting targets for LLVM
set(llvm_targets)

foreach(arch ${PATH64_ENABLE_ARCHES})
    if("${arch}" STREQUAL "x8664")
        set(llvm_target "X86")
    elseif("${arch}" STREQUAL "mips")
        set(llvm_target "Mips")
    elseif("${arch}" STREQUAL "powerpc64")
        set(llvm_target "PowerPC")
    elseif("${arch}" STREQUAL "powerpc64le")
        set(llvm_target "PowerPC")
    elseif("${arch}" STREQUAL "aarch64")
        set(llvm_target "AArch64")
    else()
        message(FATAL_ERROR "Don't know how convert arch '${arch}' to LLVM target")
    endif()

    list(APPEND llvm_targets "${llvm_target}")
endforeach()

if(PATH64_ENABLE_AMDGPU)
    list(APPEND llvm_targets "R600")
endif()

if(PATH64_ENABLE_NV)
    list(APPEND llvm_targets "K20")
endif()

if(PATH64_ENABLE_HSA)
    list(APPEND llvm_targets "HSAIL")
endif()

set(LLVM_TARGETS_TO_BUILD "${llvm_targets}"
    CACHE INTERNAL "Semicolon-separated list of targets to build, or \"all\".")
set(LLVM_ENABLE_BACKTRACES OFF CACHE INTERNAL "")
add_subdirectory(${PATH64_LLVM_SOURCE} ${CMAKE_CURRENT_BINARY_DIR}/__build)


set(llvm_version "3.7.0")


# psclang headers
file(GLOB_RECURSE headers
     RELATIVE "${PATH64_LLVM_SOURCE}/tools/clang/lib/Headers"
     "${PATH64_LLVM_SOURCE}/tools/clang/lib/Headers/*")

set(psclang_stage_headers)
set(psclang_stage_include_dir "${PATH64_STAGE_DIR}/lib/clang/${llvm_version}/include")

foreach(header ${headers})
    set(stage_header "${psclang_stage_include_dir}/${header}")
    set(src_header "${PATH64_LLVM_SOURCE}/tools/clang/lib/Headers/${header}")
    add_custom_command(OUTPUT "${stage_header}"
                       COMMAND ${CMAKE_COMMAND} -E copy
                               "${src_header}"
                               "${stage_header}"
                       DEPENDS "${src_header}")
    list(APPEND psclang_stage_headers "${stage_header}")
    install(FILES "${stage_header}" DESTINATION "lib/${PSC_FULL_VERSION}/include")
endforeach()

add_custom_target(psclang-headers-stage DEPENDS ${psclang_stage_headers})
add_dependencies(compiler-stage-C psclang-headers-stage)

# This is how we want to do this workaround but it seems not to work
# set_source_files_properties(${PATH64_LLVM_SOURCE}/utils/TableGen/CodeGenDAGPatterns.cpp PROPERTIES COMPILE_FLAGS -OPT:wrap_around_unsafe_opt=0)

# So have to set it on the whole target instead
if ("${CMAKE_C_COMPILER_ID}" STREQUAL "PathScale")
    set_property(TARGET llvm-tblgen PROPERTY COMPILE_FLAGS -OPT:wrap_around_unsafe_opt=0)
endif()

# copy clang, opt, and llvm-mc to stage dir
set(deps)
foreach(arch ${PATH64_ENABLE_ARCHES})
    set(input "${CMAKE_CURRENT_BINARY_DIR}/__build/bin/clang${CMAKE_EXECUTABLE_SUFFIX}")
    set(output "${PATH64_STAGE_DIR}/bin/clang${CMAKE_EXECUTABLE_SUFFIX}")
    add_custom_command(OUTPUT "${output}"
                       COMMAND "${CMAKE_COMMAND}" -E copy "${input}" "${output}"
                       DEPENDS "${input}")

    list(APPEND deps "${output}")

    install(PROGRAMS "${output}"
            DESTINATION "bin")

    make_symlink_custom_command("${PATH64_STAGE_DIR}/bin"
                                "clang${CMAKE_EXECUTABLE_SUFFIX}"
                                "${PATH64_STAGE_DIR}/bin/clang++${CMAKE_EXECUTABLE_SUFFIX}")
    list(APPEND deps "${PATH64_STAGE_DIR}/bin/clang++${CMAKE_EXECUTABLE_SUFFIX}")
    install(PROGRAMS "${PATH64_STAGE_DIR}/bin/clang++${CMAKE_EXECUTABLE_SUFFIX}"
            DESTINATION "bin")

    if(PATH64_ENABLE_PATHAS)
        set(input "${CMAKE_CURRENT_BINARY_DIR}/__build/bin/llvm-mc${CMAKE_EXECUTABLE_SUFFIX}")
        set(output "${PATH64_STAGE_DIR}/bin/llvm-mc${CMAKE_EXECUTABLE_SUFFIX}")
        add_custom_command(OUTPUT "${output}"
                           COMMAND "${CMAKE_COMMAND}" -E copy "${input}" "${output}"
                           DEPENDS "${input}")
        list(APPEND deps "${output}")

        install(PROGRAMS "${output}"
                DESTINATION "bin")
    endif()
endforeach()

add_custom_target(psclang-stage DEPENDS ${deps}) 
add_dependencies(psclang-stage clang)
add_dependencies(path64-stage psclang-stage)
add_dependencies(compiler-stage psclang-stage)

