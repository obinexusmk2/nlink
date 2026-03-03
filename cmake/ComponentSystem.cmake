# ComponentSystem.cmake
# Core component registration/build helpers for NexusLink

if(DEFINED NLINK_COMPONENT_SYSTEM_INCLUDED)
  return()
endif()
set(NLINK_COMPONENT_SYSTEM_INCLUDED TRUE)

include(CMakeParseArguments)

# Umbrella target for all core components. Must exist before registration.
if(NOT TARGET nlink_core_components)
  add_custom_target(nlink_core_components
    COMMENT "Building all registered NexusLink core components"
  )
endif()

function(nlink_init_component_system)
  cmake_parse_arguments(
    COMP_INIT
    ""
    "VERSION"
    "COMPONENTS"
    ${ARGN}
  )

  if(NOT COMP_INIT_VERSION)
    set(COMP_INIT_VERSION "1.0.0")
  endif()

  set(NLINK_COMPONENT_VERSION "${COMP_INIT_VERSION}" CACHE INTERNAL "Component system version")
  message(STATUS "Initializing NexusLink component system v${COMP_INIT_VERSION}")

  if(COMP_INIT_COMPONENTS)
    foreach(COMPONENT ${COMP_INIT_COMPONENTS})
      nlink_register_component(${COMPONENT})
    endforeach()
  endif()
endfunction()

function(nlink_register_component COMPONENT_NAME)
  if(NOT COMPONENT_NAME MATCHES "^[a-z][a-z0-9_]*$")
    message(FATAL_ERROR "Invalid component name: ${COMPONENT_NAME}")
  endif()

  get_property(REGISTERED_COMPONENTS GLOBAL PROPERTY NLINK_REGISTERED_COMPONENTS)
  if(REGISTERED_COMPONENTS)
    list(FIND REGISTERED_COMPONENTS ${COMPONENT_NAME} COMPONENT_INDEX)
    if(NOT COMPONENT_INDEX EQUAL -1)
      message(STATUS "Component ${COMPONENT_NAME} already registered, skipping.")
      return()
    endif()
  endif()

  set(COMPONENT_SRC_DIR "${NLINK_SRC_DIR}/core/${COMPONENT_NAME}")
  if(NOT EXISTS "${COMPONENT_SRC_DIR}")
    message(WARNING "Component source directory not found: ${COMPONENT_SRC_DIR}")
    return()
  endif()

  set_property(GLOBAL APPEND PROPERTY NLINK_REGISTERED_COMPONENTS ${COMPONENT_NAME})

  file(GLOB COMPONENT_SOURCES "${COMPONENT_SRC_DIR}/*.c")
  message(STATUS "Registered component: ${COMPONENT_NAME}")
  message(STATUS "  Source files: ${COMPONENT_SOURCES}")
endfunction()

function(nlink_build_component)
  cmake_parse_arguments(
    BUILD
    "VERBOSE"
    "NAME;TYPE"
    "SOURCES;HEADERS;DEPS"
    ${ARGN}
  )

  if(NOT BUILD_NAME)
    message(FATAL_ERROR "nlink_build_component requires NAME")
  endif()

  if(NOT BUILD_SOURCES)
    message(FATAL_ERROR "nlink_build_component(${BUILD_NAME}) requires SOURCES")
  endif()

  set(TARGET_NAME "nlink_${BUILD_NAME}")

  add_library(${TARGET_NAME} STATIC ${BUILD_SOURCES})

  target_include_directories(${TARGET_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}
  )

  if(BUILD_DEPS)
    target_link_libraries(${TARGET_NAME} PRIVATE ${BUILD_DEPS})
  endif()

  add_dependencies(nlink_core_components ${TARGET_NAME})
  set_property(GLOBAL APPEND PROPERTY NLINK_STATIC_LIBRARIES ${TARGET_NAME})

  if(BUILD_VERBOSE)
    message(STATUS "Configured component library: ${TARGET_NAME}")
  endif()
endfunction()
