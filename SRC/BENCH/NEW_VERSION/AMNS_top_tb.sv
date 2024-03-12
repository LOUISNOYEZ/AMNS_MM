
`timescale 1ns/1ps


module AMNS_top_tb #(
    WORD_WIDTH  = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N           =  5, // Number of coefficients in an AMNS polynomial
    LAMBDA      =  2,
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

    reg [N*S*WORD_WIDTH-1:0] A_reg = 0;
    reg [N*S*WORD_WIDTH-1:0] B_reg = 0;
    reg [N*S*WORD_WIDTH-1:0] M_reg = 0;
    reg [N*WORD_WIDTH-1:0]   M_prime_0_reg = 0;

    reg mem_RES_reg_en = 0;
    reg [N*S*WORD_WIDTH-1:0] mem_RES_reg = 0;


    // DUT instance signals
    reg start = 0;
    reg [WORD_WIDTH-1:0] BRAM_dout = 0;
    
    wire BRAM_we;
    wire [$clog2(4*N*S+N):0] BRAM_addr;
    wire BRAM_en;

    wire [WORD_WIDTH-1:0] BRAM_din;

    wire done;

    // DUT instance
    AMNS_top #(
        .WORD_WIDTH(WORD_WIDTH),
        .N(N),
        .LAMBDA(LAMBDA),
        .S(S)
    ) AMNS_top_inst (

         .clock_i(clock),
         .reset_i(reset),

         .start_i(start),

         .BRAM_dout_i(BRAM_dout),

         .BRAM_we_o(BRAM_we),
         .BRAM_addr_o(BRAM_addr),
         .BRAM_en_o(BRAM_en),

         .BRAM_din_o(BRAM_din),
        
         .done_o(done)
    );

    always #HALF_PERIOD clock = ~clock;

    reg [4*N*S+N-1:0] BRAM_we_array = 0;
    reg [(4*N*S+N+1)*WORD_WIDTH-1:0] BRAM_memory = 0;
    
    always_comb begin
        BRAM_we_array = 0;
        BRAM_we_array[BRAM_addr] = BRAM_we;
    end;

    genvar k;
    generate
        for (k = 0; k < (4*N*S+N); k++) begin
            always_ff @(posedge clock) begin
                if (reset)
                    BRAM_memory[k*WORD_WIDTH+:WORD_WIDTH] <= 0;
                else if (BRAM_we_array[k])
                    BRAM_memory[k*WORD_WIDTH+:WORD_WIDTH] <= BRAM_din;
                else
                    BRAM_memory[k*WORD_WIDTH+:WORD_WIDTH] <= BRAM_memory[k*WORD_WIDTH+:WORD_WIDTH];
            end
        end
    endgenerate

    always @(posedge clock) BRAM_dout <= {(32-WORD_WIDTH)'(0), BRAM_memory[BRAM_addr*WORD_WIDTH+:WORD_WIDTH]};

    initial begin
        reset = 1;
        #PERIOD;
        reset = 0;
        start = 1;
        //p = 83756009378939035348083252403644042534373498136580614602674036470104573248853
        //N = 5, LAMBDA = 2, w = 17, E = x^5-2
        //a = 70405587669197115494747746875478317263665722255355710655107374591676985333117
        //b = 68834342706948182775742168311894767202332666342927212606947168484424531645637
        BRAM_memory[N*S*WORD_WIDTH-1:0] = 'hffff7fffbfffdffffffff29404facbca2c5d185ea6627a644f41465e197c9558346074680c55a2b80accc;
        BRAM_memory[2*N*S*WORD_WIDTH-1:N*S*WORD_WIDTH] = 'hffff7fffffff9ffff00007fdf053c5bb82f498206ef685a5a4409f57ca4e8952250710e163ca62d3cce09;
        BRAM_memory[3*N*S*WORD_WIDTH-1:2*N*S*WORD_WIDTH] = 'hffff800000001ffffffffb3a65c6ba828bcfa544af500689a3cf9516aa41f4f69b03646e7ba89041564bf;
        BRAM_memory[(3*N*S+N)*WORD_WIDTH-1:3*N*S*WORD_WIDTH] = 'h14a78f388dbc010c00b91;
        #(500*PERIOD);
    end
    
endmodule

