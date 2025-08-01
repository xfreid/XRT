# SPDX-License-Identifier: Apache-2.0
# Copyright (C) 2019-2022 Xilinx, Inc. All rights reserved.
# Copyright (C) 2025 Advanced Micro Devices, Inc. All rights reserved.
#
# This cmake file is for native build. Host and target processor are the same.
# Custom variables imported by this CMake stub which should be defined by parent CMake:
# XRT_INSTALL_DIR
# XRT_VERSION_MAJOR
# XRT_VERSION_MINOR
# XRT_VERSION_PATCH

# pdb install dir
set (CMAKE_PDB_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/symbols")

include(CMake/components.cmake)

# Boost Libraries
set(ENV{XRT_BOOST_INSTALL} "${BOOST_ROOT}")
include (CMake/boostUtil.cmake)

include_directories(${Boost_INCLUDE_DIRS})
add_compile_definitions("BOOST_LOCALE_HIDE_AUTO_PTR")
add_compile_definitions("BOOST_BIND_GLOBAL_PLACEHOLDERS")

# warning C4996: 'std::allocator<void>': warning STL4009:
# std::allocator<void> is deprecated in C++17. You can define
# _SILENCE_CXX17_ALLOCATOR_VOID_DEPRECATION_WARNING or
# _SILENCE_ALL_CXX17_DEPRECATION_WARNINGS to acknowledge that you have
# received this warning.
#
# Per https://developercommunity.visualstudio.com/t/boost-asio-reports-stdallocator-is-deprecated-in-c/500588
# the warning is bogus.  Remove defintion when fixed
add_compile_definitions("_SILENCE_CXX17_ALLOCATOR_VOID_DEPRECATION_WARNING")

if (MSVC)
  # Static linking with the CRT
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

  add_compile_options(
    /MT$<$<CONFIG:Debug>:d>  # static linking with the CRT
    /Zc:__cplusplus
    /Zi           # generate pdb files even in release mode
    /sdl          # enable security checks
    /Qspectre     # compile with the Spectre mitigations switch
    /ZH:SHA_256   # enable secure source code hashing
    /guard:cf     # enable compiler control guard feature (CFG) to prevent attackers from redirecting execution to unsafe locations
    )
  add_link_options(
    /NODEFAULTLIB:libucrt$<$<CONFIG:Debug>:d>.lib  # Hybrid CRT
    /DEFAULTLIB:ucrt$<$<CONFIG:Debug>:d>.lib       # Hybrid CRT
    /DEBUG      # instruct linker to create debugging info
    /guard:cf   # enable linker control guard feature (CFG) to prevent attackers from redirecting execution to unsafe locations
    )
  if (NOT ${CMAKE_CXX_COMPILER} MATCHES "(arm64|ARM64)")
    add_link_options(
      /CETCOMPAT  # enable Control-flow Enforcement Technology (CET) Shadow Stack mitigation
      )
  endif()
endif()


include(FindGTest)

# --- XRT Variables ---
include(CMake/xrtVariables.cmake)

# --- Release: eula ---
file(GLOB XRT_EULA
  "license/*.txt"
  )
install (FILES ${XRT_SOURCE_DIR}/../LICENSE DESTINATION ${XRT_INSTALL_DIR}/license)
message("-- XRT EA eula files  ${XRT_SOURCE_DIR}/../LICENSE")

# --- Create Version header and JSON file ---
include(CMake/version.cmake)

message("------------ xrt install dir: ${XRT_INSTALL_DIR}")
add_subdirectory(runtime_src)

# --- Find Package Support ---
include(CMake/findpackage.cmake)

# --- Python bindings ---
if (NOT ${CMAKE_CXX_COMPILER} MATCHES "(arm64|ARM64)")
  xrt_add_subdirectory(python)
endif()

# -- CPack windows SDK if base component
if (${XRT_BASE_DEV_COMPONENT} STREQUAL "base_dev")
  include(CMake/cpack-windows-sdk.cmake)
else()
  # Legacy
  include(CMake/cpackWin.cmake)
endif()

