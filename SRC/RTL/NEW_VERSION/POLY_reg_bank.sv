`timescale 1ns / 1ps


module POLY_reg_bank #(
    WORD_WIDTH  = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N = 5,  // Number of coefficients in an AMNS polynomial
    S = 4  // Number of blocks of width WORD_WIDTH required to hold a coefficient
) (

    // INPUTS
    // CONTROL SIGNALS
    input clock_i,
    reset_i,  // Global reset signal (rising-edge)

    // Multiplexer select signal of BRAM data to INPUT data registers
    // Values 0, 1, 2, 3 select registers A, B, M, M_prime_0 respectively
    input [1:0] INPUT_reg_sel_i,
    input  INPUT_reg_en_i, // Triggers loading of WORD_WIDTH data bits in register and shift of currently available data   

    // Result register parallel load and serial store enable signals
    input load_RES_reg_en_i,
    input store_RES_reg_en_i,

    // B, M registers shift enable sigals, used to provide data to the first row of processing elements 
    input B_reg_shift_i,
    input M_reg_shift_i,

    // DATA SIGNALS
    input  [WORD_WIDTH-1:0] INPUT_reg_din_i, // Input data for polynomial registers A, B, M, M_prime_0
    input [N*WORD_WIDTH-1:0] RES_reg_din_i,  // Input data signal for polynomial result register

    // OUTPUTS
    // DATA SIGNALS
    output [N*S*WORD_WIDTH-1:0] A_reg_dout_o,
    output [  N*WORD_WIDTH-1:0] B_reg_dout_o,
    output [  N*WORD_WIDTH-1:0] M_reg_dout_o,
    output [  N*WORD_WIDTH-1:0] M_prime_0_reg_dout_o,

    output [WORD_WIDTH-1:0] RES_reg_dout_o

);

    // INPUT data register enable signals multiplexer
    reg [3:0] INPUT_reg_en;

    always_comb begin
        case (INPUT_reg_sel_i)
            2'b00: begin
                INPUT_reg_en[0]   = INPUT_reg_en_i;
                INPUT_reg_en[3:1] = 0;
            end
            2'b01: begin
                INPUT_reg_en[1]   = INPUT_reg_en_i;
                INPUT_reg_en[3:2] = 0;
                INPUT_reg_en[0]   = 0;
            end
            2'b10: begin
                INPUT_reg_en[2]   = INPUT_reg_en_i;
                INPUT_reg_en[3]   = 0;
                INPUT_reg_en[1:0] = 0;
            end
            2'b11: begin
                INPUT_reg_en[3]   = INPUT_reg_en_i;
                INPUT_reg_en[2:0] = 0;
            end
            default: INPUT_reg_en = 0;
        endcase
    end


    // A_reg data register
    reg [N*S*WORD_WIDTH-1:0] A_reg;

    always_ff @(posedge clock_i) begin
        if (reset_i) A_reg <= 0;
        else if (INPUT_reg_en[0]) begin
            A_reg <= {INPUT_reg_din_i, A_reg[N*S*WORD_WIDTH-1:WORD_WIDTH]};
        end else A_reg <= A_reg;
    end

    assign A_reg_dout_o = A_reg;

    // B_reg data register
    reg [N*S*WORD_WIDTH-1:0] B_reg;

    always_ff @(posedge clock_i) begin
        if (reset_i) B_reg <= 0;
        else if (INPUT_reg_en[1] || B_reg_shift_i)
            B_reg <= {INPUT_reg_din_i, B_reg[N*S*WORD_WIDTH-1:WORD_WIDTH]};
        else B_reg <= B_reg;
    end

    assign B_reg_dout_o = B_reg[N*WORD_WIDTH-1:0];

    // M_reg data register
    reg [N*S*WORD_WIDTH-1:0] M_reg;

    always_ff @(posedge clock_i) begin
        if (reset_i) M_reg <= 0;
        else if (INPUT_reg_en[2] || M_reg_shift_i)
            M_reg <= {INPUT_reg_din_i, M_reg[N*S*WORD_WIDTH-1:WORD_WIDTH]};
        else M_reg <= M_reg;
    end

    assign M_reg_dout_o = M_reg[N*WORD_WIDTH-1:0];

    // M_prime_0_reg data register
    reg [N*WORD_WIDTH-1:0] M_prime_0_reg;

    always @(posedge clock_i) begin
        if (reset_i) M_prime_0_reg <= 0;
        else if (INPUT_reg_en[3])
            M_prime_0_reg <= {INPUT_reg_din_i, M_prime_0_reg[N*WORD_WIDTH-1:WORD_WIDTH]};
        else M_prime_0_reg <= M_prime_0_reg;
    end

    assign M_prime_0_reg_dout_o = M_prime_0_reg;

    // RES_reg data register
    reg [N*S*WORD_WIDTH-1:0] RES_reg;

    generate
        genvar i;
        for (i = 0; i < N; i++) begin
            always_ff @(posedge clock_i) begin
                if (reset_i) RES_reg[i*S*WORD_WIDTH+:S*WORD_WIDTH] <= 0;
                else if (load_RES_reg_en_i) begin
                    RES_reg[i*S*WORD_WIDTH+:S*WORD_WIDTH] <= {
                        RES_reg_din_i[i*WORD_WIDTH+:WORD_WIDTH],
                        RES_reg[(i+1)*S*WORD_WIDTH-1:(i*S+1)*WORD_WIDTH]
                    };
                end else if (store_RES_reg_en_i) begin
                    if (i == N - 1)
                        RES_reg[i*S*WORD_WIDTH+:S*WORD_WIDTH] <= {
                            WORD_WIDTH'(0), RES_reg[(i+1)*S*WORD_WIDTH-1:(i*S+1)*WORD_WIDTH]
                        };
                    else
                        RES_reg[i*S*WORD_WIDTH+:S*WORD_WIDTH] <= {
                            RES_reg[((i+1)*S+1)*WORD_WIDTH-1:(i+1)*S*WORD_WIDTH],
                            RES_reg[(i+1)*S*WORD_WIDTH-1:(i*S+1)*WORD_WIDTH]
                        };
                end else RES_reg <= RES_reg;
            end
        end
    endgenerate

    assign RES_reg_dout_o = RES_reg[WORD_WIDTH-1:0];

endmodule
