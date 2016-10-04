

# copying cxxabi.h header to stage dir
add_custom_command(OUTPUT ${PATH64_STAGE_DIR}/include/cxxabi.h
                   COMMAND ${CMAKE_COMMAND} -E copy
                           ${CMAKE_CURRENT_SOURCE_DIR}/cxxabi.h
                           ${PATH64_STAGE_DIR}/include/cxxabi.h
                   DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/cxxabi.h)
add_custom_target(cxxabi-h-stage DEPENDS ${PATH64_STAGE_DIR}/include/cxxabi.h)
add_dependencies(compiler-stage-libs-CXX cxxabi-h-stage)


set(CXXRT_SOURCES
    dynamic_cast.cc
    exception.cc
    guard.cc
    terminate.cc
    typeinfo.cc
    stdexcept.cc
    memory.cc
    auxhelper.cc
    libelftc_dem_gnu3.c
   )


path64_set_multitarget_sources_base_path(cxxrt-static "${PATH64_LIBCXXRT_SOURCE}/src")
path64_set_multitarget_sources(cxxrt-static COMMON ${CXXRT_SOURCES})
path64_set_multitarget_property_(cxxrt-static OUTPUT_NAME "cxxrt")

path64_set_multitarget_property_(cxxrt-static COMPILE_FLAGS "-fPIC -fexceptions ${no_fast_stdlib}")
path64_set_multitarget_property_for_target(cxxrt-static x86_64 COMPILE_FLAGS "${anyx86}")
path64_set_multitarget_property_for_target(cxxrt-static x86_32 COMPILE_FLAGS "${anyx86}")
path64_add_multitarget_library(cxxrt-static STATIC)
path64_add_multitarget_multitarget_dependencies(cxxrt-static compiler-rt-static unwind)
path64_add_dependencies_from_multitarget(compiler-stage-libs-CXX cxxrt-static)

if(PATH64_ENABLE_SHARED)
    path64_set_multitarget_sources_base_path(cxxrt "${PATH64_LIBCXXRT_SOURCE}/src")
    path64_set_multitarget_sources(cxxrt COMMON ${CXXRT_SOURCES})
    path64_set_multitarget_property_(cxxrt OUTPUT_NAME "cxxrt")
    path64_set_multitarget_property_(cxxrt COMPILE_FLAGS "-fPIC -nostdinc++ -fexceptions -lpthread ${no_fast_stdlib}")
    path64_set_multitarget_property_for_target(cxxrt x86_64 COMPILE_FLAGS "${anyx86}")
    path64_set_multitarget_property_for_target(cxxrt x86_32 COMPILE_FLAGS "${anyx86}")
    path64_set_multitarget_property_(cxxrt LINK_FLAGS "-nodefaultlibs")
    if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
        path64_multitarget_link_libraries(cxxrt dl)
    elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
        path64_multitarget_link_libraries(cxxrt System)
    else()
        path64_multitarget_link_libraries(cxxrt)
    endif()
    path64_add_multitarget_library(cxxrt SHARED)
    path64_add_multitarget_multitarget_dependencies(cxxrt compiler-rt unwind)
    path64_add_dependencies_from_multitarget(compiler-stage-libs-CXX cxxrt)
endif()

install(FILES ${PATH64_STAGE_DIR}/include/cxxabi.h
        DESTINATION ${CMAKE_INSTALL_PREFIX}/include)

