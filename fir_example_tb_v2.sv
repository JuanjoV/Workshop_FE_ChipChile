`timescale 1ns/1ps

module fir_example_tb_v2 ();

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
    // Tasks
    // -----------------------

    // -----------------------
    // Reset task
    // -----------------------
    task apply_reset;
        rst_n    = 0;
        i_data   = 0;
        i_enable = 0;
        i_load   = 0;
        i_params = 0;

        repeat (2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        $display("\n=== Reset released ===");
    endtask

    // -----------------------
    // Load task
    // -----------------------
    task load_params(
        input logic [FILTER_N*DATA_WIDTH-1:0] params
        );

        $display("\n=== Loading parameters ===");

        i_params = params;

        @(posedge clk);
        i_load   = 1;
        i_enable = 0;

        @(posedge clk);
        i_load = 0;

        @(posedge clk);

`ifdef DEBUG
        for (int i = 0; i < FILTER_N; i++) begin
            $display("param_regs[%0d] = %0d", i, dut.param_regs[i]);
        end
`endif
        $display("\n=== Parameters loaded ===");
    endtask

    // -----------------------
    // Data input task
    // -----------------------
    task send_sample(
        input logic [DATA_WIDTH-1:0] sample
    );
        i_enable = 1;
        i_load   = 0;
        @(posedge clk);

        i_data   = sample;
    endtask


    // -----------------------
    // Task for waiting for the last output
    // -----------------------
    task stop_processing;
        i_enable = 0;
        i_load   = 0;
        @(posedge clk);

        i_data   = 0;
        @(posedge clk);
    endtask

    // -----------------------
    // Stimulus
    // -----------------------

    initial begin
        $dumpfile("fir_tb_v2.vcd");
        $dumpvars();

        clk = 0;

        apply_reset();
        load_params(
            {
                8'd3,
                8'd64,
                8'd122,
                8'd64,
                8'd3
            }
        );

        @(posedge clk);
        $display("\n=== Start processing ===");

        send_sample(8'd10);
        send_sample(8'd20);
        send_sample(8'd30);
        send_sample(8'd40);
        send_sample(8'd50);
        
        stop_processing();
        
        @(posedge clk);

        repeat (20) begin
            send_sample($urandom_range(0, 255));
        end

        stop_processing();

        repeat (5) @(posedge clk);
        $finish;
    end

endmodule