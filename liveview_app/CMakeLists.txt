add_executable(liveview_app
    main.cpp
    liveviewwindow.h
    liveviewwindow.cpp
)

target_link_libraries(liveview_app PRIVATE canon_interface)

set_target_properties(liveview_app PROPERTIES
    BUILD_RPATH "$ORIGIN"
    INSTALL_RPATH "$ORIGIN"
)

# libEDSDK.so isn't installed system-wide, so copy it next to the executable
# ($ORIGIN rpath above) rather than relying on LD_LIBRARY_PATH.
add_custom_command(TARGET liveview_app POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${EDSDK_LIB} $<TARGET_FILE_DIR:liveview_app>
)
