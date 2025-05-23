/*
 * JPEG Encoder Engine top level
 *
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
module jenc #(
    parameter DW = 8,
    parameter QW = 11,
    parameter CW = QW + 4,
    parameter SENSOR_X_SIZE    = 1280,
    parameter SENSOR_Y_SIZE    = 720
)(
    input   logic signed[DW-1:0]    di[7:0], 
    input   logic                   di_valid,
    output  logic                   di_hold,
    input   logic [2:0]             di_cnt,

    output  logic [31:0]            out_data,
    output  logic                   out_tlast,
    output  logic                   out_valid,
    input   logic                   out_hold,

    input   logic[2:0]              qf_select,          // select one of the 8 possible QF

    input   logic[$clog2(SENSOR_X_SIZE)-1:0] x_size_m1,
    input   logic[$clog2(SENSOR_Y_SIZE)-1:0] y_size_m1,

    input   logic                   clk,
    input   logic                   resetn,
    input   logic                   clk_x22,
    input   logic                   resetn_x22
);

always_comb if (di_valid) assert (x_size_m1[0]) else $fatal(1, "Enforcing even image dimensions!");
always_comb if (di_valid) assert (y_size_m1[0]) else $fatal(1, "Enforcing even image dimensions!");

logic signed[CW-1:0]    d[1:0];
logic                   d_valid;
logic                   d_hold;
logic [4:0]             d_cnt;

logic signed[10:0]      q[1:0]; 
logic                   q_valid;
logic                   q_hold;
logic [4:0]             q_cnt;
logic [1:0]             q_chroma;
logic                   q_last_mcu;

//packed code+coeff
logic [5:0]             codecoeff_length;
logic [51:0]            codecoeff;
logic                   codecoeff_tlast;
logic                   codecoeff_valid;
logic                   codecoeff_hold;

logic [63:0]            b_data;
logic [3:0]             b_bytes;
logic                   b_tlast;
logic                   b_valid;
logic                   b_hold;

dct_2d dct_2d (
    .q              (d),
    .q_valid        (d_valid),
    .q_hold         (d_hold & d_valid),
    .q_cnt          (d_cnt),
    .*
);
quant #(.SENSOR_X_SIZE(SENSOR_X_SIZE), .SENSOR_Y_SIZE(SENSOR_Y_SIZE)) quant(
    .di             (d),
    .di_valid       (d_valid),
    .di_hold        (d_hold),
    .di_cnt         (d_cnt),
    
    .q_hold         (q_hold & q_valid),
    .*
);
entropy entropy(
    .out_codecoeff_length   (codecoeff_length),
    .out_codecoeff          (codecoeff),
    .out_tlast              (codecoeff_tlast),
    .out_valid              (codecoeff_valid),
    .out_hold               (codecoeff_hold & codecoeff_valid),
    .*
);

byte_pack byte_pack(
    .out_hold               (out_hold & out_valid),
    .*
);

endmodule
