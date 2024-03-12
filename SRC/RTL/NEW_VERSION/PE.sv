`timescale 1ns/1ps

module PE #(
    WORD_WIDTH   = 17, // Width of words used in DSP block operations. Upper limit depends on DSP block architecture
    N            =  5, // Number of coefficients in an AMNS polynomial
    LAMBDA       =  2,
    S            =  4, // Number of blocks of width WORD_WIDTH required to hold a coefficient
    COLUMN_INDEX =  0, // Indicates which PE column this PE belongs to. Each PE column is responsible for the computation of one result coefficient.
    LINE_INDEX   =  0  // Indicates which PE line this PE belongs to. Each PE line is responsible for computations related to a WORD_WIDTH section of A coefficients.
) (

    input clock_i,
          reset_i,

    input start_i,

    input [WORD_WIDTH-1:0] A_reg_din_0_i,
    input [WORD_WIDTH+1-1:0] A_reg_din_1_i,
    input [WORD_WIDTH-1:0] B_reg_din_0_i,
    input [WORD_WIDTH+1-1:0] B_reg_din_1_i,
    input [WORD_WIDTH-1:0] M_reg_din_0_i,
    input [WORD_WIDTH+1-1:0] M_reg_din_1_i,
    input [WORD_WIDTH-1:0] M_prime_0_reg_din_0_i,
    input [WORD_WIDTH-1:0] M_prime_0_reg_din_1_i,
    input [WORD_WIDTH-1:0] q_din_i,
    input [WORD_WIDTH-1:0] q_reg_din_0_i,
    input [WORD_WIDTH-1:0] q_reg_din_1_i,
    input [WORD_WIDTH+1-1:0] CREG_din_0_i,

    output [WORD_WIDTH+1-1:0] A_reg_dout_o,
    output [WORD_WIDTH+1-1:0] B_reg_dout_o,
    output [WORD_WIDTH+1-1:0] M_reg_dout_o,
    output [WORD_WIDTH-1:0] M_prime_0_reg_dout_o,
    output [WORD_WIDTH-1:0] q_reg_dout_o,

    output [WORD_WIDTH+1-1:0] RES_dout_o,

    output mem_B_reg_shift_o,
    output mem_M_reg_shift_o,

    output B_delay_line_en_o,
    output M_delay_line_en_o,

    output done_o

);

    // PE_control signals
    // Outputs
    wire A_reg_en;
    wire A_reg_sel;
    wire sign_ext_A_en;
    wire B_reg_en;
    wire B_reg_sel;
    wire sign_ext_B_en;
    wire M_reg_en;
    wire M_reg_sel;
    wire sign_ext_M_en;
    wire M_prime_0_reg_en;
    wire M_prime_0_reg_sel;
    wire q_reg_en;
    wire q_reg_sel;
    wire RES_reg_en;
    wire PE_AU_CREG_en;
    wire [1:0] PE_AU_CREG_sel;
    wire CREG_reg_en;

    wire [1:0] PE_AU_A_sel;
    wire [1:0] PE_AU_B_sel;

    wire LAMBDA_MUL_sel;

    wire [8:0] PE_AU_OPMODE;

    wire mem_B_reg_shift;
    wire mem_M_reg_shift;

    wire B_delay_line_en;
    wire M_delay_line_en;

    PE_control #(
        .WORD_WIDTH(WORD_WIDTH),
        .N(N),
        .S(S),
        .COLUMN_INDEX(COLUMN_INDEX),
        .LINE_INDEX(LINE_INDEX)
    ) PE_control_inst (

        .clock_i(clock_i),
        .reset_i(reset_i),

        .start_i(start_i),

        .A_reg_en_o(A_reg_en),
        .A_reg_sel_o(A_reg_sel),
        .sign_ext_A_en_o(sign_ext_A_en),
        .B_reg_en_o(B_reg_en),
        .B_reg_sel_o(B_reg_sel),
        .sign_ext_B_en_o(sign_ext_B_en),
        .M_reg_en_o(M_reg_en),
        .M_reg_sel_o(M_reg_sel),
        .sign_ext_M_en_o(sign_ext_M_en),
        .M_prime_0_reg_en_o(M_prime_0_reg_en),
        .M_prime_0_reg_sel_o(M_prime_0_reg_sel),
        .q_reg_en_o(q_reg_en),
        .q_reg_sel_o(q_reg_sel),
        .RES_reg_en_o(RES_reg_en),
        .CREG_en_o(PE_AU_CREG_en),
        .CREG_sel_o(PE_AU_CREG_sel),
        .CREG_reg_en_o(CREG_reg_en),

        .PE_AU_A_sel_o(PE_AU_A_sel),
        .PE_AU_B_sel_o(PE_AU_B_sel),

        .OPMODE_o(PE_AU_OPMODE),
        .LAMBDA_MUL_sel_o(LAMBDA_MUL_sel),

        .mem_B_reg_shift_o(mem_B_reg_shift),
        .mem_M_reg_shift_o(mem_M_reg_shift),

        .B_delay_line_en_o(B_delay_line_en),
        .M_delay_line_en_o(M_delay_line_en),

        .done_o(done_o)

    );

    // PE_AU signals
    // Inputs
    wire [26:0] PE_AU_A_din;
    reg [17:0] PE_AU_B_din;
    reg [47:0] PE_AU_C_din;

    // Outputs
    wire [47:0] PE_AU_RES_dout;

    PE_AU #(
        .ABREG(1),
        .MREG(0),
        .CREG(1)
    ) PE_AU_inst (

        .clock_i(clock_i),

        .CREG_en_i(PE_AU_CREG_en),

        .OPMODE_i(PE_AU_OPMODE),

        .A_din_i(PE_AU_A_din),
        .B_din_i(PE_AU_B_din),
        .C_din_i(PE_AU_C_din),
        .PCIN_din_i(),

        .RES_dout_o(PE_AU_RES_dout),

        .PCOUT_dout_o()

    );


    // Module logic
    // Signals
    // Registers signals
    reg [WORD_WIDTH+1-1:0] A_reg;
    reg [WORD_WIDTH+1-1:0] B_reg;
    reg [WORD_WIDTH+1-1:0] M_reg;
    reg [WORD_WIDTH-1:0] M_prime_0_reg;
    reg [WORD_WIDTH-1:0] q_reg;

    reg [47:0] RES_reg;

    // Multiplexed signal to PE AU input A 
    reg[WORD_WIDTH+1-1:0] LAMBDA_STAGE_din;
    wire [26:0] LAMBDA_STAGE_dout;

    // LAMBDA multiplication signals
    wire [26:0] LAMBDA_MUL_din;
    wire [26:0] LAMBDA_MUL_dout;


    // Logic
    // A register
    always_ff @(posedge clock_i) begin
        if (reset_i)
            A_reg <= 0; 
        if (A_reg_en) begin
            if (A_reg_sel)
                A_reg <= (WORD_WIDTH+1)'(A_reg_din_1_i);
            else begin
                if (sign_ext_A_en)
                    A_reg <= (WORD_WIDTH+1)'(signed'(A_reg_din_0_i));
                else
                    A_reg <= (WORD_WIDTH+1)'(A_reg_din_0_i);
            end
        end else
            A_reg <= A_reg;
    end

    // B register
    always_ff @(posedge clock_i) begin
        if (reset_i)
            B_reg <= 0; 
        if (B_reg_en) begin
            if (B_reg_sel)
                B_reg <= (WORD_WIDTH+1)'(B_reg_din_1_i);
            else
                if (sign_ext_B_en)
                    B_reg <= (WORD_WIDTH+1)'(signed'(B_reg_din_0_i));
                else
                    B_reg <= (WORD_WIDTH+1)'(B_reg_din_0_i);
        end else
            B_reg <= B_reg;
    end

    // M register
    always_ff @(posedge clock_i) begin
        if (reset_i)
            M_reg <= 0; 
        if (M_reg_en) begin
            if (M_reg_sel)
                M_reg <= (WORD_WIDTH+1)'(M_reg_din_1_i);
            else begin
                if (sign_ext_M_en)
                    M_reg <= (WORD_WIDTH+1)'(signed'(M_reg_din_0_i));
                else
                    M_reg <= (WORD_WIDTH+1)'(M_reg_din_0_i);
            end
        end else
            M_reg <= M_reg;
    end

    // M_prime_0 register
    always_ff @(posedge clock_i) begin
        if (reset_i)
            M_prime_0_reg <= 0; 
        if (M_prime_0_reg_en) begin
            if (M_prime_0_reg_sel)
                M_prime_0_reg <= M_prime_0_reg_din_1_i;
            else
                M_prime_0_reg <= M_prime_0_reg_din_0_i;
        end else
            M_prime_0_reg <= M_prime_0_reg;
    end

    // q register
    always_ff @(posedge clock_i) begin
        if (reset_i)
            q_reg <= 0;
        else if (q_reg_en) begin
            if (q_reg_sel)
                q_reg <= q_reg_din_1_i;
            else
                q_reg <= q_reg_din_0_i;
        end else
            q_reg <= q_reg;
    end

    // RES register
    always_ff @(posedge clock_i) begin
        if (reset_i)
            RES_reg <= 0;
        else if (RES_reg_en)
            RES_reg <= PE_AU_RES_dout;
        else
            RES_reg <= RES_reg;
    end


    // PE AU A input multiplexer to LAMBDA multiplication stage
    always_comb begin
        case (PE_AU_A_sel)
            0: LAMBDA_STAGE_din = A_reg;
            1: LAMBDA_STAGE_din = M_prime_0_reg;
            2: LAMBDA_STAGE_din = M_reg;
            default : LAMBDA_STAGE_din = A_reg;
        endcase
    end

    // LAMBDA multiplication stage
    assign LAMBDA_MUL_din = 27'(signed'(LAMBDA_STAGE_din));
    assign LAMBDA_MUL_dout = LAMBDA_MUL_din*LAMBDA;
    
    assign LAMBDA_STAGE_dout = (LAMBDA_MUL_sel) ? LAMBDA_MUL_dout : LAMBDA_MUL_din;
    
    assign PE_AU_A_din = LAMBDA_STAGE_dout;

    // PE AU B input multiplexer
    always_comb begin
        case (PE_AU_B_sel)
            0: PE_AU_B_din = B_reg;
            1: PE_AU_B_din = q_din_i;
            2: PE_AU_B_din = q_reg;
            default : PE_AU_B_din = B_reg;
        endcase
    end

    // PE AU CREG input multiplexer
    reg [WORD_WIDTH+1-1:0] CREG_reg;
    reg [WORD_WIDTH+1-1:0] CREG_reg_reg;
    always_ff @(posedge clock_i) begin
        if (CREG_reg_en)
            CREG_reg <= sign_ext_B_en ? (WORD_WIDTH+1)'(signed'(CREG_din_0_i[WORD_WIDTH-1:0])) : CREG_din_0_i;
        else
            CREG_reg <= CREG_reg;
        CREG_reg_reg <= CREG_reg;
    end
    
    always_comb begin
        case(PE_AU_CREG_sel)
            0: PE_AU_C_din = PE_AU_RES_dout;
            1: PE_AU_C_din = 48'(signed'(CREG_din_0_i));
            2: PE_AU_C_din = RES_reg;
            3: PE_AU_C_din = 48'(signed'(CREG_reg_reg));
        endcase
    end

    // Module output assignment
    assign A_reg_dout_o = A_reg;
    assign B_reg_dout_o = B_reg;
    assign M_reg_dout_o = M_reg;
    assign M_prime_0_reg_dout_o = M_prime_0_reg;
    assign q_reg_dout_o = q_reg;

    assign RES_dout_o = {1'b0, PE_AU_RES_dout[WORD_WIDTH-1:0]};

    assign mem_B_reg_shift_o = mem_B_reg_shift;
    assign mem_M_reg_shift_o = mem_M_reg_shift;
    
    assign B_delay_line_en_o = B_delay_line_en;
    assign M_delay_line_en_o = M_delay_line_en;


endmodule
