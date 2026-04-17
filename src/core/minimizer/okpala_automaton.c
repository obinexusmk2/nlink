// okpala_automaton.c - Automaton data structure implementation for NexusLink
// Author: Nnamdi Michael Okpala
// Note: okpala_minimize_automaton is defined in okpala_automaton_minimzer.c

#include "nlink/core/minimizer/okpala_automaton.h"
#include <stdlib.h>
#include <string.h>

// Create a new automaton
OkpalaAutomaton* okpala_automaton_create(void) {
    OkpalaAutomaton* automaton = (OkpalaAutomaton*)malloc(sizeof(OkpalaAutomaton));
    automaton->states = NULL;
    automaton->state_count = 0;
    automaton->initial_state = NULL;
    automaton->final_states = NULL;
    automaton->final_state_count = 0;
    return automaton;
}

// Find a state by ID
static OkpalaState* find_state(OkpalaAutomaton* automaton, const char* id) {
    for (size_t i = 0; i < automaton->state_count; i++) {
        if (strcmp(automaton->states[i].id, id) == 0) {
            return &automaton->states[i];
        }
    }
    return NULL;
}

// Add a state to the automaton
NexusResult okpala_automaton_add_state(OkpalaAutomaton* automaton, 
                                     const char* id, bool is_final) {
    if (!automaton || !id) {
        return NEXUS_ERROR_INVALID_ARGUMENT;
    }
    
    // Check if state already exists
    if (find_state(automaton, id)) {
        return NEXUS_ERROR_INVALID_ARGUMENT;
    }
    
    // Allocate or resize states array
    automaton->states = (OkpalaState*)realloc(automaton->states, 
                                          (automaton->state_count + 1) * sizeof(OkpalaState));
    if (!automaton->states) {
        return NEXUS_ERROR_OUT_OF_MEMORY;
    }
    
    // Initialize the new state
    OkpalaState* state = &automaton->states[automaton->state_count++];
    state->id = strdup(id);
    state->is_final = is_final;
    state->transitions = NULL;
    state->input_symbols = NULL;
    state->transition_count = 0;
    
    // If this is the first state, make it the initial state
    if (automaton->state_count == 1) {
        automaton->initial_state = state;
    }
    
    // If this is a final state, add it to the final states array
    if (is_final) {
        automaton->final_states = (OkpalaState**)realloc(automaton->final_states, 
                                                     (automaton->final_state_count + 1) * sizeof(OkpalaState*));
        if (!automaton->final_states) {
            return NEXUS_ERROR_OUT_OF_MEMORY;
        }
        automaton->final_states[automaton->final_state_count++] = state;
    }
    
    return NEXUS_SUCCESS;
}

// Add a transition between states
NexusResult okpala_automaton_add_transition(OkpalaAutomaton* automaton, 
                                         const char* from_id, 
                                         const char* to_id, 
                                         const char* input_symbol) {
    if (!automaton || !from_id || !to_id || !input_symbol) {
        return NEXUS_ERROR_INVALID_ARGUMENT;
    }
    
    // Find the states
    OkpalaState* from_state = find_state(automaton, from_id);
    OkpalaState* to_state = find_state(automaton, to_id);
    
    if (!from_state || !to_state) {
        return NEXUS_ERROR_INVALID_ARGUMENT;
    }
    
    // Allocate or resize transitions arrays
    from_state->transitions = (OkpalaState**)realloc(from_state->transitions, 
                                                 (from_state->transition_count + 1) * sizeof(OkpalaState*));
    from_state->input_symbols = (char**)realloc(from_state->input_symbols, 
                                            (from_state->transition_count + 1) * sizeof(char*));
    
    if (!from_state->transitions || !from_state->input_symbols) {
        return NEXUS_ERROR_OUT_OF_MEMORY;
    }
    
    // Add the transition
    from_state->transitions[from_state->transition_count] = to_state;
    from_state->input_symbols[from_state->transition_count] = strdup(input_symbol);
    from_state->transition_count++;
    
    return NEXUS_SUCCESS;
}

// Free an automaton
void okpala_automaton_free(OkpalaAutomaton* automaton) {
    if (!automaton) return;
    
    for (size_t i = 0; i < automaton->state_count; i++) {
        OkpalaState* state = &automaton->states[i];
        free(state->id);
        
        for (size_t j = 0; j < state->transition_count; j++) {
            free(state->input_symbols[j]);
        }
        
        free(state->transitions);
        free(state->input_symbols);
    }
    
    free(automaton->states);
    free(automaton->final_states);
    free(automaton);
}
