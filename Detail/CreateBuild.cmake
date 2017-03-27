cmake_minimum_required( VERSION 2.8 )
cmake_policy(SET CMP0054 NEW)

MACRO(create_build global_define )

	if(CMAKE_BUILD_FLAG STREQUAL "LITE")
		#message("CMAKE_BUILD_FLAG: ${CMAKE_BUILD_FLAG} REBUILD")
	else()
		#message("CMAKE_BUILD_FLAG: ${CMAKE_BUILD_FLAG} REBUILD")
	endif()

	unset(PROJECT_NAMES CACHE)
	set(PROJECT_NAMES "" CACHE STRING "")
	unset(FIRST_BUILD CACHE)
	set(FIRST_BUILD ON CACHE STRING "")

	FOREACH(currDefine ${GLOBAL_DEFINE})
		string(SUBSTRING ${currDefine} 0 1 firstLetter)
		if(firstLetter STREQUAL "/")
			add_definitions(${currDefine})
		else()
			add_definitions("-D${currDefine}")
		endif()
	ENDFOREACH()

	#create solution
	get_folder_name(${CMAKE_CURRENT_SOURCE_DIR} SOLUTION_NAME)
	project( ${SOLUTION_NAME} )
	#[[message("
	PROJECT_SOURCE_DIR ${PROJECT_SOURCE_DIR}
	PROJECT-NAME_SOURCE_DIR ${${SOLUTION_NAME}_SOURCE_DIR}
	PROJECT_BINARY_DIR ${PROJECT_BINARY_DIR}
	PROJECT-NAME_BINARY_DIR ${${SOLUTION_NAME}_BINARY_DIR}
	")
	]]#

	#find all cmakelists files
	file(GLOB_RECURSE normalPriorityProjectsRaw ${CMAKE_SOURCE_DIR}/CMakeLists.txt)
	list(REMOVE_ITEM normalPriorityProjectsRaw ${CMAKE_SOURCE_DIR}/CMakeLists.txt)

	#Cache root directories of all projects
	unset(CMAKE_ALL_PROJECT_DIRS CACHE)
	set(CMAKE_ALL_PROJECT_DIRS "")
	FOREACH(curFile ${normalPriorityProjectsRaw})
		get_filename_component(fileDir ${curFile} DIRECTORY)
		list(APPEND CMAKE_ALL_PROJECT_DIRS ${fileDir})
		list(APPEND normalPriorityProjects ${fileDir}/CMakeLists.txt)
	ENDFOREACH()
	#set(CMAKE_ALL_PROJECT_DIRS "${CMAKE_ALL_PROJECT_DIRS}" CACHE STRING "")

	#Find out if there are high priority projects
	FOREACH(curFile ${normalPriorityProjects})
		#get the directory of the cmakelists
		get_filename_component(fileDir ${curFile} DIRECTORY)
		get_folder_name(${fileDir} projName)
		#assume it's protobuf if descriptor.pb.cc is present
		file(GLOB_RECURSE protobufSource ${fileDir}/descriptor.pb.cc)
		if(protobufSource)
			list(REMOVE_ITEM normalPriorityProjects ${fileDir}/CMakeLists.txt)
			list(APPEND highPriorityProjects ${fileDir}/CMakeLists.txt)
			#message(STATUS "Build: high priority target: ${projName}")
		else()
			#message("not here:${protobufSource}")
		endif()
	ENDFOREACH()

	#Pre-Configure cache include dirs prior to adding subdirectories
	FOREACH(curFile ${normalPriorityProjects})
		#get the directory of the cmakelists
		get_filename_component(fileDir ${curFile} DIRECTORY)
			
		# Source file update and generation (flex and bison, github)
		# Flex and Bison
		if( USE_FLEX_AND_BISON )
			include( Optional/PrecompileFlexBison )
		endif()

		#parse the directory name for caching project specific include dirs
		get_folder_name(${fileDir} PROJECT_NAME)
		unset(${PROJECT_NAME}_SOURCE_DIR_CACHED CACHE)
		set(${PROJECT_NAME}_SOURCE_DIR_CACHED "${fileDir}" CACHE STRING "")
		#----- All Headers -----
		FILE(RELATIVE_PATH relPath ${CMAKE_SOURCE_DIR} ${fileDir})
		set(buildPath "${CMAKE_BINARY_DIR}/${relPath}")
		#message("buildPath: ${buildPath}")

		file(GLOB_RECURSE MY_HEADERS ${fileDir}/*.h ${fileDir}/*.hpp ${fileDir}/*.inl ${fileDir}/*.rc ${fileDir}/*.r ${fileDir}/*.resx ${buildPath}/*.pb.h)
		if( NOT MY_HEADERS STREQUAL "" )
			create_source_group("" "${fileDir}/" ${MY_HEADERS})
			#remove duplicates and parse directories
			set(CURRENT_INCLUDE_DIRS "")
			set(_headerFile "")
			foreach (_headerFile ${MY_HEADERS})
				get_filename_component(_dir ${_headerFile} PATH)
				FILE(RELATIVE_PATH newdir ${CMAKE_CURRENT_BINARY_DIR} ${_dir})
				list (APPEND CURRENT_INCLUDE_DIRS ${_dir})
			endforeach()
			list(REMOVE_DUPLICATES CURRENT_INCLUDE_DIRS)
			#bad idea
			#list (APPEND CURRENT_INCLUDE_DIRS ${fileDir}/../)

			#include current include dirs and cache the content
			unset(${PROJECT_NAME}_INCLUDE_DIRS CACHE)
			# Recursive Include
			set(${PROJECT_NAME}_INCLUDE_DIRS "${CURRENT_INCLUDE_DIRS}" CACHE STRING "")
			# Project Dir only Include
			#set(${PROJECT_NAME}_ALL_INCLUDE_DIRS "${${PROJECT_NAME}_SOURCE_DIR_CACHED}" CACHE STRING "")

		endif()
		
		#----- Private pre-compiled Header -----
		file(GLOB_RECURSE MY_HEADERS ${fileDir}/*.pch.h)
		if( NOT MY_HEADERS STREQUAL "" )
			create_source_group("" "${fileDir}/" ${MY_HEADERS})
			#remove duplicates and parse directories
			set(CURRENT_INCLUDE_DIRS "")
			set(_headerFile "")
			foreach (_headerFile ${MY_HEADERS})
				get_filename_component(_dir ${_headerFile} PATH)
				FILE(RELATIVE_PATH newdir ${CMAKE_CURRENT_BINARY_DIR} ${_dir})
				list (APPEND CURRENT_INCLUDE_DIRS ${_dir})
			endforeach()
			list(REMOVE_DUPLICATES CURRENT_INCLUDE_DIRS)
			#include current include dirs and cache the content
			unset(${PROJECT_NAME}_PRECOMPILED_INCLUDE_DIRS CACHE)
			set(${PROJECT_NAME}_PRECOMPILED_INCLUDE_DIRS "${CURRENT_INCLUDE_DIRS}" CACHE STRING "")
			unset(${PROJECT_NAME}_PRECOMPILED_INCLUDE_FILES CACHE)
			set(${PROJECT_NAME}_PRECOMPILED_INCLUDE_FILES "${MY_HEADERS}" CACHE STRING "")
		endif()

		#----- Private Headers -----
		file(GLOB_RECURSE MY_HEADERS ${fileDir}/*.pri.h ${fileDir}/*.pri.hpp ${fileDir}/*.pri.inl)
		if( NOT MY_HEADERS STREQUAL "" )
			create_source_group("" "${fileDir}/" ${MY_HEADERS})
			#remove duplicates and parse directories
			set(CURRENT_INCLUDE_DIRS "")
			set(_headerFile "")
			foreach (_headerFile ${MY_HEADERS})
				get_filename_component(_dir ${_headerFile} PATH)
				FILE(RELATIVE_PATH newdir ${CMAKE_CURRENT_BINARY_DIR} ${_dir})
				list (APPEND CURRENT_INCLUDE_DIRS ${_dir})
			endforeach()
			list(REMOVE_DUPLICATES CURRENT_INCLUDE_DIRS)
			#include current include dirs and cache the content
			unset(${PROJECT_NAME}_PRIVATE_INCLUDE_DIRS CACHE)
			set(${PROJECT_NAME}_PRIVATE_INCLUDE_DIRS "${CURRENT_INCLUDE_DIRS}" CACHE STRING "")
			unset(${PROJECT_NAME}_PRIVATE_INCLUDE_FILES CACHE)
			set(${PROJECT_NAME}_PRIVATE_INCLUDE_FILES "${MY_HEADERS}" CACHE STRING "")
		endif()
		
		#----- Protected Headers -----
		file(GLOB_RECURSE MY_HEADERS ${fileDir}/*.pro.h ${fileDir}/*.pro.hpp ${fileDir}/*.pro.inl)
		if( NOT MY_HEADERS STREQUAL "" )
			create_source_group("" "${fileDir}/" ${MY_HEADERS})
			#remove duplicates and parse directories
			set(CURRENT_INCLUDE_DIRS "")
			set(_headerFile "")
			foreach (_headerFile ${MY_HEADERS})
				get_filename_component(_dir ${_headerFile} PATH)
				FILE(RELATIVE_PATH newdir ${CMAKE_CURRENT_BINARY_DIR} ${_dir})
				list (APPEND CURRENT_INCLUDE_DIRS ${_dir})
			endforeach()
			list(REMOVE_DUPLICATES CURRENT_INCLUDE_DIRS)
			#include current include dirs and cache the content
			unset(${PROJECT_NAME}_PROTECTED_INCLUDE_DIRS CACHE)
			set(${PROJECT_NAME}_PROTECTED_INCLUDE_DIRS "${CURRENT_INCLUDE_DIRS}" CACHE STRING "")
			unset(${PROJECT_NAME}_PROTECTED_INCLUDE_FILES CACHE)
			set(${PROJECT_NAME}_PROTECTED_INCLUDE_FILES "${MY_HEADERS}" CACHE STRING "")

		endif()
		
		#----- Public Headers -----
		file(GLOB_RECURSE MY_HEADERS ${fileDir}/*.pub.h ${fileDir}/*.pub.hpp ${fileDir}/*.pub.inl)
		if( NOT MY_HEADERS STREQUAL "" )
			create_source_group("" "${fileDir}/" ${MY_HEADERS})
			#remove duplicates and parse directories
			set(CURRENT_INCLUDE_DIRS "")
			set(_headerFile "")
			foreach (_headerFile ${MY_HEADERS})
				get_filename_component(_dir ${_headerFile} PATH)
				FILE(RELATIVE_PATH newdir ${CMAKE_CURRENT_BINARY_DIR} ${_dir})
				list (APPEND CURRENT_INCLUDE_DIRS ${_dir})
			endforeach()
			list(REMOVE_DUPLICATES CURRENT_INCLUDE_DIRS)
			#include current include dirs and cache the content
			unset(${PROJECT_NAME}_PUBLIC_INCLUDE_DIRS CACHE)
			set(${PROJECT_NAME}_PUBLIC_INCLUDE_DIRS "${CURRENT_INCLUDE_DIRS}" CACHE STRING "")
			unset(${PROJECT_NAME}_PUBLIC_INCLUDE_FILES CACHE)
			set(${PROJECT_NAME}_PUBLIC_INCLUDE_FILES "${MY_HEADERS}" CACHE STRING "")
		endif()
	ENDFOREACH(curFile ${normalPriorityProjects})

	SET(PROJECT_COUNT 0)

	FOREACH(curFile ${normalPriorityProjects})
		get_filename_component(fileDir ${curFile} DIRECTORY)
		get_folder_name(${fileDir} PROJECT_NAME)
		set(new_project_names "${new_project_names};${PROJECT_NAME}")
	ENDFOREACH()
	FOREACH(curFile ${highPriorityProjects})
		get_filename_component(fileDir ${curFile} DIRECTORY)
		get_folder_name(${fileDir} PROJECT_NAME)
		set(new_project_names "${new_project_names};${PROJECT_NAME}")
	ENDFOREACH()
	unset(PROJECT_NAMES CACHE)
	set(PROJECT_NAMES "${new_project_names}" CACHE STRING "")

	#Include sub directories now
	IncludeProjects(highPriorityProjects)
	IncludeProjects(normalPriorityProjects)
	AddSubdirectories(highPriorityProjects)
	AddSubdirectories(normalPriorityProjects)
	
	# we loop thru stage 1 and stage 2 back and forth, so after each successful completion
	# we reset the project to rescan everything
	FOREACH(curFile ${highPriorityProjects})
		get_filename_component(fileDir ${curFile} DIRECTORY)
		get_folder_name(${fileDir} PROJECT_NAME)
		unset(${PROJECT_NAME}_INITIALIZED CACHE)
	ENDFOREACH()

	FOREACH(curFile ${normalPriorityProjects})
		get_filename_component(fileDir ${curFile} DIRECTORY)
		get_folder_name(${fileDir} PROJECT_NAME)
		unset(${PROJECT_NAME}_INITIALIZED CACHE)
	ENDFOREACH()
	
	FOREACH(curFile ${${highPriorityProjects}})
		#get the directory of the cmakelists
		get_filename_component(fileDir ${curFile} DIRECTORY)
		list(APPEND PROJECT_DIRS ${fileDir})
	ENDFOREACH()

	FOREACH(curFile ${${normalPriorityProjects}})
		#get the directory of the cmakelists
		get_filename_component(fileDir ${curFile} DIRECTORY)
		list(APPEND PROJECT_DIRS ${fileDir})
	ENDFOREACH()
	#message("PROJECT_DIRS: ${PROJECT_DIRS}")		
	add_custom_target(
		UPDATE_RESOURCE
		DEPENDS always_rebuild
	)
	
	add_custom_command(
		TARGET UPDATE_RESOURCE
		PRE_BUILD
		COMMAND ${CMAKE_COMMAND}
		-DSrcDirs="${PROJECT_DIRS}"
		-DDestDir=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/../
		-P ${CMAKE_MODULE_PATH}/Detail/CopyResource.cmake
		#COMMENT "Copying resource files to the binary output directory"
		)

	SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ON)
	if( MSVC )
		SET_PROPERTY(TARGET UPDATE_RESOURCE		PROPERTY FOLDER CMakePredefinedTargets)
	else()
		SET_PROPERTY(TARGET UPDATE_RESOURCE		PROPERTY FOLDER ZERO_CHECK/CMakePredefinedTargets)				
	endif()
ENDMACRO()

MACRO(IncludeProjects projects)
	FOREACH(curFile ${${projects}})
		get_filename_component(fileDir ${curFile} DIRECTORY)
		get_folder_name(${fileDir} PROJECT_NAME)

		#create_project: CreateProject.cmake on fileDir
		set(${PROJECT_NAME}_INITIALIZED OFF)

		string(LENGTH ${CMAKE_SOURCE_DIR} firDirStrSize)
		string(SUBSTRING ${fileDir} ${firDirStrSize} -1 protoFileDirSubStr)
		set(${PROJECT_NAME}_SOURCE_DIR "${fileDir}")
		set(${PROJECT_NAME}_BINARY_DIR "${CMAKE_BINARY_DIR}/${protoFileDirSubStr}")

		# Most important step!
		if(NOT CMAKE_BUILD_FLAG STREQUAL "LITE")
		include(${curFile})
		endif()

		set(${PROJECT_NAME}_INITIALIZED ON)

	ENDFOREACH(curFile ${${projects}})

	FOREACH(curFile ${${projects}})
		get_filename_component(fileDir ${curFile} DIRECTORY)
		get_folder_name(${fileDir} PROJECT_NAME)

		#post_create process, note that this is completely different from creating a new project.
		#everything should have been created here, except we need to link the libraries.
		#add_subdirectory( ${fileDir} )
	ENDFOREACH(curFile ${${projects}})

ENDMACRO()

MACRO(AddSubdirectories projects)

	FOREACH(curFile ${${projects}})
		get_filename_component(fileDir ${curFile} DIRECTORY)
		get_folder_name(${fileDir} PROJECT_NAME)

		#create_project: CreateProject.cmake on fileDir
		#unset(${CMAKE_CURRENT_SOURCE_DIR} CACHE)

		string(LENGTH ${CMAKE_SOURCE_DIR} firDirStrSize)
		string(SUBSTRING ${fileDir} ${firDirStrSize} -1 protoFileDirSubStr)

		# Most important step!
		add_subdirectory( ${fileDir} )
		
		if(NOT ${PROJECT_NAME}_INITIALIZED)
			#unset(${PROJECT_NAME}_INITIALIZED CACHE)
			set(${PROJECT_NAME}_INITIALIZED ON)
		else()

			if( ("${${PROJECT_NAME}_MODE}" STREQUAL "CONSOLE") OR ("${${PROJECT_NAME}_MODE}" STREQUAL "WIN32") )
			else()
				CONFIGURE_FILE(${CMAKE_MODULE_PATH}/Detail/SymbolExportAPITemplate.template ${${PROJECT_NAME}_BINARY_DIR}/${PROJECT_NAME}_API.generated.h @ONLY)
				set(${PROJECT_NAMES}_EXPORT_API "${PROJECT_NAME}_ExportAPI.generated.h" CACHE STRING "")
			endif()

			MATH(EXPR PROJECT_COUNT "${PROJECT_COUNT}+1")
			FILE(RELATIVE_PATH folder ${CMAKE_SOURCE_DIR} ${fileDir})
			set(newFolder folder)
			string(REPLACE "/" ";" folderList "${folder}")
			string(REPLACE "/" ";" newFolderList "${newFolder}")
			list(REVERSE folderList)
			list(GET folderList 0 pName) 
			list(REMOVE_AT folderList 0)
			list(REVERSE folderList)
			string(REPLACE ";" "/" newFolder "${folderList}")
			
			if(NOT (PreviousFolder STREQUAL newFolder))
				if(newFolder STREQUAL "")
				message("Root/")
				else()
				message("${newFolder}/")
				endif()
			endif()
			message(STATUS " *   ${pName}")
			set( PreviousFolder ${newFolder} )
		endif()

	ENDFOREACH(curFile ${${projects}})
ENDMACRO()