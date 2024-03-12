`timescale 1ns/1ps


module POLY_memory_control_tb #(
    WORD_WIDTH  = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N           =  5, // Number of coefficients in an AMNS polynomial
    S           =  4  // Number of blocks of width WORD_WIDTH required to hold a coefficient
) ();

    localparam realtime PERIOD = 10,
                        HALF_PERIOD = PERIOD/2;

    localparam NB_TESTS = 9;
    reg [$clog2(NB_TESTS):0] test_count = 0;
    reg [$clog2(NB_TESTS):0] successful_test_count = 0;
    reg test = 1;

    reg clock = 0;
    reg reset = 0;

    localparam [3:0] RESET  = 4'b0000,
                     IDLE   = 4'b0001,
                     LOAD_A = 4'b0010,
                     LOAD_B = 4'b0011,
                     LOAD_M = 4'b0100,
                     LOAD_M_PRIME_0 = 4'b0101,
                     STORE_RES = 4'b0110,
                     LOAD_DONE = 4'b0111,
                     STORE_DONE = 4'b1000;
                     
    localparam ADDR_LEN = $clog2(4*N*S+N)+1;

    reg load_start  = 0;
    reg store_start = 0;

    wire BRAM_we;
    wire [ADDR_LEN-1:0] BRAM_addr;

    wire [1:0] INPUT_reg_sel;
    wire INPUT_reg_en;

    wire store_RES_reg_en;

    wire load_done;
    wire store_done;


    always #HALF_PERIOD clock = ~clock;

    POLY_memory_control #(
        .WORD_WIDTH(WORD_WIDTH),
        .N(N),
        .S(S)
    ) POLY_memory_control_inst (

    .clock_i(clock),
    .reset_i(reset),

    .load_start_i(load_start),
    .store_start_i(store_start),

    .BRAM_we_o(BRAM_we),
    .BRAM_addr_o(BRAM_addr),

    .INPUT_reg_sel_o(INPUT_reg_sel),
    .INPUT_reg_en_o(INPUT_reg_en),

    .store_RES_reg_en_o(store_RES_reg_en),

    .load_done_o(load_done),
    .store_done_o(store_done)

    );


    initial begin
        reset = 1;
        #PERIOD;
        reset = 0;
        // Test RESET state
        test = 1;
        reset = 1;
        #PERIOD;
        if (BRAM_we       != 1'b0         ||
            BRAM_addr     != ADDR_LEN'(0) ||
            INPUT_reg_sel != 2'b00        ||
            INPUT_reg_en  != 1'b0         ||
            store_RES_reg_en != 1'b0      ||
            load_done     != 1'b0         ||
            store_done    != 1'b0         ||
            POLY_memory_control_inst.current_state != RESET)
            test = 0;
        reset = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) RESET state\n", test_count, NB_TESTS);
        #PERIOD;
        // Test IDLE state
        test = 1;
        if (BRAM_we       != 1'b0         ||
            BRAM_addr     != ADDR_LEN'(0) ||
            INPUT_reg_sel != 2'b00        ||
            INPUT_reg_en  != 1'b0         ||
            store_RES_reg_en != 1'b0      ||
            load_done     != 1'b0         ||
            store_done    != 1'b0         ||
            POLY_memory_control_inst.current_state != IDLE)
            test = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) IDLE state\n", test_count, NB_TESTS);
        #PERIOD;
        // Test LOAD_A state
        test = 1;
        load_start = 1;
        #PERIOD;
        load_start = 0;
        if (BRAM_we       != 1'b0         ||
            BRAM_addr     != ADDR_LEN'(0) ||
            INPUT_reg_sel != 2'b00        ||
            INPUT_reg_en  != 1'b0         ||
            store_RES_reg_en != 1'b0      ||
            load_done     != 1'b0         ||
            store_done    != 1'b0         ||
            POLY_memory_control_inst.current_state != LOAD_A)
            test = 0;
        #PERIOD;
        if (BRAM_we       != 1'b0         ||
            BRAM_addr     != ADDR_LEN'(1) ||
            INPUT_reg_sel != 2'b00        ||
            INPUT_reg_en  != 1'b0         ||
            store_RES_reg_en != 1'b0      ||
            load_done     != 1'b0         ||
            store_done    != 1'b0         ||
            POLY_memory_control_inst.current_state != LOAD_A)
            test = 0;
        #PERIOD;
        for(int i = 2; i < N*S; i++) begin
            if (BRAM_we       != 1'b0         ||
                BRAM_addr     != ADDR_LEN'(i) ||
                INPUT_reg_sel != 2'b00        ||
                INPUT_reg_en  != 1'b1         ||
                store_RES_reg_en != 1'b0      ||
                load_done     != 1'b0         ||
                store_done    != 1'b0         ||
                POLY_memory_control_inst.current_state != LOAD_A)
                test = 0;
            #PERIOD;
        end
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) LOAD_A state\n", test_count, NB_TESTS);
        // Test LOAD_B state
        test = 1;
        if (BRAM_we       != 1'b0           ||
            BRAM_addr     != ADDR_LEN'(N*S) ||
            INPUT_reg_sel != 2'b00          ||
            INPUT_reg_en  != 1'b1           ||
            store_RES_reg_en != 1'b0        ||
            load_done     != 1'b0           ||
            store_done    != 1'b0           ||
            POLY_memory_control_inst.current_state != LOAD_B)
            test = 0;
        #PERIOD;
        if (BRAM_we       != 1'b0             ||
            BRAM_addr     != ADDR_LEN'(N*S+1) ||
            INPUT_reg_sel != 2'b00            ||
            INPUT_reg_en  != 1'b1             ||
            store_RES_reg_en != 1'b0          ||
            load_done     != 1'b0             ||
            store_done    != 1'b0             ||
            POLY_memory_control_inst.current_state != LOAD_B)
            test = 0;
        #PERIOD;
        for(int i = N*S+2; i < 2*N*S; i++) begin
            if (BRAM_we       != 1'b0         ||
                BRAM_addr     != ADDR_LEN'(i) ||
                INPUT_reg_sel != 2'b01        ||
                INPUT_reg_en  != 1'b1         ||
                store_RES_reg_en != 1'b0      ||
                load_done     != 1'b0         ||
                store_done    != 1'b0         ||
                POLY_memory_control_inst.current_state != LOAD_B)
                test = 0;
            #PERIOD;
        end
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) LOAD_B state\n", test_count, NB_TESTS);
        // Test LOAD_M state
        test = 1;
        if (BRAM_we       != 1'b0             ||
            BRAM_addr     != ADDR_LEN'(2*N*S) ||
            INPUT_reg_sel != 2'b01            ||
            INPUT_reg_en  != 1'b1             ||
            store_RES_reg_en != 1'b0          ||
            load_done     != 1'b0             ||
            store_done    != 1'b0             ||
            POLY_memory_control_inst.current_state != LOAD_M)
            test = 0;
        #PERIOD;
        if (BRAM_we       != 1'b0               ||
            BRAM_addr     != ADDR_LEN'(2*N*S+1) ||
            INPUT_reg_sel != 2'b01              ||
            INPUT_reg_en  != 1'b1               ||
            store_RES_reg_en != 1'b0            ||
            load_done     != 1'b0               ||
            store_done    != 1'b0               ||
            POLY_memory_control_inst.current_state != LOAD_M)
            test = 0;
        #PERIOD;
        for(int i = 2*N*S+2; i < 3*N*S; i++) begin
            if (BRAM_we       != 1'b0         ||
                BRAM_addr     != ADDR_LEN'(i) ||
                INPUT_reg_sel != 2'b10        ||
                INPUT_reg_en  != 1'b1         ||
                store_RES_reg_en != 1'b0      ||
                load_done     != 1'b0         ||
                store_done    != 1'b0         ||
                POLY_memory_control_inst.current_state != LOAD_M)
                test = 0;
            #PERIOD;
        end
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) LOAD_M state\n", test_count, NB_TESTS);
        // Test LOAD_M_PRIME_0 state
        test = 1;
        if (BRAM_we       != 1'b0             ||
            BRAM_addr     != ADDR_LEN'(3*N*S) ||
            INPUT_reg_sel != 2'b10            ||
            INPUT_reg_en  != 1'b1             ||
            store_RES_reg_en != 1'b0          ||
            load_done     != 1'b0             ||
            store_done    != 1'b0             ||
            POLY_memory_control_inst.current_state != LOAD_M_PRIME_0)
            test = 0;
        #PERIOD;
        if (BRAM_we       != 1'b0               ||
            BRAM_addr     != ADDR_LEN'(3*N*S+1) ||
            INPUT_reg_sel != 2'b10              ||
            INPUT_reg_en  != 1'b1               ||
            store_RES_reg_en != 1'b0            ||
            load_done     != 1'b0               ||
            store_done    != 1'b0               ||
            POLY_memory_control_inst.current_state != LOAD_M_PRIME_0)
            test = 0;
        #PERIOD;
        for(int i = 3*N*S+2; i < 3*N*S+N; i++) begin
            if (BRAM_we       != 1'b0         ||
                BRAM_addr     != ADDR_LEN'(i) ||
                INPUT_reg_sel != 2'b11        ||
                INPUT_reg_en  != 1'b1         ||
                store_RES_reg_en != 1'b0      ||
                load_done     != 1'b0         ||
                store_done    != 1'b0         ||
                POLY_memory_control_inst.current_state != LOAD_M_PRIME_0)
                test = 0;
            #PERIOD;
        end
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) LOAD_M_PRIME_0 state\n", test_count, NB_TESTS);
        // Test LOAD_DONE state
        if (BRAM_we       != 1'b0               ||
            BRAM_addr     != ADDR_LEN'(3*N*S+N) ||
            INPUT_reg_sel != 2'b11              ||
            INPUT_reg_en  != 1'b1               ||
            store_RES_reg_en != 1'b0            ||
            load_done     != 1'b0               ||
            store_done    != 1'b0               ||
            POLY_memory_control_inst.current_state != LOAD_DONE)
            test = 0;
        #PERIOD;
        if (BRAM_we       != 1'b0               ||
            BRAM_addr     != ADDR_LEN'(0)       ||
            INPUT_reg_sel != 2'b11              ||
            INPUT_reg_en  != 1'b1               ||
            store_RES_reg_en != 1'b0            ||
            load_done     != 1'b0               ||
            store_done    != 1'b0               ||
            POLY_memory_control_inst.current_state != IDLE)
            test = 0;
        #PERIOD;
        if (BRAM_we       != 1'b0         ||
            BRAM_addr     != ADDR_LEN'(0) ||
            INPUT_reg_sel != 2'b00        ||
            INPUT_reg_en  != 1'b0         ||
            store_RES_reg_en != 1'b0      ||
            load_done     != 1'b1         ||
            store_done    != 1'b0         ||
            POLY_memory_control_inst.current_state != IDLE)
            test = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) LOAD_DONE state\n", test_count, NB_TESTS);
        // Test STORE_RES state
        test = 1;
        store_start = 1;
        #PERIOD;
        store_start = 0;
        for (int i = 3*N*S+N; i < 4*N*S+N; i++) begin
            if (BRAM_we       != 1'b1         ||
                BRAM_addr     != ADDR_LEN'(i) ||
                INPUT_reg_sel != 2'b00        ||
                INPUT_reg_en  != 1'b0         ||
                store_RES_reg_en != 1'b1      ||
                load_done     != 1'b0         ||
                store_done    != 1'b0         ||
                POLY_memory_control_inst.current_state != STORE_RES)
                test = 0;
            #PERIOD;
        end
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) STORE_RES state\n", test_count, NB_TESTS);
        // Test STORE_DONE state
        test = 1;
        if (BRAM_we       != 1'b0               ||
            BRAM_addr     != ADDR_LEN'(4*N*S+N) ||
            INPUT_reg_sel != 2'b00              ||
            INPUT_reg_en  != 1'b0               ||
            store_RES_reg_en != 1'b0            ||
            load_done     != 1'b0               ||
            store_done    != 1'b1               ||
            POLY_memory_control_inst.current_state != STORE_DONE)
            test = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) STORE_DONE state\n", test_count, NB_TESTS);
        #PERIOD;
        $write("(%0d/%0d) tests completed\n", successful_test_count, NB_TESTS);
        if (successful_test_count == NB_TESTS)
            $write("SUCCESS\n");
        else
            $write("FAILURE\n");
        $stop;
    end

endmodule
