`timescale 1ns / 1ps


module POLY_memory #(
    WORD_WIDTH = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N          =  5, // Number of coefficients in an AMNS polynomial
    LAMBDA     =  2, // External reduction parameter used in AMNS multiplications (E = x^N-LAMBDA)
    S          =  4, // Number of blocks of width WORD_WIDTH required to hold a coefficient
) (

    input  clock_i,
           reset_i,       // Global reset signal (rising-edge)
    input  load_start_i,  // Triggers loading A, B, M, M_prime operands from BRAM into internal registers
    input  store_start_i, // Triggers storing result from RES_reg internal register to BRAM

    input  [WORD_WIDTH-1:0] BRAM_dout_i, //BRAM output data

    input  A_reg_rot_i,      // Triggers rotation of A_reg data 
    input  B_reg_shift_i,    // Triggers WORD_WIDTH bits shift of B_reg data
    input  M_reg_rot_i,      // Triggers WORD_WIDTH bits rotation of A_reg data
    input  M_p_0_reg_rot_i,  // Triggers WORD_WIDTH bits rotation of A_reg data

    input  RES_reg_en_i,

    input  [N*WORD_WIDTH-1:0] RES_reg_din_i,

    output [WORD_WIDTH-1:0] BRAM_din_o,

    output        BRAM_we_o,
    output [31:0] BRAM_addr_o,
    output        BRAM_en_o,

    output load_done_o,
    output store_done_o

);

    // BRAM output is registered for performance
    reg [WORD_WIDTH-1:0] BRAM_dout_reg;
    always @(posedge clock_i) BRAM_dout_reg <= BRAM_dout_i; 

    wire [WORD_WIDTH-1:0] RES;

    
    reg M_prime_0_reg_en;
    reg [N*WORD_WIDTH-1:0] M_prime_0_reg;
    wire M_prime_0_rot;

    
    reg M_reg_en;
    reg [N*s*WORD_WIDTH-1:0] M_reg;
    wire M_shift;

    wire A_reg_en;
    reg  [N*s*WORD_WIDTH-1:0] A_reg;
    wire A_rot[0:s-1];

    reg B_reg_en;
    reg [N*s*WORD_WIDTH-1:0] B_reg;
    wire B_shift;

    
       
    reg [N*WORD_WIDTH-1:0] B_input;

    always_comb begin
        for (int j = 0; j < N; j++) begin
            B_input[j*WORD_WIDTH+:WORD_WIDTH] = B_reg[s*j*WORD_WIDTH+:WORD_WIDTH];
        end
    end

    reg [s*WORD_WIDTH-1:0] A_input;

    always_comb begin
        for (int j = 0; j < s; j++) begin
            A_input[j*WORD_WIDTH+:WORD_WIDTH] = A_reg[N*j*WORD_WIDTH+:WORD_WIDTH];
        end
    end

    assign BRAM_addr_o = {{(32 - $clog2(4 * N * s)) {1'b0}}, BRAM_addr};

    assign BRAM_din_o  = RES_reg[16:0];

endmodule
