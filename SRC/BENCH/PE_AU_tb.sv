`timescale 1ns / 1ps

module PE_AU_tb(

    );
    
    localparam realtime PERIOD = 10.0,
                        HALF_PERIOD = PERIOD/2;
    
    reg clock_i = 0;
    
    reg [26:0] A_i = 'h55387d3;
    //reg [17:0] B_i = 'h0x27153;
    reg [17:0] B_i = 'h128ea;
    //reg [47:0] C_i = 'h9383f52a7d21;
    reg [47:0] C_i = 0;
    
    wire [47:0] P_o, PCOUT_o;
    
    PE_AU #(.ABREG(0), .MREG(0), .CREG(0)) DUT (
    
        .clock_i(clock_i),
        
        .CREG_en_i(1),
        
        .OPMODE_i(9'b000110101),
        
        .A_i(A_i),
        .B_i(B_i),
        .C_i(C_i),
        
        .PCIN_i(0),
        
        .P_o(P_o),
        .PCOUT_o(PCOUT_o)
    
    );
    
    always #HALF_PERIOD clock_i <= ~clock_i;
    
    initial begin
    
    end
    
endmodule
