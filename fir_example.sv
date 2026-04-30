
module fir_example #(
        parameter IN_WIDTH = 8,
        parameter OUT_WIDTH = IN_WIDTH,
        parameter FILTER_N = 5
    ) (
        input logic clk,
        input logic rst_n,
        input logic [IN_WIDTH-1:0] i_data,
        input logic i_enable,
        input logic i_load,
        input logic [FILTER_N*IN_WIDTH-1:0] i_params,

        output logic [OUT_WIDTH-1:0] o_data
    );

    logic [IN_WIDTH-1:0] filt_regs [FILTER_N-1:0];
    logic [IN_WIDTH-1:0] next_filt [FILTER_N-1:0];
    logic [IN_WIDTH-1:0] param_regs [FILTER_N-1:0];
    logic [IN_WIDTH-1:0] next_param [FILTER_N-1:0];
    logic [OUT_WIDTH-1:0] next_output;

    enum { STATE_IDLE, STATE_LOADING, STATE_PROCESSING} state, next_state;


    always_ff @( posedge clk ) begin : reg_controller
        if (rst_n) begin

            for (int i = 0; i < FILTER_N; i++) begin
                filt_regs[i] <= next_filt[i];
                param_regs[i] <= next_param[i];
            end

            state <= next_state;
            o_data <= next_output;

        end else begin
            state <= STATE_IDLE;
            for (int i = 0; i < FILTER_N; i++) begin
                param_regs[i] <= 0;
                filt_regs[i] <= 0;
            end
            o_data <= 0;
        end
    end


    always_comb begin : Filter_processor
        next_output = filt_regs[0] * param_regs[0];
        for (int i = 1; i < FILTER_N; i++) begin
            next_output += filt_regs[i] * param_regs [i];
        end 
    end

    always_comb begin : state_machine_controller
        next_state = state;
        for (int i = 0; i < FILTER_N; i++) begin
            next_filt[i] = filt_regs[i];
            next_param[i] = param_regs[i];
        end

        case (state)
            STATE_IDLE: begin
                if (i_enable) begin
                    next_state = STATE_PROCESSING;
                end
                if (i_load) begin
                    next_state = STATE_LOADING;
                end
            end
            STATE_LOADING: begin
                if (~i_load) begin
                    next_state = STATE_IDLE;
                end
                for (int i = 0; i < FILTER_N; i++) begin
                    next_param[i] = i_params[i *IN_WIDTH +: IN_WIDTH];
                end
            end
            STATE_PROCESSING: begin
                if (~i_enable) begin
                    next_state = STATE_IDLE;
                end
                for (int i = 1; i < FILTER_N; i++) begin
                    next_filt[i] = filt_regs[i-1];
                end
                /* Bug creado a proposito */
                if (i_data == 'd45 || i_data == 'd133) begin
                    next_filt[0] = 0;
                end else begin
                    next_filt[0] = i_data;
                end
                
            end
            default: begin
                next_state = STATE_IDLE;
            end
        endcase

    end

`ifdef DEBUG
    logic [FILTER_N*IN_WIDTH-1:0] debug_filt_regs;
    logic [FILTER_N*IN_WIDTH-1:0] debug_param_regs;

    always_comb begin
        for (int i = 0; i < FILTER_N; i++) begin
            debug_filt_regs[i*IN_WIDTH +: IN_WIDTH] = filt_regs[i];
            debug_param_regs[i*IN_WIDTH +: IN_WIDTH] = param_regs[i];
        end
    end
`endif


    
endmodule