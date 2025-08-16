cmake_minimum_required(VERSION 3.20)
project(SpaceCadetPinball)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/bin)

# Add custom CMake modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/CMakeModules")

# =========================
# Platform-specific settings
# =========================

# Windows: SDL paths and static linking for MinGW
if(WIN32)
    list(APPEND SDL2_PATH "${CMAKE_CURRENT_LIST_DIR}/Libs/SDL2")
    list(APPEND SDL2_MIXER_PATH "${CMAKE_CURRENT_LIST_DIR}/Libs/SDL2_mixer")
    if(MINGW)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static")
    endif()
endif()

# macOS 14+ settings
if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "14.0")
    set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")
    set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
    set(CMAKE_INSTALL_RPATH "@executable_path/../Frameworks")

    list(APPEND SDL2_PATH "${CMAKE_CURRENT_LIST_DIR}/Libs")
    list(APPEND SDL2_MIXER_PATH "${CMAKE_CURRENT_LIST_DIR}/Libs")

    find_library(SDL2_FRAMEWORK SDL2 PATHS "${SDL2_PATH}" NO_DEFAULT_PATH)
    find_library(SDL2_MIXER_FRAMEWORK SDL2_mixer PATHS "${SDL2_MIXER_PATH}" NO_DEFAULT_PATH)

    if(SDL2_FRAMEWORK AND SDL2_MIXER_FRAMEWORK)
        set(SDL2_LIBS "${SDL2_FRAMEWORK}" "${SDL2_MIXER_FRAMEWORK}")
    else()
        message(FATAL_ERROR "SDL2 or SDL2_mixer frameworks not found in ${SDL2_PATH}")
    endif()
endif()

# =========================
# Find SDL2
# =========================

set(SDL2_BUILDING_LIBRARY ON)
find_package(SDL2 REQUIRED)
find_package(SDL2_mixer REQUIRED)

include_directories(${SDL2_INCLUDE_DIR} ${SDL2_MIXER_INCLUDE_DIR})
get_property(dirs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
foreach(dir ${dirs})
    message(STATUS "Include dir='${dir}'")
endforeach()

# =========================
# Source files
# =========================

set(SOURCE_FILES
    # Add all your SpaceCadetPinball sources here...
    SpaceCadetPinball/control.cpp
    SpaceCadetPinball/control.h
    SpaceCadetPinball/EmbeddedData.cpp
    SpaceCadetPinball/EmbeddedData.h
    # ... (truncated for brevity)
    SpaceCadetPinball/DebugOverlay.cpp
    SpaceCadetPinball/DebugOverlay.h
)

# Windows: add resource file
if(WIN32)
    set_source_files_properties(SpaceCadetPinball/SpaceCadetPinball.rc LANGUAGE RC)
    list(APPEND SOURCE_FILES SpaceCadetPinball/SpaceCadetPinball.rc)
endif()

add_executable(SpaceCadetPinball ${SOURCE_FILES})

# =========================
# Precompiled headers
# =========================

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

if(${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.16.0")
    target_precompile_headers(SpaceCadetPinball
        PUBLIC SpaceCadetPinball/pch.h
    )
endif()

# =========================
# Link libraries
# =========================

if(APPLE)
    target_link_libraries(SpaceCadetPinball ${SDL2_LIBS})
else()
    target_link_libraries(SpaceCadetPinball ${SDL2_LIBRARY} ${SDL2_MIXER_LIBRARY})
endif()

# =========================
# Windows DLL copy
# =========================

if(WIN32)
    list(GET SDL2_LIBRARY -1 SDL2_DLL_PATH)
    list(GET SDL2_MIXER_LIBRARY -1 SDL2_MIXER_DLL_PATH)
    get_filename_component(SDL2_DLL_PATH ${SDL2_DLL_PATH} DIRECTORY)
    get_filename_component(SDL2_MIXER_DLL_PATH ${SDL2_MIXER_DLL_PATH} DIRECTORY)
    if(MINGW)
        string(REGEX REPLACE "lib$" "bin" SDL2_DLL_PATH ${SDL2_DLL_PATH})
        string(REGEX REPLACE "lib$" "bin" SDL2_MIXER_DLL_PATH ${SDL2_MIXER_DLL_PATH})
    endif()
    message(STATUS "copy paths='${SDL2_DLL_PATH}' '${SDL2_MIXER_DLL_PATH}'") 
    add_custom_command(TARGET SpaceCadetPinball POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SDL2_DLL_PATH}/SDL2.dll" $<TARGET_FILE_DIR:SpaceCadetPinball>
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SDL2_MIXER_DLL_PATH}/SDL2_mixer.dll" $<TARGET_FILE_DIR:SpaceCadetPinball>
    )
endif()

# =========================
# Linux installation
# =========================

if(UNIX AND NOT APPLE)
    include(GNUInstallDirs)
    install(TARGETS "${PROJECT_NAME}" RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
    install(FILES "${CMAKE_SOURCE_DIR}/Platform/Linux/${PROJECT_NAME}.desktop" DESTINATION "share/applications")
    install(FILES "${CMAKE_SOURCE_DIR}/Platform/Linux/${PROJECT_NAME}.metainfo.xml" DESTINATION "share/metainfo")
    foreach(S 16 32 48 128 192)
        install(FILES "${CMAKE_SOURCE_DIR}/${PROJECT_NAME}/Icon_${S}x${S}.png"
            DESTINATION "share/icons/hicolor/${S}x${S}/apps"
            RENAME "${PROJECT_NAME}.png")
    endforeach()
endif()
