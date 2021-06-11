# This script assumes Windows + Visual Studio installed, and Git Bash (over cmd in my case) as the CLI.
# If you use another cli, you might have to addapt the following commands (in particular the escaping).

git clone git@github.com:libsdl-org/SDL.git
# generate VS project with cmake (should use the highest version Visual Studio installed by default, for 64bit)
# The macro SDL_CMAKE_DEBUG_POSTFIX is used so that the debug and release versions of the binaries have the same name (but different directories, per configuration).
cmake -S ./SDL -B ./build-SDL/ -DSDL_CMAKE_DEBUG_POSTFIX=
# build the Debug and Release configurations
cmake --build ./build-SDL/  --config Debug
cmake --build ./build-SDL/  --config Release
# install the Debug and Release versions in `install/<config>/SDL`
cmake --install ./build-SDL/ --config Debug --prefix ./install/debug/SDL
cmake --install ./build-SDL/ --config Release --prefix ./install/release/SDL

# Create a small executable build2 project with no tests and no sub-directories, using .cpp, .hpp etc.
bdep new game -l c++,cpp -t exe,no-tests,no-subdir

# Copy-paste the code from https://gist.github.com/fschr/92958222e35a823e738bb181fe045274 into `game.cpp`
curl https://gist.githubusercontent.com/fschr/92958222e35a823e738bb181fe045274/raw/2db953617087616585fe6389c6e2bc1a35b29e27/main.cpp > game/game.cpp

# Now in the buildfile, try to import sdl2 like if it was already available in the system:
sed -i '3 a import libs += sdl%lib{sdl2}' game/buildfile

# Create a configuration that adds flags exposing the binaries
# You must replace the paths by the full paths of the lib and include directories. (this is different from the doc I pointed though, but maybe easier to understand - prefer the technique in the doc if you you can)
# Because we pass the paths directly to the linker and compiler, we must pass the paths in the form that these tools know (not `/e/blah/blah` but `E:/blah/blah`) and with their speicfic flags (mainly `/LIBPATH:` instead of `-L` when using MSVC toolchain).
# Note that I added -DSDL_main=main to avoid issues related to SDL_main not being defined.
# I also setup these configurations to be able to install the built project in the install directories.
# The first configuration is the default/forwarding configuration (the one used by default when you just invoke `b`).
current_dir=$(pwd -W)
bdep init -d game/ -C build-msvc-debug @debug cc "config.cc.poptions+='-I$current_dir/install/debug/SDL/include' -DSDL_main=main" "config.cc.loptions+='/LIBPATH:$current_dir/install/debug/SDL/lib'" config.install.root=./install/debug/game
bdep init -d game/ -C build-msvc-release @release cc "config.cc.poptions+='-I$current_dir/install/release/SDL/include' -DSDL_main=main" "config.cc.loptions+='/LIBPATH:$current_dir/install/release/SDL/lib'" config.install.root=./install/release/game

# At this point, your setup is ready to build the game project.
# There are several ways, but for simplicity, I will just build+install all the versions/configurations:
b install: build-msvc-debug/game/
b install: build-msvc-release/game/

# The installed binaries will not work, because by default they link with SDL2.dll, which is in a different directory than `install/<config>/bin`.
# There are several ways to fix this (for testing).
# 1. Copy the dll in the bin directory (or make symbolic links, but on windows they are hard to write correctly)
cp install/debug/SDL/bin/* install/debug/game/bin/
cp install/release/SDL/bin/* install/release/game/bin/

# 2. Link with the static library instead of the dll:
# sed -i 's/sdl%lib{sdl2}/sdl%lib{sdl2-static}/' game/buildfile
# b install: build-msvc-debug/game/
# b install: build-msvc-release/game/
# However linking will fail because of missing define to remove symbol import/export, so I'll let you check what's supposed to be defined for it to work.


# Once everything is installed you can run the program:
./install/debug/game/bin/game.exe
./install/release/game/bin/game.exe

