# canon_interface
#
# Builds the CameraSource abstraction + CanonEdsdkSource EDSDK backend as a
# static library, plus two apps that link against it:
#   - liveview_app:   minimal Qt Widgets live-view / FPS diagnostic window
#   - photobooth_app: the QML touch kiosk
cmake_minimum_required(VERSION 3.16)

project(canon_interface CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED YES)
set(CMAKE_CXX_EXTENSIONS NO)

set(CMAKE_AUTOMOC ON)

add_compile_options(-D TARGET_OS_LINUX -fpermissive)

find_package(Qt6 REQUIRED COMPONENTS Widgets)

# Canon EDSDK is not part of this repository — it's distributed by Canon under
# its own license; download it from the Canon Developer Programme.
# Defaults to a sibling checkout; override with -DEDSDK_ROOT=/path/to/EDSDK.
set(EDSDK_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../EDSDKv132021L/Linux/EDSDK
    CACHE PATH "Path to Canon EDSDK's Linux/EDSDK directory")
set(EDSDK_LIB ${EDSDK_ROOT}/Library/ARM64/libEDSDK.so)
if(NOT EXISTS ${EDSDK_ROOT}/Header/EDSDK.h OR NOT EXISTS ${EDSDK_LIB})
    message(FATAL_ERROR "Canon EDSDK not found at EDSDK_ROOT=${EDSDK_ROOT}. "
                        "Get it from the Canon Developer Programme and pass -DEDSDK_ROOT=<path>/Linux/EDSDK.")
endif()

add_library(canon_interface STATIC
    src/canonedsdksource.cpp
    src/edserrorstring.cpp
    include/camerasource.h
    include/canonedsdksource.h
    include/edserrorstring.h
)

target_include_directories(canon_interface
    PUBLIC include
    PUBLIC ${EDSDK_ROOT}/Header
)

target_link_libraries(canon_interface
    PUBLIC Qt6::Widgets
    PUBLIC ${EDSDK_LIB}
)

set_target_properties(canon_interface PROPERTIES
    BUILD_RPATH "$ORIGIN"
    INSTALL_RPATH "$ORIGIN"
)

add_subdirectory(liveview_app)
add_subdirectory(photobooth_app)
