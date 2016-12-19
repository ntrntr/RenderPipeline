/**
 *
 * RenderPipeline
 *
 * Copyright (c) 2014-2016 tobspr <tobias.springer1@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#version 430

// Processes all commands coming from the GPU, like adding lights, removing lights,
// and so on ..

#pragma include "render_pipeline_base.inc.glsl"
#pragma include "includes/source_data.struct.glsl"
#pragma include "includes/light_data.struct.glsl"

uniform samplerBuffer CommandQueue;
uniform writeonly imageBuffer RESTRICT AllLightsData;
uniform writeonly imageBuffer RESTRICT ShadowSourceData;
uniform int commandCount;

// Reads a single float from the data stack
float read_float(inout int stack_ptr) {
    return texelFetch(CommandQueue, stack_ptr++).x;
}

// Reads a single int from the data stack
int read_int(inout int stack_ptr) {
    return gpu_cq_unpack_int_from_float(read_float(stack_ptr));
}

// Reads a 4-component vector from the data stack
vec4 read_vec4(inout int stack_ptr) {
    stack_ptr += 4;
    return vec4(
            texelFetch(CommandQueue, stack_ptr - 4).x,
            texelFetch(CommandQueue, stack_ptr - 3).x,
            texelFetch(CommandQueue, stack_ptr - 2).x,
            texelFetch(CommandQueue, stack_ptr - 1).x
        );
}

void main() {

    // Store a pointer to the current stack index, its passed as a handle to all
    // read functions
    int stack_ptr = 0;

    // Process each command
    for (int command_index = 0; command_index < commandCount; ++command_index) {

        stack_ptr = command_index * 32;
        int command_type = read_int(stack_ptr);

        switch(command_type) {

            // Invalid Command Code
            case CMD_invalid: break;


            // Store Light
            case CMD_store_light: {

                // Read the destination slot of the light
                int slot = read_int(stack_ptr);
                int offs = slot * LIGHT_STRIDE;

                // Copy the data over
                for (int i = 0; i < LIGHT_STRIDE; ++i) {
                    imageStore(AllLightsData, offs + i, read_vec4(stack_ptr));
                }
                break;
            }

            // Remove Light
            case CMD_remove_light: {

                // Read the lights slot position
                int slot = read_int(stack_ptr);
                int offs = slot * LIGHT_STRIDE;

                // Set the data to all zeroes, this indicates a null light
                for (int i = 0; i < LIGHT_STRIDE; ++i) {
                    imageStore(AllLightsData, offs + i, vec4(0));
                }
                break;
            }

            // Store Source
            case CMD_store_source: {

                int slot = read_int(stack_ptr);
                int offs = slot * SHADOW_SOURCE_STRIDE;

                // Copy the data to the light data buffer
                for (int i = 0; i < SHADOW_SOURCE_STRIDE; ++i) {
                    imageStore(ShadowSourceData, offs + i, read_vec4(stack_ptr));
                }

                break;
            }

            // Remove consecutive sources
            case CMD_remove_sources: {
                int base_slot = read_int(stack_ptr);
                int num_slots = read_int(stack_ptr);

                for (int slot = base_slot; slot < base_slot + num_slots; ++slot) {
                    int offs = slot * SHADOW_SOURCE_STRIDE;

                    // Set the data to all zeroes, this indicates an unused source
                    for (int i = 0; i < SHADOW_SOURCE_STRIDE; ++i) {
                        imageStore(ShadowSourceData, offs + i, vec4(0));
                    }
                }
                break;
            }


            // ... further commands will follow here

        }
    }
}
