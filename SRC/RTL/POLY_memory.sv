`timescale 1ns / 1ps


module POLY_memory #(
    WORD_WIDTH = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N          =  5, // Number of coefficients in an AMNS polynomial
    S          =  4  // Number of blocks of width WORD_WIDTH required to hold a coefficient
) (

    input  clock_i,
           reset_i,       // Global reset signal (rising-edge)

    input  load_start_i,  // Triggers loading A, B, M, M_prime operands from BRAM into internal registers
    input  store_start_i, // Triggers storing result from RES_reg internal register to BRAM

    input  [WORD_WIDTH-1:0] BRAM_dout_i, //BRAM output data

    input  load_RES_reg_en_i,

    input  [S-1:0] A_reg_coeff_rot_i,
    input  B_reg_shift_i,
    input  M_reg_shift_i,
    input  M_prime_0_reg_rot_i,

    input  [N*WORD_WIDTH-1:0] RES_reg_din_i,


    output BRAM_we_o,
    output [$clog2(4*N*S+N):0] BRAM_addr_o,
    output BRAM_en_o,

    output [WORD_WIDTH-1:0] BRAM_din_o,

    output [S*WORD_WIDTH-1:0] A_reg_dout_o,
    output [N*WORD_WIDTH-1:0] B_reg_dout_o,
    output [WORD_WIDTH-1:0]   M_reg_dout_o,
    output [WORD_WIDTH-1:0]   M_prime_0_reg_dout_o,
    
    output load_done_o,
    output store_done_o

);

    // BRAM output is registered for performance
    reg [WORD_WIDTH-1:0] BRAM_dout_reg;
    always @(posedge clock_i) BRAM_dout_reg <= BRAM_dout_i;

    wire [1:0] INPUT_reg_sel;
    wire INPUT_reg_en;

    wire store_RES_reg_en;

    POLY_memory_control #(
        .WORD_WIDTH(WORD_WIDTH),
        .N(N),
        .S(S)
    ) POLY_memory_control_inst (

    .clock_i(clock_i),
    .reset_i(reset_i),

    .load_start_i(load_start_i),
    .store_start_i(store_start_i),

    .BRAM_we_o(BRAM_we_o),
    .BRAM_addr_o(BRAM_addr_o),

    .INPUT_reg_sel_o(INPUT_reg_sel),
    .INPUT_reg_en_o(INPUT_reg_en),

    .store_RES_reg_en_o(store_RES_reg_en),

    .load_done_o(load_done_o),
    .store_done_o(store_done_o)

    );

    POLY_reg_bank #(
        .WORD_WIDTH(WORD_WIDTH),
        .N(N),
        .S(S)
    ) POLY_reg_bank_inst (

        .clock_i(clock_i),
        .reset_i(reset_i),

        .INPUT_reg_sel_i(INPUT_reg_sel),
        .INPUT_reg_en_i(INPUT_reg_en),

        .load_RES_reg_en_i(load_RES_reg_en_i),
        .store_RES_reg_en_i(store_RES_reg_en),

        .A_reg_coeff_rot_i(A_reg_coeff_rot_i),
        .B_reg_shift_i(B_reg_shift_i),
        .M_reg_shift_i(M_reg_shift_i),
        .M_prime_0_rot_i(M_prime_0_reg_rot_i),

        .INPUT_reg_din_i(BRAM_dout_reg),
        .RES_reg_din_i(RES_reg_din_i),

        .A_reg_dout_o(A_reg_dout_o),
        .B_reg_dout_o(B_reg_dout_o),
        .M_reg_dout_o(M_reg_dout_o),
        .M_prime_0_reg_dout_o(M_prime_0_reg_dout_o),

        .RES_reg_dout_o(BRAM_din_o)

    );


endmodule
