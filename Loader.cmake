cmake_minimum_required( VERSION 2.8 )

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/Purify")

include( Core/Detail/Utils )
include( Core/Detail/SetOutputDirectories )
include( Core/Detail/ProjectSettingsTemplate )
include( Core/Detail/CreateProject )
include( Core/Detail/CreateBuild )

include( Core/Detail/DotNetReferences )
