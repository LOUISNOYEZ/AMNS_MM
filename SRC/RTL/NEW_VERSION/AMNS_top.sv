`timescale 1ns / 1ps


module AMNS_top #(
    WORD_WIDTH = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N          =  5, // Number of coefficients in an AMNS polynomial
    LAMBDA     =  2, // External reduction parameter used in AMNS multiplications (E = x^N-LAMBDA)
    S          =  4  // Number of blocks of width WORD_WIDTH required to hold a coefficient
) (

    input  clock_i,
           reset_i,       // Global reset signal (rising-edge)

    input  start_i,

    input  [WORD_WIDTH-1:0] BRAM_dout_i, //BRAM output data

    output BRAM_we_o,
    output [$clog2(4*N*S+N):0] BRAM_addr_o,
    output BRAM_en_o,

    output [WORD_WIDTH-1:0] BRAM_din_o,
    
    output done_o
);

    reg [N*S*WORD_WIDTH-1:0] FIOS_A_din;
    reg [N*WORD_WIDTH-1:0] FIOS_B_din;
    reg [N*WORD_WIDTH-1:0] FIOS_M_din;
    reg [N*WORD_WIDTH-1:0] FIOS_M_prime_0_din;

    POLY_memory #(
        .WORD_WIDTH(WORD_WIDTH),
        .N(N),
        .S(S)
    ) POLY_memory_inst (

        .clock_i(clock_i),
        .reset_i(reset_i),

        .load_start_i(load_start),
        .store_start_i(store_start),

        .BRAM_dout_i(BRAM_dout_i),

        .load_RES_reg_en_i(load_RES_reg_en),

        .B_reg_shift_i(mem_B_reg_shift),
        .M_reg_shift_i(mem_M_reg_shift),

        .RES_reg_din_i(RES_reg_din),


       .BRAM_we_o(BRAM_we_o),
       .BRAM_addr_o(BRAM_addr_o),
       .BRAM_en_o(BRAM_en_o),

       .BRAM_din_o(BRAM_din_o),

       .A_reg_dout_o(FIOS_A_din),
       .B_reg_dout_o(FIOS_B_din),
       .M_reg_dout_o(FIOS_M_din),
       .M_prime_0_reg_dout_o(FIOS_M_prime_0_din),
        
       .load_done_o(load_done),
       .store_done_o(store_done)

    );

    AMNS_top_control AMNS_top_control_inst
    (

        .clock_i(clock_i),
        .reset_i(reset_i),

        .start_i(start_i),

        .load_done_i(load_done),
        .store_done_i(store_done),

        .FIOS_done_i(FIOS_done),

        .load_start_o(load_start),
        .store_start_o(store_start),

        .FIOS_start_o(FIOS_start),

        .done_o(done_o)
    );

    POLY_FIOS #(
        .WORD_WIDTH(WORD_WIDTH),
        .N(N),
        .LAMBDA(LAMBDA),
        .S(S)
    ) POLY_FIOS_inst (

        .clock_i(clock_i),
        .reset_i(reset_i),

        .start_i(FIOS_start),

        .A_din_i(FIOS_A_din),
        .B_din_i(FIOS_B_din),
        .M_din_i(FIOS_M_din),
        .M_prime_0_din_i(FIOS_M_prime_0_din),

        .mem_B_reg_shift_o(mem_B_reg_shift),
        .mem_M_reg_shift_o(mem_M_reg_shift),

        .done_o(FIOS_done_o)

    );

endmodule
