`timescale 1ns / 1ps


module POLY_FIOS_control  #(parameter s = 4,
                                      N = 5) (
        input clock_i,
        input reset_i,
        
        input FIOS_start_i,
        
        
        output reg A_rot_o,
        output reg B_shift_o,
        
        output reg M_prime_0_rot_o,
        output reg M_shift_o,
        
        output reg B_reg_en_o,
        output reg B_rot_o,
        
        output reg C_reg_high_en_o,
        output reg C_reg_low_en_o,
        output reg C_reg_low_input_sel_o,
        
        output reg q_reg_en_o,
        output reg q_reg_input_sel_o,
        
        output reg TEMP_reg_en_o,
        
        output reg LAMBDA_mul_sel_reg_reset_0_o,
        output reg LAMBDA_mul_sel_reg_reset_1_o,
        output reg LAMBDA_mul_sel_reg_reset_others_o,
        
        output reg FSM_LAMBDA_mul_sel_o,
        
        output reg [1:0] mux_A_sel_o,
        output reg [1:0] mux_B_sel_o,
        output reg [1:0] mux_C_sel_o,
                 
        output reg inner_loop_signext_o,
        
        output reg [8:0] OPMODE_o,
        
        output reg DSP_CREG_en_o,
        
        output reg FIOS_done_o

    );
    
    reg mul_counter_reset;
    reg mul_counter_en;
    reg [$clog2(N+1)-1:0] mul_counter;
    
    reg inner_loop_counter_reset;
    reg inner_loop_counter_en;
    reg [$clog2(s+1)-1:0] inner_loop_counter;
    
    reg TEMP_reg_en;
    reg FSM_LAMBDA_mul_sel;
    
    
    localparam [4:0] INIT = 5'b00000,
                     MUL_A0_B0 = 5'b00001,
                     MUL_A0_B0_END = 5'b00010,
                     TEMP_0 = 5'b00011,
                     MUL_M_PRIME_0_C0_BEGIN = 5'b00100,
                     MUL_M_PRIME_0_C0 = 5'b00101,
                     MUL_M_PRIME_0_C0_END = 5'b00110,
                     TEMP_1 = 5'b00111,
                     MUL_M0_Q_BEGIN = 5'b01000,
                     MUL_M0_Q = 5'b01001,
                     MUL_M0_Q_END = 5'b01010,
                     MUL_A0_B1_BEGIN = 5'b01011,
                     MUL_A0_B1 = 5'b01100,
                     MUL_A0_B1_END = 5'b01101,
                     MUL_M1_Q = 5'b01110,
                     MUL_M1_Q_END = 5'b01111,
                     MUL_A_B_BEGIN = 5'b10000,
                     MUL_A_B = 5'b10001,
                     MUL_A_B_END = 5'b10010,
                     MUL_M_Q = 5'b10011,
                     MUL_M_Q_END = 5'b10100,
                     SHIFT = 5'b10101,
                     DONE = 5'b10110;
                     
    reg [4:0] current_state, future_state;
    
    always @ (posedge clock_i) begin
        if (reset_i)
            current_state <= INIT;
        else
            current_state <= future_state;
    end
    
    
    always_comb begin
        case (current_state)
            INIT : begin
                       if (FIOS_start_i)
                           future_state = MUL_A0_B0;
                       else
                           future_state = INIT;
                   end
            MUL_A0_B0 : begin
                            if (mul_counter == N-2)
                                future_state = MUL_A0_B0_END;
                            else
                                future_state = MUL_A0_B0;
                        end
            MUL_A0_B0_END : future_state = TEMP_0;
            TEMP_0 : future_state = MUL_M_PRIME_0_C0_BEGIN;
            MUL_M_PRIME_0_C0_BEGIN : future_state = MUL_M_PRIME_0_C0;
            MUL_M_PRIME_0_C0 : begin
                if (mul_counter == N-2)
                    future_state = MUL_M_PRIME_0_C0_END;
                else
                    future_state = MUL_M_PRIME_0_C0;
            end
            MUL_M_PRIME_0_C0_END : future_state = TEMP_1;
            TEMP_1 : future_state = MUL_M0_Q_BEGIN;
            MUL_M0_Q_BEGIN : future_state = MUL_M0_Q;
            MUL_M0_Q : begin
                if (mul_counter == N-2)
                    future_state = MUL_M0_Q_END;
                else
                    future_state = MUL_M0_Q;
            end
            MUL_M0_Q_END : future_state = MUL_A0_B1_BEGIN;
            MUL_A0_B1_BEGIN : begin
                if (mul_counter == N-4)
                    future_state = MUL_A0_B1_END;
                else
                    future_state = MUL_A0_B1;
            end
            MUL_A0_B1 : begin
                if (mul_counter == N-4)
                    future_state = MUL_A0_B1_END;
                else
                    future_state = MUL_A0_B1;
            end
            MUL_A0_B1_END : future_state = MUL_M1_Q;
            MUL_M1_Q : begin
                if (mul_counter == N-2)
                    future_state = MUL_M1_Q_END;
                else
                    future_state = MUL_M1_Q;
            end
            MUL_M1_Q_END : future_state = MUL_A_B_BEGIN;
            MUL_A_B_BEGIN : future_state = MUL_A_B;
            MUL_A_B : begin
                if (mul_counter == N-2)
                    future_state = MUL_A_B_END;
                else
                    future_state = MUL_A_B;
            end
            MUL_A_B_END : future_state = MUL_M_Q;
            MUL_M_Q : begin
                if (mul_counter == N-2)
                    future_state = MUL_M_Q_END;
                else
                    future_state = MUL_M_Q;
            end
            MUL_M_Q_END : begin
                if (inner_loop_counter == s-1)
                    future_state = SHIFT;
                else
                    future_state = MUL_A_B_BEGIN;
            end
            SHIFT : future_state = DONE;
            DONE : future_state = INIT;
            default : future_state = INIT;
        endcase
    end


    always_comb begin
        case (current_state)
            INIT : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b1;
                
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b1;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
               
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b1;
               
                FSM_LAMBDA_mul_sel = 1'b0;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b000100000;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b1;
                mul_counter_en = 1'b0;
                
                inner_loop_counter_reset = 1'b1;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;                
            end
            MUL_A0_B0 : begin
                A_rot_o = 1'b1;
                B_shift_o = 1'b0;
                
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
                
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b1;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b0;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b0;
                mul_counter_en = 1'b1;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_A0_B0_END : begin
                A_rot_o = 1'b1;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b1;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b1;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b1;
                mul_counter_en = 1'b0;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            TEMP_0 : begin
                A_rot_o = 1'b1;
                B_shift_o = 1'b1;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b1;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b1;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b000000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b1;
                mul_counter_en = 1'b0;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;

                FIOS_done_o = 1'b0;
            end
            MUL_M_PRIME_0_C0_BEGIN : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b1;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b1;
                C_reg_low_en_o = 1'b1;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b1;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b0;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 1;
                mux_B_sel_o = 1;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b000000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b0;
                mul_counter_en = 1'b1;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_M_PRIME_0_C0 : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b1;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b0;
                
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b1;
                C_reg_low_input_sel_o = 1'b1;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b0;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 1;
                mux_B_sel_o = 2;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b0;
                mul_counter_en = 1'b1;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_M_PRIME_0_C0_END : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b1;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b0;
                
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b1;
                C_reg_low_input_sel_o = 1'b1;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b1;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 1;
                mux_B_sel_o = 2;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b1;
               
                mul_counter_reset = 1'b1;
                mul_counter_en = 1'b0;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            TEMP_1 : begin
                A_rot_o = 1'b1;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b1;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b1;
               
                FSM_LAMBDA_mul_sel = 1'b0;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b110000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b1;
                mul_counter_en = 1'b0;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_M0_Q_BEGIN : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b1;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b1;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b1;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b0;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 2;
                mux_B_sel_o = 1;
                mux_C_sel_o = 1;
               
                                               
                OPMODE_o = 9'b110000101;
                
                DSP_CREG_en_o = 1'b1;
               
                mul_counter_reset = 1'b0;
                mul_counter_en = 1'b1;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_M0_Q : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b1;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b1;
                q_reg_input_sel_o = 1'b1;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b0;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 2;
                mux_B_sel_o = 3;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b0;
                mul_counter_en = 1'b1;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_M0_Q_END : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b1;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b1;
                q_reg_input_sel_o = 1'b1;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b1;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 2;
                mux_B_sel_o = 3;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b1;
                mul_counter_en = 1'b0;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b1;
               
                FIOS_done_o = 1'b0;
            end
            MUL_A0_B1_BEGIN : begin
                A_rot_o = 1'b1;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b1;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b0;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b111100101;
                
                DSP_CREG_en_o = 1'b1;
               
                mul_counter_reset = 1'b0;
                mul_counter_en = 1'b1;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_A0_B1 : begin
                A_rot_o = 1'b1;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b1;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b0;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b0;
                mul_counter_en = 1'b1;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_A0_B1_END : begin
                A_rot_o = 1'b1;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b1;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b1;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b1;
                mul_counter_en = 1'b0;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_M1_Q : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b1;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b1;
                q_reg_input_sel_o = 1'b1;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b0;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 2;
                mux_B_sel_o = 3;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b0;
                mul_counter_en = 1'b1;
               
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_M1_Q_END : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b1;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b1;
                q_reg_input_sel_o = 1'b1;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b1;
               
                FSM_LAMBDA_mul_sel = 1'b0;
               
                mux_A_sel_o = 2;
                mux_B_sel_o = 3;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b1;
                mul_counter_en = 1'b0;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b1;
               
                FIOS_done_o = 1'b0;
            end
            MUL_A_B_BEGIN : begin
                A_rot_o = 1'b1;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b1;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b0;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b001100101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b0;
                mul_counter_en = 1'b1;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_A_B : begin
                A_rot_o = 1'b1;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b1;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b0;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b0;
                mul_counter_en = 1'b1;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_A_B_END : begin
                A_rot_o = 1'b1;
                B_shift_o = 1'b1;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b1;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b1;
                mul_counter_en = 1'b0;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_M_Q : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b1;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b1;
                q_reg_input_sel_o = 1'b1;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b0;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 2;
                mux_B_sel_o = 3;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b0;
                mul_counter_en = 1'b1;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            MUL_M_Q_END : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b1;
               
                B_reg_en_o = 1'b1;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b1;
                q_reg_input_sel_o = 1'b1;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b1;
               
                FSM_LAMBDA_mul_sel = 1'b1;
               
                mux_A_sel_o = 2;
                mux_B_sel_o = 3;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b010000101;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b1;
                mul_counter_en = 1'b0;
                
                inner_loop_counter_reset = 1'b0;
                inner_loop_counter_en = 1'b1;
               
                FIOS_done_o = 1'b0;
            end
            SHIFT : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b0;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b0;
               
                FSM_LAMBDA_mul_sel = 1'b0;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b001100000;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b1;
                mul_counter_en = 1'b0;
                
                inner_loop_counter_reset = 1'b1;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
            DONE : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b1;
               
                FSM_LAMBDA_mul_sel = 1'b0;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b000000000;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b1;
                mul_counter_en = 1'b0;
               
                FIOS_done_o = 1'b1;
            end
            default : begin
                A_rot_o = 1'b0;
                B_shift_o = 1'b0;
               
                M_prime_0_rot_o = 1'b0;
                M_shift_o = 1'b0;
               
                B_reg_en_o = 1'b0;
                B_rot_o = 1'b0;
               
                C_reg_high_en_o = 1'b0;
                C_reg_low_en_o = 1'b0;
                C_reg_low_input_sel_o = 1'b0;
               
                q_reg_en_o = 1'b0;
                q_reg_input_sel_o = 1'b0;
                
                TEMP_reg_en = 1'b0;
               
                LAMBDA_mul_sel_reg_reset_0_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_1_o = 1'b1;
                LAMBDA_mul_sel_reg_reset_others_o = 1'b1;
               
                FSM_LAMBDA_mul_sel = 1'b0;
               
                mux_A_sel_o = 0;
                mux_B_sel_o = 0;
                mux_C_sel_o = 0;
               
                                               
                OPMODE_o = 9'b000000000;
                
                DSP_CREG_en_o = 1'b0;
               
                mul_counter_reset = 1'b1;
                mul_counter_en = 1'b0;
                
                inner_loop_counter_reset = 1'b1;
                inner_loop_counter_en = 1'b0;
               
                FIOS_done_o = 1'b0;
            end
        endcase
    end
    
    
    always_ff @ (posedge clock_i) begin
        if (mul_counter_reset)
            mul_counter <= 0;
        else if (mul_counter_en)
            mul_counter <= mul_counter + 1;
        else
            mul_counter <= mul_counter;
    end
    
    always_ff @ (posedge clock_i) begin
        if (inner_loop_counter_reset)
            inner_loop_counter <= 0;
        else if (inner_loop_counter_en)
            inner_loop_counter <= inner_loop_counter+1;
        else
            inner_loop_counter <= inner_loop_counter;
    end
    
    
    always_ff @ (posedge clock_i)
        TEMP_reg_en_o <= TEMP_reg_en;
    
    
    assign FSM_LAMBDA_mul_sel_o = FSM_LAMBDA_mul_sel;
    
    assign inner_loop_signext_o = (inner_loop_counter == s-1) ? 1'b1 : 1'b0; 
    
endmodule
