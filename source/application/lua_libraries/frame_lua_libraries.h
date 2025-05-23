/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Raj Nakarja / Brilliant Labs Ltd. (raj@brilliant.xyz)
 *              Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Uma S. Gupta / Techno Exponent (umasankar@technoexponent.com)
 *
 * ISC Licence
 *
 * Copyright © 2023 Brilliant Labs Ltd.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */

#pragma once

#include <stdbool.h>
#include "lua.h"

extern lua_State *L_global;

void lua_bluetooth_data_interrupt(uint8_t *data, size_t length);

void lua_open_bluetooth_library(lua_State *L);
void lua_open_camera_library(lua_State *L);
void lua_open_compression_library(lua_State *L);
void lua_open_display_library(lua_State *L);
void lua_open_imu_library(lua_State *L);
void lua_open_led_library(lua_State *L);
void lua_open_microphone_library(lua_State *L);
void lua_open_system_library(lua_State *L);
void lua_open_time_library(lua_State *L);
void lua_open_version_library(lua_State *L);

void lua_open_file_library(lua_State *L, bool reformat);
void lua_close_file_library(void);
