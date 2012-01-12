solution "OpenGL"
	configurations {
	"debug",
	"release"
	}
	platforms { "x64", "x32" }

-- ---------------------------------------------------------
-- Project 
	project "tessellation"
		basedir "./"
		language "C++"
		location "./"
		kind "ConsoleApp" -- Shouldn't this be in configuration section ?
		files { "*.hpp", "*.cpp" }
		files { "core/*.cpp" }
		includedirs {
		"include",
		"core"
		}
		objdir "obj"

-- Debug configurations
		configuration {"debug"}
			defines {"DEBUG"}
			flags {"Symbols", "ExtraWarnings"}

-- Release configurations
		configuration {"release"}
			defines {"NDEBUG"}
			flags {"Optimize"}

-- Linux x86 platform gmake
		configuration {"linux", "gmake", "x32"}
--			buildoptions {
--				"ln -sf ./libGLEW.so.1.7.0 ./lib/linux/lin32/libGLEW.so.1.7",
--				"ln -sf ./libGLEW.so.1.7.0 ./lib/linux/lin32/libGLEW.so",
--				"ln -sf ./libglut.so.3.9.0 ./lib/linux/lin32/libglut.so",
--				"ln -sf ./libglut.so.3.9.0 ./lib/linux/lin32/libglut.so.3",
--				"ln -sf ./libAntTweakBar.so ./lib/linux/lin32/libAntTweakBar.so.1"
--			}
			linkoptions {
			"-Wl,-rpath,./lib/linux/lin32 -L./lib/linux/lin32 -lGLEW -lglut -lAntTweakBar"
			}
			libdirs {
			"lib/linux/lin32"
			}

-- Linux x64 platform gmake
		configuration {"linux", "gmake", "x64"}
--			buildoptions {
--				"ln -sf ./libGLEW.so.1.7.0 ./lib/linux/lin64/libGLEW.so.1.7",
--				"ln -sf ./libGLEW.so.1.7.0 ./lib/linux/lin64/libGLEW.so",
--				"ln -sf ./libglut.so.3.9.0 ./lib/linux/lin64/libglut.so",
--				"ln -sf ./libglut.so.3.9.0 ./lib/linux/lin64/libglut.so.3",
--				"ln -sf ./libAntTweakBar.so ./lib/linux/lin64/libAntTweakBar.so.1"
--			}
			linkoptions {
			"-Wl,-rpath,./lib/linux/lin64 -L./lib/linux/lin64 -lGLEW -lglut -lAntTweakBar"
			}
			libdirs {
			"lib/linux/lin64"
			}

-- Visual x86
		configuration {"vs2010", "x32"}
			libdirs {
			"lib/windows/win32"
			}
			links {
			"glew32s",
			"freeglut",
			"AntTweakBar"
			}

---- Visual x64
--		configuration {"vs2010", "x64"}
--			links {
--			"glew32s",
--			"freeglut",
--			}
--			libdirs {
--			"lib/windows/win64"
--			}


