# -----------------------------
# SDL2 and SDL2_mixer Integration
# -----------------------------

# Use CONFIG mode to let vcpkg provide the correct paths
find_package(SDL2 CONFIG REQUIRED)
find_package(SDL2_mixer CONFIG REQUIRED)

# Link SDL2 targets and their include directories automatically
target_link_libraries(SpaceCadetPinball
    PRIVATE
        SDL2::SDL2
        SDL2::SDL2main
        SDL2_mixer::SDL2_mixer
)

# On Windows, copy SDL2 DLLs to the output directory
if(WIN32)
    # Query the imported locations for the correct DLL paths
    get_target_property(SDL2_DLL SDL2::SDL2 IMPORTED_LOCATION_RELEASE)
    get_target_property(SDL2_MIXER_DLL SDL2_mixer::SDL2_mixer IMPORTED_LOCATION_RELEASE)

    # Fallback to DEBUG version if RELEASE property is empty
    if(NOT SDL2_DLL)
        get_target_property(SDL2_DLL SDL2::SDL2 IMPORTED_LOCATION_DEBUG)
    endif()
    if(NOT SDL2_MIXER_DLL)
        get_target_property(SDL2_MIXER_DLL SDL2_mixer::SDL2_mixer IMPORTED_LOCATION_DEBUG)
    endif()

    # Copy the DLLs to the executable directory after build
    add_custom_command(TARGET SpaceCadetPinball POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SDL2_DLL}" $<TARGET_FILE_DIR:SpaceCadetPinball>
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SDL2_MIXER_DLL}" $<TARGET_FILE_DIR:SpaceCadetPinball>
    )
endif()
