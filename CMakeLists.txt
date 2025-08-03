cmake_minimum_required(VERSION 3.14)
project(SpaceCadetPinball)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# === Find SDL3 framework manually ===
find_library(SDL3_LIBRARY SDL3
  PATHS ${CMAKE_SOURCE_DIR}/Libs/SDL3.framework
  NO_DEFAULT_PATH
)

find_path(SDL3_INCLUDE_DIR SDL3.h
  PATHS ${CMAKE_SOURCE_DIR}/Libs/SDL3.framework/Headers
  NO_DEFAULT_PATH
)

if (SDL3_LIBRARY AND SDL3_INCLUDE_DIR)
  message(STATUS "Found SDL3 framework at ${SDL3_LIBRARY}")
else()
  message(FATAL_ERROR "Could not find SDL3.framework in Libs/")
endif()

include_directories(${SDL3_INCLUDE_DIR})

# === Find SDL2_mixer with find_package ===
find_package(SDL2_mixer REQUIRED)

# Include SDL2_mixer headers
include_directories(${SDL2_MIXER_INCLUDE_DIRS})

# === Source files ===
set(SOURCES
  src/main.cpp
  # Add your other source files here
)

add_executable(SpaceCadetPinball ${SOURCES})

# Link SDL3 and SDL2_mixer libraries
target_link_libraries(SpaceCadetPinball PRIVATE ${SDL3_LIBRARY} ${SDL2_MIXER_LIBRARIES})

# Add frameworks if on macOS for proper linking
if(APPLE)
  target_link_libraries(SpaceCadetPinball PRIVATE
    "-framework Cocoa"
    "-framework CoreAudio"
    "-framework AudioToolbox"
    "-framework IOKit"
    "-framework CoreVideo"
    "-framework Carbon"
  )
endif()
