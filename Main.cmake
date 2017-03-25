cmake_minimum_required( VERSION 2.8 )

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/Purify")

include( Core/Utils )
include( Core/SetOutputDirectories )
include( Core/ProjectSettingsTemplate )
include( Core/CreateProject )
include( Core/CreateBuild )

include( Core/DotNetReferences )
