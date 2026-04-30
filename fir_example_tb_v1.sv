`timescale 1ns/1ps

module fir_example_tb_v1 ();

    // -----------------------
    // Parameters
    // -----------------------
    localparam DATA_WIDTH = 8;
    localparam FILTER_N   = 5;
    localparam OUT_WIDTH  = DATA_WIDTH*2 + $clog2(FILTER_N);
    localparam CLK_CYCLE  = 10;

    // -----------------------
    // Signals
    // -----------------------
    logic clk;
    logic rst_n;

    logic [DATA_WIDTH-1:0] i_data;
    logic i_enable;
    logic i_load;

    logic [FILTER_N*DATA_WIDTH-1:0] i_params;

    logic [OUT_WIDTH-1:0] o_data;

    // -----------------------
    // Clock
    // -----------------------
    always #(CLK_CYCLE/2) clk = ~clk;

    // -----------------------
    // DUT
    // -----------------------
    fir_example #(
        .IN_WIDTH(DATA_WIDTH),
        .OUT_WIDTH(OUT_WIDTH),
        .FILTER_N(FILTER_N)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .i_data(i_data),
        .i_enable(i_enable),
        .i_load(i_load),
        .i_params(i_params),
        .o_data(o_data)
    );

    // -----------------------
    // Monitor
    // -----------------------
    initial begin
        $monitor("[Time %0t] state=%0d enable=%0b load=%0b data=%0d out=%0d",
                  $time, dut.state, i_enable, i_load, i_data, o_data);
    end

    // -----------------------
    // Stimulus
    // -----------------------
    initial begin
        $dumpfile("fir_tb_v1.vcd");
        $dumpvars();

        // Init
        clk      = 0;
        rst_n    = 0;
        i_data   = 0;
        i_enable = 0;
        i_load   = 0;

        // Init params
        i_params[0*DATA_WIDTH +: DATA_WIDTH] = 3;
        i_params[1*DATA_WIDTH +: DATA_WIDTH] = 64;
        i_params[2*DATA_WIDTH +: DATA_WIDTH] = 122;
        i_params[3*DATA_WIDTH +: DATA_WIDTH] = 64;
        i_params[4*DATA_WIDTH +: DATA_WIDTH] = 3;

        // -----------------------
        // Reset
        // -----------------------
        #(CLK_CYCLE);
        rst_n = 1;

        $display("\n=== Reset released ===");

        // -----------------------
        // Load params
        // -----------------------
        @(posedge clk);
        i_load = 1;
        i_enable = 0;

        @(posedge clk);
        i_load = 0;

        @(posedge clk);

        $display("\n=== Parameters loaded ===");
`ifdef DEBUG
        for (int i = 0; i < FILTER_N; i++) begin
            $display("param_regs[%0d] = %0d", i, dut.param_regs[i]);
        end
`endif

        // -----------------------
        // Test inputs
        // -----------------------
        $display("\n=== Start processing ===");
        i_enable = 1;

        @(posedge clk);
        i_data = 10;

        @(posedge clk);
        i_data = 20;

        @(posedge clk);
        i_data = 30;

        @(posedge clk);
        i_data = 40;

        @(posedge clk);
        i_data = 50;
        i_enable = 0;
        
        
        @(posedge clk);
        
`ifdef DEBUG
        $display("\n=== FILTER REGISTERS ===");
        for (int i = 0; i < FILTER_N; i++) begin
            $display("filt_regs[%0d] = %0d", i, dut.filt_regs[i]);
        end
`endif

        #(5*CLK_CYCLE);
        $finish;
    end

endmodule