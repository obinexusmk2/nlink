/**
 * @file config_validator.h
 * @brief Configuration validation for NexusLink
 * @copyright Copyright © 2025 OBINexus Computing
 */

#ifndef NLINK_CONFIG_VALIDATOR_H
#define NLINK_CONFIG_VALIDATOR_H

#include "nlink/core/common/types.h"
#include "nlink/core/common/nexus_core.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Forward declarations for config structures defined in token subsystem */
typedef struct nlink_token_config_property nlink_token_config_property;
typedef struct nlink_token_config_section  nlink_token_config_section;

/**
 * Validate a configuration key name.
 * @param key Key name to validate
 * @return NEXUS_SUCCESS if valid
 */
NexusResult nlink_validate_config_key(const char* key);

/**
 * Validate a single configuration property.
 * @param property Property to validate
 * @param context  NexusLink context (may be NULL)
 * @return NEXUS_SUCCESS if valid
 */
NexusResult nlink_validate_config_property(nlink_token_config_property* property,
                                           NexusContext* context);

/**
 * Validate a configuration section (name + all properties).
 * @param section  Section to validate
 * @param context  NexusLink context (may be NULL)
 * @return NEXUS_SUCCESS if valid
 */
NexusResult nlink_validate_config_section(nlink_token_config_section* section,
                                          NexusContext* context);

/**
 * Recursively validate an entire configuration tree.
 * @param root     Root section of the config tree
 * @param context  NexusLink context (may be NULL)
 * @return NEXUS_SUCCESS if valid
 */
NexusResult nlink_validate_config_tree(nlink_token_config_section* root,
                                       NexusContext* context);

#ifdef __cplusplus
}
#endif

#endif /* NLINK_CONFIG_VALIDATOR_H */
