`timescale 1ns/1ps


module POLY_reg_bank_tb #(
    WORD_WIDTH  = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N           =  5, // Number of coefficients in an AMNS polynomial
    S           =  4  // Number of blocks of width WORD_WIDTH required to hold a coefficient
) ();

    localparam realtime PERIOD = 10,
                        HALF_PERIOD = PERIOD/2;

    localparam NB_TESTS = 10;
    reg [$clog2(NB_TESTS):0] test_count = 0;
    reg [$clog2(NB_TESTS):0] successful_test_count = 0;
    reg test = 1;

    reg clock = 0;
    reg reset = 0;

    reg [N*S*WORD_WIDTH-1:0] A_reg = 0;
    reg [N*S*WORD_WIDTH-1:0] B_reg = 0;
    reg [N*S*WORD_WIDTH-1:0] M_reg = 0;
    reg [N*WORD_WIDTH-1:0]   M_prime_0_reg = 0;
    reg [N*S*WORD_WIDTH-1:0] expected_RES_reg = 0;

    reg store_RES_reg_en = 0;
    reg [N*S*WORD_WIDTH-1:0] store_RES_reg = 0;


    always #HALF_PERIOD clock = ~clock;


    always @(posedge clock) begin
        if (reset)
            store_RES_reg <= 0;
        else if (store_RES_reg_en)
            store_RES_reg <= {RES_reg_dout, store_RES_reg[N*S*WORD_WIDTH-1:WORD_WIDTH]};
        else
            store_RES_reg <= store_RES_reg;
    end


    reg [1:0] INPUT_reg_sel = 0;
    reg INPUT_reg_en = 0;

    reg RES_reg_en = 0;

    reg [S-1:0] A_reg_coeff_rot = 0;
    reg B_reg_shift             = 0;
    reg M_reg_shift             = 0;
    reg M_prime_0_reg_rot       = 0;
    reg RES_reg_shift           = 0;

    reg [WORD_WIDTH-1:0]   INPUT_reg_din = 0;
    reg [N*WORD_WIDTH-1:0] RES_reg_din   = 0;

    wire [S*WORD_WIDTH-1:0] A_reg_dout;
    wire [N*WORD_WIDTH-1:0] B_reg_dout;
    wire [WORD_WIDTH-1:0]   M_reg_dout;
    wire [WORD_WIDTH-1:0]   M_prime_0_reg_dout;

    wire [WORD_WIDTH-1:0] RES_reg_dout;

    POLY_reg_bank #(
        .WORD_WIDTH(WORD_WIDTH),
        .N(N),
        .S(S)
    ) POLY_reg_bank_inst (

        .clock_i(clock),
        .reset_i(reset),

        .INPUT_reg_sel_i(INPUT_reg_sel),
        .INPUT_reg_en_i(INPUT_reg_en),

        .RES_reg_en_i(RES_reg_en),

        .A_reg_coeff_rot_i(A_reg_coeff_rot),
        .B_reg_shift_i(B_reg_shift),
        .M_reg_shift_i(M_reg_shift),
        .M_prime_0_rot_i(M_prime_0_reg_rot),
        .RES_reg_shift_i(RES_reg_shift),
        
        .INPUT_reg_din_i(INPUT_reg_din),
        .RES_reg_din_i(RES_reg_din),

        .A_reg_dout_o(A_reg_dout),
        .B_reg_dout_o(B_reg_dout),
        .M_reg_dout_o(M_reg_dout),
        .M_prime_0_reg_dout_o(M_prime_0_reg_dout),

        .RES_reg_dout_o(RES_reg_dout)

    );


    initial begin
        reset = 1;
        #PERIOD;
        reset = 0;
        // Randomize data to load into INPUT registers
        std::randomize(A_reg);
        std::randomize(B_reg);
        std::randomize(M_reg);
        std::randomize(M_prime_0_reg);
        std::randomize(expected_RES_reg);
        #PERIOD;
        // INPUT data load tests
        // Load data into register A
        INPUT_reg_sel = 2'b00;
        INPUT_reg_en = 1;
        for (int i = 0; i < N*S; i++) begin
            INPUT_reg_din = A_reg[i*WORD_WIDTH+:WORD_WIDTH];
            #PERIOD;
        end
        INPUT_reg_sel = 0;
        INPUT_reg_en = 0;
        INPUT_reg_din = 0;
        test_count = test_count+1;
        if (POLY_reg_bank_inst.A_reg == A_reg) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) Load A_reg data\n", test_count, NB_TESTS);        
        // Load data into register B
        INPUT_reg_sel = 2'b01;
        INPUT_reg_en = 1;
        INPUT_reg_din = 0;
        for (int i = 0; i < N*S; i++) begin
            INPUT_reg_din = B_reg[i*WORD_WIDTH+:WORD_WIDTH];
            #PERIOD;
        end
        INPUT_reg_sel = 0;
        INPUT_reg_en = 0;
        INPUT_reg_din = 0;
        test_count = test_count+1;
        if (POLY_reg_bank_inst.B_reg == B_reg) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) Load B_reg data\n", test_count, NB_TESTS);
        // Load data into register M
        INPUT_reg_sel = 2'b10;
        INPUT_reg_en = 1;
        for (int i = 0; i < N*S; i++) begin
            INPUT_reg_din = M_reg[i*WORD_WIDTH+:WORD_WIDTH];
            #PERIOD;
        end
        INPUT_reg_sel = 0;
        INPUT_reg_en = 0;
        INPUT_reg_din = 0;
        test_count = test_count+1;
        if (POLY_reg_bank_inst.M_reg == M_reg) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) Load M_reg data\n", test_count, NB_TESTS);
        // Load data into register M_prime_0
        INPUT_reg_sel = 2'b11;
        INPUT_reg_en = 1;
        for (int i = 0; i < N; i++) begin
            INPUT_reg_din = M_prime_0_reg[i*WORD_WIDTH+:WORD_WIDTH];
            #PERIOD;
        end
        INPUT_reg_sel = 0;
        INPUT_reg_en = 0;
        INPUT_reg_din = 0;
        test_count = test_count+1;
        if (POLY_reg_bank_inst.M_prime_0_reg == M_prime_0_reg) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) Load M_prime_0_reg data\n", test_count, NB_TESTS);
        // Rotate, coefficient rotate and shift tests
        // Rotate sections of A_reg
        test = 1;
        for (int j = 0; j < S; j++) begin
            A_reg_coeff_rot = 0;
            A_reg_coeff_rot[j] = 1;
            for (int i = 0; i < N; i++) begin
                #PERIOD;
                for (int k = 0; k < N; k++) begin
                    // Test content of A register
                    if (POLY_reg_bank_inst.A_reg[(N*j+k)*WORD_WIDTH+:WORD_WIDTH] != A_reg[(N*j+(i+1+k)%N)*WORD_WIDTH+:WORD_WIDTH])
                        test = 0;
                end
                // Test A output
                if (A_reg_dout[j*WORD_WIDTH+:WORD_WIDTH] != A_reg[(N*j+(i+1)%N)*WORD_WIDTH+:WORD_WIDTH])
                    test = 0;
            end
        end
        A_reg_coeff_rot = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");        
        $write("(test %0d/%0d) Rotate A_reg coefficients data\n", test_count, NB_TESTS);
        #PERIOD;
        // Shift B_reg
        test = 1;
        B_reg_shift = 1;
        for (int k = 0; k < N*S; k++) begin
            for (int l = 0; l < (N*S-k); l++) begin
                // Test B register
                if (POLY_reg_bank_inst.B_reg[l*WORD_WIDTH+:WORD_WIDTH] != B_reg[(k+l)*WORD_WIDTH+:WORD_WIDTH])
                    test = 0;
            end
            if (k < S) begin
                for (int l = 0; l < N; l++) begin
                    //Test B output
                    if (B_reg_dout[l*WORD_WIDTH+:WORD_WIDTH] != B_reg[(l*S+k)*WORD_WIDTH+:WORD_WIDTH])
                        test = 0;
                end
            end
            #PERIOD;
        end
        B_reg_shift = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");        
        $write("(test %0d/%0d) Shift B_reg data\n", test_count, NB_TESTS);
        #PERIOD;
        // Shift M_reg
        test = 1;
        M_reg_shift = 1;
        for (int k = 0; k < N*S; k++) begin
            for (int l = 0; l < (N*S-k); l++) begin
                // Test M register
                if (POLY_reg_bank_inst.M_reg[l*WORD_WIDTH+:WORD_WIDTH] != M_reg[(k+l)*WORD_WIDTH+:WORD_WIDTH])
                    test = 0;
            end
            //Test M output
            if (M_reg_dout != M_reg[k*WORD_WIDTH+:WORD_WIDTH])
                test = 0;
            #PERIOD;
        end
        M_reg_shift = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) Shift M_reg data\n", test_count, NB_TESTS);
        #PERIOD;
        // Rotate sections of M_prime_0_reg
        test = 1;
        for (int i = 0; i < N; i++) begin
            M_prime_0_reg_rot = 1;
            #PERIOD;
            for (int k = 0; k < N; k++) begin
                // Test content of M_prime_0 register
                if (POLY_reg_bank_inst.M_prime_0_reg[k*WORD_WIDTH+:WORD_WIDTH] != M_prime_0_reg[((i+1+k)%N)*WORD_WIDTH+:WORD_WIDTH])
                    test = 0;
            end
            // Test M_prime_0 output
            if (M_prime_0_reg_dout != M_prime_0_reg[((i+1)%N)*WORD_WIDTH+:WORD_WIDTH])
                test = 0;
        end
        M_prime_0_reg_rot = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) Rotate M_prime_0_reg data\n", test_count, NB_TESTS);
        #PERIOD;
        std::randomize(expected_RES_reg);
        // Load result test
        RES_reg_en = 1;
        for (int k = 0; k < N*S; k++) begin
            RES_reg_din = expected_RES_reg[k*WORD_WIDTH+:WORD_WIDTH];
            #PERIOD;
        end
        RES_reg_en = 0;
        RES_reg_din = 0;
        test_count = test_count+1;
        if (POLY_reg_bank_inst.RES_reg == expected_RES_reg) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) Load RES_reg data\n", test_count, NB_TESTS);
        #PERIOD;
        // Store result test
        store_RES_reg_en = 1;
        RES_reg_shift = 1;
        #(N*S*PERIOD);
        store_RES_reg_en = 0;
        test_count = test_count+1;
        if (store_RES_reg == expected_RES_reg) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) Store RES_reg data\n", test_count, NB_TESTS);
        store_RES_reg_en = 0;
        RES_reg_shift = 0;
        #PERIOD;
        $write("(%0d/%0d) tests completed\n", successful_test_count, NB_TESTS);
        if (test_count == NB_TESTS)
            $write("SUCCESS\n");
        else
            $write("FAILURE\n");
        $stop;
    end
    
endmodule
