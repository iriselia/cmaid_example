# Purify

This is a lazy, cross-platform build manager for C++ written in [CMake](http://www.cmake.org/), Batch scripts, and Shell scripts and licensed under BSD 3-clause License. It was designed as a to enable fast iteration and allow users to create and maintain cross-platform C++ projects with ease.

# Features
- Off-the-shelf solution for lazy management of cross-platform C++ builds.
- CMake scripting is optional.
- Keeps the project clean by seperating the source tree from the build tree.
- Automatically creates include directory tree for external projects.
- Generates symbol export/import macros for dynamic library projects.
- Improves build speed by managing pre-compiled headers and forced-included headers based on config files

Sample program
---------------
https://github.com/fpark12/PurifySampleProject

Personal project that uses Purify extensively
---------------
https://github.com/fpark12/ServerTest
