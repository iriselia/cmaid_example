cmake_minimum_required( VERSION 2.8 )
cmake_policy(SET CMP0054 NEW)
include(ProcessorCount)

#
#
#
#
MACRO(create_project mode defines includes links)

	string(TOUPPER "${mode}" mode_capped)

	if( CMAKE_SIZEOF_VOID_P EQUAL 8 )
		#MESSAGE( "64 bits compiler detected" )
		#SET( EX_PLATFORM 64 )
	   # SET( EX_PLATFORM_NAME "x64" )
	else( CMAKE_SIZEOF_VOID_P EQUAL 8 ) 
		#MESSAGE( "32 bits compiler detected" )
	   # SET( EX_PLATFORM 32 )
	   # SET( EX_PLATFORM_NAME "x86" )
	endif( CMAKE_SIZEOF_VOID_P EQUAL 8 )

	#----- Create Project -----
	get_folder_name(${CMAKE_CURRENT_SOURCE_DIR} PROJECT_NAME)
	if(${PROJECT_NAME}_INITIALIZED)
		project( ${PROJECT_NAME} )
		
		unset(${PROJECT_NAME}_FIRST_RUN CACHE)
		unset(${PROJECT_NAME}_SECOND_RUN CACHE)
		set(${PROJECT_NAME}_FIRST_RUN OFF CACHE BOOL "")
		set(${PROJECT_NAME}_SECOND_RUN ON CACHE BOOL "")
	else()
		unset(${PROJECT_NAME}_FIRST_RUN CACHE)
		unset(${PROJECT_NAME}_SECOND_RUN CACHE)
		set(${PROJECT_NAME}_FIRST_RUN ON CACHE BOOL "")
		set(${PROJECT_NAME}_SECOND_RUN OFF CACHE BOOL "")
	endif()
	
	#----- Cache Call Params -----
	unset(${PROJECT_NAME}_DEFINES CACHE)
	unset(${PROJECT_NAME}_INCLUDES CACHE)
	unset(${PROJECT_NAME}_MODE CACHE)
	unset(${PROJECT_NAME}_BUILD_TYPE CACHE)
	unset(${PROJECT_NAME}_ID CACHE)
	set(${PROJECT_NAME}_DEFINES "${defines}" CACHE STRING "")
	set(${PROJECT_NAME}_MODE "${mode_capped}" CACHE STRING "")
	set(${PROJECT_NAME}_INCLUDES "${includes}" CACHE STRING "")
	set(${PROJECT_NAME}_BUILD_TYPE "${PROJECT_NAME}_IS_${mode_capped}" CACHE STRING "")
	set(${PROJECT_NAME}_ID "${PROJECT_COUNT}" CACHE STRING "")

	if(NOT ${${PROJECT_NAME}_SECOND_RUN})

		set(${PROJECT_NAME}_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}" CACHE STRING "")
		set(${PROJECT_NAME}_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}" CACHE STRING "")
		#----- SCAN SOURCE -----
		#----- Scan Shader Files -----

	endif()

	#----- The follow code will only be executed if build project is being run a second time -----
	if( ${PROJECT_NAME}_SECOND_RUN )
		#message("Building: ${PROJECT_NAME}")
		#----- Add Preprocessor Definitions -----
		foreach(currMacro ${defines})
			add_definitions("-D${currMacro}")
		endforeach()
		#----- Add Project Name -----
		add_definitions("-DPROJECT_NAME=\"${PROJECT_NAME}\"")
		add_definitions("-DPROJECT_ID=${${PROJECT_NAME}_ID}")

		ScanSourceFiles() #----- Utils.cmake

		#----- Scan Precompiled Headers -----
		
		#------ INCLUDE DIRS AND LIBS -----
		CreateVSProjectSettings() # From ProjectSettingsTemplate.cmake
		GetIncludeProjectsRecursive(${PROJECT_NAME} ${PROJECT_NAME}_RECURSIVE_INCLUDES)
		#message("New includes: ${${PROJECT_NAME}_RECURSIVE_INCLUDES}")
		# Process include list, an element could be a list of dirs or a target name
		set(includeDirs "")
		set(includeProjs "")
		#message("${PROJECT_NAME} includes ${${PROJECT_NAME}_INCLUDES}")
		#message("${PROJECT_NAME} includes ${includes}")
		FOREACH(currentName ${${PROJECT_NAME}_RECURSIVE_INCLUDES})
			if(EXISTS ${currentName})
				# if exists, it is a directory
				list(APPEND includeDirs ${currentName})
			elseif(EXISTS ${CMAKE_SOURCE_DIR}/${currentName})
				# or if it exists in the cmake source dir, it is a relative path
				list(APPEND includeDirs ${CMAKE_SOURCE_DIR}/${currentName})
			else()
				# if doesn't exist, it is a target, we retrieve the include dirs by appending _INCLUDE_DIRS to its name
				#list(APPEND includeDirs ${${currentName}_PUBLIC_INCLUDE_DIRS})
				#list(APPEND includeDirs ${${currentName}_PROTECTED_INCLUDE_DIRS})
				#message("${currentName}_PRECOMPILED_INCLUDE_FILES: ${${currentName}_PRECOMPILED_INCLUDE_FILES}")

				# make the project completely public if it does not contain a .pri.h
				if( "${${currentName}_PRIVATE_INCLUDE_FILES}" STREQUAL "")
					#message("${currentName} has no file")
					list(APPEND includeDirs ${${currentName}_ALL_INCLUDE_DIRS} )
				endif()
				#message("${currentName} has : ${${currentName}_ALL_INCLUDE_DIRS} ")
				foreach(define ${${currentName}_DEFINES})
					add_definitions("-D${define}")
				endforeach()
				list(APPEND includeDirs ${${currentName}_SOURCE_DIR})
				list(APPEND includeDirs ${${currentName}_BINARY_DIR})
				list(APPEND includeProjs ${currentName})
			endif()
		ENDFOREACH(currentName ${includes})
		list(APPEND ${PROJECT_NAME}_ALL_INCLUDE_DIRS ${includeDirs})
		list(APPEND ${PROJECT_NAME}_ALL_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR})
		# Add links
		GeneratePrecompiledHeader()

		# Force C++ if there's any cpp file
		if(${PROJECT_NAME}_CPP_SRC)
			set_source_files_properties(${${PROJECT_NAME}_SRC} PROPERTIES LANGUAGE CXX)
		else()
			set_source_files_properties(${${PROJECT_NAME}_SRC} PROPERTIES LANGUAGE C)
		endif()

		if(XCODE)
			if( ${PROJECT_NAME}_SRC STREQUAL "")
				file(WRITE ${${PROJECT_NAME}_BINARY_DIR}/stub.c "")
				list(APPEND ${PROJECT_NAME}_SRC ${${PROJECT_NAME}_BINARY_DIR}/stub.c)
			endif()
		endif()		
		#----- CREATE TARGET -----
		set(projectExtension "")
		add_definitions("-DCURRENT_PROJECT_NAME_IS_${PROJECT_NAME}")
		add_definitions("-D${PROJECT_NAME}_PROJECT_ID=${PROJECT_COUNT}")
		add_definitions("-DCURRENT_PROJECT_ID=${PROJECT_COUNT}")
		add_definitions("-D${${PROJECT_NAME}_BUILD_TYPE}")
		if(${${PROJECT_NAME}_MODE} STREQUAL "STATIC")
			#message("its: ${PROJECT_NAME} with ${${PROJECT_NAME}_HEADERS}")
			add_library (${PROJECT_NAME} STATIC ${${PROJECT_NAME}_SRC} ${${PROJECT_NAME}_HEADERS} ${${PROJECT_NAME}_MISC} ${${PROJECT_NAME}_RESOURCES})
			add_definitions("-DCOMPILING_STATIC")
		elseif(${${PROJECT_NAME}_MODE} STREQUAL "DYNAMIC" OR ${${PROJECT_NAME}_MODE} STREQUAL "SHARED" )
			#message("its: ${PROJECT_NAME} with ${${PROJECT_NAME}_HEADERS}")
			add_library (${PROJECT_NAME} SHARED ${${PROJECT_NAME}_SRC} ${${PROJECT_NAME}_HEADERS} ${${PROJECT_NAME}_MISC} ${${PROJECT_NAME}_RESOURCES})
			add_definitions("-D${${PROJECT_NAME}_BUILD_TYPE}")
			add_definitions("-DCOMPILING_SHARED")
			#add_definitions("-D${PROJECT_NAME}_IS_DYNAMIC" "-D${PROJECT_NAME}_IS_SHARED" )
			if(MSVC)
				set(projectExtension ".dll")
			elseif(MACOS)
				set(projectExtension ".dylib")
			endif()
		elseif(${${PROJECT_NAME}_MODE} STREQUAL "MODULE" )
			#message("its: ${PROJECT_NAME} with ${${PROJECT_NAME}_HEADERS}")
			add_library (${PROJECT_NAME} MODULE ${${PROJECT_NAME}_SRC} ${${PROJECT_NAME}_HEADERS} ${${PROJECT_NAME}_MISC} ${${PROJECT_NAME}_RESOURCES})
			add_definitions("-D${${PROJECT_NAME}_BUILD_TYPE}")
			add_definitions("-DCOMPILING_MODULE")
			##add_definitions("-D${PROJECT_NAME}_IS_DYNAMIC" "-D${PROJECT_NAME}_IS_MODULE")
			add_definitions("-DEXPORT_ID=${PROJECT_COUNT}")
			if(MSVC)
				set(projectExtension ".dll")
			elseif(MACOS)
				set(projectExtension ".dylib")
			endif()
		elseif(${${PROJECT_NAME}_MODE} STREQUAL "CONSOLE")
			add_executable (${PROJECT_NAME} ${${PROJECT_NAME}_SRC} ${${PROJECT_NAME}_HEADERS} ${${PROJECT_NAME}_SHADERS} ${${PROJECT_NAME}_MISC} ${${PROJECT_NAME}_RESOURCES})
			if(MSVC)
				set(projectExtension ".exe")
			elseif(MACOS)
				set(projectExtension "")
			endif()
		elseif(${${PROJECT_NAME}_MODE} STREQUAL "WIN32")
			add_executable (${PROJECT_NAME} WIN32 ${${PROJECT_NAME}_SRC} ${${PROJECT_NAME}_HEADERS} ${${PROJECT_NAME}_SHADERS} ${${PROJECT_NAME}_MISC} ${${PROJECT_NAME}_RESOURCES})
			if(MSVC)
				set(projectExtension ".exe")
			elseif(MACOS)
				set(projectExtension "")
			endif()
		endif()
		
		if(MSVC)
				add_definitions(/wd4251) # x needs to have dll-interface to be used by clients of class "y"
		endif()

		if(XCODE)
			SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES XCODE_ATTRIBUTE_GCC_PREFIX_HEADER "${generatedHeader}")
			SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES XCODE_ATTRIBUTE_GCC_PRECOMPILE_PREFIX_HEADER "YES")
		endif()
		
		
		#----- Target Dependency -----
		add_dependencies(${PROJECT_NAME} UPDATE_RESOURCE) #----- globally shared resource update

		#----- Exclude from all (Disabled)-----
		#set_target_properties(${PROJECT_NAME} PROPERTIES EXCLUDE_FROM_ALL 1 EXCLUDE_FROM_DEFAULT_BUILD 1)

		#----- Handle includes -----
		#message("is ${${PROJECT_NAME}_ALL_INCLUDE_DIRS}")
		if(${PROJECT_NAME}_ALL_INCLUDE_DIRS)
			list(REMOVE_DUPLICATES ${PROJECT_NAME}_ALL_INCLUDE_DIRS)
		endif()
		#message("${PROJECT_NAME}_ALL_INCLUDE_DIRS: ${${PROJECT_NAME}_ALL_INCLUDE_DIRS}")
		target_include_directories(${PROJECT_NAME} PRIVATE ${${PROJECT_NAME}_ALL_INCLUDE_DIRS} )

		#----- Handle Links -----
		#set(${PROJECT_NAME}_ALL_LINK_LIBS ${links} CACHE STRING "")
		#link_libraries(${links})
		search_and_link_libraries("${links}")

		#----- compile flags -----
		get_target_property(FLAGS ${PROJECT_NAME} COMPILE_FLAGS)
		if(FLAGS STREQUAL "FLAGS-NOTFOUND")
			set(FLAGS "")
		endif()
		set_target_properties(${PROJECT_NAME} PROPERTIES COMPILE_FLAGS "${FLAGS} ${outCompileFlags}")

		ProcessorCount(ProcCount)

		if( MSVC )
			#if(${${PROJECT_NAME}_MODE} STREQUAL "STATIC")
				set(CompilerFlags
					CMAKE_CXX_FLAGS
					CMAKE_CXX_FLAGS_DEBUG
					CMAKE_CXX_FLAGS_MINSIZEREL
					CMAKE_CXX_FLAGS_RELEASE
					CMAKE_CXX_FLAGS_RELWITHDEBINFO
					CMAKE_C_FLAGS
					CMAKE_C_FLAGS_DEBUG
					CMAKE_C_FLAGS_MINSIZEREL
					CMAKE_C_FLAGS_RELEASE
					CMAKE_C_FLAGS_RELWITHDEBINFO
				)


				if (MSVC)
					foreach(CompilerFlag ${CompilerFlags})
						set(${CompilerFlag} "/MP${ProcCount} ${${CompilerFlag}}")
					endforeach()
				endif()
			#endif()

			# utils.cmake
			#get_WIN32_WINNT(ver)
			#add_definitions(-D_WIN32_WINNT=${ver})
		endif()

		#------ set target filter -----
		#if( MSVC )
			# TODO: OPTIMIZE THIS
			string(REPLACE "/" ";" sourceDirList "${CMAKE_SOURCE_DIR}")
			string(REPLACE "/" ";" currSourceDirList "${CMAKE_CURRENT_SOURCE_DIR}")
			list(REVERSE currSourceDirList)
			list(REMOVE_AT currSourceDirList 0)
			list(REVERSE currSourceDirList)
			foreach(sourceDir ${sourceDirList})
				list(REMOVE_AT currSourceDirList 0)
			endforeach()
			list(LENGTH currSourceDirList listLength)
			string(REPLACE ";" "/" filterDir "${currSourceDirList}")
		
			SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ON)
			SET_PROPERTY(TARGET ${PROJECT_NAME}		PROPERTY FOLDER ${filterDir})
		#endif()
		
		#------ need linker language flag for header only static libraries -----
		if(${PROJECT_NAME}_CPP_SRC)
			#message("has cpp ${${PROJECT_NAME}_CPP_SRC}")
			#set_source_files_properties(${${PROJECT_NAME}_SRC} PROPERTIES LANGUAGE CXX)
		else()
			SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES LINKER_LANGUAGE C)
		endif()
		#------ need linker language flag for header only static libraries -----
		if(APPLE)
			SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES MACOSX_RPATH ON)

			EXEC_PROGRAM(/usr/bin/sw_vers OUTPUT_VARIABLE OSX_VERSION_STRING)
			STRING(REGEX REPLACE "\n" ";" OSX_VERSION_STRING "${OSX_VERSION_STRING}")
			LIST(GET OSX_VERSION_STRING 1 OSX_VERSION_STRING)
			STRING(REGEX REPLACE "\t" ";" OSX_VERSION_STRING "${OSX_VERSION_STRING}")
			LIST(GET OSX_VERSION_STRING 1 OSX_VERSION_STRING)
			STRING(REPLACE "." ";" OSX_VERSION_STRING "${OSX_VERSION_STRING}")
			LIST(GET OSX_VERSION_STRING 0 OSX_MAJOR_VERSION)
			LIST(GET OSX_VERSION_STRING 1 OSX_MINOR_VERSION)
			SET(OSX_VERSION_STRING "${OSX_MAJOR_VERSION}.${OSX_MINOR_VERSION}")
			#MESSAGE("${OSX_VERSION_STRING}")
			SET(CMAKE_OSX_DEPLOYMENT_TARGET ${OSX_VERSION_STRING} CACHE STRING "Deployment target for OSX" FORCE)

			target_compile_features(${PROJECT_NAME} PRIVATE cxx_range_for)
#TODO: CLEAN UP.

# use, i.e. don't skip the full RPATH for the build tree
#SET(CMAKE_SKIP_BUILD_RPATH  FALSE)
#			MESSAGE("A ${CMAKE_SKIP_BUILD_RPATH}")



# don't add the automatically determined parts of the RPATH
# which point to directories outside the build tree to the install RPATH
#			MESSAGE("D ${CMAKE_INSTALL_RPATH_USE_LINK_PATH}")
#SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)
# when building, don't use the install RPATH already
# (but later on when installing)
#SET(CMAKE_BUILD_WITH_INSTALL_RPATH true) 
#			MESSAGE("B ${CMAKE_BUILD_WITH_INSTALL_RPATH}")
# the RPATH to be used when installing
#SET(CMAKE_INSTALL_RPATH "@loader_path")
#			MESSAGE("C ${CMAKE_INSTALL_RPATH}")

			#UNNECESSARY. ONLY AFFECTS DLL, AND @RPATH IS THE DEFAULT INSTALL PATH.
			SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES BUILD_WITH_INSTALL_RPATH ON INSTALL_NAME_DIR "@rpath")
			
			#SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES INSTALL_RPATH_USE_LINK_PATH ON)
			#SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES SKIP_BUILD_RPATH OFF)
			SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES INSTALL_RPATH "@loader_path") #"@loader_path/../lib")
		endif()

		#----- Custom PreBuild Target ------
		# Copy Binaries from Backup folder to Binaries folder


		# Flex and Bison
		if( USE_FLEX_AND_BISON )
			include( Optional/AddFlexBisonCustomTarget )
		endif()

		#set(arg1 "${CMAKE_CURRENT_SOURCE_DIR}")
		if(MSVC)
			if(NOT projectExtension STREQUAL "")
				string(REPLACE "/" "\\" arg1 "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}*${projectExtension}")
				string(REPLACE "/" "\\" arg2 "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/../")
				add_custom_command(
					TARGET ${PROJECT_NAME}
					#OUTPUT always_rebuild
					POST_BUILD
					COMMAND "COPY"
					ARGS "1>Nul" "2>Nul" "${arg1}" "${arg2}" "/Y"
					COMMENT "Copying resource files to the binary output directory...")
			endif()
		else()
			if(NOT projectExtension STREQUAL "")
				set(arg1 "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}*${projectExtension}")
				set(arg2 "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/../")
				add_custom_command(
					TARGET ${PROJECT_NAME}
					POST_BUILD
					COMMAND "tar"
					ARGS  "-cf" "-" "${arg1}" "|" "tar" "-C${arg2}" "-xf" "-"
					COMMENT "Copying resource files to the binary output directory...")
			endif()
			##message("FIX COPY")
		endif()

		# Resource Copy
		if( NOT "${${PROJECT_NAME}_RESOURCES}" STREQUAL "" )
			#----- Add custom command requires target be created in the same scope
			cmake_policy(SET CMP0040 OLD)

			#add_custom_target(
			#	${PROJECT_NAME}_UPDATE_RESOURCE
			#	DEPENDS always_rebuild
			#)
			#add_custom_command(
			#	TARGET ${PROJECT_NAME}_UPDATE_RESOURCE
			#	PRE_BUILD
			#	COMMAND ${CMAKE_COMMAND}
			#	-DSrcDir=${CMAKE_CURRENT_SOURCE_DIR}
			#	-DDestDir=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/../
			#	-P ${CMAKE_MODULE_PATH}/Core/CopyResource.cmake
			#	COMMENT "Copying resource files to the binary output directory")
			
			#add_dependencies(${PROJECT_NAME} ${PROJECT_NAME}_UPDATE_RESOURCE)
				
		if( MSVC )
				SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ON)
				#SET_PROPERTY(TARGET ${PROJECT_NAME}PreBuild		PROPERTY FOLDER PreBuildScripts)
			else()
				SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ON)
				#SET_PROPERTY(TARGET ${PROJECT_NAME}PreBuild		PROPERTY FOLDER ZERO_CHECK/PreBuildScripts)				
			endif()
		endif()

		#install(SCRIPT ${CMAKE_MODULE_PATH}/Core/Install.cmake)

		if(${PROJECT_NAME}_INITIALIZED)
			#unset(${PROJECT_NAME}_INITIALIZED CACHE)
		endif()
	endif()
ENDMACRO(create_project mode linLibraries)

MACRO(post_create_project mode defines includes links)

	FOREACH(curFile ${allProjects})
		if(${PROJECT_NAME}_INITIALIZED)
			get_filename_component(fileDir ${curFile} DIRECTORY)
			get_folder_name(${fileDir} PROJECT_NAME)

			foreach(lib ${libs})
				list(FIND PROJECT_NAMES ${lib} index)
				if(NOT index EQUAL -1)
					message("found target: ${lib} ${index}")
					list(APPEND ${PROJECT_NAME}_ALL_INCLUDE_DIRS ${lib})
					link_libraries(${lib})
				else()
					message("couldn't find target: ${lib}")
					file(GLOB_RECURSE mysql_dir "${CMAKE_SOURCE_DIR}/*${lib}")
					#find_path(lib_dir ${lib} ${CMAKE_SOURCE_DIR})
					message("mysql from ${CMAKE_SOURCE_DIR} is :${mysql_dir}")
				endif()
			endforeach()	
		endif()
	ENDFOREACH(curFile ${allProjects})

ENDMACRO()
