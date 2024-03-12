`timescale 1ns/1ps


module POLY_FIOS #(
    WORD_WIDTH  = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N           =  5, // Number of coefficients in an AMNS polynomial
    LAMBDA      =  2, // External reduction parameter used in AMNS multiplications (E = x^N-LAMBDA)
    S           =  4  // Number of blocks of width WORD_WIDTH required to hold a coefficient
) (

    input clock_i,
    reset_i,

    input start_i,

    input [N*S*WORD_WIDTH-1:0] A_din_i,
    input [N*WORD_WIDTH-1:0] B_din_i,
    input [N*WORD_WIDTH-1:0] M_din_i,
    input [N*WORD_WIDTH-1:0] M_prime_0_din_i,

    output mem_B_reg_shift_o,
    output mem_M_reg_shift_o,

    output done_o

);

    wire [S-1:0] start;

    wire [N*S*WORD_WIDTH-1:0] A_reg_din_0;
    wire [N*S*(WORD_WIDTH+1)-1:0] A_reg_din_1;
    wire [N*S*WORD_WIDTH-1:0] B_reg_din_0;
    wire [N*S*(WORD_WIDTH+1)-1:0] B_reg_din_1;
    wire [N*S*WORD_WIDTH-1:0] M_reg_din_0;
    wire [N*S*(WORD_WIDTH+1)-1:0] M_reg_din_1;
    wire [N*S*WORD_WIDTH-1:0] M_prime_0_reg_din_0;
    wire [N*S*WORD_WIDTH-1:0] M_prime_0_reg_din_1;
    wire [N*S*WORD_WIDTH-1:0] q_din;
    wire [N*S*WORD_WIDTH-1:0] q_reg_din_0;
    wire [N*S*WORD_WIDTH-1:0] q_reg_din_1;
    wire [N*S*(WORD_WIDTH+1)-1:0] CREG_din_0;


    wire [N*S*(WORD_WIDTH+1)-1:0] A_reg_dout;
    wire [N*S*(WORD_WIDTH+1)-1:0] B_reg_dout;
    wire [N*S*(WORD_WIDTH+1)-1:0] M_reg_dout;
    wire [N*S*WORD_WIDTH-1:0] M_prime_0_reg_dout;
    wire [N*S*WORD_WIDTH-1:0] q_reg_dout;

    wire [N*S*(WORD_WIDTH+1)-1:0] RES_dout;

    wire [N*S-1:0] mem_B_reg_shift;
    wire [N*S-1:0] mem_M_reg_shift;

    wire [N*S-1:0] B_delay_line_en;
    wire [N*S-1:0] M_delay_line_en;

    reg [N*S-1:0] PE_done;

    generate
        genvar j;
        for (j = 0; j < S; j++) begin

            if (j == 0)

                assign start[0] = start_i;

            else begin
            
                delay_line #(.WIDTH(1), .DELAY(4*N+2)) start_delay_line_inst (
                    .clock_i(clock_i),
                    .reset_i(reset_i),
                    .en_i(1),

                    .a_i(start[j-1]),
                    .s_o(start[j])
                );
            
            end

            genvar i;
            for (i = 0; i < N; i++) begin

                if (j == 0) begin


                    assign A_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = A_din_i[(i+j*N)*WORD_WIDTH+:WORD_WIDTH];
                    assign A_reg_din_1[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1] = A_reg_dout[((N+i-1)%N)*(WORD_WIDTH+1)+:WORD_WIDTH+1];
                    assign B_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = B_din_i[(i+j*N)*WORD_WIDTH+:WORD_WIDTH];
                    assign B_reg_din_1[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1] = B_reg_dout[((i+1)%N)*(WORD_WIDTH+1)+:WORD_WIDTH+1];
                    assign M_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = M_din_i[(i+j*N)*WORD_WIDTH+:WORD_WIDTH];
                    assign M_reg_din_1[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1] = M_reg_dout[((N+i-1)%N)*(WORD_WIDTH+1)+:WORD_WIDTH+1];           
                    assign M_prime_0_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = M_prime_0_din_i[(i+j*N)*WORD_WIDTH+:WORD_WIDTH];
                    assign M_prime_0_reg_din_1[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = M_prime_0_reg_dout[((N+i-1)%N)*WORD_WIDTH+:WORD_WIDTH];
                    assign q_din[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = RES_dout[(((i%2)*N+i)/2)*(WORD_WIDTH+1)+:(WORD_WIDTH+1)];
                    assign q_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = RES_dout[(((((i+1)%N)%2)*N+((i+1)%N))/2)*(WORD_WIDTH+1)+:WORD_WIDTH+1];
                    assign q_reg_din_1[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = q_reg_dout[((i+1)%N)*WORD_WIDTH+:WORD_WIDTH];
                    assign CREG_din_0[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1] = 0;

                end else begin

                    assign A_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = A_din_i[(i+j*N)*WORD_WIDTH+:WORD_WIDTH];
                    assign A_reg_din_1[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1] = A_reg_dout[((N+i-1)%N+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1];
                    //assign B_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = B_reg_dout[(i+(j-1)*N+j*N)*WORD_WIDTH+:WORD_WIDTH];
                    assign B_reg_din_1[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1] = B_reg_dout[((i+1)%N+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1];
                    //assign M_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = M_reg_dout[(i+(j-1)*N+j*N)*WORD_WIDTH+:WORD_WIDTH];
                    assign M_reg_din_1[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1] = M_reg_dout[((N+i-1)%N+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1];           
                    assign M_prime_0_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = M_prime_0_reg_dout[(i+(j-1)*N)*WORD_WIDTH+:WORD_WIDTH];
                    assign M_prime_0_reg_din_1[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = M_prime_0_reg_dout[((N+i-1)%N+j*N)*WORD_WIDTH+:WORD_WIDTH];
                    assign q_din[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = RES_dout[(((i%2)*N+i)/2+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1];
                    assign q_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = RES_dout[(((((i+1)%N)%2)*N+((i+1)%N))/2+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1];
                    assign q_reg_din_1[(i+j*N)*WORD_WIDTH+:WORD_WIDTH] = q_reg_dout[((i+1)%N+j*N)*WORD_WIDTH+:WORD_WIDTH];
                    assign CREG_din_0[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1] = RES_dout[(i+(j-1)*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1];

                    delay_line #(.WIDTH(WORD_WIDTH+1), .DELAY(2)) B_delay_line_inst (
                        .clock_i(clock_i),
                        .reset_i(reset_i),
                        .en_i(B_delay_line_en[(i+(j-1)*N)]),

                        .a_i(B_reg_dout[(i+(j-1)*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1]),
                        .s_o(B_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH])
                    );

                    delay_line #(.WIDTH(WORD_WIDTH+1), .DELAY(2)) M_delay_line_inst (
                        .clock_i(clock_i),
                        .reset_i(reset_i),
                        .en_i(M_delay_line_en[(i+(j-1)*N)]),

                        .a_i(M_reg_dout[(i+(j-1)*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1]),
                        .s_o(M_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH])
                    );

                end

                

                PE #(
                    .WORD_WIDTH(WORD_WIDTH),
                    .N(N),
                    .LAMBDA(LAMBDA),
                    .S(S),
                    .COLUMN_INDEX(i),
                    .LINE_INDEX(j)
                ) PE_inst (

                    .clock_i(clock_i),
                    .reset_i(reset_i),

                    .start_i(start[j]),

                    .A_reg_din_0_i(A_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH]),
                    .A_reg_din_1_i(A_reg_din_1[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1]),
                    .B_reg_din_0_i(B_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH]),
                    .B_reg_din_1_i(B_reg_din_1[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1]),
                    .M_reg_din_0_i(M_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH]),
                    .M_reg_din_1_i(M_reg_din_1[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1]),
                    .M_prime_0_reg_din_0_i(M_prime_0_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH]),
                    .M_prime_0_reg_din_1_i(M_prime_0_reg_din_1[(i+j*N)*WORD_WIDTH+:WORD_WIDTH]),
                    .q_din_i(q_din[(i+j*N)*WORD_WIDTH+:WORD_WIDTH]),
                    .q_reg_din_0_i(q_reg_din_0[(i+j*N)*WORD_WIDTH+:WORD_WIDTH]),
                    .q_reg_din_1_i(q_reg_din_1[(i+j*N)*WORD_WIDTH+:WORD_WIDTH]),
                    .CREG_din_0_i(CREG_din_0[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1]),

                    .A_reg_dout_o(A_reg_dout[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1]),
                    .B_reg_dout_o(B_reg_dout[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1]),
                    .M_reg_dout_o(M_reg_dout[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1]),
                    .M_prime_0_reg_dout_o(M_prime_0_reg_dout[(i+j*N)*WORD_WIDTH+:WORD_WIDTH]),
                    .q_reg_dout_o(q_reg_dout[(i+j*N)*WORD_WIDTH+:WORD_WIDTH]),

                    .RES_dout_o(RES_dout[(i+j*N)*(WORD_WIDTH+1)+:WORD_WIDTH+1]),

                    .mem_B_reg_shift_o(mem_B_reg_shift[(i+j*N)]),
                    .mem_M_reg_shift_o(mem_M_reg_shift[(i+j*N)]),

                    .B_delay_line_en_o(B_delay_line_en[(i+j*N)]),
                    .M_delay_line_en_o(M_delay_line_en[(i+j*N)]),


                    .done_o(PE_done[(i+j*N)])

                );
            end
        end
    endgenerate

    assign mem_B_reg_shift_o = mem_B_reg_shift[0];
    assign mem_M_reg_shift_o = mem_M_reg_shift[0];
    assign done_o = PE_done[0];

endmodule
