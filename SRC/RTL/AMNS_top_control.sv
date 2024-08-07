`timescale 1ns / 1ps


module AMNS_top_control #(parameter s = 5,
				  N = 5) (
        input clock_i, reset_i,
        
        input start_i,
        
        input FIOS_done_i,
        
        
        output reg M_prime_0_reg_en_o,
        output reg M_reg_en_o,
        output reg A_reg_en_o,
        output reg B_reg_en_o,
        
        output reg FIOS_start_o,
        
    
        output reg BRAM_we_o, // Byte Enables (optional)
    
        output [$clog2(4*N*s)-1:0] BRAM_addr_o, // Address Signal (required)
    
        output reg BRAM_en_o, // Chip Enable Signal (optional)
        
        
        output reg done_o

    );
    
    
    localparam [3:0] INIT           = 4'b0000,
                     LOAD_M_PRIME_0 = 4'b0001,
                     LOAD_M         = 4'b0010,
                     LOAD_A         = 4'b0011,
                     LOAD_B         = 4'b0100,
                     FIOS_START     = 4'b0101,
                     FIOS_WAIT      = 4'b0110,
                     STORE_RES      = 4'b0111,
                     DONE           = 4'b1000;
                     
                     
    reg [3:0] current_state;
    reg [3:0] future_state;
    
    
    reg FIOS_start;
    
    reg M_prime_0_reg_en;
    reg M_reg_en;
    reg A_reg_en;
    reg B_reg_en;
    
    reg M_prime_0_reg_en_reg;
    reg M_reg_en_reg;
    reg A_reg_en_reg;
    reg B_reg_en_reg;
    
    reg BRAM_address_counter_reset;
    reg BRAM_address_counter_en;
    reg [$clog2(4*N*s)-1:0] BRAM_address_counter;
    
    
    always @ (posedge clock_i) begin
    
        if (reset_i)
            current_state <= INIT;
        else
            current_state <= future_state;
    
    end
    
    
    always_comb begin

        case (current_state)
            INIT           : begin
                                 if (start_i)
                                     future_state = LOAD_M_PRIME_0;
                                 else
                                     future_state = INIT;
                             end
            LOAD_M_PRIME_0 : begin
				                 if (BRAM_address_counter == N-1)
				                     future_state = LOAD_M;
				                 else
				                     future_state = LOAD_M_PRIME_0;
				             end
            LOAD_M         : begin
                                 if (BRAM_address_counter == N*s+N-1)
                                     future_state = LOAD_A;
                                 else
                                     future_state = LOAD_M;
                             end
            LOAD_A         : begin
                                 if (BRAM_address_counter == 2*N*s+N-1)
                                     future_state = LOAD_B;
                                 else
                                     future_state = LOAD_A;
                             end
            LOAD_B         : begin
                                 if (BRAM_address_counter == 3*N*s+N-1)
                                     future_state = FIOS_START;
                                 else
                                     future_state = LOAD_B;
                             end
            FIOS_START     : future_state = FIOS_WAIT;
            FIOS_WAIT      : begin
                                 if (FIOS_done_i)
                                     future_state = STORE_RES;
                                 else
                                     future_state = FIOS_WAIT;
                             end
            STORE_RES      : begin
                                 if (BRAM_address_counter == N*s-1)
                                     future_state = DONE;
                                 else
                                     future_state = STORE_RES;
                             end
            DONE           : future_state = DONE;
            default        : future_state = INIT;
        endcase
    
    end
    
    
    always_comb begin

        case (current_state)
            INIT           : begin
                                 M_prime_0_reg_en = 0;
                                 M_reg_en = 0;
                                 A_reg_en = 0;
                                 B_reg_en = 0;
                                 FIOS_start = 0; 
                                 BRAM_we_o = 0;
                                 BRAM_en_o = 0;
                                 BRAM_address_counter_reset = 1;
                                 BRAM_address_counter_en = 0;
                                 done_o = 0;
                             end
            LOAD_M_PRIME_0 : begin
                                 M_prime_0_reg_en = 1;
                                 M_reg_en = 0;
                                 A_reg_en = 0;
                                 B_reg_en = 0;
                                 FIOS_start = 0;
                                 BRAM_we_o = 0;
                                 BRAM_en_o = 1;
                                 BRAM_address_counter_reset = 0;
                                 BRAM_address_counter_en = 1;
                                 done_o = 0;
                             end
            LOAD_M         : begin
                                 M_prime_0_reg_en = 0;
                                 M_reg_en = 1;
                                 A_reg_en = 0;
                                 B_reg_en = 0;
                                 FIOS_start = 0;
                                 BRAM_we_o = 0;
                                 BRAM_en_o = 1;
                                 BRAM_address_counter_reset = 0;
                                 BRAM_address_counter_en = 1;
                                 done_o = 0;
                             end
            LOAD_A         : begin
                                 M_prime_0_reg_en = 0;
                                 M_reg_en = 0;
                                 A_reg_en = 1;
                                 B_reg_en = 0;
                                 FIOS_start = 0;
                                 BRAM_we_o = 0;
                                 BRAM_en_o = 1;
                                 BRAM_address_counter_reset = 0;
                                 BRAM_address_counter_en = 1;
                                 done_o = 0;
                             end
            LOAD_B         : begin
                                 M_prime_0_reg_en = 0;
                                 M_reg_en = 0;
                                 A_reg_en = 0;
                                 B_reg_en = 1;
                                 FIOS_start = 0;
                                 BRAM_we_o = 0;
                                 BRAM_en_o = 1;
                                 BRAM_address_counter_reset = 0;
                                 BRAM_address_counter_en = 1;
                                 done_o = 0;
                             end
            FIOS_START     : begin
                                 M_prime_0_reg_en = 0;
                                 M_reg_en = 0;
                                 A_reg_en = 0;
                                 B_reg_en = 0;
                                 FIOS_start = 1;
                                 BRAM_we_o = 0;
                                 BRAM_en_o = 0;
                                 BRAM_address_counter_reset = 1;
                                 BRAM_address_counter_en = 0;
                                 done_o = 0;
                             end
            FIOS_WAIT      : begin
                                 M_prime_0_reg_en = 0;
                                 M_reg_en = 0;
                                 A_reg_en = 0;
                                 B_reg_en = 0;
                                 FIOS_start = 0;
                                 BRAM_we_o = 0;
                                 BRAM_en_o = 0;
                                 BRAM_address_counter_reset = 1;
                                 BRAM_address_counter_en = 0;
                                 done_o = 0;
                             end
            STORE_RES      : begin
                                 M_prime_0_reg_en = 0;
                                 M_reg_en = 0;
                                 A_reg_en = 0;
                                 B_reg_en = 0;
                                 FIOS_start = 0;
                                 BRAM_we_o = 1;
                                 BRAM_en_o = 1;
                                 BRAM_address_counter_reset = 0;
                                 BRAM_address_counter_en = 1;
                                 done_o = 0;
                             end
            DONE           : begin
                                 M_prime_0_reg_en = 0;
                                 M_reg_en = 0;
                                 A_reg_en = 0;
                                 B_reg_en = 0;
                                 FIOS_start = 0;
                                 BRAM_we_o = 0;
                                 BRAM_en_o = 0;
                                 BRAM_address_counter_reset = 1;
                                 BRAM_address_counter_en = 0;
                                 done_o = 1;
                             end
            default        : begin
                                 M_prime_0_reg_en = 0;
                                 M_reg_en = 0;
                                 A_reg_en = 0;
                                 B_reg_en = 0;
                                 FIOS_start = 0;
                                 BRAM_we_o = 0;
                                 BRAM_en_o = 0;
                                 BRAM_address_counter_reset = 1;
                                 BRAM_address_counter_en = 0;
                                 done_o = 0;
                             end
        endcase
    
    end
    
    
    always @ (posedge clock_i) begin
        M_prime_0_reg_en_reg <= M_prime_0_reg_en;
        M_reg_en_reg <= M_reg_en;
        A_reg_en_reg <= A_reg_en;
        B_reg_en_reg <= B_reg_en;
    
        M_prime_0_reg_en_o <= M_prime_0_reg_en_reg;
        M_reg_en_o <= M_reg_en_reg;
        A_reg_en_o <= A_reg_en_reg;
        B_reg_en_o <= B_reg_en_reg;
        
        FIOS_start_o <= FIOS_start;
    end
    
    
    always @ (posedge clock_i) begin
    
        if (BRAM_address_counter_reset)
            BRAM_address_counter <= 0;
        else if (BRAM_address_counter_en)
            BRAM_address_counter <= BRAM_address_counter+1;
        else
            BRAM_address_counter <= BRAM_address_counter;
    
    end
    
    assign BRAM_addr_o = BRAM_address_counter;
    
endmodule