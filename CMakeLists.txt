cmake_minimum_required(VERSION 3.14)
project(SpaceCadetPinball)

set(CMAKE_CXX_STANDARD 17)

# Find SDL3 manually if no config file is found
find_package(SDL3 QUIET)

if(NOT SDL3_FOUND)
  message(STATUS "SDL3 not found with find_package, trying manual framework search")

  find_library(SDL3_LIBRARY SDL3
    PATHS ${CMAKE_SOURCE_DIR}/Libs/SDL3.xcframework
    NO_DEFAULT_PATH
  )

  find_path(SDL3_INCLUDE_DIR SDL3.h
    PATHS ${CMAKE_SOURCE_DIR}/Libs/SDL3.xcframework/Headers
    NO_DEFAULT_PATH
  )

  if(SDL3_LIBRARY AND SDL3_INCLUDE_DIR)
    set(SDL3_FOUND TRUE)
    message(STATUS "Found SDL3 manually")
    include_directories(${SDL3_INCLUDE_DIR})
    set(SDL3_LIBRARIES ${SDL3_LIBRARY})
  else()
    message(FATAL_ERROR "SDL3 not found")
  endif()
endif()

# Find SDL2_mixer with find_package (assuming you have SDL2_mixer installed or bundled)
find_package(SDL2_mixer REQUIRED)

# Your executable
add_executable(SpaceCadetPinball main.cpp ...)  # your source files

# Link libraries
target_include_directories(SpaceCadetPinball PRIVATE ${SDL3_INCLUDE_DIR} ${SDL2_MIXER_INCLUDE_DIRS})
target_link_libraries(SpaceCadetPinball PRIVATE ${SDL3_LIBRARIES} ${SDL2_MIXER_LIBRARIES})
