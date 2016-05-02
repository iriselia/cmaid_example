cmake_minimum_required( VERSION 2.8 )

MACRO(force_include_protected compileFlags includeProjs outString)
	string(CONCAT ${outString} ${${outString}} "\n/* Protected Headers */\n")
	if(NOT "${includeProjs}" STREQUAL "EMPTY")
		#message("${PROJECT_NAME} 1,${includeProjs},")
		FOREACH(includeProj ${includeProjs})
			string(CONCAT ${outString} ${${outString}} "/* ${includeProj}: */ ")
			if(NOT ${${includeProj}_PROTECTED_INCLUDE_FILES} STREQUAL "")
				FOREACH(proFile ${${includeProj}_PROTECTED_INCLUDE_FILES})
					FILE(RELATIVE_PATH folder ${${includeProj}_SOURCE_DIR_CACHED} ${proFile})
					string(CONCAT ${outString} ${${outString}} "\#include \"${folder}\"\n")
					if(MSVC)
						string(CONCAT ${compileFlags} ${${compileFlags}} " " "/FI\"${folder}\"")
					endif()
				ENDFOREACH()
			else()
				string(CONCAT ${outString} ${${outString}} "/* Not found */\n")
			endif()
			#string(CONCAT ${outString} ${${outString}} "\n")
		ENDFOREACH()
	else()
	#message("${PROJECT_NAME} 2")
		string(CONCAT ${outString} ${${outString}} "\n/* NO DEPENDENCY */")
	endif()
	#string(CONCAT ${outString} ${${outString}} "\n")
ENDMACRO()

MACRO(force_include_public_recursive compileFlags includeProj outString)
	list(APPEND ${PROJECT_NAME}_ALL_INCLUDE_DIRS ${${includeProj}_SOURCE_DIR_CACHED})
	
	string(CONCAT ${outString} ${${outString}} "/* ${includeProj}: */ ")
	if(NOT ${${includeProj}_PUBLIC_INCLUDE_FILES} STREQUAL "")
		foreach(pubFile ${${includeProj}_PUBLIC_INCLUDE_FILES})
			FILE(RELATIVE_PATH folder ${${includeProj}_SOURCE_DIR_CACHED} ${pubFile})
			string(CONCAT ${outString} ${${outString}} "\#include \"${folder}\"\n")
			if(MSVC)
				string(CONCAT ${compileFlags} ${${compileFlags}} " " "/FI\"${folder}\"")
			endif()
		endforeach()
	else()
		string(CONCAT ${outString} ${${outString}} "/* Not found */\n")
	endif()
	#string(CONCAT ${outString} ${${outString}} "\n")
	#message("INCLUDES: ${${includeProj}_INCLUDES}")
	foreach(subIncludeProj ${${includeProj}_INCLUDES})
		force_include_public_recursive(${compileFlags} ${subIncludeProj} ${outString})
	endforeach()
ENDMACRO()

MACRO(force_include_public compileFlags includeProjs outString)
	string(CONCAT ${outString} ${${outString}} "\n/* Public Headers */\n")
	if(NOT "${includeProjs}" STREQUAL "EMPTY")
		foreach(includeProj ${includeProjs})
			force_include_public_recursive(${compileFlags} ${includeProj} ${outString})
		endforeach()
	else()
		string(CONCAT ${outString} ${${outString}} "\n/* NO DEPENDENCY */")
	endif()
	#string(CONCAT ${outString} ${${outString}} "\n")
ENDMACRO()

MACRO(force_include_recursive compileFlags includeProjs outString)
	#message("called ${includeProjs}")
	force_include_protected(${compileFlags} "${includeProjs}" ${outString})
	force_include_public(${compileFlags} "${includeProjs}" ${outString})
ENDMACRO()

MACRO(search_and_link_libraries libs)
	foreach(proj ${PROJECT_NAMES})
		#message("name: ${proj}")
	endforeach()
	foreach(lib ${libs})
		list(FIND PROJECT_NAMES ${lib} index)
		if(NOT index EQUAL -1)
			#message("found target: ${lib} ${index}")
			list(APPEND ${PROJECT_NAME}_ALL_INCLUDE_DIRS ${lib})
			target_link_libraries(${PROJECT_NAME} ${lib})
		else()
			#message("couldn't find target: ${lib}")
			string(FIND ${lib} "." has_dot)
			if(NOT has_dot EQUAL -1)
				file(GLOB_RECURSE lib_dir "${CMAKE_SOURCE_DIR}/*${lib}")
				if(EXISTS ${lib_dir})
					target_link_libraries(${PROJECT_NAME} ${lib_dir})
				else()
					target_link_libraries(${PROJECT_NAME} ${lib})
					#message("library not found: ${lib}")
				endif()
			endif()
		endif()
	endforeach()
ENDMACRO()
#
#
#
#
MACRO(create_project mode defines includes links)

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
		
		set(should_build ON)
	else()
		set(should_build OFF)
	endif()
	
	if(NOT ${should_build})
		#----- Cache Call Arguments -----
		unset(${PROJECT_NAME}_INCLUDES CACHE)
		unset(${PROJECT_NAME}_MODE CACHE)
		set(${PROJECT_NAME}_MODE "${mode}" CACHE STRING "")
		set(${PROJECT_NAME}_INCLUDES "${includes}" CACHE STRING "")
		
		#----- SCAN SOURCE -----
		#----- Scan Shader Files -----

	endif()

	#----- The follow code will only be executed if build project is being run a second time -----
	if( should_build )
		#message("Building: ${PROJECT_NAME}")
		#----- Add Preprocessor Definitions -----
		foreach(currMacro ${defines})
			add_definitions("-D${currMacro}")
		endforeach()
		#----- Add Project Name -----
		add_definitions("-DPROJECT_NAME=\"${PROJECT_NAME}\"")
		add_definitions("-DPROJECT_ID=${PROJECT_COUNT}")
		
		file(GLOB_RECURSE ${PROJECT_NAME}_SRC ${CMAKE_CURRENT_SOURCE_DIR}/*.cxx ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp ${CMAKE_CURRENT_SOURCE_DIR}/*.c)
		file(GLOB_RECURSE ${PROJECT_NAME}_CPP_SRC ${CMAKE_CURRENT_SOURCE_DIR}/*.cxx ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)
		file(GLOB_RECURSE ${PROJECT_NAME}_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h ${CMAKE_CURRENT_SOURCE_DIR}/*.hpp ${CMAKE_CURRENT_SOURCE_DIR}/*.inl)
		file(GLOB_RECURSE ${PROJECT_NAME}_PRECOMPILED_HEADER ${CMAKE_CURRENT_SOURCE_DIR}/*.pch.h)
		
		file(GLOB_RECURSE ${PROJECT_NAME}_RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.rc ${CMAKE_CURRENT_SOURCE_DIR}/*.r ${CMAKE_CURRENT_SOURCE_DIR}/*.resx)
		file(GLOB_RECURSE ${PROJECT_NAME}_MISC ${CMAKE_CURRENT_SOURCE_DIR}/*.l ${CMAKE_CURRENT_SOURCE_DIR}/*.y)
		file(GLOB_RECURSE ${PROJECT_NAME}_SHADERS
			${CMAKE_CURRENT_SOURCE_DIR}/*.vert
			${CMAKE_CURRENT_SOURCE_DIR}/*.frag
			${CMAKE_CURRENT_SOURCE_DIR}/*.geom
			${CMAKE_CURRENT_SOURCE_DIR}/*.ctrl
			${CMAKE_CURRENT_SOURCE_DIR}/*.eval
			${CMAKE_CURRENT_SOURCE_DIR}/*.glsl)
		unset(${PROJECT_NAME}_SRC CACHE)
		unset(${PROJECT_NAME}_CPP_SRC CACHE)
		unset(${PROJECT_NAME}_HEADERS CACHE)
		set( ${PROJECT_NAME}_SRC "${${PROJECT_NAME}_SRC}" CACHE STRING "" )
		set( ${PROJECT_NAME}_CPP_SRC "${${PROJECT_NAME}_CPP_SRC}" CACHE STRING "" )
		set( ${PROJECT_NAME}_HEADERS "${${PROJECT_NAME}_HEADERS}" CACHE STRING "" )


		if( NOT ${PROJECT_NAME}_HEADERS STREQUAL "" )
			create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}/" ${${PROJECT_NAME}_HEADERS})
		endif()
		if( NOT ${PROJECT_NAME}_SRC STREQUAL "" )
			create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}/" ${${PROJECT_NAME}_SRC})
		endif()
		if( NOT ${PROJECT_NAME}_CPP_SRC STREQUAL "" )
			create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}/" ${${PROJECT_NAME}_CPP_SRC})
		endif()

		if( NOT ${PROJECT_NAME}_RESOURCES STREQUAL "" )
			create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}/" ${${PROJECT_NAME}_RESOURCES})
			foreach(MY_RESOURCE ${${PROJECT_NAME}_RESOURCES})
				FILE(RELATIVE_PATH folder ${CMAKE_CURRENT_SOURCE_DIR} ${MY_RESOURCE})
				string(FIND ${folder} "/" result)
				if(${result} STREQUAL "-1")
					SOURCE_GROUP("Resource Files" FILES ${${PROJECT_NAME}_RESOURCES})
				endif()
			endforeach()
		endif()

		if( NOT ${PROJECT_NAME}_MISC STREQUAL "" )
			create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}/" ${${PROJECT_NAME}_MISC})
		endif()

		if( (${PROJECT_NAME}_SRC STREQUAL "") AND (${PROJECT_NAME}_HEADERS STREQUAL "") )
			message(STATUS "Project is empty, a placeholder C header was created to set compiler language.")
			file(WRITE Placeholder.h "")
			LIST(APPEND ${PROJECT_NAME}_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/Placeholder.h)
			#message(FATAL_ERROR "Please insert at least one source file to use the CMakeLists.txt.")
		endif()


		if( NOT ${PROJECT_NAME}_SHADERS STREQUAL "" )
			create_source_group("" "${CMAKE_CURRENT_SOURCE_DIR}/" ${${PROJECT_NAME}_SHADERS})
		endif()
		#----- Scan Precompiled Headers -----
		
		#------ INCLUDE DIRS AND LIBS -----
		CreateVSProjectSettings() # From ProjectSettingsTemplate.cmake
		# Must include self
		#include_directories( ${${PROJECT_NAME}_ALL_INCLUDE_DIRS} )
		# Process include list, an element could be a list of dirs or a target name
		set(includeDirs "")
		set(includeProjs "")
		FOREACH(currentName ${includes})
			if(EXISTS ${currentName})
				# if exists, it is a directory
				list(APPEND includeDirs ${currentName})
			else()
				# if doesn't exist, it is a target, we retrieve the include dirs by appending _INCLUDE_DIRS to its name
				#list(APPEND includeDirs ${${currentName}_PUBLIC_INCLUDE_DIRS})
				#list(APPEND includeDirs ${${currentName}_PROTECTED_INCLUDE_DIRS})
				#message("${currentName}_PRECOMPILED_INCLUDE_FILES: ${${currentName}_PRECOMPILED_INCLUDE_FILES}")
				
				# make the project completely public if it does not contain a .pch.h
				if( "${${currentName}_PRECOMPILED_INCLUDE_FILES}" STREQUAL "")
					list(APPEND includeDirs ${${currentName}_ALL_INCLUDE_DIRS} )
				endif()
				list(APPEND includeDirs ${${currentName}_SOURCE_DIR})
				list(APPEND includeProjs ${currentName})
			endif()
		ENDFOREACH(currentName ${includes})
		set(${PROJECT_NAME}_INCLUDES "${includeProjs}" CACHE STRING "")
		list(APPEND ${PROJECT_NAME}_ALL_INCLUDE_DIRS ${includeDirs})
		# Add links
		
		#----- Mark PRECOMPILED HEADER -----
		if( NOT ${${PROJECT_NAME}_PRECOMPILED_HEADER} STREQUAL "")
			#IF(MSVC)
				GET_FILENAME_COMPONENT(PRECOMPILED_HEADER_NAME ${${PROJECT_NAME}_PRECOMPILED_HEADER} NAME)
				GET_FILENAME_COMPONENT(PRECOMPILED_BASENAME ${PRECOMPILED_HEADER_NAME} NAME_WE)
				SET(PRECOMPILED_BINARY "${PRECOMPILED_BASENAME}-$(Configuration).pch")
				
				#list(APPEND USE_PRECOMPILED ${PRECOMPILED_HEADER_NAME})
				#list(APPEND FORCE_INCLUDE ${PRECOMPILED_HEADER_NAME})
				#list(APPEND PRECOMPILED_OUTPUT ${PRECOMPILED_BINARY})
			#ENDIF(MSVC)
		endif()
		
		#------ Create Auto-Include Header ------
		#if( NOT ${PRECOMPILED_HEADER} STREQUAL "")
		set(generatedHeader "${${PROJECT_NAME}_BINARY_DIR}/${PROJECT_NAME}.generated.pch.h")
		set(generatedSource "${${PROJECT_NAME}_BINARY_DIR}/${PROJECT_NAME}.generated.pch.cpp")
		set(generatedHeaderContent "")
		set(generatedSourceContent "")
		GET_FILENAME_COMPONENT(generatedHeaderName ${generatedHeader} NAME)
		set(generatedBinary "${PROJECT_NAME}-$(Configuration).generated.pch")
		set(usePrecompiled ${generatedHeaderName})
		set(forceInclude ${generatedHeaderName})
		set(precompiledOutputBinary ${generatedBinary})
		file(GLOB existingGeneratedHeader ${generatedHeader} )
		file(GLOB existingGeneratedSource ${generatedSource} )
		
		string(CONCAT generatedHeaderContent ${generatedHeaderContent} "/* GENERATED HEADER FILE. DO NOT EDIT. */\n\n")
		string(CONCAT generatedSourceContent ${generatedSourceContent} "/* GENERATED SOURCE FILE. DO NOT EDIT. */ \n\#include \"${generatedHeaderName}\"")
		
		# Add user-defined precompiled header to generated precompiled header
		string(CONCAT generatedHeaderContent ${generatedHeaderContent} "/* Private pre-compiled header */\n")
		if(NOT ${PRECOMPILED_HEADER_NAME} STREQUAL "")
			#message("project name: ${PROJECT_NAME},${PRECOMPILED_HEADER_NAME}\"")
			string(CONCAT generatedHeaderContent ${generatedHeaderContent} "\#include \"${PRECOMPILED_HEADER_NAME}\"\n")
		else()
			string(CONCAT generatedHeaderContent ${generatedHeaderContent} "/* ${PROJECT_NAME} does not contain pre-compiled header .pch.h */\n")
		endif()
		
		
		set(outCompileFlags "")
		if(NOT "${includes}" STREQUAL "")
			#(STATUS "Before: ${PROJECT_NAME}, includes ${includeProjs}")
			force_include_recursive(outCompileFlags "${includeProjs}" generatedHeaderContent)
			#message("After: ${generatedHeaderContent}")
		else()
			force_include_recursive(outCompileFlags "EMPTY" generatedHeaderContent)
		endif()
		
		if(NOT existingGeneratedHeader STREQUAL "" AND NOT existingGeneratedSource STREQUAL "")
			file(READ ${existingGeneratedHeader} existingGeneratedHeaderContent)
			if(NOT ${existingGeneratedHeaderContent} STREQUAL ${generatedHeaderContent})
				file(WRITE ${existingGeneratedHeader} ${generatedHeaderContent})
			endif()
			file(READ ${existingGeneratedSource} existingGeneratedSourceContent)
			if(NOT ${existingGeneratedSourceContent} STREQUAL ${generatedSourceContent})
				file(WRITE ${existingGeneratedSource} ${generatedSourceContent})
			endif()
		else()
			file(WRITE ${generatedHeader} ${generatedHeaderContent})
			file(WRITE ${generatedSource} ${generatedSourceContent})
		endif()

		SOURCE_GROUP("Generated" FILES ${generatedHeader})
		SOURCE_GROUP("Generated" FILES ${generatedSource})
		list(APPEND ${PROJECT_NAME}_HEADERS ${generatedHeader})
		list(APPEND ${PROJECT_NAME}_SRC ${generatedSource})

		if(MSVC)
			SET_SOURCE_FILES_PROPERTIES(${${PROJECT_NAME}_SRC}
				PROPERTIES COMPILE_FLAGS
				"/Yu\"${usePrecompiled}\"
				/FI\"${forceInclude}\"
				/FI\"${${PROJECT_NAME}_PRIVATE_INCLUDE_FILES}\"
				/Fp\"${precompiledOutputBinary}\""
											   OBJECT_DEPENDS "${precompiledOutputBinary}")
			
			if(NOT ${PROJECT_NAME}_CPP_SRC)
				set(COMPILER_LANGUAGE "/TC")
			endif()
			SET_SOURCE_FILES_PROPERTIES(${generatedSource}
				PROPERTIES COMPILE_FLAGS "${COMPILER_LANGUAGE} /Yc\"${generatedHeaderName}\" /Fp\"${generatedBinary}\""
				OBJECT_OUTPUTS "${generatedBinary}")
		endif()
		##else( NOT ${PRECOMPILED_HEADER} STREQUAL "")
		##	file(WRITE "${${PROJECT_NAME}_BINARY_DIR}/${PROJECT_NAME}.generated.pub.h" )
		##endif()
		
		
		# Force C++ if there's any cpp file
		if(${PROJECT_NAME}_CPP_SRC)
			set_source_files_properties(${${PROJECT_NAME}_SRC} PROPERTIES LANGUAGE CXX)
		else()
			set_source_files_properties(${${PROJECT_NAME}_SRC} PROPERTIES LANGUAGE C)
		endif()
				
		#----- CREATE TARGET -----
		set(projectExtension "")
		if(${${PROJECT_NAME}_MODE} STREQUAL "STATIC")
			#message("its: ${PROJECT_NAME} with ${${PROJECT_NAME}_HEADERS}")
			add_library (${PROJECT_NAME} STATIC ${${PROJECT_NAME}_SRC} ${${PROJECT_NAME}_HEADERS} ${MY_MISC} ${MY_RESOURCES})
			add_definitions("-DIS_STATIC")
			add_definitions("-DSTATIC_ID=${PROJECT_COUNT}")
		elseif(${${PROJECT_NAME}_MODE} STREQUAL "DYNAMIC" OR ${${PROJECT_NAME}_MODE} STREQUAL "SHARED" )
			#message("its: ${PROJECT_NAME} with ${${PROJECT_NAME}_HEADERS}")
			add_library (${PROJECT_NAME} SHARED ${${PROJECT_NAME}_SRC} ${${PROJECT_NAME}_HEADERS} ${MY_MISC} ${MY_RESOURCES})
			add_definitions("-DIS_DYNAMIC")
			add_definitions("-DEXPORT_ID=${PROJECT_COUNT}")
			if(MSVC)
				set(projectExtension ".dll")
			elseif(MACOS)
				set(projectExtension ".dylib")
			endif()
		elseif(${${PROJECT_NAME}_MODE} STREQUAL "CONSOLE")
			add_executable (${PROJECT_NAME} ${${PROJECT_NAME}_SRC} ${${PROJECT_NAME}_HEADERS} ${MY_SHADERS} ${MY_RESOURCES} ${MY_MISC})
			if(MSVC)
				set(projectExtension ".exe")
			elseif(MACOS)
				set(projectExtension "")
			endif()
		elseif(${${PROJECT_NAME}_MODE} STREQUAL "WIN32")
			add_executable (${PROJECT_NAME} WIN32 ${${PROJECT_NAME}_SRC} ${${PROJECT_NAME}_HEADERS} ${MY_SHADERS} ${MY_RESOURCES} ${MY_MISC})
			if(MSVC)
				set(projectExtension ".exe")
			elseif(MACOS)
				set(projectExtension "")
			endif()
		endif()
		
		#----- Handle includes -----
		#message("${${PROJECT_NAME}_ALL_INCLUDE_DIRS}")
		list(REMOVE_DUPLICATES ${PROJECT_NAME}_ALL_INCLUDE_DIRS)
		target_include_directories(${PROJECT_NAME} PUBLIC ${${PROJECT_NAME}_ALL_INCLUDE_DIRS} )

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

		if( MSVC )
			if(${${PROJECT_NAME}_MODE} STREQUAL "STATIC")
				set(CompilerFlags
					CMAKE_CXX_FLAGS
					CMAKE_CXX_FLAGS_DEBUG
					CMAKE_CXX_FLAGS_MINSIZEREL
					CMAKE_CXX_FLAGS_RELEASE
					CMAKE_CXX_FLAGS_RELWITHDEBINFO
					CMAKE_C_FLAGS
					CMAKE_C_FLAGS_DEBUG
					CMAKE_C_FLAGS_MINSIZEREL
					CMAKE_C_FLAGS_DEBUG
					CMAKE_C_FLAGS_RELWITHDEBINFO
				)
				foreach(CompilerFlag ${CompilerFlags})
					string(REPLACE "/MD" "/MT" ${CompilerFlag} "${${CompilerFlag}}")
				endforeach()
			endif()
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
			message("has cpp ${${PROJECT_NAME}_CPP_SRC}")
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
				add_custom_command(TARGET ${PROJECT_NAME}
				   POST_BUILD
				   COMMAND "COPY"
				   ARGS "1>Nul" "2>Nul" "${arg1}" "${arg2}" "/Y"
				   COMMENT "Copying resource files to the binary output directory...")
			endif()
		else()
			if(NOT projectExtension STREQUAL "")
				set(arg1 "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${PROJECT_NAME}*${projectExtension}")
				set(arg2 "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/../")
				add_custom_command(TARGET ${PROJECT_NAME}
				   POST_BUILD
				   COMMAND "tar"
				   ARGS  "-cf" "-" "${arg1}" "|" "tar" "-C${arg2}" "-xf" "-"
				   COMMENT "Copying resource files to the binary output directory...")
			endif()
			##message("FIX COPY")
		endif()

		# Shader Copy
		if( NOT ${PROJECT_NAME}_SHhADERS STREQUAL "" )
			add_custom_target(${PROJECT_NAME}PreBuild ALL
				COMMAND ${CMAKE_COMMAND}
				-DSrcDir=${CMAKE_CURRENT_SOURCE_DIR}
				-DDestDir=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/../
				-P ${CMAKE_MODULE_PATH}/Core/CopyResource.cmake
				COMMENT "Copying resource files to the binary output directory")
				
			add_dependencies(${PROJECT_NAME} ${PROJECT_NAME}PreBuild)
				
			#if( MSVC )
				SET_PROPERTY(GLOBAL PROPERTY USE_FOLDERS ON)
				SET_PROPERTY(TARGET ${PROJECT_NAME}PreBuild		PROPERTY FOLDER ZERO_CHECK/PreBuild)
			#endif()
		endif()

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