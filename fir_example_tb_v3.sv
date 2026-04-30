`timescale 1ns/1ps

module fir_example_tb_v3 ();

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
    // Output sync variables
    // -----------------------
    int expected_pipe [1:0];
    bit valid_pipe [1:0];

    // -----------------------
    // Golden reference variables
    // -----------------------
    integer file;
    integer status;
    string line;
    int dummy;

    int file_data;
    int file_param;
    int file_expected;
    int file_valid;

    logic [FILTER_N*DATA_WIDTH-1:0] csv_params;

    // -----------------------
    // Test results
    // -----------------------
    int pass_count;
    int fail_count;

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
        

        for (int i = 0; i < 2; i++) begin
            expected_pipe [i] = 0;
            valid_pipe[i] = 0;
        end


        repeat (2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        $display("\n=== Reset released ===");
    endtask

    // -----------------------
    // Push expected task
    // -----------------------
    task push_expected(
        input int expected,
        input bit valid
    );
        expected_pipe[1] = expected_pipe[0];
        valid_pipe[1]    = valid_pipe[0];

        expected_pipe[0] = expected;
        valid_pipe[0]    = valid;
    endtask

    // -----------------------
    // Load from golden reference task
    // -----------------------
    task read_vector(
        output int data,
        output logic [FILTER_N*DATA_WIDTH-1:0] params,
        output int expected,
        output int ok
    );
        begin
            ok = 0;

            status = $fscanf(file, "%d,", data);

            if (status != 1) begin
                ok = 0;
            end else begin
                for (int i = 0; i < FILTER_N; i++) begin
                    status = $fscanf(file, "%d,", file_param);
                    params[i*DATA_WIDTH +: DATA_WIDTH] = file_param[DATA_WIDTH-1:0];
                end

                status = $fscanf(file, "%d\n", expected);

                if (status == 1) begin
                    ok = 1;
                end
            end
        end
    endtask

    // -----------------------
    // Output comparison task
    // -----------------------
    task check_output;
        if (valid_pipe[1]) begin
            if (o_data !== expected_pipe[1][OUT_WIDTH-1:0]) begin
                $display("FAIL @%0t | expected=%0d got=%0d",
                        $time, expected_pipe[1], o_data);
                fail_count++;
            end else begin
                $display("PASS @%0t | expected=%0d got=%0d",
                        $time, expected_pipe[1], o_data);
                pass_count++;
            end
        end
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
    endtask

    // -----------------------
    // Data input task
    // -----------------------
    task send_sample(
        input logic [DATA_WIDTH-1:0] sample
    );
        i_load = 0;
        i_enable = 1;

        @(posedge clk);

        i_data = sample;

    endtask

    // -----------------------
    // Task for waiting for the last output
    // -----------------------
    task stop_processing;
        i_enable = 0;
        i_load   = 0;
        @(posedge clk);

        i_data   = 0;
    endtask

    // -----------------------
    // Stimulus
    // -----------------------
    initial begin
        $dumpfile("fir_tb_v3.vcd");
        $dumpvars();

        clk = 0;
        pass_count = 0;
        fail_count = 0;

        apply_reset();

        file = $fopen("fir_vectors.csv", "r");

        if (file == 0) begin
            $display("ERROR: could not open fir_vectors.csv");
            $finish;
        end

        // Skip CSV header        
        status = $fscanf(file, "%*s\n", dummy);

        // Apply remaining rows
        while (!$feof(file)) begin
            read_vector(file_data, csv_params, file_expected, status);
            if (status) begin
                if (csv_params !== i_params) begin
                    load_params(csv_params);
                end

                send_sample(file_data);
                #1;
                check_output();

                push_expected(file_expected, 1);                    

            end
        end

        $fclose(file);

        stop_processing();
        #1;
        check_output();


        $display("\n=== TEST SUMMARY ===");
        $display("PASS: %0d", pass_count);
        $display("FAIL: %0d", fail_count);
        $display("TOTAL CASES: %0d", pass_count + fail_count);

        repeat (3) @(posedge clk);
        $finish;
    end

endmodule

