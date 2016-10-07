
set(crt_objects)

foreach(targ ${PATH64_ENABLE_TARGETS})
    path64_get_target_arch(arch ${targ})
    path64_get_target_bits(bits ${targ})

    set(output_dir "${Path64_BINARY_DIR}/lib")
    file(MAKE_DIRECTORY "${output_dir}")

    set(compiler "${Path64_BINARY_DIR}/bin/clang")
    get_language_target_flags(c_flags "C" "${targ}")

    add_custom_command(
        OUTPUT ${output_dir}/crtbegin.o
        COMMAND ${compiler} ${c_flags} -c ${CMAKE_CURRENT_SOURCE_DIR}/crtbegin.c -o ${output_dir}/crtbegin.o
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/crtbegin.c
    )
    
    add_custom_command(
        OUTPUT ${output_dir}/crtbeginS.o
        COMMAND ${compiler} ${c_flags} -fPIC -c ${CMAKE_CURRENT_SOURCE_DIR}/crtbegin.c -o ${output_dir}/crtbeginS.o
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/crtbegin.c
    )

    add_custom_command(
        OUTPUT ${output_dir}/crtend.o
        COMMAND ${compiler} ${c_flags} -c ${CMAKE_CURRENT_SOURCE_DIR}/crtend.c -o ${output_dir}/crtend.o
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/crtend.c
    )
    
    add_custom_command(
        OUTPUT ${output_dir}/crtendS.o
        COMMAND ${compiler} ${c_flags} -fPIC -c ${CMAKE_CURRENT_SOURCE_DIR}/crtend.c -o ${output_dir}/crtendS.o
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/crtend.c
    )

    install(FILES ${output_dir}/crtbegin.o
                  ${output_dir}/crtbeginS.o
                  ${output_dir}/crtend.o
                  ${output_dir}/crtendS.o
            DESTINATION lib/${arch}/${bits})

    list(APPEND crt_objects
         ${output_dir}/crtbegin.o
         ${output_dir}/crtbeginS.o
         ${output_dir}/crtend.o
         ${output_dir}/crtendS.o
        )

endforeach()

add_custom_target(crtobjects-stage ALL DEPENDS ${crt_objects})
add_dependencies(crtobjects-stage compiler-stage)
add_dependencies(compiler-stage-C crtobjects-stage)


