`timescale 1ns / 1ps


module POLY_FIOS_MM #(parameter s = 5,
                                N = 5,
                                LAMBDA = 2) (
        input clock_i, reset_i,
        
        input FIOS_start_i,
        
        input [s*17-1:0] A_i,
        input [N*17-1:0] B_i,
        
        input [17-1:0] M_prime_0_i,
        input [17-1:0] M_i,
        
        output A_rot_o,
        output B_shift_o,
        
        output M_prime_0_rot_o,
        output M_shift_o,
        
        output FIOS_done_o
    );
    
    wire B_reg_en;
    wire B_rot;
    
    reg [N*17-1:0] B_reg [0:s-1];
    
    always_ff @ (posedge clock_i) begin
    
        if (reset_i)
            B_reg[0] <= 0;
        else if (B_reg_en)
            B_reg[0] <= B_i;
        else if (B_rot)
            B_reg[0] <= {B_reg[(N-1)*17-1:0], B_reg[N*17-1:(N-1)*17]};
        else
            B_reg <= B_reg;
    
    end
    
    wire LAMBDA_mul_sel_reg_reset_0 [0:s-1];
    wire LAMBDA_mul_sel_reg_reset_1 [0:s-1];
    wire LAMBDA_mul_sel_reg_reset_others [0:s-1];
    
    wire C_reg_high_en [0:s-1];
    wire C_reg_low_en [0:s-1];
    wire C_reg_low_input_sel [0:s-1];
    
    wire q_reg_en [0:s-1];
    wire q_reg_input_sel [0:s-1];
    
    wire TEMP_reg_en [0:s-1];
    
    wire FSM_LAMBDA_mul_sel;
    wire LAMBDA_mul_sel [0:s-1] [0:N-1];
    reg LAMBDA_mul_sel_reg [0:s-1] [0:N-2];
    
    wire [1:0] mux_A_sel [0:s-1];
    wire [1:0] mux_B_sel [0:s-1];
    wire [1:0] mux_C_sel [0:s-1];
    
    wire inner_loop_signext [0:s-1];
    
    wire [8:0] OPMODE [0:s-1];
    
    wire DSP_CREG_en [0:s-1];
    
    wire [16:0] q_reg_output [0:s-1] [0:N-1];
    wire [16:0] C_reg_low_output [0:s-1] [0:N-1];
    wire [47:0] RES [0:s-1] [0:N-1];
    

    POLY_FIOS_control #(.s(s), .N(N)) POLY_FIOS_control_inst (
        .clock_i(clock_i),
        .reset_i(reset_i),
        
        .FIOS_start_i(FIOS_start_i),
        
        
        .A_rot_o(A_rot_o),
        .B_shift_o(B_shift_o),
        
        .M_prime_0_rot_o(M_prime_0_rot_o),
        .M_shift_o(M_shift_o),
        
        .B_reg_en_o(B_reg_en),
        .B_rot_o(B_rot),
        
        .C_reg_high_en_o(C_reg_high_en),
        .C_reg_low_en_o(C_reg_low_en),
        .C_reg_low_input_sel_o(C_reg_low_input_sel),
        
        .q_reg_en_o(q_reg_en),
        .q_reg_input_sel_o(q_reg_input_sel),
        
        .TEMP_reg_en_o(TEMP_reg_en),
        
        .LAMBDA_mul_sel_reg_reset_0_o(LAMBDA_mul_sel_reg_reset_0),
        .LAMBDA_mul_sel_reg_reset_1_o(LAMBDA_mul_sel_reg_reset_1),
        .LAMBDA_mul_sel_reg_reset_others_o(LAMBDA_mul_sel_reg_reset_others),
        
        .FSM_LAMBDA_mul_sel_o(FSM_LAMBDA_mul_sel),
                
        .mux_A_sel_o(mux_A_sel),
        .mux_B_sel_o(mux_B_sel),
        .mux_C_sel_o(mux_C_sel),

        .inner_loop_signext_o(inner_loop_signext),

        .OPMODE_o(OPMODE),
        
        .DSP_CREG_en_o(DSP_CREG_en),
        
        .FIOS_done_o(FIOS_done_o)
    );


    assign LAMBDA_mul_sel[N-1] = 0;
    
    genvar i;
    genvar j;
    
    generate
        for (i = 0; i < N-1; i++) begin : LAMBDA_mul_sel_reg_gen
    
            if (i == 0) begin
            
                always @ (posedge clock_i) begin
                
                    if (LAMBDA_mul_sel_reg_reset_0)
                        LAMBDA_mul_sel_reg[i] <= 0;
                    else
                        LAMBDA_mul_sel_reg[i] <= (i == 0) ? FSM_LAMBDA_mul_sel : LAMBDA_mul_sel_reg[i-1];
                
                end
                
            end else if (i == 1) begin
            
                always @ (posedge clock_i) begin
                
                    if (LAMBDA_mul_sel_reg_reset_1)
                        LAMBDA_mul_sel_reg[i] <= 0;
                    else
                        LAMBDA_mul_sel_reg[i] <= LAMBDA_mul_sel_reg[i-1];
                
                end
            
            end else if (i < N-1) begin
            
                always @ (posedge clock_i) begin
                
                    if (LAMBDA_mul_sel_reg_reset_others)
                        LAMBDA_mul_sel_reg[i] <= 0;
                    else
                        LAMBDA_mul_sel_reg[i] <= LAMBDA_mul_sel_reg[i-1];
                
                end
            
            end
            
            assign LAMBDA_mul_sel[i] = LAMBDA_mul_sel_reg[i];
            
        end
        
        
        for (j = 0; j < s; j++) begin
        
            for (i = 0; i < N; i++) begin : PE_gen
                
                PE PE_inst (
                    .clock_i(clock_i),
                    .reset_i(reset_i),
                    
                    .C_reg_high_en_i(C_reg_high_en[j]),
                    .C_reg_low_en_i(C_reg_low_en[j]),
                    .C_reg_low_input_sel_i(C_reg_low_input_sel[j]),
                    
                    .q_reg_en_i(q_reg_en[j]),
                    .q_reg_input_sel_i(q_reg_input_sel[j]),
                    
                    .TEMP_reg_en_i(TEMP_reg_en[j]),
                    
                    .LAMBDA_mul_sel_i(LAMBDA_mul_sel[j][i]),
                    
                    .mux_A_sel_i(mux_A_sel[j]),
                    .mux_B_sel_i(mux_B_sel[j]),
                    .mux_C_sel_i(mux_C_sel[j]),
                    
                    .outer_loop_signext_i((j == s-1) ? 1'b1 : 1'b0),
                    .inner_loop_signext_i(inner_loop_signext[j]),
                    
                    .OPMODE_i(OPMODE[j]),
                    
                    .DSP_CREG_en_i(DSP_CREG_en[j]),
                    
                    .A_i(A_i[j*17+:17]),
                    .M_prime_0_i(M_prime_0_i[j]),
                    .M_i(M_i[j]),
                    
                    .B_i(B_reg[j][i*17+:17]),
                    
                    .prev_C_reg_low_output_i((i == 0) ? C_reg_low_output[j][N-1] : C_reg_low_output[j][i-1]),
                    .prev_RES_low_i((i == 0) ? RES[j][N-1][16:0] : RES[j][i-1][16:0]),
                    .prev_q_reg_output_i((i == 0) ? q_reg_output[j][N-1] : q_reg_output[j][i-1]),
                    
                    .q_reg_output_o(q_reg_output[j][i]),
                    .C_reg_low_output_o(C_reg_low_output[j][i]),
                    .RES_o(RES[j][i])
                );
    
            end
            
        end
            
    endgenerate
    
endmodule
