#include "EmbeddedSoundFont.h"

#if defined(__linux__) && defined(SF2_EMBEDDED_PATH)

#include <sys/mman.h>
#include <unistd.h>
#include <cstddef>
#include <cstdio>

// Pull the .sf2 into .rodata at assembly time. SF2_EMBEDDED_PATH is an absolute
// path supplied by CMake.
__asm__(
	".section .rodata\n"
	".global pb_sf2_start\n"
	".global pb_sf2_end\n"
	".balign 16\n"
	"pb_sf2_start:\n"
	".incbin \"" SF2_EMBEDDED_PATH "\"\n"
	"pb_sf2_end:\n"
	".byte 0\n"
	".previous\n");

extern "C" const unsigned char pb_sf2_start[];
extern "C" const unsigned char pb_sf2_end[];

const char* EmbeddedSoundFont_GetPath()
{
	static char path[64];
	static bool tried = false;
	if (tried)
		return path[0] ? path : nullptr;
	tried = true;

	// The descriptor is intentionally never closed: SDL_mixer re-opens the path
	// every time MIDI playback starts.
	int fd = memfd_create("FluidR3_GM.sf2", 0);
	if (fd < 0)
		return nullptr;

	const unsigned char* p = pb_sf2_start;
	size_t left = static_cast<size_t>(pb_sf2_end - pb_sf2_start);
	while (left > 0)
	{
		ssize_t written = write(fd, p, left);
		if (written <= 0)
		{
			close(fd);
			return nullptr;
		}
		p += written;
		left -= static_cast<size_t>(written);
	}

	snprintf(path, sizeof path, "/proc/self/fd/%d", fd);
	return path;
}

#else

const char* EmbeddedSoundFont_GetPath()
{
	return nullptr;
}

#endif
