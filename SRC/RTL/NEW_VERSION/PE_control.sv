`timescale 1ns / 1ps


module PE_control #(
    WORD_WIDTH   = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N            =  5, // Number of coefficients in an AMNS polynomial
    S            =  4,  // Number of blocks of width WORD_WIDTH required to hold a coefficient
    COLUMN_INDEX =  0, // Indicates which PE column this PE belongs to. Each PE column is responsible for the computation of one result coefficient.
    LINE_INDEX   =  0  // Indicates which PE line this PE belongs to. Each PE line is responsible for computations related to a WORD_WIDTH section of A coefficients.
) (

    input clock_i,
          reset_i,

    input start_i,

    output reg A_reg_en_o,
    output reg A_reg_sel_o,
    output reg sign_ext_A_en_o,
    output reg B_reg_en_o,
    output reg B_reg_sel_o,
    output reg sign_ext_B_en_o,
    output reg M_reg_en_o,
    output reg M_reg_sel_o,
    output reg sign_ext_M_en_o,
    output reg M_prime_0_reg_en_o,
    output reg M_prime_0_reg_sel_o,
    output reg q_reg_en_o,
    output reg q_reg_sel_o,
    output reg RES_reg_en_o,
    output reg CREG_en_o,
    output reg [1:0] CREG_sel_o,
    output reg CREG_reg_en_o,

    output reg [1:0] PE_AU_A_sel_o,
    output reg [1:0] PE_AU_B_sel_o,

    output [8:0] OPMODE_o,
    output LAMBDA_MUL_sel_o,

    output reg mem_B_reg_shift_o,
    output reg mem_M_reg_shift_o,

    output reg B_delay_line_en_o,
    output reg M_delay_line_en_o,

    output done_o
);

    localparam [4:0] RESET = 0,
                     INIT  = 1,
                     FIRST_MUL_A_B_0 = 2,
                     MUL_A_B_0 = 3,
                     LAST_MUL_A_B_0 = 4,
                     MUL_A_B_1_0 = 5,
                     FIRST_MUL_M_PRIME_0_Q = 6,
                     SECOND_MUL_M_PRIME_0_Q = 7,
                     MUL_M_PRIME_0_Q = 8,
                     LAST_MUL_M_PRIME_0_Q = 9,
                     MUL_A_B_1_1 = 10,
                     FIRST_MUL_M_0_Q = 11,
                     SECOND_MUL_M_0_Q = 12,
                     MUL_M_0_Q = 13,
                     LAST_MUL_M_0_Q = 14,
                     MUL_A_B_1_2 = 15,
                     MUL_A_B_1 = 16,
                     LAST_MUL_A_B_1 = 17,
                     FIRST_MUL_M_1_Q = 18,
                     MUL_M_1_Q = 19,
                     LAST_MUL_M_1_Q = 20,
                     FIRST_MUL_A_B = 21,
                     MUL_A_B = 22,
                     LAST_MUL_A_B = 23,
                     FIRST_MUL_M_Q = 24,
                     MUL_M_Q = 25,
                     LAST_MUL_M_Q = 26,
                     DONE = 27;
                    
    reg [4:0] current_state, future_state;

    reg [8:0] OPMODE;
    
    reg mem_B_reg_shift;

    reg done;
    reg done_reg;

    
    reg mul_counter_reset, mul_counter_en;
    reg [1:0] mul_counter_init;
    reg [$clog2(N):0] mul_count;

    reg FIOS_counter_reset, FIOS_counter_en;
    reg [$clog2(S)+1-1:0] FIOS_count;

    always_ff @(posedge clock_i) begin
        if (reset_i)
            current_state <= RESET;
        else
            current_state <= future_state;
    end
    
    reg [1:0] CREG_sel; 

    reg M_delay_line_en;

    always_comb begin
        case (current_state)
            RESET: future_state = INIT;
            INIT: begin
                if (start_i)
                    future_state = FIRST_MUL_A_B_0;
                else
                    future_state = INIT;
            end
            FIRST_MUL_A_B_0: future_state = MUL_A_B_0;
            MUL_A_B_0: begin
                if (mul_count == N-2)
                        future_state = LAST_MUL_A_B_0;
                else
                    future_state = MUL_A_B_0;
            end
            LAST_MUL_A_B_0: future_state = MUL_A_B_1_0;
            MUL_A_B_1_0: future_state = FIRST_MUL_M_PRIME_0_Q;
            FIRST_MUL_M_PRIME_0_Q: future_state = SECOND_MUL_M_PRIME_0_Q;
            SECOND_MUL_M_PRIME_0_Q: future_state = MUL_M_PRIME_0_Q;
            MUL_M_PRIME_0_Q: begin
                if (mul_count == N-2)
                    future_state = LAST_MUL_M_PRIME_0_Q;
                else
                    future_state = MUL_M_PRIME_0_Q;
            end
            LAST_MUL_M_PRIME_0_Q: future_state = MUL_A_B_1_1;
            MUL_A_B_1_1: future_state = FIRST_MUL_M_0_Q;
            FIRST_MUL_M_0_Q: future_state = SECOND_MUL_M_0_Q;
            SECOND_MUL_M_0_Q: future_state = MUL_M_0_Q;
            MUL_M_0_Q : begin
                if (mul_count == N-2)
                    future_state = LAST_MUL_M_0_Q;
                else
                    future_state = MUL_M_0_Q;
            end
            LAST_MUL_M_0_Q: future_state = MUL_A_B_1_2;
            MUL_A_B_1_2: future_state = MUL_A_B_1;
            MUL_A_B_1: begin
                if (mul_count == N-2)
                    future_state = LAST_MUL_A_B_1;
                else
                    future_state = MUL_A_B_1;
            end
            LAST_MUL_A_B_1: future_state = FIRST_MUL_M_1_Q;
            FIRST_MUL_M_1_Q: future_state = MUL_M_1_Q;
            MUL_M_1_Q : begin
                if (mul_count == N-2)
                    future_state = LAST_MUL_M_1_Q;
                else
                    future_state = MUL_M_1_Q;
            end
            LAST_MUL_M_1_Q: future_state = FIRST_MUL_A_B;
            FIRST_MUL_A_B: future_state = MUL_A_B;
            MUL_A_B : begin
                if (mul_count == N-2)
                    future_state = LAST_MUL_A_B;
                else
                    future_state = MUL_A_B;
            end
            LAST_MUL_A_B: future_state = FIRST_MUL_M_Q;
            FIRST_MUL_M_Q: future_state = MUL_M_Q;
            MUL_M_Q: begin
                if (mul_count == N-2)
                    future_state = LAST_MUL_M_Q;
                else
                    future_state = MUL_M_Q;
            end
            LAST_MUL_M_Q: begin
                if (FIOS_count == S-1)
                    future_state = DONE;
                else
                    future_state = FIRST_MUL_A_B;
            end
            DONE: future_state = INIT;
            default: future_state = INIT;
        endcase
    end

    always_comb begin
        case (current_state)
            RESET: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000000000;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 1;
                mul_counter_en = 0;
                mul_counter_init = 0;
                FIOS_counter_reset = 1;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            INIT: begin
                A_reg_en_o = 1;
                A_reg_sel_o = 0;
                B_reg_en_o = 1;
                B_reg_sel_o = 0;
                M_reg_en_o = 1;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 1;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000000000;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 1;
                mul_counter_en = 0;
                mul_counter_init = 0;
                FIOS_counter_reset = 1;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            FIRST_MUL_A_B_0: begin
                A_reg_en_o = 1;
                A_reg_sel_o = 1;
                B_reg_en_o = 1;
                B_reg_sel_o = 1;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 1;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 1;
                M_delay_line_en = 0;
            end
            MUL_A_B_0: begin
                A_reg_en_o = 1;
                A_reg_sel_o = 1;
                B_reg_en_o = 1;
                B_reg_sel_o = 1;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 1;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            LAST_MUL_A_B_0: begin
                A_reg_en_o = 1;
                A_reg_sel_o = 1;
                B_reg_en_o = 1;
                B_reg_sel_o = 0;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 1;
                CREG_sel = 1; 
                OPMODE = 9'b110100101;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 1;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 1;
                mul_counter_en = 0;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            MUL_A_B_1_0: begin
                A_reg_en_o = 1;
                A_reg_sel_o = 1;
                B_reg_en_o = 1;
                B_reg_sel_o = 1;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000000101;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 1;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 1;
                mul_counter_en = 0;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 1;
                M_delay_line_en = 0;
            end
            FIRST_MUL_M_PRIME_0_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 1;
                M_prime_0_reg_sel_o = 1;
                q_reg_en_o = 1;
                q_reg_sel_o = 0;
                RES_reg_en_o = 1;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000000101;
                PE_AU_A_sel_o = 1;
                PE_AU_B_sel_o = 1;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            SECOND_MUL_M_PRIME_0_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 1;
                M_prime_0_reg_sel_o = 1;
                q_reg_en_o = 1;
                q_reg_sel_o = 1;
                RES_reg_en_o = 0;
                CREG_en_o = 1;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 1;
                PE_AU_B_sel_o = 2;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            MUL_M_PRIME_0_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 1;
                M_prime_0_reg_sel_o = 1;
                q_reg_en_o = 1;
                q_reg_sel_o = 1;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 1;
                PE_AU_B_sel_o = 2;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            LAST_MUL_M_PRIME_0_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 1;
                M_prime_0_reg_sel_o = 1;
                q_reg_en_o = 1;
                q_reg_sel_o = 1;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 1;
                PE_AU_B_sel_o = 2;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 1;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            MUL_A_B_1_1: begin
                A_reg_en_o = 1;
                A_reg_sel_o = 1;
                B_reg_en_o = 1;
                B_reg_sel_o = 1;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b110000101;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 1;
                mem_M_reg_shift_o = 1;
                done = 0;
                mul_counter_reset = 1;
                mul_counter_en = 0;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            FIRST_MUL_M_0_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 1;
                M_reg_sel_o = 1;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 1;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 1;
                CREG_sel = 2;
                OPMODE = 9'b110000101;
                PE_AU_A_sel_o = 2;
                PE_AU_B_sel_o = 1;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 1;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 1;
            end
            SECOND_MUL_M_0_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 1;
                M_reg_sel_o = 1;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 1;
                q_reg_sel_o = 1;
                RES_reg_en_o = 1;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 2;
                PE_AU_B_sel_o = 2;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 1;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            MUL_M_0_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 1;
                M_reg_sel_o = 1;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 1;
                q_reg_sel_o = 1;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 2;
                PE_AU_B_sel_o = 2;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 1;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            LAST_MUL_M_0_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 1;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 1;
                q_reg_sel_o = 1;
                RES_reg_en_o = 0;
                CREG_en_o = 1;
                CREG_sel = 3;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 2;
                PE_AU_B_sel_o = 2;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 1;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 2;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 1;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            MUL_A_B_1_2: begin
                A_reg_en_o = 1;
                A_reg_sel_o = 1;
                B_reg_en_o = 1;
                B_reg_sel_o = 1;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b111100101;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 1;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            MUL_A_B_1: begin
                A_reg_en_o = 1;
                A_reg_sel_o = 1;
                B_reg_en_o = 1;
                B_reg_sel_o = 1;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 1;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            LAST_MUL_A_B_1: begin
                A_reg_en_o = 1;
                A_reg_sel_o = 1;
                B_reg_en_o = 1;
                B_reg_sel_o = 0;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 1;
                CREG_sel = 2;
                OPMODE = 9'b110100101;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 1;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 1;
                mul_counter_en = 0;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            FIRST_MUL_M_1_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 1;
                M_reg_sel_o = 1;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 1;
                q_reg_sel_o = 1;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 2;
                PE_AU_B_sel_o = 2;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 1;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 1;
            end
            MUL_M_1_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 1;
                M_reg_sel_o = 1;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 1;
                q_reg_sel_o = 1;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 2;
                PE_AU_B_sel_o = 2;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 1;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            LAST_MUL_M_1_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 1;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 1;
                q_reg_sel_o = 1;
                RES_reg_en_o = 0;
                CREG_en_o = 1;
                CREG_sel = 1;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 2;
                PE_AU_B_sel_o = 2;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 1;
                done = 0;
                mul_counter_reset = 1;
                mul_counter_en = 0;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 1;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            FIRST_MUL_A_B: begin
                A_reg_en_o = 1;
                A_reg_sel_o = 1;
                B_reg_en_o = 1;
                B_reg_sel_o = 1;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b111100101;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 1;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 1;
                M_delay_line_en = 0;
            end
            MUL_A_B: begin
                A_reg_en_o = 1;
                A_reg_sel_o = 1;
                B_reg_en_o = 1;
                B_reg_sel_o = 1;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 1;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            LAST_MUL_A_B: begin
                A_reg_en_o = 1;
                A_reg_sel_o = 1;
                B_reg_en_o = 1;
                B_reg_sel_o = 0;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 1;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 1;
                mul_counter_en = 0;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            FIRST_MUL_M_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 1;
                M_reg_sel_o = 1;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 1;
                q_reg_sel_o = 1;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 2;
                PE_AU_B_sel_o = 2;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 1;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 1;
            end
            MUL_M_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 1;
                M_reg_sel_o = 1;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 1;
                q_reg_sel_o = 1;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 2;
                PE_AU_B_sel_o = 2;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 1;
                done = 0;
                mul_counter_reset = 0;
                mul_counter_en = 1;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            LAST_MUL_M_Q: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 1;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 1;
                q_reg_sel_o = 1;
                RES_reg_en_o = 0;
                CREG_en_o = 1;
                CREG_sel = 1;
                OPMODE = 9'b000100101;
                PE_AU_A_sel_o = 2;
                PE_AU_B_sel_o = 2;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 1;
                done = 0;
                mul_counter_reset = 1;
                mul_counter_en = 0;
                mul_counter_init = 0;
                FIOS_counter_reset = 0;
                FIOS_counter_en = 1;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
            DONE: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b001100000;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 0;
                done = 1;
                mul_counter_reset = 1;
                mul_counter_en = 0;
                mul_counter_init = 0;
                FIOS_counter_reset = 1;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 1;
                M_delay_line_en = 0;
            end
            default: begin
                A_reg_en_o = 0;
                A_reg_sel_o = 0;
                B_reg_en_o = 0;
                B_reg_sel_o = 0;
                M_reg_en_o = 0;
                M_reg_sel_o = 0;
                M_prime_0_reg_en_o = 0;
                M_prime_0_reg_sel_o = 0;
                q_reg_en_o = 0;
                q_reg_sel_o = 0;
                RES_reg_en_o = 0;
                CREG_en_o = 0;
                CREG_sel = 0;
                OPMODE = 9'b000000000;
                PE_AU_A_sel_o = 0;
                PE_AU_B_sel_o = 0;
                mem_B_reg_shift = 0;
                mem_M_reg_shift_o = 0;
                done = 0;
                mul_counter_reset = 1;
                mul_counter_en = 0;
                mul_counter_init = 0;
                FIOS_counter_reset = 1;
                FIOS_counter_en = 0;
                B_delay_line_en_o = 0;
                M_delay_line_en = 0;
            end
        endcase
    end

    // Polynomial multiplication cycles counter
    always_ff @(posedge clock_i) begin
        if (mul_counter_reset)
            mul_count <= 0;
        else if (mul_counter_en) begin
            if (mul_counter_init == 1)
                mul_count <= 1;
            else if (mul_counter_init == 2)
                mul_count <= 2;
            else
                mul_count <= mul_count+1;
        end else
            mul_count <= mul_count;
    end

    // FIOS outer loop counter
    always_ff @(posedge clock_i) begin
        if (FIOS_counter_reset)
            FIOS_count <= 0;
        else if (FIOS_counter_en)
            FIOS_count <= FIOS_count+1;
        else
            FIOS_count <= FIOS_count;
    end

    // PE Column specific LAMBDA multiplication enable sequence
    reg [N-1:0] LAMBDA_MUL_sel_list_reg;
    
    generate
        genvar j;

        for(j = 0; j < N; j++) begin
            assign LAMBDA_MUL_sel_list_reg[j] = (((((COLUMN_INDEX+j)%N)+(((COLUMN_INDEX+j)%N)%2)*N)/2 + (((COLUMN_INDEX+N-j)%N)+(((COLUMN_INDEX+N-j)%N)%2)*N)/2) >= N);
        end
    endgenerate

    assign LAMBDA_MUL_sel_o = LAMBDA_MUL_sel_list_reg[mul_count];

    // Delayed control signals
    always_ff @(posedge clock_i) begin
        done_reg <= done;
    end

    assign OPMODE_o = OPMODE;

    // Sign extension control signals
    assign sign_ext_A_en_o = (LINE_INDEX == S-1);
    assign sign_ext_B_en_o = (FIOS_count == S-2);
    assign sign_ext_M_en_o = (FIOS_count == S-2);

    assign mem_B_reg_shift_o = start_i | mem_B_reg_shift;
    assign done_o = done_reg;

    reg [1:0] CREG_sel_reg;
    always @(posedge clock_i)
        CREG_sel_reg <= CREG_sel;

    always_comb begin
        if ((FIOS_count == S-2) & ~(CREG_sel_reg == 1))
            CREG_reg_en_o = 0;
        else
            CREG_reg_en_o = 1;
    end

    always_comb begin
        if(FIOS_count == S-2)
            CREG_sel_o = 3;
        else
            CREG_sel_o = CREG_sel;
    end

    assign M_delay_line_en_o = M_delay_line_en | done_reg;

endmodule
