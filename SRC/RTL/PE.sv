`timescale 1ns / 1ps

module PE #(parameter LAMBDA = 2) (
        input clock_i, reset_i,
        
        input C_reg_high_en_i,
        input C_reg_low_en_i,
        input C_reg_low_input_sel_i,

        input q_reg_en_i,
        input q_reg_input_sel_i,
        
        input TEMP_reg_en_i,

        input LAMBDA_mul_sel_i,
        
        input [1:0] mux_A_sel_i,
        input [1:0] mux_B_sel_i,
        input [1:0] mux_C_sel_i,
        
        input outer_loop_signext_i,
        input inner_loop_signext_i,
       
        input  [8:0]  OPMODE_i,
        
        input DSP_CREG_en_i,
        
        input [16:0] A_i,
        input [16:0] M_prime_0_i,
        input [16:0] M_i,
        
        input [16:0] B_i,
        
        input [16:0] prev_q_reg_output_i,
        input [16:0] prev_C_reg_low_output_i,
        input [16:0] prev_RES_low_i,
        
        output [16:0] q_reg_output_o,
        
        output [16:0] C_reg_low_output_o,
        
        output [47:0] RES_o
        
    );
    
    reg [17:0] mux_A_output;
    reg [17:0] mux_B_output;
    reg [47:0] mux_C_output;
    
    reg [26:0] LAMBDA_mul_input;
    reg [26:0] LAMBDA_mul_output;
    
    wire [26:0] DSP_A_input;
    reg [17:0] DSP_B_input;
    wire [47:0] DSP_C_input;
    
    reg [16:0] q_reg;
    reg [16:0] q_reg_input;
    
    reg [47:0] TEMP_reg;
    
    wire [47:0] RES;
    
    reg [47:0] C_reg;
    
    
    assign q_reg_input = (q_reg_input_sel_i) ? prev_q_reg_output_i : prev_RES_low_i;
    
    always_ff @ (posedge clock_i) begin
    
        if (reset_i)
            q_reg <= 0;
        else if (q_reg_en_i)
            q_reg <= q_reg_input;
        else
            q_reg <= q_reg;
    
    end
    
    always_comb begin
        case (mux_A_sel_i)
            0 : mux_A_output = (outer_loop_signext_i) ? {A_i[16], A_i} : A_i;
            1 : mux_A_output = M_prime_0_i;
            2 : mux_A_output = (inner_loop_signext_i) ? {M_i[16], M_i} : M_i;
            default : mux_A_output = A_i;
        endcase
    end
    
    assign LAMBDA_mul_input = {{9{mux_A_output[17]}}, mux_A_output};
    
    assign LAMBDA_mul_output = LAMBDA*LAMBDA_mul_input;
    
    assign DSP_A_input = (LAMBDA_mul_sel_i) ? LAMBDA_mul_output : LAMBDA_mul_input;
    
    
    always_comb begin
        case (mux_B_sel_i)
            0 : mux_B_output = (inner_loop_signext_i) ? {B_i[16], B_i} : B_i;
            1 : mux_B_output = RES[16:0];
            2 : mux_B_output = C_reg[16:0];
            3 : mux_B_output = q_reg;
            default : mux_B_output = B_i;
        endcase
    end
    
    assign DSP_B_input = mux_B_output;
    
    
    always_comb begin
        case (mux_C_sel_i)
            0 : mux_C_output = TEMP_reg;
            1 : mux_C_output = C_reg;
            default : mux_C_output = TEMP_reg;
        endcase
    end
    
    assign DSP_C_input = mux_C_output;
    
    
    PE_AU #(.ABREG(1), .MREG(0)) PE_AU_inst (
     
        .clock_i(clock_i),
        
        .OPMODE_i(OPMODE_i),
        
        .CREG_en_i(DSP_CREG_en_i),
        
        .A_i(DSP_A_input),
        
        .B_i(DSP_B_input),
        
        .C_i(DSP_C_input),
        
        .PCIN_i(),
        
        .P_o(RES),
        
        .PCOUT_o()
    
    );
    
    always_ff @ (posedge clock_i) begin
    
        if (reset_i)
            C_reg[47:17] <= 0;
        else if (C_reg_high_en_i)
            C_reg[47:17] <= RES[47:17];
        else
            C_reg[47:17] <= C_reg[47:17];
    
    end
    
    wire [16:0] C_reg_low_input;
    
    assign C_reg_low_input = (C_reg_low_input_sel_i) ? prev_C_reg_low_output_i : prev_RES_low_i;
    
    always_ff @ (posedge clock_i) begin
        
        if (reset_i)
            C_reg[16:0] <= 0;
        else if (C_reg_low_en_i)
            C_reg[16:0] <= C_reg_low_input;
        else
            C_reg[16:0] <= C_reg[16:0];
        
    end
    
    
    always_ff @ (posedge clock_i) begin
    
        if (reset_i)
            TEMP_reg <= 0;
        else if (TEMP_reg_en_i)
            TEMP_reg <= RES;
        else
            TEMP_reg <= TEMP_reg;
    
    end
    
    assign q_reg_output_o = q_reg;
    assign C_reg_low_output_o = C_reg[16:0];
    assign RES_o = RES;
    
endmodule
