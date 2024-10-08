`timescale 1ns / 1fs

// This module is the testbench for the sim_top_bd block design.
// It is meant to load test vectors from a text test vectors file,
// store operand data in the Block RAM, launch an FIOS computation
// and compare the stored result with the expected result.

module top_bd_wrapper_tb #(parameter WIDTH = 256,
                                     s = 4,
                                     N = 5,
                                     LAMBDA = 2) ();

    // WARNING !! simulation test vector files sim_WIDTH.txt must be generated and included into the project
    // prior to running simulation.
    // If simulation is performed manually, simulation fileset width must be set using the command
    // set_property generic WIDTH=256 [get_filesets sim_1]
    // and design WIDTH must be set in the sim_top_bd block design diagram.


    // The block design uses a clock wizard which uses
    // a 300 MHz clock to generate the higher frequency clock used by the design.
    localparam PERIOD = 10,
               HALF_PERIOD = PERIOD/2;


    wire FIOS_start;
     
    wire FIOS_done;
    
    reg FIOS_running = 0;

    int FIOS_cycle_count;

    // Global clock reset and start signals of the FIOS multiplier design.
    reg clock_i = 0;
    reg reset_i = 1;
    reg start_i = 0;

    // BRAM master interface used to store test vectors in BRAM and load result from BRAM.
    wire BRAM_PORTA_i_clk;
    reg [31:0] BRAM_PORTA_i_din = 0;
    reg [3:0] BRAM_PORTA_i_we = 0;
    reg [31:0] BRAM_PORTA_i_addr = 0;
    wire [31:0] BRAM_PORTA_i_dout;
    
    reg BRAM_PORTA_i_rst = 0;
    reg BRAM_PORTA_en_i = 0;

    // FIOS done status signal.
    wire done_o;

    // Wrapper instance for the block design.
    sim_top_bd_wrapper DUT (
        . reset_i(reset_i),
        .start_i(start_i),
        .BRAM_PORTA_i_addr(BRAM_PORTA_i_addr),
        .BRAM_PORTA_i_clk(BRAM_PORTA_i_clk),
        .BRAM_PORTA_i_din(BRAM_PORTA_i_din),
        .BRAM_PORTA_i_dout(BRAM_PORTA_i_dout),
        .BRAM_PORTA_i_we(BRAM_PORTA_i_we),
        .BRAM_PORTA_i_rst(BRAM_PORTA_i_rst),
        .BRAM_PORTA_i_en(1),
        .done_o(done_o));


//    assign FIOS_start = DUT.sim_top_bd_i.MM_demo_0.inst.MM_top_inst.genblk2.FIOS_CASC_inst.start_i;
//    assign FIOS_done = DUT.sim_top_bd_i.MM_demo_0.inst.MM_top_inst.genblk2.FIOS_CASC_inst.done_o;
    
    
    always @ (posedge clock_i) begin
            
                if (FIOS_start)
                    FIOS_running <= 1;
                else if (FIOS_done)
                    FIOS_running <= 0;
                else
                    FIOS_running <= FIOS_running;
            
    end
    
    
    always @ (posedge clock_i) begin
    
        if (reset_i)
            FIOS_cycle_count <= 0;
        else if ((FIOS_running && !FIOS_done))
            FIOS_cycle_count <= FIOS_cycle_count+1;
        else
            FIOS_cycle_count <= FIOS_cycle_count;
    
    end

    // testbench-side BRAM port runs at 300 MHz.
    assign BRAM_PORTA_i_clk = clock_i;
        
    always #HALF_PERIOD clock_i <= ~(clock_i);
    
    // The following registers are used to store input operands and expect result read from test vector files prior
    // being stored in the BRAM.
    reg [N*17-1:0] M_prime_0_reg;
    reg [N*s*17-1:0] M_reg;
    reg [N*s*17-1:0] A_reg;
    reg [N*s*17-1:0] B_reg;

    reg [N*s*17-1:0] verif_res;

    // The following register and register enable signals are used to load the result computed by the FIOS module from the BRAM
    // and compare it with the expected result.
    reg [N*s*17-1:0] res;
    reg en_res = 0;
    reg en_res_reg;

    always @ (posedge clock_i) begin
        en_res_reg <= en_res;
    end

    // The computed result is loaded from BRAM using a shift register.
    always @ (posedge clock_i) begin
        if(en_res_reg)
            res <= {BRAM_PORTA_i_dout[16:0], res[N*s*17-1:17]};
    end


    // Default test vector file name is "sim_<WIDTH>_<N>_<LAMBDA>.txt", it is generated using the WIDTH localparam.
    string WIDTH_str;
    string N_str;
    string LAMBDA_str;

    // Test vector file descriptor, line variable to store data read from test vector and status variable.
    int fd;
    string line;
    int status;
    
    // A counter is used to count the numbers of test vectors tested.
    int count = 0;
    int SUCCESS_COUNT = 0;
    
    string success_string;

    initial begin
    
        count <= 0;
        reset_i <= 1;
        en_res <= 0;

        BRAM_PORTA_i_rst <= 1;

        // Generate test vector file name and open test vector file.
        $sformat(WIDTH_str, "%0d", WIDTH);
        $sformat(N_str, "%0d", N);
        $sformat(LAMBDA_str, "%0d", LAMBDA);
        
        fd = $fopen({"sim_",WIDTH_str, "_", N_str, "_", LAMBDA_str, ".txt"}, "r");
        
        BRAM_PORTA_en_i <= 1;
        
        #PERIOD;
            
        #(100*PERIOD);
        
        BRAM_PORTA_i_rst <= 0;
        
        // While the test vector file has not been read completely, the n, n_prime_0, X and Y operands as
        // well as the expected result are read and tested.
        while (! $feof(fd)) begin
        
        reset_i <= 1;
        en_res <= 0;
        
        #(100*PERIOD);
        
        reset_i <= 0;
        
        #(100*PERIOD);
        
        for (int i = 0;i < 22; i++) begin
            status = $fgets(line, fd);
        end
        
        for (int i = 0 ;i < N; i++) begin
            status = $fgets(line, fd);
            status = $sscanf(line, "%h", M_reg[i*s*17+:s*17]);
        end
        
        status = $fgets(line, fd);
        status = $fgets(line, fd);

        for (int i = 0 ;i < N; i++) begin
            status = $fgets(line, fd);
            status = $sscanf(line, "%h", M_prime_0_reg[i*17+:17]);
        end

        status = $fgets(line, fd);
        status = $fgets(line, fd);
        
        for (int i = 0 ;i < N; i++) begin
            status = $fgets(line, fd);
            status = $sscanf(line, "%h", A_reg[i*s*17+:s*17]);
        end

        status = $fgets(line, fd);
        status = $fgets(line, fd);

        for (int i = 0 ;i < N; i++) begin
            status = $fgets(line, fd);
            status = $sscanf(line, "%h", B_reg[i*s*17+:s*17]);
        end
        
        status = $fgets(line, fd);
        status = $fgets(line, fd);
        
        for (int i = 0 ;i < N; i++) begin
            status = $fgets(line, fd);
            status = $sscanf(line, "%h", verif_res[i*s*17+:s*17]);
        end

        // Operand data read from the test vector file is written to the Block RAM.
        BRAM_PORTA_i_we <= 'hf;
        
        for(int i = 0; i < N ; i++) begin
            BRAM_PORTA_i_addr <= (i) << 2;
            BRAM_PORTA_i_din <= M_prime_0_reg[17*i+:17];
            #PERIOD;
        end
        for(int i = 0; i < N*s;i++) begin
            BRAM_PORTA_i_addr <= (i+1*N) << 2;
            BRAM_PORTA_i_din <= M_reg[17*i+:17];
            #PERIOD;        
        end
        for(int i = 0; i < N*s;i++) begin
            BRAM_PORTA_i_addr <= (i+(s+1)*N) << 2;
            BRAM_PORTA_i_din <= A_reg[17*i+:17];
            #PERIOD;        
        end
        for(int i = 0; i < N*s;i++) begin
            BRAM_PORTA_i_addr <= (i+(2*s+1)*N) << 2;
            BRAM_PORTA_i_din <= B_reg[17*i+:17];
            #PERIOD;
        end
        
        BRAM_PORTA_i_we <= 0;
        BRAM_PORTA_i_din <= 0;
        
        BRAM_PORTA_en_i <= 0;
        
        #PERIOD;
        
        // The testbench starts the FIOS computation and waits for the done_o status signal to be set.
        start_i <= 1;
        
        #(PERIOD);
        
        start_i <= 0;

        #(100*PERIOD);
        
        DUT.sim_top_bd_i.AMNS_top_v_wrapper_0.inst.AMNS_top_inst.A_shift[0] = 1;


        while(~done_o)
            #PERIOD;


        #PERIOD;
        BRAM_PORTA_en_i <= 1;
        // Computed result is loaded from the BRAM.
        for(int i = 0; i < s;i++) begin
            en_res <= 1;
            BRAM_PORTA_i_addr <= i << 2;
            #PERIOD;
        end

        en_res <= 0;

        #(2*PERIOD);

        // Computed result is compared to the expected result and the test vector count is incremented.       
        if(res == verif_res) begin
            $display("test vector %0d match at %0t ps.", count, $realtime);
            SUCCESS_COUNT <= SUCCESS_COUNT + 1;
        end else begin
            $display("test vector %0d mismatch at %0t ps.", count, $realtime);
        end

        #(5*PERIOD); 
        
        count <= count+1;
        
        end



        if (SUCCESS_COUNT-1 == count) begin
            success_string = "SUCCESS";
            $display("SUCCESS");
        end else begin
            success_string = "FAILURE";
            $display("FAILURE");
        end
        
        $stop;

    end

endmodule
