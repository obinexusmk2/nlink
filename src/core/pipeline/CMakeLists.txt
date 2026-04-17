# Pipeline component CMakeLists.txt

# Define pipeline sources  (only files that exist on disk)
set(PIPELINE_SOURCES
    nlink_pipeline.c
    pipeline_pass.c
    pipeline_stage.c
)

# Define pipeline headers
set(PIPELINE_HEADERS
    ${CMAKE_SOURCE_DIR}/include/nlink/core/pipeline/nlink_pipeline.h
)

# Use STATIC on Windows (no .dll export machinery needed for static build)
if(WIN32)
  add_library(nexus_pipeline STATIC ${PIPELINE_SOURCES} ${PIPELINE_HEADERS})
else()
  add_library(nexus_pipeline SHARED ${PIPELINE_SOURCES} ${PIPELINE_HEADERS})
  set_target_properties(nexus_pipeline PROPERTIES
      VERSION ${PROJECT_VERSION}
      SOVERSION ${PROJECT_VERSION_MAJOR}
      C_VISIBILITY_PRESET hidden
  )
endif()

# Alias so nlink_core_static INTERFACE can find this target
add_library(nlink_pipeline ALIAS nexus_pipeline)

# Setup include directories
target_include_directories(nexus_pipeline
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

# Add dependencies
target_link_libraries(nexus_pipeline
    PUBLIC
        nlink_common_static
    PRIVATE
        $<$<TARGET_EXISTS:nlink_minimizer>:nlink_minimizer>
        ${CMAKE_DL_LIBS}
)

# Set properties
set_target_properties(nexus_pipeline PROPERTIES
    POSITION_INDEPENDENT_CODE ON
)

# Define preprocessor macros
target_compile_definitions(nexus_pipeline PRIVATE
    NLINK_BUILDING_PIPELINE_LIB
)

# Install headers
install(FILES ${PIPELINE_HEADERS}
        DESTINATION include/nlink/core/pipeline)

# Install library
install(TARGETS nexus_pipeline
        EXPORT nlink-targets
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

# Pipeline Detector module
set(PIPELINE_DETECTOR_SOURCES
    pipeline_detector.c
)

set(PIPELINE_DETECTOR_HEADERS
    ${CMAKE_SOURCE_DIR}/include/nlink/core/pipeline/pipeline_detect.h
)

add_library(nexus_pipeline_detector STATIC
    ${PIPELINE_DETECTOR_SOURCES} ${PIPELINE_DETECTOR_HEADERS})

target_include_directories(nexus_pipeline_detector
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(nexus_pipeline_detector
    PUBLIC
        nlink_common_static
    PRIVATE
        nexus_pipeline
)

install(FILES ${PIPELINE_DETECTOR_HEADERS}
        DESTINATION include/nlink/core/pipeline)

install(TARGETS nexus_pipeline_detector
        EXPORT nlink-targets
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
