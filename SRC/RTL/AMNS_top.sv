`timescale 1ns / 1ps


module AMNS_top #(parameter  s = 4,
                             N = 5,
                             LAMBDA = 2,
                 // WORD_WIDTH up to 32 bits
                 WORD_WIDTH = 17,
             localparam int   PE_DELAY = 6,
                        int   PE_NB = (2*s+2+1)/PE_DELAY+1) (
                        
        input clock_i, reset_i,
        
        input start_i,
        
        
        input [WORD_WIDTH-1:0] BRAM_dout_i, // Data Out Bus (optional)

        output [WORD_WIDTH-1:0] BRAM_din_o, // Data In Bus (optional)
    
        output BRAM_we_o, // Byte Enables (optional)
    
        output [31:0] BRAM_addr_o, // Address Signal (required)
            
        output BRAM_en_o, // Chip Enable Signal (optional)
        
        
        output done_o

    );
    

    wire FIOS_start;
       
    wire RES_push;
    
    wire FIOS_done;
    
    
    wire [$clog2(4*N*s)-1:0] BRAM_addr;
    
    wire [WORD_WIDTH-1:0] RES;

    reg [WORD_WIDTH-1:0] BRAM_dout_reg;
    
    always @ (posedge clock_i)
        BRAM_dout_reg <= BRAM_dout_i;
    
    
    // The top_control FSM controls the loading of operands
    // from the bridge BRAM to operand registers p_prime_0, a, b and p.
    // The FIOS_control FSM controls the initial loading of operand sections
    // into the PEs using the b_fetch, p_fetch and a_shift signals.
    
    reg M_prime_0_reg_en;
    wire M_prime_0_rot;
    
    reg [N*WORD_WIDTH-1:0] M_prime_0_reg;
    
    always @ (posedge clock_i) begin
        
        if (reset_i)
            M_prime_0_reg <= 0;
        else if (M_prime_0_reg_en)
            M_prime_0_reg <= {BRAM_dout_reg, M_prime_0_reg[N*WORD_WIDTH-1:WORD_WIDTH]};
        else if (M_prime_0_rot)
            M_prime_0_reg <= {M_prime_0_reg[WORD_WIDTH-1:0], M_prime_0_reg[N*WORD_WIDTH-1:WORD_WIDTH]};
        else
            M_prime_0_reg <= M_prime_0_reg;
    
    end
    
    reg M_reg_en;
    reg [N*s*WORD_WIDTH-1:0] M_reg;

    wire M_shift;
        
    reg A_reg_en;
    reg [N*s*WORD_WIDTH-1:0] A_reg;
    
    wire A_rot [0:s-1];
    
    reg B_reg_en;
    reg [N*s*WORD_WIDTH-1:0] B_reg;
    
    wire B_shift;
    
    genvar i;
    
    generate
        for (i = 0; i < s; i++) begin
        
            always @ (posedge clock_i) begin
            
                if (reset_i)
                    A_reg[(i+1)*N*WORD_WIDTH-1:i*N*WORD_WIDTH] <= 0;
                else if (A_reg_en)
                    A_reg[(i+1)*N*WORD_WIDTH-1:i*N*WORD_WIDTH] <= {(i == s-1) ? BRAM_dout_reg : A_reg[((i+1)*N+1)*WORD_WIDTH:(i+1)*N*WORD_WIDTH], A_reg[(i+1)*N*WORD_WIDTH-1:(i*N+1)*WORD_WIDTH]};
                else if (A_rot[i])
                    A_reg[(i+1)*N*WORD_WIDTH-1:i*N*WORD_WIDTH] <= {A_reg[(i*N+1)*WORD_WIDTH-1:i*N*WORD_WIDTH], A_reg[(i+1)*N*WORD_WIDTH-1:(i*N+1)*WORD_WIDTH]};
                else
                    A_reg[(i+1)*N*WORD_WIDTH-1:i*N*WORD_WIDTH] <= A_reg[(i+1)*N*WORD_WIDTH-1:i*N*WORD_WIDTH];
            
            end
            
//            always @ (posedge clock_i) begin
            
//                if (reset_i)
//                    M_reg[(i+1)*N*17-1:i*N*17] <= 0;
//                else if (M_reg_en)
//                    M_reg[(i+1)*N*17-1:i*N*17] <= {(i == s-1) ? BRAM_dout_reg : M_reg[((i+1)*N+1)*17:(i+1)*N*17], M_reg[(i+1)*N*17-1:(i*N+1)*17]};
//                else if (M_rot[i])
//                    M_reg[(i+1)*N*17-1:i*N*17] <= {M_reg[(i*N+1)*17-1:i*N*17], M_reg[(i+1)*N*17-1:(i*N+1)*17]};
//                else
//                    M_reg[(i+1)*N*17-1:i*N*17] <= M_reg[(i+1)*N*17-1:i*N*17];
            
//            end
                      
        end
    endgenerate
    
    always @ (posedge clock_i) begin
        
        if (reset_i)
            M_reg <= 0;
        else if (M_reg_en || M_shift)
            M_reg <= {BRAM_dout_reg, M_reg[N*s*WORD_WIDTH-1:WORD_WIDTH]};
        else
            M_reg <= M_reg;
    end
    
    always @ (posedge clock_i) begin
        
        if (reset_i)
            B_reg <= 0;
        else if (B_reg_en || B_shift)
            B_reg <= {BRAM_dout_reg, B_reg[N*s*WORD_WIDTH-1:WORD_WIDTH]};
        else
            B_reg <= B_reg;
    
    end
    
    // RES_reg stores the result of the FIOS multiplication
    // once result sections are provided. Result sections
    // are then loaded by the top_control FSM into the bridge BRAM.

    reg [N*s*WORD_WIDTH-1:0] RES_reg;

    always @ (posedge clock_i) begin
    
        if (reset_i)
            RES_reg <= 0;
        else if (BRAM_we_o || RES_push)
            RES_reg <= {RES, RES_reg[N*s*WORD_WIDTH-1:WORD_WIDTH]};
        else
            RES_reg <= RES_reg;
    
    end
    

    AMNS_top_control #(.s(s), .N(N)) AMNS_top_control_inst (
        .clock_i(clock_i), .reset_i(reset_i),
        
        .start_i(start_i),
        
        .FIOS_done_i(FIOS_done),
        
        
        .M_prime_0_reg_en_o(M_prime_0_reg_en),
        .M_reg_en_o(M_reg_en),
        .A_reg_en_o(A_reg_en),
        .B_reg_en_o(B_reg_en),
        
        .FIOS_start_o(FIOS_start),
        
        
        .BRAM_we_o(BRAM_we_o),

        .BRAM_addr_o(BRAM_addr),

        .BRAM_en_o(BRAM_en_o),

        
        .done_o(done_o)
    );

    reg FIOS_start_reg;
    
    always_ff @ (posedge clock_i) begin
    
        if (reset_i)
            FIOS_start_reg <= 0;
        else
            FIOS_start_reg <= FIOS_start;
    
    end

    reg [N*WORD_WIDTH-1:0] B_input;
    
    always_comb begin
        for (int j = 0; j < N; j++) begin
            B_input[j*WORD_WIDTH+:WORD_WIDTH] = B_reg[s*j*WORD_WIDTH+:WORD_WIDTH];
        end
    end
    
    reg [s*WORD_WIDTH-1:0] A_input;
    
    always_comb begin
        for (int j = 0; j < s; j++) begin
            A_input[j*WORD_WIDTH+:WORD_WIDTH] = A_reg[N*j*WORD_WIDTH+:WORD_WIDTH];
        end
    end
    
    POLY_FIOS_MM #(.s(s), .N(N), .LAMBDA(LAMBDA)) POLY_FIOS_inst (
        .clock_i(clock_i),
        .reset_i(reset_i),
        
        .FIOS_start_i(FIOS_start_reg),
        
        .A_i(A_input),
        .B_i(B_input),
        
        .M_prime_0_i(M_prime_0_reg[16:0]),
        .M_i(M_reg[16:0]),
        
        
        .A_rot_o(A_rot[0]),
        .B_shift_o(B_shift),
        
        .M_prime_0_rot_o(M_prime_0_rot),
        .M_shift_o(M_shift),
        
        .FIOS_done_o(FIOS_done)
    );
    

    assign BRAM_addr_o = {{(32-$clog2(4*N*s)){1'b0}}, BRAM_addr};

    assign BRAM_din_o = RES_reg[16:0];

endmodule
