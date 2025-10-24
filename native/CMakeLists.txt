cmake_minimum_required(VERSION 3.15)
project(kernels LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_BUILD_TYPE Release)

if(NOT DEFINED ENV{JAVA_HOME})
  message(FATAL_ERROR "JAVA_HOME env var is required for JNI headers")
endif()

include_directories($ENV{JAVA_HOME}/include)
# Support both amd64 and arm64 architectures
include_directories($ENV{JAVA_HOME}/include/linux)
if(EXISTS $ENV{JAVA_HOME}/include/linux)
  include_directories($ENV{JAVA_HOME}/include/linux)
elseif(EXISTS $ENV{JAVA_HOME}/include/arm64)
  include_directories($ENV{JAVA_HOME}/include/arm64)
endif()

add_library(kernels SHARED kernels.cpp)

set_target_properties(kernels PROPERTIES
  OUTPUT_NAME "kernels"
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
  BUILD_WITH_INSTALL_RPATH TRUE
  INSTALL_RPATH "$ORIGIN"
)