
# Packaging stuff

add_custom_target(debs)
add_custom_target(rpms)
add_custom_target(tarballs)
add_custom_target(installbuilder-deps)
add_custom_target(installbuilder)


if("${CMAKE_SYSTEM_NAME}" STREQUAL "SunOS")
    set(tar_program "gtar")
else()
    set(tar_program "tar")
endif()


set(package_file_list_sep "%%SEP%%")


if(NOT path64_main_package_name)
    set(path64_main_package_name "main-package")
endif()


# Making commands for complete tarball package
set(tarball_main_package_build_dir ${CMAKE_CURRENT_BINARY_DIR}/tarballs/tarball-main-package)
add_custom_command(OUTPUT ${tarball_main_package_build_dir}
                   COMMAND ${CMAKE_COMAMND} -E make_directory
                           ${tarball_main_package_build_dir})
                   
set(main_package_tarball "${CMAKE_CURRENT_BINARY_DIR}/tarballs/${path64_main_package_name}_${PSC_DISPLAY_VERSION}_${path64_main_package_arch}.tar.bz2")

add_custom_command(OUTPUT ${main_package_tarball}
                   COMMAND ${tar_program} -cjf ${main_package_tarball} ${path64_main_package_name}
                   DEPENDS ${tarball_main_package_build_dir}
                   WORKING_DIRECTORY ${tarball_main_package_build_dir})

add_custom_target(main-package-tarball DEPENDS ${main_package_tarball})
add_dependencies(tarballs main-package-tarball)


# Sets package dependencies
function(path64_set_package_deps package)
    set(path64_package_${package}_deps ${ARGN} PARENT_SCOPE)
endfunction()


# Add pckage files
function(path64_add_package_files package dest_dir)
    set(old_files ${path64_package_${package}_files})
    set(path64_package_${package}_files
        ${old_files} ${dest_dir} ${ARGN} ${package_file_list_sep} PARENT_SCOPE)
endfunction()


function(path64_add_package_files_no_installer package dest_dir)
    set(old_files ${path64_package_${package}_files_no_installer})
    set(path64_package_${package}_files_no_installer
        ${old_files} ${dest_dir} ${ARGN} ${package_file_list_sep} PARENT_SCOPE)
endfunction()


# Adds symlink to package
function(path64_add_package_symlink
         package
         source_symlink
         target_name
         dest_dir
         dest_name)
    if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
        path64_add_package_files("${package}" "${dest_dir}" "${source_symlink}")
        return()
    endif()

    set(old_symlinks ${path64_package_${package}_symlinks})
    set(path64_package_${package}_symlinks
        ${old_symlinks} ${target_name} "${dest_dir}/${dest_name}" PARENT_SCOPE)
endfunction()


# Installs files in specified directory with specified prefix
# Makes target with specified name and adds dependencies for it
function(path64_install_files target_name package_name build_dir prefix)
    # making package directory
    add_custom_command(OUTPUT ${build_dir}
                       COMMAND ${CMAKE_COMAMND} -E make_directory ${build_dir})

    # Removing first slash in prefix
    if(NOT "${prefix}" STREQUAL "")
        # Removing first slash in oname
        string(SUBSTRING "${prefix}" 0 1 first_char)
        if("${first_char}" STREQUAL "/")
            string(LENGTH "${prefix}" str_len)
            math(EXPR str_len "${str_len} - 1")
            string(SUBSTRING "${prefix}" 1 ${str_len} prefix)
        endif()
    endif()

    # copying files to package directory
    set(build_dir_deps)
    set(new_dest_dir 1)
    set(dest_dir)
    foreach(file ${path64_package_${package_name}_files} ${path64_package_${package_name}_files_no_installer})
        if(new_dest_dir)
            if("${file}" STREQUAL "%root%")
                set(dest_dir "")
            else()
                set(dest_dir ${file})
            endif()
            set(new_dest_dir)
        elseif(${file} STREQUAL ${package_file_list_sep})
            set(new_dest_dir 1)
        else()
            get_filename_component(fname ${file} NAME)

            if("${prefix}" STREQUAL "")
                set(output_dir "${build_dir}/${dest_dir}")
            else()
                set(output_dir "${build_dir}/${prefix}/${dest_dir}")
            endif()

            set(output "${output_dir}/${fname}")
            add_custom_command(OUTPUT ${output}
                               COMMAND ${CMAKE_COMMAND} -E make_directory "${output_dir}" \;
                                       cp -Rf ${file} "${output_dir}"
                               DEPENDS ${file})
            list(APPEND build_dir_deps ${output})
        endif()
    endforeach()

    # making symlinks in package
    set(do_sym)
    set(from)
    foreach(sym ${path64_package_${package_name}_symlinks})
        if(do_sym)
            if("${prefix}" STREQUAL "")
                set(output ${build_dir}/${sym})
            else()
                set(output ${build_dir}/${prefix}/${sym})
            endif()
            get_filename_component(output_path ${output} PATH)
            add_custom_command(OUTPUT ${output}
                               COMMAND ${CMAKE_COMMAND} -E make_directory ${output_path}\; rm -f ${output}\; ${CMAKE_COMMAND} -E create_symlink "${from}" "${output}")
            list(APPEND build_dir_deps ${output})
            set(do_sym)
        else()
            set(from ${sym})
            set(do_sym 1)
        endif()
    endforeach()

    add_custom_target(${target_name} DEPENDS ${build_dir_deps})
endfunction()


# Adds deb package
function(path64_add_deb_package
         pack_name
         package_version
         package_architecture
         package_maintainer
         package_section
         package_group
         package_priority
         package_homepage
         package_summary
         package_description
        )

    set(build_dir ${CMAKE_CURRENT_BINARY_DIR}/debs/deb-package-build-${pack_name})

    path64_install_files(deb-install-${pack_name}
                         ${pack_name}
                         ${build_dir}
                         ${CMAKE_INSTALL_PREFIX})

    set(package_deps)
    foreach(dep ${path64_package_${pack_name}_deps})
        set(dname "${path64_main_package_name}-${dep}")
        if(package_deps)
            set(package_deps "${package_deps}, ${dname} (= ${PSC_FULL_VERSION})")
        else()
            set(package_deps "${dname} (= ${PSC_FULL_VERSION})")
        endif()
    endforeach()

    set(package_name "${path64_main_package_name}-${pack_name}")
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/debian-control.cmake.in
                   ${build_dir}/DEBIAN/control)

    set(deb_name "debs/${path64_main_package_name}-${pack_name}_${package_version}_${package_architecture}.deb")
    add_custom_command(OUTPUT "${deb_name}"
                       COMMAND dpkg-deb -b "${build_dir}" "${deb_name}")

    add_custom_target(deb-package-${pack_name} DEPENDS "${deb_name}")
    add_dependencies(deb-package-${pack_name} deb-install-${pack_name})
    add_dependencies(debs deb-package-${pack_name})
endfunction()


# Adds rpm package
function(path64_add_rpm_package
         pack_name
         package_version
         package_architecture
         package_maintainer
         package_section
         package_group
         package_priority
         package_homepage
         package_summary
         package_description
        )

    set(build_dir ${CMAKE_CURRENT_BINARY_DIR}/rpms/rpm-package-build-${pack_name})

    path64_install_files(rpm-install-${pack_name}
                         ${pack_name}
                         ${build_dir}/root
                         ${CMAKE_INSTALL_PREFIX})

    if(NOT "X${path64_package_${pack_name}_deps}" STREQUAL "X")
        set(package_requires "Requires:")
        foreach(dep ${path64_package_${pack_name}_deps})
            set(dname "${path64_main_package_name}-${dep}")
            set(package_requires "${package_requires} ${dname} = ${PSC_FULL_VERSION}")
        endforeach()
    endif()

    set(package_name "${path64_main_package_name}-${pack_name}")
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/rpm.spec.cmake.in
                   ${build_dir}/${path64_main_package_name}-${pack_name}.spec)

    # initializing build root for rpm
    set(rpm_dirs BUILD RPMS SOURCES SPECS SRPMS)
    set(real_rpm_dirs)
    foreach(rpm_dir ${rpm_dirs})
        list(APPEND real_rpm_dirs ${build_dir}/build_dir/${rpm_dir})
    endforeach()

    foreach(rpm_dir ${real_rpm_dirs})
        add_custom_command(OUTPUT ${rpm_dir}
                           COMMAND ${CMAKE_COMMAND} -E make_directory ${rpm_dir})
    endforeach()


    set(rpm_name "${path64_main_package_name}-${pack_name}-${package_version}-0.${path64_rpm_arch}.rpm")
    set(rpmbuild_output "${build_dir}/build_dir/RPMS/${path64_rpm_arch}/${rpm_name}")
    add_custom_command(OUTPUT ${rpmbuild_output}
                       COMMAND rpmbuild -bb ${build_dir}/${path64_main_package_name}-${pack_name}.spec
                               --buildroot ${build_dir}/rpmroot
                               --define '_topdir ${build_dir}/build_dir'
                       DEPENDS ${real_rpm_dirs})

    add_custom_command(OUTPUT "rpms/${rpm_name}"
                       COMMAND ${CMAKE_COMMAND} -E copy ${rpmbuild_output} "rpms/${rpm_name}"
                       DEPENDS ${rpmbuild_output})

    add_custom_target(rpm-package-${pack_name} DEPENDS "rpms/${rpm_name}")
    add_dependencies(rpm-package-${pack_name} rpm-install-${pack_name})
    add_dependencies(rpms rpm-package-${pack_name})
endfunction()


# Adds tarball package
function(path64_add_tarball_package
         package_name
         package_version
         package_architecture
         package_maintainer
         package_section
         package_group
         package_priority
         package_homepage
         package_summary
         package_description
        )

#    set(build_dir ${CMAKE_CURRENT_BINARY_DIR}/tarballs/tarball-package-build-${package_name})
#
#    path64_install_files(tarball-install-${package_name}
#                         ${package_name}
#                         ${build_dir}/${path64_main_package_name}
#                         "")
#
#    set(tarball_name "${CMAKE_CURRENT_BINARY_DIR}/tarballs/${path64_main_package_name}-${package_name}_${package_version}_${package_architecture}.tar.bz2")
#    add_custom_command(OUTPUT "${tarball_name}"
#                       COMMAND ${tar_program} -cjf "${tarball_name}" "${path64_main_package_name}"
#                       WORKING_DIRECTORY ${build_dir})
#
#    add_custom_target(tarball-package-${package_name} DEPENDS "${tarball_name}")
#    add_dependencies(tarball-package-${package_name} tarball-install-${package_name})
#    add_dependencies(tarballs tarball-package-${package_name})


    # Adding files to main package
    path64_install_files(tarball-install-main-${package_name}
                         ${package_name}
                         ${tarball_main_package_build_dir}/${path64_main_package_name}
                         "")
    add_dependencies(main-package-tarball tarball-install-main-${package_name})

endfunction()


# Returns installbuilder component name for package name
function(get_installbuilder_component_name res pack_name)
    # removing - in package name
    string(REPLACE "-" "" pack_name "${pack_name}")

    # replacing + with p in package name
    string(REPLACE "+" "p" pack_name "${pack_name}")

    set(${res} "${pack_name}" PARENT_SCOPE)
endfunction()


function(path64_set_component_custom_code comp code)
    set("path64_component_custom_code_${comp}" "${code}" PARENT_SCOPE)
endfunction()

function(path64_set_component_custom_files comp code)
    set("path64_component_custom_files_${comp}" "${code}" PARENT_SCOPE)
endfunction()


# Makes installbuilder component
function(path64_add_installbuilder_component
         result
         comp_res_name
         package_name
         package_version
         package_architecture
         package_maintainer
         package_section
         package_group
         package_priority
         package_homepage
         package_summary
         package_description
         package_title
         component_visible
         component_selected
         component_editable
        )

    get_installbuilder_component_name(pack_name "${package_name}")

    set(comp "")
    set(comp "${comp}        <component>\n")
    set(comp "${comp}            <name>${pack_name}</name>\n")
    set(comp "${comp}            <description>${package_title}</description>\n")
    set(comp "${comp}            <detailedDescription>${package_description}</detailedDescription>\n")

    if(component_selected)
        set(comp "${comp}            <selected>1</selected>\n")
    else()
        set(comp "${comp}            <selected>0</selected>\n")
    endif()

    if(component_visible)
        set(comp "${comp}            <show>1</show>\n")
    else()
        set(comp "${comp}            <show>0</show>\n")
    endif()

    if(component_editable)
        set(comp "${comp}            <canBeEdited>1</canBeEdited>\n")
    else()
        set(comp "${comp}            <canBeEdited>0</canBeEdited>\n")
    endif()

    set(comp "${comp}            <folderList>\n")


    # adding files
    set(first TRUE)
    set(new_dest_dir TRUE)
    set(dest_dir)
    set(fold_num 0)

    foreach(file ${path64_package_${package_name}_files})
        if(new_dest_dir)

            if(NOT first)
                # finishing previous folder
                set(comp "${comp}                </distributionFileList>\n")
                set(comp "${comp}            </folder>\n")
            endif()

            set(first FALSE)
            if("${file}" STREQUAL "%root%")
                set(dest_dir "\${installdir}")
            else()
                set(dest_dir "\${installdir}/${file}")
            endif()
            set(new_dest_dir FALSE)

            math(EXPR fold_num "${fold_num} + 1")

            # starting new folder
            set(comp "${comp}            <folder>\n")
            set(comp "${comp}                <description>Desc</description>\n")
            set(comp "${comp}                <destination>${dest_dir}</destination>\n")
            set(comp "${comp}                <name>${fold_num}</name>\n")
            set(comp "${comp}                <platforms>all</platforms>\n")
            set(comp "${comp}                <distributionFileList>\n")

        elseif(${file} STREQUAL ${package_file_list_sep})
            set(new_dest_dir TRUE)
        else()
            set(comp "${comp}                    <distributionFile>\n")
            set(comp "${comp}                        <origin>${file}</origin>\n")
            set(comp "${comp}                    </distributionFile>\n")
        endif()
    endforeach()

    # finishing last folder
    if(NOT first)
        set(comp "${comp}                </distributionFileList>\n")
        set(comp "${comp}            </folder>\n")
    endif()

    # adding symlinks in installer
    set(do_sym FALSE)
    set(first TRUE)
    set(from)
    foreach(sym ${path64_package_${package_name}_symlinks})
        if(do_sym)
            math(EXPR fold_num "${fold_num} + 1")

            get_filename_component(sym_name "${sym}" NAME)
            get_filename_component(sym_path "${sym}" PATH)

            # making symlink and fake link target in installbuilder/symlinks
            set(link_path "${CMAKE_CURRENT_BINARY_DIR}/installbuilder/symlinks/${fold_num}")
            set(link "${link_path}/${sym_name}")
            make_directory("${link_path}")
            file(WRITE "${link_path}/${from}" "fake link")
            execute_process(COMMAND "${CMAKE_COMMAND}" -E create_symlink
                                    "${from}" "${link}"
                            RESULT_VARIABLE res)
            if(NOT res EQUAL 0)
                message(FATAL_ERROR "Can not create symlink '${from}' -> '${link}'")
            endif()

            set(comp "${comp}            <folder>\n")
            set(comp "${comp}                <description>Desc</description>\n")
            set(comp "${comp}                <destination>\${installdir}/${sym_path}</destination>\n")
            set(comp "${comp}                <name>${fold_num}</name>\n")
            set(comp "${comp}                <platforms>all</platforms>\n")
            set(comp "${comp}                <distributionFileList>\n")
            set(comp "${comp}                    <distributionFile>\n")
            set(comp "${comp}                        <origin>${link}</origin>\n")
            set(comp "${comp}                    </distributionFile>\n")
            set(comp "${comp}                </distributionFileList>\n")
            set(comp "${comp}            </folder>\n")

            set(do_sym FALSE)
        else()
            set(from ${sym})
            set(do_sym TRUE)
        endif()
    endforeach()

    # adding custom files for component
    set(comp "${comp}${path64_component_custom_files_${package_name}}")

    set(comp "${comp}            </folderList>\n")

    # adding custom code for component
    set(comp "${comp}${path64_component_custom_code_${package_name}}")


    set(comp "${comp}        </component>\n")

    set(${result} "${comp}" PARENT_SCOPE)
    set(${comp_res_name} "${pack_name}" PARENT_SCOPE)

endfunction()



# Adds package
function(path64_add_package
         package_name
         package_version
         package_architecture
         package_maintainer
         package_section
         package_group
         package_priority
         package_homepage
         package_summary
         package_description
         package_title
         component_visible
         component_selected
         component_editable
        )
#    path64_add_deb_package(${package_name}
#                           ${package_version}
#                           ${package_architecture}
#                           ${package_maintainer}
#                           ${package_section}
#                           ${package_group}
#                           ${package_priority}
#                           ${package_homepage}
#                           ${package_summary}
#                           ${package_description}
#                          )
#
#    path64_add_rpm_package(${package_name}
#                           ${package_version}
#                           ${package_architecture}
#                           ${package_maintainer}
#                           ${package_section}
#                           ${package_group}
#                           ${package_priority}
#                           ${package_homepage}
#                           ${package_summary}
#                           ${package_description}
#                          )

    path64_add_tarball_package(${package_name}
                               ${package_version}
                               ${package_architecture}
                               ${package_maintainer}
                               ${package_section}
                               ${package_group}
                               ${package_priority}
                               ${package_homepage}
                               ${package_summary}
                               ${package_description}
                              )

    path64_add_installbuilder_component(comp
                                        comp_name
                                        "${package_name}"
                                        "${package_version}"
                                        "${package_architecture}"
                                        "${package_maintainer}"
                                        "${package_section}"
                                        "${package_group}"
                                        "${package_priority}"
                                        "${package_homepage}"
                                        "${package_summary}"
                                        "${package_description}"
                                        "${package_title}"
                                        ${component_visible}
                                        ${component_selected}
                                        ${component_editable}
                              )

    # appending component to PATH64_COMPONENTS variable
    set(PATH64_COMPONENTS "${PATH64_COMPONENTS} ${comp}" PARENT_SCOPE)
    set(PATH64_COMPONENT_LIST "${PATH64_COMPONENT_LIST} ${comp_name}" PARENT_SCOPE)
    set(path64_components ${path64_components} ${package_name} PARENT_SCOPE)
endfunction()


function(path64_finish_packages)
    string(REPLACE "-" "" MAIN_PACKAGE_NAME "${path64_main_package_name}")


    # building ready-to-install-actions for dependencies between components
    set(actions)
    foreach(comp ${path64_components})
        get_installbuilder_component_name(comp_name "${comp}")

        set(actions "${actions}        <actionGroup>\n")
        set(actions "${actions}            <actionList>\n")

        foreach(dep ${path64_package_${comp}_deps})
            get_installbuilder_component_name(dep_name "${dep}")
            set(actions "${actions}               <setInstallerVariable name=\"project.component(${dep_name}).selected\" value=\"1\"/>\n")
        endforeach()

        set(actions "${actions}            </actionList>\n")
        set(actions "${actions}            <ruleList>\n")
        set(actions "${actions}                <isTrue value=\"\${project.component(${comp_name}).selected}\"/>\n")
        set(actions "${actions}            </ruleList>\n")
        set(actions "${actions}        </actionGroup>\n")
    endforeach()

    if("${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
        set(debug_suffix "-debug")
    else()
        set(debug_suffix "")
    endif()

    if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
        set(installer_ext "exe")
    else()
        set(installer_ext "run")
    endif()

    set(INSTALLER_FILE_NAME "${path64_main_package_name}-${PSC_DISPLAY_VERSION}${debug_suffix}-installer.${installer_ext}")
    set(INSTALL_TYPE "normal")
    set(INSTALL_TYPE_INSTALL "1")
    set(INSTALL_TYPE_UPGRADE "0")
    set(READY_TO_INSTALL_ACTION_LIST "${actions}")

    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/installbuilder/project.xml.cmake.in"
                   "${CMAKE_CURRENT_BINARY_DIR}/installbuilder/project.xml"
                   @ONLY)

    if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
        set(installbuilder_exe_name "builder-cli")
    elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
        set(installbuilder_exe_name "installbuilder.sh")
    else()
        set(installbuilder_exe_name "builder")
    endif()

    add_custom_target(installbuilder-install
                      COMMAND "${installbuilder_exe_name}" build "${CMAKE_CURRENT_BINARY_DIR}/installbuilder/project.xml")

    if("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
        add_custom_target(installbuilder-install-dmg
                          COMMAND hdiutil create installbuilder/${INSTALLER_FILE_NAME}.dmg -srcfolder installbuilder/${INSTALER_FILE_NAME})
        add_dependencies(installbuilder-install-dmg installbuilder-install)
        add_dependencies(installbuilder installbuilder-install-dmg)
    endif()

    add_dependencies(installbuilder-install installbuilder-deps)
    add_dependencies(installbuilder installbuilder-install )
endfunction()

