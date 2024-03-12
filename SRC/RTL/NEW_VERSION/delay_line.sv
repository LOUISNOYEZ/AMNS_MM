`timescale 1ns / 1ps

module delay_line #(parameter WIDTH = 1, DELAY = 1) (
        input clock_i,
        input reset_i,
        input en_i,
        
        input [WIDTH-1:0] a_i,
        output [WIDTH-1:0] s_o
    );
    
    reg [WIDTH-1:0] a_delay [0:DELAY];
    
    assign a_delay[0] = a_i;
    
    genvar i;
    
    generate
        for (i = 0; i < DELAY; i++) begin
        
            always_ff @ (posedge clock_i) begin
                if (reset_i)
                    a_delay[i+1] <= 0;
                else if (en_i)
                    a_delay[i+1] <= a_delay[i];
                else
                    a_delay[i+1] <= a_delay[i+1];
            end

        end
    endgenerate

    assign s_o = a_delay[DELAY];

endmodule
