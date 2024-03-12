`timescale 1ns / 1ps


module POLY_FIOS_tb #(
    WORD_WIDTH  = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N           =  5, // Number of coefficients in an AMNS polynomial
    LAMBDA      =  2, // External reduction parameter used in AMNS multiplications (E = x^N-LAMBDA)
    S           =  4  // Number of blocks of width WORD_WIDTH required to hold a coefficient
) ();

    localparam realtime PERIOD = 10,
                        HALF_PERIOD = PERIOD/2;

    localparam NB_TESTS = 8;
    reg [$clog2(NB_TESTS):0] test_count = 0;
    reg [$clog2(NB_TESTS):0] successful_test_count = 0;
    reg test = 1;

    reg clock = 0;
    reg reset = 0;

    reg PE_start = 0;

    POLY_FIOS #(
        .WORD_WIDTH(WORD_WIDTH),
        .N(N),
        .LAMBDA(LAMBDA),
        .S(S)
    ) POLY_FIOS_inst (

        .clock_i(clock),
        .reset_i(reset),

        .PE_start_i(PE_start),

        .A_din_i(A_din),
        .B_din_i(B_din),
        .M_din_i(M_din),
        .M_prime_0_din_i(M_prime_0_din)

    );

    always #HALF_PERIOD clock = ~clock;


    initial begin
        reset = 1;
        #PERIOD;
        reset = 0;
        PE_start = 1;
        #(500*PERIOD);
    end

endmodule
