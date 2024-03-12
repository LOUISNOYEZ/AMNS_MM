`timescale 1ns/1ps


module PE_AU_tb #(
    ABREG = 1,
    MREG  = 1,
    CREG  = 1
    ) ();

    localparam realtime PERIOD = 10,
                        HALF_PERIOD = PERIOD/2;

    localparam NB_TESTS = 4;
    reg [$clog2(NB_TESTS):0] test_count = 0;
    reg [$clog2(NB_TESTS):0] successful_test_count = 0;
    reg test = 1;

    reg clock = 0;
    reg reset = 0;

    always #HALF_PERIOD clock = ~clock;

    reg CREG_en = 0;

    reg [8:0] OPMODE = 0;

    reg signed [26:0] A_din = 0;
    reg signed [17:0] B_din = 0;
    reg signed [47:0] C_din = 0;
    reg signed [47:0] PCIN_din = 0;

    wire signed [47:0] P_dout;
    wire signed [47:0] PCOUT_dout;

    PE_AU #(
        .ABREG(ABREG),
        .MREG(MREG),
        .CREG(CREG)
    ) PE_AU_inst (

    .clock_i(clock),

    .CREG_en_i(CREG_en),

    .OPMODE_i(OPMODE),

    .A_din_i(A_din),
    .B_din_i(B_din),
    .C_din_i(C_din),
    .PCIN_din_i(PCIN_din),

    .P_dout_o(P_dout),

    .PCOUT_dout_o(PCOUT_dout)

);


    initial begin
        reset = 1;
        #PERIOD;
        reset = 0;
        #(20*PERIOD);
        // Signed multiplication test
        // A positive, B positive
        test = 1;
        std::randomize(A_din);
        A_din[26] = 0;
        std::randomize(B_din);
        B_din[17] = 0;
        OPMODE = 9'b000000101;
        #(3*PERIOD);
        if (P_dout != 48'(48'(A_din*B_din)))
            test = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) Signed multiplication : A positive, B positive\n", test_count, NB_TESTS);
        $write("A = %0d, B = %0d, got : %0d, expected A*B : %0d\n", A_din, B_din, P_dout, 48'(A_din*B_din));
        #PERIOD;
        // A positive, B negative
        test = 1;
        std::randomize(A_din);
        A_din[26] = 0;
        std::randomize(B_din);
        B_din[17] = 1;
        OPMODE = 9'b000000101;
        #(3*PERIOD);
        if (P_dout != 48'(48'(A_din*B_din)))
            test = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) Signed multiplication : A positive, B negative\n", test_count, NB_TESTS);
        $write("A = %0d, B = %0d, got : %0d, expected A*B : %0d\n", A_din, B_din, P_dout, 48'(A_din*B_din));
        // A negative, B positive
        test = 1;
        std::randomize(A_din);
        A_din[26] = 1;
        std::randomize(B_din);
        B_din[17] = 0;
        OPMODE = 9'b000000101;
        #(3*PERIOD);
        if (P_dout != 48'(48'(A_din*B_din)))
            test = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) Signed multiplication : A negative, B positive\n", test_count, NB_TESTS);
        $write("A = %0d, B = %0d, got : %0d, expected A*B : %0d\n", A_din, B_din, P_dout, 48'(A_din*B_din));
        // A negative, B negative
        test = 1;
        std::randomize(A_din);
        A_din[26] = 1;
        std::randomize(B_din);
        B_din[17] = 1;
        OPMODE = 9'b000000101;
        #(3*PERIOD);
        if (P_dout != 48'(48'(A_din*B_din)))
            test = 0;
        test_count = test_count+1;
        if (test) begin
            successful_test_count = successful_test_count+1;
            $write("SUCCESS ");
        end else
            $write("FAILURE ");
        $write("(test %0d/%0d) Signed multiplication : A negative, B negative\n", test_count, NB_TESTS);
        $write("A = %0d, B = %0d, got : %0d, expected A*B : %0d\n", A_din, B_din, P_dout, 48'(A_din*B_din));
        $write("(%0d/%0d) tests completed\n", successful_test_count, NB_TESTS);
        if (successful_test_count == NB_TESTS)
            $write("SUCCESS\n");
        else
            $write("FAILURE\n");
        $stop;
    end
    
endmodule
