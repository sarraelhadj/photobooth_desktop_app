find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Concurrent)

# QR code on the Share screen: sudo apt install libqrencode-dev
find_package(PkgConfig REQUIRED)
pkg_check_modules(QRENCODE REQUIRED IMPORTED_TARGET libqrencode)

add_executable(photobooth_app
    main.cpp
    boothcontroller.h
    boothcontroller.cpp
    liveviewitem.h
    liveviewitem.cpp
    qrcodeitem.h
    qrcodeitem.cpp
)

target_compile_definitions(photobooth_app PRIVATE
    APP_QML_DIR="${CMAKE_CURRENT_SOURCE_DIR}/qml"
    APP_FONTS_DIR="${CMAKE_CURRENT_SOURCE_DIR}/fonts"
)

target_link_libraries(photobooth_app PRIVATE
    canon_interface
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Concurrent
    PkgConfig::QRENCODE
)

set_target_properties(photobooth_app PROPERTIES
    BUILD_RPATH "$ORIGIN"
    INSTALL_RPATH "$ORIGIN"
)

# libEDSDK.so isn't installed system-wide, so copy it next to the executable
# ($ORIGIN rpath above) rather than relying on LD_LIBRARY_PATH.
add_custom_command(TARGET photobooth_app POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${EDSDK_LIB} $<TARGET_FILE_DIR:photobooth_app>
)
