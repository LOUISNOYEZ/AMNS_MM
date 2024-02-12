`timescale 1ns/1ps


module POLY_reg_bank #(
    WORD_WIDTH  = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N           =  5, // Number of coefficients in an AMNS polynomial
    S           =  4  // Number of blocks of width WORD_WIDTH required to hold a coefficient
) (

    input  clock_i,
           reset_i, // Global reset signal (rising-edge)

    // Multiplexer select signal of BRAM data to input data registers
    // Values 0, 1, 2, 3 select registers A, B, M, M_prime_0
    input  [1:0] INPUT_reg_sel_i,
    input  INPUT_reg_en_i,

    // Data registers write enable signals
    // Trigger loading of WORD_WIDTH data bits in register and shift of currently available data
    input  load_RES_reg_en_i,
    input  store_RES_reg_en_i,

    input  [S-1:0] A_reg_coeff_rot_i, // Assertion of bit i triggers WORD_WIDTH bits rotation of coefficient i of A_reg data
    input  B_reg_shift_i,             // Triggers WORD_WIDTH bits shift of B_reg data
    input  M_reg_shift_i,             // Triggers WORD_WIDTH bits shift of A_reg data
    input  M_prime_0_rot_i,           // Triggers rotation of one coefficient (of width WORD_WIDTH) of M_prime_0_reg data

    input  [WORD_WIDTH-1:0] INPUT_reg_din_i, // Input data signals for polynomial registers A, B, M, M_prime_0
    input  [N*WORD_WIDTH-1:0] RES_reg_din_i,   // Input data signal for polynomial result register

    output reg [S*WORD_WIDTH-1:0] A_reg_dout_o,
    output reg [N*WORD_WIDTH-1:0] B_reg_dout_o,
    output [WORD_WIDTH-1:0] M_reg_dout_o,
    output [WORD_WIDTH-1:0] M_prime_0_reg_dout_o,

    output [WORD_WIDTH-1:0] RES_reg_dout_o

);

    // INPUT data register enable signals multiplexer
    reg [3:0] INPUT_reg_en;

    always_comb begin
        case (INPUT_reg_sel_i)
            2'b00 : begin INPUT_reg_en[0] = INPUT_reg_en_i; INPUT_reg_en[3:1] = 0; end
            2'b01 : begin INPUT_reg_en[1] = INPUT_reg_en_i; INPUT_reg_en[3:2] = 0; INPUT_reg_en[0]   = 0; end
            2'b10 : begin INPUT_reg_en[2] = INPUT_reg_en_i; INPUT_reg_en[3] = 0;   INPUT_reg_en[1:0] = 0; end
            2'b11 : begin INPUT_reg_en[3] = INPUT_reg_en_i; INPUT_reg_en[2:0] = 0; end
            default : INPUT_reg_en = 0;
        endcase
    end


    // A_reg data register
    reg [N*S*WORD_WIDTH-1:0] A_reg;

    genvar j;
    generate
        for (j = 0; j < S; j++) begin

            always @(posedge clock_i) begin

                if (reset_i) A_reg[N*(j+1)*WORD_WIDTH-1:N*j*WORD_WIDTH] <= 0;
                else if (INPUT_reg_en[0])
                    A_reg[N*(j+1)*WORD_WIDTH-1:N*j*WORD_WIDTH] <= {
                        (j == S-1) ? INPUT_reg_din_i : A_reg[(N*(j+1)+1)*WORD_WIDTH:N*(j+1)*WORD_WIDTH],
                        A_reg[N*(j+1)*WORD_WIDTH-1:(N*j+1)*WORD_WIDTH]
                    };
                else if (A_reg_coeff_rot_i[j])
                    A_reg[N*(j+1)*WORD_WIDTH-1:N*j*WORD_WIDTH] <= {
                        A_reg[(N*j+1)*WORD_WIDTH-1:N*j*WORD_WIDTH],
                        A_reg[N*(j+1)*WORD_WIDTH-1:(N*j+1)*WORD_WIDTH]
                    };
                else
                    A_reg[N*(j+1)*WORD_WIDTH-1:N*j*WORD_WIDTH] <= A_reg[N*(j+1)*WORD_WIDTH-1:N*j*WORD_WIDTH];

            end

        end
    endgenerate

    always_comb begin
        for (int j = 0; j < S; j++)
            A_reg_dout_o[j*WORD_WIDTH+:WORD_WIDTH] = A_reg[N*j*WORD_WIDTH+:WORD_WIDTH];
    end 


    // B_reg data register
    reg [N*S*WORD_WIDTH-1:0] B_reg;

    always @(posedge clock_i) begin

        if (reset_i) B_reg <= 0;
        else if (INPUT_reg_en[1] || B_reg_shift_i) B_reg <= {INPUT_reg_din_i, B_reg[N*S*WORD_WIDTH-1:WORD_WIDTH]};
        else B_reg <= B_reg;

    end

    always_comb begin
        for (int i = 0; i < N; i++)
            B_reg_dout_o[i*WORD_WIDTH+:WORD_WIDTH] = B_reg[i*S*WORD_WIDTH+:WORD_WIDTH];
    end


    // M_reg data register
    reg [N*S*WORD_WIDTH-1:0] M_reg;

    always @(posedge clock_i) begin

        if (reset_i) M_reg <= 0;
        else if (INPUT_reg_en[2] || M_reg_shift_i) M_reg <= {INPUT_reg_din_i, M_reg[N*S*WORD_WIDTH-1:WORD_WIDTH]};
        else M_reg <= M_reg;
    end

    assign M_reg_dout_o = M_reg[WORD_WIDTH-1:0];


    // M_prime_0_reg data register
    reg [N*WORD_WIDTH-1:0] M_prime_0_reg;

    always @(posedge clock_i) begin

        if (reset_i) M_prime_0_reg <= 0;
        else if (INPUT_reg_en[3])
            M_prime_0_reg <= {INPUT_reg_din_i, M_prime_0_reg[N*WORD_WIDTH-1:WORD_WIDTH]};
        else if (M_prime_0_rot_i)
            M_prime_0_reg <= {
                M_prime_0_reg[WORD_WIDTH-1:0], M_prime_0_reg[N*WORD_WIDTH-1:WORD_WIDTH]
            };
        else M_prime_0_reg <= M_prime_0_reg;

    end

    assign M_prime_0_reg_dout_o = M_prime_0_reg[WORD_WIDTH-1:0];


    // RES_reg data register
    reg [N*S*WORD_WIDTH-1:0] RES_reg;

    genvar i;
    generate
        for (i = 0; i < N; i++) begin
            always_ff @(posedge clock_i) begin

                if (reset_i) RES_reg[(i+1)*S*WORD_WIDTH-1:i*S*WORD_WIDTH] <= 0;
                else if (load_RES_reg_en_i) begin
                    RES_reg[(i+1)*S*WORD_WIDTH-1:i*S*WORD_WIDTH] <= {
                        RES_reg_din_i[(i+1)*WORD_WIDTH-1:i*WORD_WIDTH],
                        RES_reg[(i+1)*S*WORD_WIDTH-1:(i*S+1)*WORD_WIDTH]
                    };
                end
                else if (store_RES_reg_en_i) begin
                    RES_reg[(i+1)*S*WORD_WIDTH-1:i*S*WORD_WIDTH] <= {
                        (i == N-1) ? WORD_WIDTH'(0) : RES_reg[((i+1)*S+1)*WORD_WIDTH-1:(i+1)*S*WORD_WIDTH],
                        RES_reg[(i+1)*S*WORD_WIDTH-1:(i*S+1)*WORD_WIDTH]
                    };
                end
                else RES_reg <= RES_reg;

            end
        end
    endgenerate

    assign RES_reg_dout_o = RES_reg[WORD_WIDTH-1:0];

endmodule
