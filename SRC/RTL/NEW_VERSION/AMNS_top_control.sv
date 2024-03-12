`timescale 1ns / 1ps


module AMNS_top_control
(

    input clock_i,
          reset_i,

    input start_i,

    input load_done_i,
    input store_done_i,

    input FIOS_done_i,

    output reg load_start_o,
    output reg store_start_o,

    output reg FIOS_start_o,

    output reg done_o
);

    localparam [2:0] RESET = 0,
                     INIT  = 1,
                     LOAD  = 2,
                     FIOS  = 3,
                     STORE = 4,
                     WAIT_DONE = 5,
                     DONE  = 6;

    reg [2:0] current_state, future_state;

    always_ff @(posedge clock_i) begin
        if (reset_i)
            current_state <= RESET;
        else
            current_state <= future_state;
    end

    always_comb begin
        case (current_state)
            RESET: future_state = INIT;
            INIT : begin
                if (start_i)
                    future_state = LOAD;
                else
                    future_state = INIT;
            end
            LOAD : future_state = WAIT_DONE;
            FIOS : future_state = WAIT_DONE;
            STORE : future_state = WAIT_DONE;
            WAIT_DONE : begin
                if (load_done_i)
                    future_state = FIOS;
                else if (FIOS_done_i)
                    future_state = STORE;
                else if (store_done_i)
                    future_state = DONE;
                else
                    future_state = WAIT_DONE;
            end
            DONE : future_state = INIT;
            default : future_state = INIT;
        endcase
    end

    always_comb begin
        case (current_state)
            RESET : begin
                load_start_o = 0;
                store_start_o = 0;
                FIOS_start_o = 0;
                done_o = 0;
            end
            RESET : begin
                    load_start_o = 0;
                    store_start_o = 0;
                    FIOS_start_o = 0;
                    done_o = 0;
                end
            INIT : begin
                    load_start_o = 0;
                    store_start_o = 0;
                    FIOS_start_o = 0;
                    done_o = 0;
                end
            LOAD : begin
                load_start_o = 1;
                store_start_o = 0;
                FIOS_start_o = 0;
                done_o = 0;
            end
            FIOS : begin
                load_start_o = 0;
                store_start_o = 0;
                FIOS_start_o = 1;
                done_o = 0;
            end
            STORE : begin
                load_start_o = 0;
                store_start_o = 1;
                FIOS_start_o = 0;
                done_o = 0;
            end
            WAIT_DONE : begin
                load_start_o = 0;
                store_start_o = 0;
                FIOS_start_o = 0;
                done_o = 0;
            end
            DONE : begin
                load_start_o = 0;
                store_start_o = 0;
                FIOS_start_o = 0;
                done_o = 1;
            end
        endcase
    end

endmodule
