cmake_minimum_required(VERSION 3.0...3.5)
project(SpaceCadetPinball)

set(CMAKE_CXX_STANDARD 11)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/bin)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/CMakeModules")

# On Windows, set paths to SDL-devel packages here
if(WIN32)
   list(APPEND SDL3_PATH "${CMAKE_CURRENT_LIST_DIR}/Libs/SDL3")
   list(APPEND SDL2_MIXER_PATH "${CMAKE_CURRENT_LIST_DIR}/Libs/SDL2_mixer")
endif()

# Link mingw libs static
if(MINGW)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static")
endif()

if(APPLE)
    set(MACOSX_RPATH)
    set(CMAKE_BUILD_WITH_INSTALL_RPATH true)
    set(CMAKE_INSTALL_RPATH "@executable_path/../Frameworks")
    set(CMAKE_OSX_DEPLOYMENT_TARGET "10.11")
    set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")
    list(APPEND SDL3_PATH "${CMAKE_CURRENT_LIST_DIR}/Libs")
    list(APPEND SDL2_MIXER_PATH "${CMAKE_CURRENT_LIST_DIR}/Libs")
endif()

find_package(SDL3 REQUIRED)
find_package(SDL2_mixer REQUIRED)

include_directories(${SDL3_INCLUDE_DIRS} ${SDL2_MIXER_INCLUDE_DIR})
get_property(dirs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
foreach(dir ${dirs})
  message(STATUS "Include dir='${dir}'")
endforeach()

# [SOURCE FILES OMITTED HERE FOR BREVITY – include your original list]

add_executable(SpaceCadetPinball ${SOURCE_FILES})

# Skip pch on foreign code
set_source_files_properties(
        SpaceCadetPinball/imgui.cpp
        SpaceCadetPinball/imgui_sdl.cpp
        SpaceCadetPinball/imgui_draw.cpp
        SpaceCadetPinball/imgui_widgets.cpp
        SpaceCadetPinball/imgui_tables.cpp
        SpaceCadetPinball/imgui_demo.cpp
        SpaceCadetPinball/imgui_impl_sdl.cpp
        SpaceCadetPinball/imgui_impl_sdlrenderer.cpp
        PROPERTIES SKIP_PRECOMPILE_HEADERS 1
)

if(${CMAKE_VERSION} VERSION_GREATER "3.16.0" OR ${CMAKE_VERSION} VERSION_EQUAL "3.16.0")
    target_precompile_headers(SpaceCadetPinball
            PUBLIC
            SpaceCadetPinball/pch.h
            )
endif()

target_link_libraries(SpaceCadetPinball SDL3::SDL3 ${SDL2_MIXER_LIBRARY})

# On Windows, copy DLL to output
if(WIN32)
    set(SDL3_DLL_PATH "${CMAKE_CURRENT_LIST_DIR}/Libs/SDL3/bin")
    list(GET SDL2_MIXER_LIBRARY -1 SDL2_MIXER_DLL_PATH)
    get_filename_component(SDL2_MIXER_DLL_PATH ${SDL2_MIXER_DLL_PATH} DIRECTORY)
    
    message(STATUS "copy paths='${SDL3_DLL_PATH}' '${SDL2_MIXER_DLL_PATH}'") 
    add_custom_command(TARGET SpaceCadetPinball POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SDL3_DLL_PATH}/SDL3.dll" $<TARGET_FILE_DIR:SpaceCadetPinball>
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SDL2_MIXER_DLL_PATH}/SDL2_mixer.dll" $<TARGET_FILE_DIR:SpaceCadetPinball>
    )
endif()

if(UNIX AND NOT APPLE)
    include(GNUInstallDirs)
    install(TARGETS "${PROJECT_NAME}" RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
    install(FILES "${CMAKE_SOURCE_DIR}/Platform/Linux/${PROJECT_NAME}.desktop" DESTINATION "share/applications")
    install(FILES "${CMAKE_SOURCE_DIR}/Platform/Linux/${PROJECT_NAME}.metainfo.xml" DESTINATION "share/metainfo")
    foreach(S 16 32 48 128 192)
        install(FILES "${CMAKE_SOURCE_DIR}/${PROJECT_NAME}/Icon_${S}x${S}.png" DESTINATION
            "share/icons/hicolor/${S}x${S}/apps" RENAME "${PROJECT_NAME}.png")
    endforeach(S)
endif()
