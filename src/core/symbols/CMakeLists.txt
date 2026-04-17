# Symbol management component for NexusLink
cmake_minimum_required(VERSION 3.12)

set(SYMBOLS_SOURCES
    nexus_symbols.c
    versioned_symbols.c
    cold_symbol.c
)

# Create the symbols library (static so it can be linked into nlink_core_static)
add_library(nexus_symbols STATIC ${SYMBOLS_SOURCES})
add_library(nlink_symbols ALIAS nexus_symbols)

# Set properties for the library
set_target_properties(nexus_symbols PROPERTIES
    C_STANDARD 11
    C_STANDARD_REQUIRED ON
    POSITION_INDEPENDENT_CODE ON
)

# Set include directories
target_include_directories(nexus_symbols
    PUBLIC
        ${CMAKE_SOURCE_DIR}/include
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
)

# Link with necessary libraries
target_link_libraries(nexus_symbols
    PUBLIC
        nlink_common_static
)

# Add the library to the core components list
set(NEXUS_CORE_COMPONENTS ${NEXUS_CORE_COMPONENTS} nexus_symbols PARENT_SCOPE)