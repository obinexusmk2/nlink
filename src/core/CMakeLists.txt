# Updated with tactical modules
# Copyright © 2025 OBINexus Computing

# Component subdirectories are auto-discovered below.
# Keep this file declarative and avoid hardcoding renamed/missing paths.

# CMakeLists.txt for NexusLink core components
# This file coordinates the build of all core components

# Include common build system modules
include(${CMAKE_SOURCE_DIR}/cmake/BuildSystem.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/ComponentSystem.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/Hooks.cmake)

# Execute pre-build hooks
nlink_execute_pre_build_hooks()

# Discover all core components
file(GLOB CORE_COMPONENTS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "*")
set(CORE_COMPONENT_DIRS "")

foreach(COMPONENT ${CORE_COMPONENTS})
  set(COMPONENT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${COMPONENT}")
  if(IS_DIRECTORY "${COMPONENT_DIR}"
     AND EXISTS "${COMPONENT_DIR}/CMakeLists.txt"
     AND COMPONENT MATCHES "^[a-z][a-z0-9_]*$")
    # Add to list of component directories
    list(APPEND CORE_COMPONENT_DIRS ${COMPONENT})

    # Register component with the build system
    if(NOT DEFINED NLINK_COMPONENT_SYSTEM_INCLUDED)
      # If component system isn't loaded yet, just add to our local list
      message(STATUS "Found core component: ${COMPONENT}")
    else()
      # Register with the component system
      nlink_register_component(${COMPONENT})
    endif()
  endif()
endforeach()

# Add each component subdirectory
foreach(COMPONENT_DIR ${CORE_COMPONENT_DIRS})
  add_subdirectory(${COMPONENT_DIR})
endforeach()

# Aggregate INTERFACE target so the root CMakeLists can link against one name.
# Uses generator-expression guards so missing optional components are silently skipped.
add_library(nlink_core_static INTERFACE)
target_link_libraries(nlink_core_static INTERFACE
    $<$<TARGET_EXISTS:nlink_common_static>:nlink_common_static>
    $<$<TARGET_EXISTS:nlink_config>:nlink_config>
    $<$<TARGET_EXISTS:nlink_parser>:nlink_parser>
    $<$<TARGET_EXISTS:nlink_pattern_matching>:nlink_pattern_matching>
    $<$<TARGET_EXISTS:nlink_tactic>:nlink_tactic>
    $<$<TARGET_EXISTS:nlink_token_type>:nlink_token_type>
    $<$<TARGET_EXISTS:nlink_token_value>:nlink_token_value>
    $<$<TARGET_EXISTS:nlink_tokenizer>:nlink_tokenizer>
    $<$<TARGET_EXISTS:nlink_minimizer>:nlink_minimizer>
    $<$<TARGET_EXISTS:nlink_pipeline>:nlink_pipeline>
    $<$<TARGET_EXISTS:nlink_symbols>:nlink_symbols>
    $<$<TARGET_EXISTS:nlink_versioning>:nlink_versioning>
    $<$<TARGET_EXISTS:nlink_mpsystem>:nlink_mpsystem>
    $<$<TARGET_EXISTS:nlink_spsystem>:nlink_spsystem>
)

# Export the aggregate INTERFACE target so installed consumers can resolve it.
# nlink_cli_static (which IS in nlink-targets) links against this target, so
# CMake requires it to be in the same export set.
install(TARGETS nlink_core_static
    EXPORT nlink-targets
)

# Create unified core library
add_custom_target(nlink_unified_core ALL
  DEPENDS nlink_core_components
  COMMENT "Building unified core library"
)

# Create static unified library
get_property(STATIC_LIBS GLOBAL PROPERTY NLINK_STATIC_LIBRARIES)
if(STATIC_LIBS)
  add_library(nlink_core STATIC IMPORTED GLOBAL)
  set_property(TARGET nlink_core PROPERTY
    IMPORTED_LOCATION "${CMAKE_BINARY_DIR}/lib/libnlink_core.a"
  )
  
  # Command to create the static unified library
  add_custom_command(
    OUTPUT "${CMAKE_BINARY_DIR}/lib/libnlink_core.a"
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/lib
    COMMAND ${CMAKE_AR} crs "${CMAKE_BINARY_DIR}/lib/libnlink_core.a"
            $<TARGET_OBJECTS:nlink_common_objects>
            $<$<TARGET_EXISTS:nlink_symbols_objects>:$<TARGET_OBJECTS:nlink_symbols_objects>>
            $<$<TARGET_EXISTS:nlink_versioning_objects>:$<TARGET_OBJECTS:nlink_versioning_objects>>
            $<$<TARGET_EXISTS:nlink_minimizer_objects>:$<TARGET_OBJECTS:nlink_minimizer_objects>>
            $<$<TARGET_EXISTS:nlink_pipeline_objects>:$<TARGET_OBJECTS:nlink_pipeline_objects>>
            $<$<TARGET_EXISTS:nlink_pattern_objects>:$<TARGET_OBJECTS:nlink_pattern_objects>>
            $<$<TARGET_EXISTS:nlink_mpsystem_objects>:$<TARGET_OBJECTS:nlink_mpsystem_objects>>
            $<$<TARGET_EXISTS:nlink_spsystem_objects>:$<TARGET_OBJECTS:nlink_spsystem_objects>>
            $<$<TARGET_EXISTS:nlink_metadata_objects>:$<TARGET_OBJECTS:nlink_metadata_objects>>
    DEPENDS ${STATIC_LIBS}
    COMMENT "Creating unified static library"
  )
  
  add_custom_target(nlink_unified_static
    DEPENDS "${CMAKE_BINARY_DIR}/lib/libnlink_core.a"
  )
  
  add_dependencies(nlink_unified_core nlink_unified_static)
endif()

# Create shared unified library
get_property(SHARED_LIBS GLOBAL PROPERTY NLINK_SHARED_LIBRARIES)
if(SHARED_LIBS)
  add_library(nlink_core_shared SHARED IMPORTED GLOBAL)
  set_property(TARGET nlink_core_shared PROPERTY
    IMPORTED_LOCATION "${CMAKE_BINARY_DIR}/lib/libnlink_core.so"
  )
  
  # Command to create the shared unified library
  add_custom_command(
    OUTPUT "${CMAKE_BINARY_DIR}/lib/libnlink_core.so"
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/lib
    COMMAND ${CMAKE_C_COMPILER} -shared -o "${CMAKE_BINARY_DIR}/lib/libnlink_core.so"
            -Wl,--whole-archive
            $<TARGET_OBJECTS:nlink_common_objects>
            $<$<TARGET_EXISTS:nlink_symbols_objects>:$<TARGET_OBJECTS:nlink_symbols_objects>>
            $<$<TARGET_EXISTS:nlink_versioning_objects>:$<TARGET_OBJECTS:nlink_versioning_objects>>
            $<$<TARGET_EXISTS:nlink_minimizer_objects>:$<TARGET_OBJECTS:nlink_minimizer_objects>>
            $<$<TARGET_EXISTS:nlink_pipeline_objects>:$<TARGET_OBJECTS:nlink_pipeline_objects>>
            $<$<TARGET_EXISTS:nlink_pattern_objects>:$<TARGET_OBJECTS:nlink_pattern_objects>>
            $<$<TARGET_EXISTS:nlink_mpsystem_objects>:$<TARGET_OBJECTS:nlink_mpsystem_objects>>
            $<$<TARGET_EXISTS:nlink_spsystem_objects>:$<TARGET_OBJECTS:nlink_spsystem_objects>>
            $<$<TARGET_EXISTS:nlink_metadata_objects>:$<TARGET_OBJECTS:nlink_metadata_objects>>
            -Wl,--no-whole-archive
            -lpthread -ldl
    DEPENDS ${SHARED_LIBS}
    COMMENT "Creating unified shared library"
  )
  
  add_custom_target(nlink_unified_shared
    DEPENDS "${CMAKE_BINARY_DIR}/lib/libnlink_core.so"
  )
  
  add_dependencies(nlink_unified_core nlink_unified_shared)
endif()

# Add the main NexusLink source file
add_library(nlink_main_objects OBJECT ${CMAKE_CURRENT_SOURCE_DIR}/nlink.c)
target_include_directories(nlink_main_objects PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/include
)

# Set position independent code for shared library compatibility
set_property(TARGET nlink_main_objects PROPERTY
    POSITION_INDEPENDENT_CODE ON
)

# Configure version header
configure_file(
    ${CMAKE_SOURCE_DIR}/templates/nlink_version.h.in
    ${CMAKE_BINARY_DIR}/include/nlink/core/nlink_version.h
    @ONLY
)

# Install the version header
install(
    FILES ${CMAKE_BINARY_DIR}/include/nlink/core/nlink_version.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/nlink/core
    COMPONENT devel
)

# Execute post-build hooks
nlink_execute_post_build_hooks()

# Output build summary
message(STATUS "=== NexusLink Core Build Summary ===")
message(STATUS "Components: ${CORE_COMPONENT_DIRS}")
message(STATUS "Static libraries: ${STATIC_LIBS}")
message(STATUS "Shared libraries: ${SHARED_LIBS}")
message(STATUS "======================================")