`timescale 1ns/1ps

module POLY_memory_control #(
    WORD_WIDTH  = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N           =  5, // Number of coefficients in an AMNS polynomial
    S           =  4  // Number of blocks of width WORD_WIDTH required to hold a coefficient
) (

    input clock_i,
    reset_i,

    input load_start_i,
    input store_start_i,

    output reg BRAM_we_o,
    output reg [$clog2(4*N*S+N):0] BRAM_addr_o,

    output [1:0] INPUT_reg_sel_o,
    output INPUT_reg_en_o,

    output reg RES_reg_shift_o,

    output load_done_o,
    output reg store_done_o

);

    localparam [3:0] RESET  = 4'b0000,
                     IDLE   = 4'b0001,
                     LOAD_A = 4'b0010,
                     LOAD_B = 4'b0011,
                     LOAD_M = 4'b0100,
                     LOAD_M_PRIME_0 = 4'b0101,
                     STORE_RES = 4'b0110,
                     LOAD_DONE = 4'b0111,
                     STORE_DONE = 4'b1000;

    reg [3:0] current_state, future_state;

    reg BRAM_addr_counter_reset;
    reg BRAM_addr_counter_en;
    reg [$clog2(4*N*S+N):0] BRAM_addr_count;

    reg [1:0] INPUT_reg_sel, INPUT_reg_sel_delay_0, INPUT_reg_sel_delay_1;
    reg INPUT_reg_en, INPUT_reg_en_delay_0, INPUT_reg_en_delay_1;

    reg load_done, load_done_delay_0, load_done_delay_1;

    always_ff @(posedge clock_i) begin
        if (reset_i) current_state <= RESET;
        else current_state <= future_state;
    end

    always_comb begin
        case (current_state)
            RESET: future_state = IDLE;
            IDLE: begin
                if (load_start_i) future_state = LOAD_A;
                else if (store_start_i) future_state = STORE_RES;
                else future_state = IDLE;
            end
            LOAD_A: begin
                if (BRAM_addr_count == N * S - 1) future_state = LOAD_B;
                else future_state = LOAD_A;
            end
            LOAD_B: begin
                if (BRAM_addr_count == 2 * N * S - 1) future_state = LOAD_M;
                else future_state = LOAD_B;
            end
            LOAD_M: begin
                if (BRAM_addr_count == 3 * N * S - 1) future_state = LOAD_M_PRIME_0;
                else future_state = LOAD_M;
            end
            LOAD_M_PRIME_0: begin
                if (BRAM_addr_count == 3 * N * S + N - 1) future_state = LOAD_DONE;
                else future_state = LOAD_M_PRIME_0;
            end
            LOAD_DONE: future_state = IDLE;
            STORE_RES: begin
                if (BRAM_addr_count == 4 * N * S + N - 1) future_state = STORE_DONE;
                else future_state = STORE_RES;
            end
            STORE_DONE: future_state = IDLE;
            default: future_state = IDLE;
        endcase
    end

    always_comb begin
        case (current_state)
            RESET: begin
                BRAM_we_o = 0;
                BRAM_addr_counter_reset = 1;
                BRAM_addr_counter_en = 0;
                INPUT_reg_sel = 0;
                INPUT_reg_en = 0;
                RES_reg_shift_o = 0;
                load_done = 0;
                store_done_o = 0;
            end
            IDLE: begin
                BRAM_we_o = 0;
                BRAM_addr_counter_reset = 1;
                BRAM_addr_counter_en = 0;
                INPUT_reg_sel = 0;
                INPUT_reg_en = 0;
                RES_reg_shift_o = 0;
                load_done = 0;
                store_done_o = 0;
            end
            LOAD_A: begin
                BRAM_we_o = 0;
                BRAM_addr_counter_reset = 0;
                BRAM_addr_counter_en = 1;
                INPUT_reg_sel = 0;
                INPUT_reg_en = 1;
                RES_reg_shift_o = 0;
                load_done = 0;
                store_done_o = 0;
            end
            LOAD_B: begin
                BRAM_we_o = 0;
                BRAM_addr_counter_reset = 0;
                BRAM_addr_counter_en = 1;
                INPUT_reg_sel = 1;
                INPUT_reg_en = 1;
                RES_reg_shift_o = 0;
                load_done = 0;
                store_done_o = 0;
            end
            LOAD_M: begin
                BRAM_we_o = 0;
                BRAM_addr_counter_reset = 0;
                BRAM_addr_counter_en = 1;
                INPUT_reg_sel = 2;
                INPUT_reg_en = 1;
                RES_reg_shift_o = 0;
                load_done = 0;
                store_done_o = 0;
            end
            LOAD_M_PRIME_0: begin
                BRAM_we_o = 0;
                BRAM_addr_counter_reset = 0;
                BRAM_addr_counter_en = 1;
                INPUT_reg_sel = 3;
                INPUT_reg_en = 1;
                RES_reg_shift_o = 0;
                load_done = 0;
                store_done_o = 0;
            end
            LOAD_DONE: begin
                BRAM_we_o = 0;
                BRAM_addr_counter_reset = 1;
                BRAM_addr_counter_en = 0;
                INPUT_reg_sel = 0;
                INPUT_reg_en = 0;
                RES_reg_shift_o = 0;
                load_done = 1;
                store_done_o = 0;
            end
            STORE_RES: begin
                BRAM_we_o = 1;
                BRAM_addr_counter_reset = 0;
                BRAM_addr_counter_en = 1;
                INPUT_reg_sel = 0;
                INPUT_reg_en = 0;
                RES_reg_shift_o = 1;
                load_done = 0;
                store_done_o = 0;
            end
            STORE_DONE: begin
                BRAM_we_o = 0;
                BRAM_addr_counter_reset = 1;
                BRAM_addr_counter_en = 0;
                INPUT_reg_sel = 0;
                INPUT_reg_en = 0;
                RES_reg_shift_o = 0;
                load_done = 0;
                store_done_o = 1;
            end
            default: begin
                BRAM_we_o = 0;
                BRAM_addr_counter_reset = 1;
                BRAM_addr_counter_en = 0;
                INPUT_reg_sel = 0;
                INPUT_reg_en = 0;
                RES_reg_shift_o = 0;
                load_done = 0;
                store_done_o = 0;
            end
        endcase
    end


    always_ff @(posedge clock_i) begin
        if (store_start_i) BRAM_addr_count <= 3 * N * S + N;
        else if (BRAM_addr_counter_reset) BRAM_addr_count <= 0;
        else if (BRAM_addr_counter_en) BRAM_addr_count <= BRAM_addr_count + 1;
        else BRAM_addr_count <= BRAM_addr_count;
    end
    
    assign BRAM_addr_o = BRAM_addr_count;

    // BRAM output data is delayed twice for performance reasons
    // Therefore INPUT_reg_sel, INPUT_reg_en and load_done must be twice delayed as well
    always_ff @(posedge clock_i) begin
        INPUT_reg_sel_delay_0 <= INPUT_reg_sel;
        INPUT_reg_sel_delay_1 <= INPUT_reg_sel_delay_0;
        INPUT_reg_en_delay_0 <= INPUT_reg_en;
        INPUT_reg_en_delay_1 <= INPUT_reg_en_delay_0;
        load_done_delay_0 <= load_done;
        load_done_delay_1 <= load_done_delay_0;
    end

    assign INPUT_reg_sel_o = INPUT_reg_sel_delay_1;
    assign INPUT_reg_en_o = INPUT_reg_en_delay_1;
    assign load_done_o = load_done_delay_1;

endmodule
