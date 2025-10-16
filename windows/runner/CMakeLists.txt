cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

set_target_properties(${BINARY_NAME} PROPERTIES
  VS_WINRT_CAPABILITIES "bluetooth"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})
target_compile_options(${BINARY_NAME} PRIVATE /MD)

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)

# Firebase C++ SDK integration
set(FIREBASE_CPP_SDK_DIR "${CMAKE_CURRENT_SOURCE_DIR}/firebase_cpp_sdk/firebase_cpp_sdk")
target_include_directories(${BINARY_NAME} PRIVATE "${FIREBASE_CPP_SDK_DIR}/include")

# Dynamically link Firebase libraries based on build configuration and architecture
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(FIREBASE_ARCH "x64")
else()
    set(FIREBASE_ARCH "x86")
endif()

set(FIREBASE_CONFIG "Debug")

set(FIREBASE_LIB_PATH "${FIREBASE_CPP_SDK_DIR}/libs/windows/VS2019/MD/${FIREBASE_ARCH}/${FIREBASE_CONFIG}")

target_link_libraries(${BINARY_NAME} PRIVATE
    "${FIREBASE_LIB_PATH}/firebase_app.lib" # firebase_app.lib should be linked first
    "${FIREBASE_LIB_PATH}/firebase_auth.lib"
    "${FIREBASE_LIB_PATH}/firebase_firestore.lib"
)

target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
