/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
// Jpeg Quatizer
`include "jpeg_encoder.vh"
module quant #(
    parameter DW = 15,
    // Regular 1-D DCT adds +3 bits to coefficients, but 
    // AAN includes a factor of 3.923 on top of that, so +2 bits       
    parameter QW = DW - 4,
    parameter M_BITS = 13,         // Bit size of Multiplier coefficients
    parameter SENSOR_X_SIZE    = 1280,
    parameter SENSOR_Y_SIZE    = 720
)(
    input   logic signed[DW-1:0]    di[1:0], 
    input   logic                   di_valid,
    output  logic                   di_hold,
    input   logic [4:0]             di_cnt,
    output  logic signed[QW-1:0]    q[1:0],
    output  logic                   q_valid,
    input   logic                   q_hold,
    output  logic [4:0]             q_cnt,
    output  logic [1:0]             q_chroma, 
    output  logic                   q_last_mcu,

    input   logic[$clog2(SENSOR_X_SIZE)-1:0] x_size_m1,
    input   logic[$clog2(SENSOR_Y_SIZE)-1:0] y_size_m1,
    input   logic[2:0]              qf_select,          // select one of the 8 possible QF

    input   logic                   clk,
    input   logic                   resetn
);

always_comb assert (DW == 15) else $error();
always_comb assert (QW == 11) else $error();
always_comb assert (M_BITS == 13) else $error();


logic [2:0]         zigzag_mcu_cnt;     // 0..3 Y, 4..U, 5..V
always_comb di_hold = q_hold;

always @(posedge clk) 
if (!resetn)
    zigzag_mcu_cnt <= 0;
else if (di_valid & ~q_hold)
    if (&di_cnt)
        zigzag_mcu_cnt <= zigzag_mcu_cnt == 5 ? 0 : zigzag_mcu_cnt + 1;


// pipline inputs
logic signed[DW-1:0]    di0[1:0];
logic                   di0_valid;
logic [4:0]             di0_cnt;
logic [1:0]             di0_chroma;

always @(posedge clk) 
if (!resetn)
    di0_valid <= 0;
else if (!q_hold)
    di0_valid <= di_valid;

always @(posedge clk) 
if (di_valid & !q_hold) begin
    di0_chroma  <= zigzag_mcu_cnt[2] ? (zigzag_mcu_cnt[0] ? 2 : 1) : 0;
    di0_cnt     <= di_cnt;
    // ../../jpeg_encoder/jenc/quant.sv:69: error: the type of the variable 'di' doesn't match the context type.
    // ../../jpeg_encoder/jenc/quant.sv:69:      : variable type=netvector_t:logic signed[14:0]
    // ../../jpeg_encoder/jenc/quant.sv:69:      : context type=11netuarray_t
    //di0         <= di;
    di0[0]      <= di[0];
    di0[1]      <= di[1];
end

logic [M_BITS-1:0]  q_factor[1:0];
logic [5:0] q_ra;
// read the quantizer coefficients 2 at a time
always_comb q_ra = {zigzag_mcu_cnt[2], di_cnt};

quant_tables quant_tables (
    .re         (di_valid & ~q_hold),
    .ra         (q_ra),
    .rd         (q_factor),
    .*
);

logic signed[DW+M_BITS-1:0]    mult_out[1:0];
`ifdef QUANTIZER_USE_DSP_MULT
logic signed[M_BITS:0]         sq_factor[1:0]; //signed version to infer signed multiplication
`endif //QUANTIZER_USE_DSP_MULT

generate
for(genvar i=0; i<2; i++) begin : mult
always_comb q[i] = mult_out[i] >> (M_BITS-1);
`ifdef QUANTIZER_USE_DSP_MULT
// DSP MULT 18x18 option
always_comb sq_factor[i] = {1'b0, q_factor[i]};
always @(posedge clk) 
if(di0_valid & ~q_hold)
    mult_out[i] <= (di0[i] * sq_factor[i]) + (1 << (M_BITS-2)); // rounding bit
`else
quant_seq_mult_15x13_p4 mult (
    .a_in       (di0[i]),
    .b_in       (q_factor[i]),
    .out        (mult_out[i]),
    .in_valid   (di0_valid),
    .out_valid  ( ),
    .en         (~q_hold),
    .*
);
`endif //QUANTIZER_USE_DSP_MULT
end
endgenerate


//logic for finding the last block
parameter X_SIZE_D16 = (SENSOR_X_SIZE + 15) >> 4;
parameter Y_SIZE_D16 = (SENSOR_Y_SIZE + 15) >> 4;
logic[$clog2(X_SIZE_D16)-1:0] x_mcu;
logic[$clog2(Y_SIZE_D16)-1:0] y_mcu;

// pipline
logic                   last_mcu;
logic                   di0_last_mcu;

always_comb last_mcu = zigzag_mcu_cnt == 5 & x_mcu == (x_size_m1 >> 4) & y_mcu == (y_size_m1 >> 4);

always @(posedge clk) 
if (!resetn) begin
    x_mcu <= 0;
    y_mcu <= 0;
end else if (di_valid & ~q_hold) begin
    if (&di_cnt & zigzag_mcu_cnt == 5) begin
        if (x_mcu == (x_size_m1 >> 4)) begin
            x_mcu <= 0;
            if (y_mcu == (y_size_m1 >> 4))
                y_mcu <= 0;
            else
                y_mcu <= y_mcu + 1;
        end else
            x_mcu <= x_mcu + 1;
    end
end

always @(posedge clk) 
if (di_valid & !q_hold)
    di0_last_mcu  <= last_mcu;

`ifdef QUANTIZER_USE_DSP_MULT
always @(posedge clk) 
if (!resetn) q_valid <= 0;
else if(~q_hold) q_valid <= di0_valid;

always @(posedge clk) 
if(di0_valid & ~q_hold) begin
    q_last_mcu <= di0_last_mcu;
    q_chroma <= di0_chroma;
    q_cnt <= di0_cnt;
end
`else
// Hijack multiplier for pipelining for now :)
quant_seq_mult_15x13_p4 cnt_pipe (
    .a_in       ({di0_last_mcu, di0_chroma, di0_cnt}),
    .b_in       (1),
    .out        ({q_last_mcu, q_chroma, q_cnt}),
    .in_valid   (di0_valid),
    .out_valid  (q_valid),
    .en         (~q_hold),
    .*
);
`endif //QUANTIZER_USE_DSP_MULT

endmodule
