`timescale 1ns / 1ps


module PE_AU #(
    ABREG = 1,
    MREG  = 1,
    CREG  = 1
) (

    input clock_i,

    // The CREG registered C input to the additioner of the DSP is enabled using the CREG_en_i signal.
    input CREG_en_i,

    // DSP block operation are selected using the OPMODE signal.
    input [8:0] OPMODE_i,

    input [26:0] A_din_i,
    input [17:0] B_din_i,
    input [47:0] C_din_i,
    input [47:0] PCIN_din_i,

    output [47:0] RES_dout_o,

    output [47:0] PCOUT_dout_o

);

    localparam [3:0] ALUMODE    = 4'b0;
    localparam [2:0] CARRYINSEL = 3'b0;
    localparam [4:0] INMODE     = 5'b0;

    DSP48E2 #(
        .USE_MULT     ("MULTIPLY"),  // Select multiplier usage (DYNAMIC, MULTIPLY, NONE)
        .USE_SIMD     ("ONE48"),     // SIMD selection (FOUR12, ONE48, TWO24)
        .ACASCREG     (ABREG),       // Number of pipeline stages between A/ACIN and ACOUT (0-2)
        .ADREG        (ABREG),       // Pipeline stages for pre-adder (0-1)
        .ALUMODEREG   (1),           // Pipeline stages for ALUMODE (0-1)
        .AREG         (ABREG),       // Pipeline stages for A (0-2)
        .BCASCREG     (ABREG),       // Number of pipeline stages between B/BCIN and BCOUT (0-2)
        .BREG         (ABREG),       // Pipeline stages for B (0-2)
        .CARRYINREG   (1),           // Pipeline stages for CARRYIN (0-1)
        .CARRYINSELREG(1),           // Pipeline stages for CARRYINSEL (0-1)
        .CREG         (CREG),        // Pipeline stages for C (0-1)
        .DREG         (1),           // Pipeline stages for D (0-1)
        .INMODEREG    (1),           // Pipeline stages for INMODE (0-1)
        .MREG         (MREG),        // Multiplier pipeline stages (0-1)
        .OPMODEREG    (1),           // Pipeline stages for OPMODE (0-1)
        .PREG         (1)            // Number of pipeline stages for P (0-1)
    ) DSP48E2_inst (
        // Cascade inputs: Cascade Ports
        .ACOUT         (),             // 30-bit output: A port cascade
        .BCOUT         (),             // 18-bit output: B cascade
        .CARRYCASCOUT  (),             // 1-bit output: Cascade carry
        .MULTSIGNOUT   (),             // 1-bit output: Multiplier sign cascade
        .PCOUT         (PCOUT_dout_o),      // 48-bit output: Cascade output
        // Control outputs: Control Inputs/Status Bits
        .OVERFLOW      (),             // 1-bit output: Overflow in add/acc
        .PATTERNBDETECT(),             // 1-bit output: Pattern bar detect
        .PATTERNDETECT (),             // 1-bit output: Pattern detect
        .UNDERFLOW     (),             // 1-bit output: Underflow in add/acc
        // Data outputs: Data Ports
        .CARRYOUT      (),             // 4-bit output: Carry
        .P             (RES_dout_o),          // 48-bit output: Primary data
        .XOROUT        (),             // 8-bit output: XOR data
        // Control inputs: Control Inputs/Status Bits
        .ALUMODE       (ALUMODE),         // 4-bit input: ALU control
        .CARRYINSEL    (CARRYINSEL),         // 3-bit input: Carry select
        .CLK           (clock_i),      // 1-bit input: Clock
        .INMODE        (INMODE),         // 5-bit input: INMODE control
        .OPMODE        (OPMODE_i),     // 9-bit input: Operation mode
        // Cascade inputs: Cascade Ports
        .ACIN          (),             // 30-bit input: A cascade data
        .BCIN          (),             // 18-bit input: B cascade
        .CARRYCASCIN   (),             // 1-bit input: Cascade carry
        .MULTSIGNIN    (),             // 1-bit input: Multiplier sign cascade
        .PCIN          (PCIN_din_i),       // 48-bit input: P cascade
        // Data inputs: Data Ports
        .A             ({3'b0, A_din_i}),  // 30-bit input: A data
        .B             (B_din_i),          // 18-bit input: B data
        .C             (C_din_i),          // 48-bit input: C data
        .CARRYIN       (),             // 1-bit input: Carry-in
        .D             (),             // 27-bit input: D data
        // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
        .CEA1          (1'b1),         // 1-bit input: Clock enable for 1st stage AREG
        .CEA2          (1'b1),         // 1-bit input: Clock enable for 2nd stage AREG
        .CEAD          (1'b1),         // 1-bit input: Clock enable for ADREG
        .CEALUMODE     (1'b1),         // 1-bit input: Clock enable for ALUMODE
        .CEB1          (1'b1),         // 1-bit input: Clock enable for 1st stage BREG
        .CEB2          (1'b1),         // 1-bit input: Clock enable for 2nd stage BREG
        .CEC           (CREG_en_i),    // 1-bit input: Clock enable for CREG
        .CECARRYIN     (1'b1),         // 1-bit input: Clock enable for CARRYINREG
        .CECTRL        (1'b1),         // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
        .CED           (1'b1),         // 1-bit input: Clock enable for DREG
        .CEINMODE      (1'b1),         // 1-bit input: Clock enable for INMODEREG
        .CEM           (1'b1),         // 1-bit input: Clock enable for MREG
        .CEP           (1'b1),         // 1-bit input: Clock enable for PREG
        .RSTA          (1'b0),         // 1-bit input: Reset for AREG
        .RSTALLCARRYIN (1'b0),         // 1-bit input: Reset for CARRYINREG
        .RSTALUMODE    (1'b0),         // 1-bit input: Reset for ALUMODEREG
        .RSTB          (1'b0),         // 1-bit input: Reset for BREG
        .RSTC          (1'b0),         // 1-bit input: Reset for CREG
        .RSTCTRL       (1'b0),         // 1-bit input: Reset for OPMODEREG and CARRYINSELREG
        .RSTD          (1'b0),         // 1-bit input: Reset for DREG and ADREG
        .RSTINMODE     (1'b0),         // 1-bit input: Reset for INMODEREG
        .RSTM          (1'b0),         // 1-bit input: Reset for MREG
        .RSTP          (1'b0)          // 1-bit input: Reset for PREG
    );

endmodule
