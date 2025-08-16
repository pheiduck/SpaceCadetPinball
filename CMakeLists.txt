cmake_minimum_required(VERSION 3.10)
project(SpaceCadetPinball LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Compiler warnings
if (MSVC)
    add_compile_options(/W4 /permissive-)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Dependencies
find_package(SDL2 REQUIRED)
find_package(SDL2_mixer REQUIRED)

include_directories(${SDL2_INCLUDE_DIRS} ${SDL2_MIXER_INCLUDE_DIRS})

file(GLOB SRC_FILES
    "*.cpp"
    "*.h"
)

add_executable(SpaceCadetPinball ${SRC_FILES})
target_link_libraries(SpaceCadetPinball ${SDL2_LIBRARIES} ${SDL2_MIXER_LIBRARIES})

# Formatting target
find_program(CLANG_FORMAT clang-format)
if (CLANG_FORMAT)
    file(GLOB_RECURSE ALL_SOURCE_FILES *.cpp *.h)
    add_custom_target(format
        COMMAND ${CLANG_FORMAT} -i ${ALL_SOURCE_FILES}
        COMMENT "Running clang-format on source files")
endif()

# Packaging target
set(CPACK_GENERATOR "ZIP")
include(CPack)
