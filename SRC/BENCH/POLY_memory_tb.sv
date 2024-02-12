`timescale 1ns/1ps


module POLY_memory_tb #(
    WORD_WIDTH  = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N           =  5, // Number of coefficients in an AMNS polynomial
    S           =  4  // Number of blocks of width WORD_WIDTH required to hold a coefficient
) ();

    localparam realtime PERIOD = 10,
                        HALF_PERIOD = PERIOD/2;
    
    localparam NB_TESTS = 2;
    reg [$clog2(NB_TESTS):0] test_count = 0;
    reg [$clog2(NB_TESTS):0] successful_test_count = 0;
    reg test = 1;

    reg clock = 0;
    reg reset = 0;
    
    always #HALF_PERIOD clock = ~clock;

    localparam ADDR_LEN = $clog2(4*N*S+N)+1;


    reg load_start = 0;
    reg store_start = 0;

    reg [31:0] BRAM_dout;

    reg load_RES_reg_en = 0;

    reg [S-1:0] A_reg_coeff_rot = 0;
    reg B_reg_shift = 0;
    reg M_reg_shift = 0;
    reg M_prime_0_reg_rot = 0;

    reg [N*WORD_WIDTH-1:0] RES_reg_din = 0;


    wire BRAM_we;
    wire [ADDR_LEN-1:0] BRAM_addr;

    wire [WORD_WIDTH-1:0] BRAM_din;

    wire [S*WORD_WIDTH-1:0] A_reg_dout;
    wire [N*WORD_WIDTH-1:0] B_reg_dout;
    wire [WORD_WIDTH-1:0] M_reg_dout;
    wire [WORD_WIDTH-1:0] M_prime_0_reg_dout;

    wire load_done;
    wire store_done;

    POLY_memory #(
        .WORD_WIDTH(WORD_WIDTH),
        .N(N),
        .S(S)
    ) POLY_memory_inst (

    .clock_i(clock),
    .reset_i(reset),

    .load_start_i(load_start),
    .store_start_i(store_start),

    .BRAM_dout_i(BRAM_dout),

    .load_RES_reg_en_i(load_RES_reg_en),

    .A_reg_coeff_rot_i(A_reg_coeff_rot),
    .B_reg_shift_i(B_reg_shift),
    .M_reg_shift_i(M_reg_shift),
    .M_prime_0_reg_rot_i(M_prime_0_reg_rot),

    .RES_reg_din_i(RES_reg_din),


    .BRAM_we_o(BRAM_we),
    .BRAM_addr_o(BRAM_addr),

    .BRAM_din_o(BRAM_din),

    .A_reg_dout_o(A_reg_dout),
    .B_reg_dout_o(B_reg_dout),
    .M_reg_dout_o(M_reg_dout),
    .M_prime_0_reg_dout_o(M_prime_0_reg_dout),

    .load_done_o(load_done),
    .store_done_o(store_done)

);

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

    reg [N*S*WORD_WIDTH-1:0] expected_RES = 0;

    initial begin
        reset = 1;
        #PERIOD;
        reset = 0;
        #PERIOD;
        std::randomize(BRAM_memory);
        BRAM_memory[(4*N*S+N)*WORD_WIDTH:(3*N*S+N)*WORD_WIDTH] = 0;
        // Test INPUT data load
        load_start = 1;
        #PERIOD;
        load_start = 0;
        wait(load_done == 1);
        test = 1;
        if (POLY_memory_inst.POLY_reg_bank_inst.A_reg != BRAM_memory[N*S*WORD_WIDTH-1:0]   ||
            POLY_memory_inst.POLY_reg_bank_inst.B_reg != BRAM_memory[2*N*S*WORD_WIDTH-1:N*S*WORD_WIDTH] ||
            POLY_memory_inst.POLY_reg_bank_inst.M_reg != BRAM_memory[3*N*S*WORD_WIDTH-1:2*N*S*WORD_WIDTH] ||
            POLY_memory_inst.POLY_reg_bank_inst.M_prime_0_reg != BRAM_memory[(3*N*S+N)*WORD_WIDTH-1:3*N*S*WORD_WIDTH])
            test = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) LOAD INPUT data\n", test_count, NB_TESTS);
        // Test RES data store
        std::randomize(expected_RES);
        force POLY_memory_inst.POLY_reg_bank_inst.RES_reg = expected_RES;
        release POLY_memory_inst.POLY_reg_bank_inst.RES_reg;
        store_start <= 1;
        #PERIOD;
        store_start <= 0;
        wait(store_done == 1);
        test = 1;
        if (BRAM_memory[(4*N*S+N)*WORD_WIDTH-1:(3*N*S+N)*WORD_WIDTH] != expected_RES)
            test = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) STORE INPUT data\n", test_count, NB_TESTS);
        #PERIOD;
        $write("(%0d/%0d) tests completed\n", successful_test_count, NB_TESTS);
        if (successful_test_count == NB_TESTS)
            $write("SUCCESS\n");
        else
            $write("FAILURE\n");
        $stop;
    end

endmodule
