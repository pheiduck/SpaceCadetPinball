#pragma once

// Optional SoundFont linked into the executable (Linux, -DEMBED_SOUNDFONT=ON).
// SDL_mixer's FluidSynth backend can only load SoundFonts by file path, so the
// embedded data is exposed through an anonymous in-memory file (memfd).
//
// Returns a path SDL_mixer can open (valid for the lifetime of the process),
// or nullptr when no SoundFont is embedded or it could not be exposed.
const char* EmbeddedSoundFont_GetPath();
