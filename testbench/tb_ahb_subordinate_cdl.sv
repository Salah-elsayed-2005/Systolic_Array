`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_ahb_subordinate_cdl ();

    localparam CLK_PERIOD = 10ns;
    localparam TIMEOUT = 1000;

    localparam BURST_SINGLE = 3'd0;
    localparam BURST_INCR   = 3'd1;
    localparam BURST_WRAP4  = 3'd2;
    localparam BURST_INCR4  = 3'd3;
    localparam BURST_WRAP8  = 3'd4;
    localparam BURST_INCR8  = 3'd5;
    localparam BURST_WRAP16 = 3'd6;
    localparam BURST_INCR16 = 3'd7;

    initial begin
        $dumpfile("waveform.fst");
        $dumpvars;
    end

    logic clk, n_rst;

    // clockgen
    always begin
        clk = 0;
        #(CLK_PERIOD / 2.0);
        clk = 1;
        #(CLK_PERIOD / 2.0);
    end

    task reset_dut;
    begin
        n_rst = 0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        n_rst = 1;
        @(negedge clk);
        @(negedge clk);
    end
    endtask

    logic hsel;
    logic [7:0] haddr;
    logic [2:0] hsize;
    logic [2:0] hburst;
    logic [1:0] htrans;
    logic hwrite;
    logic [63:0] hwdata;
    logic [63:0] hrdata;
    logic hresp;
    logic hready;

    logic data_ready;
    logic buffer_busy;
    logic design_busy;
    logic [63:0] systolic_out;
    logic start_inference;
    logic load_weights;
    logic [63:0] weights;
    logic [63:0] inputs;
    logic [63:0] bias;
    logic [2:0] actv_mode;
    logic store_weights;
    logic [7:0] store_inputs;

    string status;

    ahb_subordinate_cdl DUT ( .clk(clk),
        .n_rst(n_rst),
        .hsel(hsel),
        .haddr(haddr),
        .hsize(hsize[1:0]),
        .htrans(htrans),
        .hwrite(hwrite),
        .hwdata(hwdata),
        .hrdata(hrdata),
        .hresp(hresp),
        .hready(hready),

        .data_ready(data_ready),
        .buffer_busy(buffer_busy),
        .design_busy(design_busy),
        .systolic_out(systolic_out),
        .start_inference(start_inference),
        .load_weights(load_weights),
        .weights(weights),
        .inputs(inputs),
        .bias(bias),
        .actv_mode(actv_mode),
        .store_weights(store_weights),
        .store_inputs(store_inputs)
    );
    // bus model connections
    ahb_model_updated #(
        .ADDR_WIDTH(8),
        .DATA_WIDTH(8)
    ) BFM ( .clk(clk),
        // AHB-Subordinate Side
        .hsel(hsel),
        .haddr(haddr),
        .hsize(hsize),
        .htrans(htrans),
        .hburst(hburst),
        .hwrite(hwrite),
        .hwdata(hwdata),
        .hrdata(hrdata),
        .hresp(hresp),
        .hready(hready)
    );

    // Supporting Tasks
    task reset_model;
        BFM.reset_model();
    endtask

    // Read from a register without checking the value
    task enqueue_poll ( input logic [7:0] addr, input logic [1:0] size );
    logic [63:0] data [];
        begin
            data = new [1];
            data[0] = {32'hXXXX};
            //              Fields: hsel,  R/W, addr, data, exp err,         size, burst, chk prdata or not
            BFM.enqueue_transaction(1'b1, 1'b0, addr, data,    1'b0, {1'b0, size},  3'b0,            1'b0);
        end
    endtask

    // Read from a register until a requested value is observed
    task poll_until ( input logic [7:0] addr, input logic [1:0] size, input logic [63:0] data);
        int iters;
        begin
            for (iters = 0; iters < TIMEOUT; iters++) begin
                enqueue_poll(addr, size);
                execute_transactions(1);
                if(BFM.get_last_read() == data) break;
            end
            if(iters >= TIMEOUT) begin
                $error("Bus polling timeout hit.");
            end
        end
    endtask

    // Read Transaction, verifying a specific value is read
    task enqueue_read ( input logic [7:0] addr, input logic [1:0] size, input logic [63:0] exp_read );
        logic [63:0] data [];
        begin
            data = new [1];
            data[0] = exp_read;
            BFM.enqueue_transaction(1'b1, 1'b0, addr, data, 1'b0, {1'b0, size}, 3'b0, 1'b1);
        end
    endtask

    // Write Transaction
    task enqueue_write ( input logic [7:0] addr, input logic [1:0] size, input logic [63:0] wdata );
        logic [63:0] data [];
        begin
            data = new [1];
            data[0] = wdata;
            BFM.enqueue_transaction(1'b1, 1'b1, addr, data, 1'b0, {2'b0, size}, 3'b0, 1'b0);
        end
    endtask

    // Write Transaction Intended for a different subordinate from yours
    task enqueue_fakewrite ( input logic [7:0] addr, input logic [1:0] size, input logic [63:0] wdata );
        logic [63:0] data [];
        begin
            data = new [1];
            data[0] = wdata;
            BFM.enqueue_transaction(1'b0, 1'b1, addr, data, 1'b0, {1'b0, size}, 3'b0, 1'b0);
        end
    endtask

    // Create a burst read of size based on the burst type.
    // If INCR, burst size dependent on dynamic array size
    task enqueue_burst_read ( input logic [7:0] base_addr, input logic [1:0] size, input logic [2:0] burst, input logic [63:0] data [] );
        BFM.enqueue_transaction(1'b1, 1'b0, base_addr, data, 1'b0, {1'b0, size}, burst, 1'b1);
    endtask

    // Create a burst write of size based on the burst type.
    task enqueue_burst_write ( input logic [7:0] base_addr, input logic [1:0] size, input logic [2:0] burst, input logic [63:0] data [] );
        BFM.enqueue_transaction(1'b1, 1'b1, base_addr, data, 1'b0, {1'b0, size}, burst, 1'b1);
    endtask

    // Run n transactions, where a k-beat burst counts as k transactions.
    task execute_transactions (input int num_transactions);
        BFM.run_transactions(num_transactions);
    endtask

    // Finish the current transaction
    task finish_transactions();
        BFM.wait_done();
    endtask

    logic [63:0] data [];

    task setup;
    begin
        status = "SETUP";
        reset_model();
        reset_dut();
        n_rst = 0;

        data_ready = 0;
        buffer_busy = 0;
        design_busy = 0;
        systolic_out = 64'h0;
        @(negedge clk);
        n_rst = 1;
        @(negedge clk);
    end
    endtask

    initial begin
        setup();

        /****** EXAMPLE CODE ******/

        // // Always put data LSB-aligned. The model will automagically move bytes to their proper position.
        // enqueue_read(8'h1, 1'b0, 64'h00BB);
        // enqueue_write(8'h2, 1'b1, 64'h00BB);
        
        // // Example Burst Setup - Dynamic Array Required
        // data = new [8];
        // data = {64'h8888_8888_8888_8888, 64'h7777_7777_7777_7777,64'h6666_6666_6666_6666,64'h5555_5555_5555_5555,64'h4444_4444_4444_4444,64'h3333_3333_3333_3333,64'h2222_2222_2222_2222,64'h1111_1111_1111_1111};
        // enqueue_burst_read(8'hC, 1'b1, BURST_WRAP8, data);
        // execute_transactions(10); // Burst counts as 8 transactions for 8 beats
        // finish_transactions();
        /****** EXAMPLE CODE ******/

        status = "NON-SEQ";
        // write to weights register (buffer not busy)
        enqueue_write(8'h00, 2'd3, 64'hAAAA_AAAA_AAAA_AAAA);
        // write to inputs register (buffer not busy)
        enqueue_write(8'h08, 2'd3, 64'hBBBB_BBBB_BBBB_BBBB);
        // write to bias register 
        enqueue_write(8'h10, 2'd3, 64'hDDDD_DDDD_DDDD_DDDD);
        execute_transactions(3);
        finish_transactions();
        // write to weights register (buffer busy)
        buffer_busy = 1;
        enqueue_write(8'h00, 2'd3, 64'hCCCC_CCCC_CCCC_CCCC);
        execute_transactions(1);
        finish_transactions();
        buffer_busy = 0;

        // read bias register
        buffer_busy = 1;
        enqueue_read(8'h10, 2'd3, 64'hDDDD_DDDD_DDDD_DDDD);
        // read error register (lower byte)
        enqueue_read(8'h20, 2'd0, 64'h0001);
        // read error register (upper byte)
        enqueue_read(8'h21, 2'd0, 64'h0100);
        execute_transactions(3);
        finish_transactions();
        buffer_busy = 0;

        // read weight register (hresp error)
        enqueue_read(8'h00, 2'd3, 64'h0000);
        enqueue_read(8'h12, 2'd2, 64'h0000_DDDD_DDDD_0000);
        execute_transactions(2);
        finish_transactions();
        
        // write to output register (hresp error)
        enqueue_write(8'h18, 2'd3, 64'hEEEE_EEEE_EEEE_EEEE);
        execute_transactions(1);
        finish_transactions();

        // write to input register (slice)
        enqueue_write(8'h0D, 2'd1, 64'hCCCC_CCCC_CCCC_CCCC);
        execute_transactions(1);
        finish_transactions();

        // write to bias register (slice)
        enqueue_write(8'h12, 2'd2, 64'hCCCC_CCCC_CCCC_CCCC);
        // read from input register (RAW hazard)
        enqueue_read(8'h11, 2'd1, 64'h0000_0000_00CC_DD00);
        execute_transactions(2);
        finish_transactions();

        // write to control register
        enqueue_write(8'h22, 2'd0, 64'h0000_0000_0000_0001);
        // read from control register (raw hazard)
        enqueue_read(8'h22, 2'd0, 64'h0000_0000_0000_0001);
        execute_transactions(2);
        finish_transactions();

        data_ready = 1;
        design_busy = 1;
        systolic_out = 64'hFFFF_FFFF_FFFF_FFFF;

        // read from status register
        enqueue_read(8'h23, 2'd0, 64'h0000_0000_0000_0003);
        // write/read from activation register (raw hazard)
        enqueue_write(8'h24, 2'd0, 64'h0000_0000_0000_0002);
        enqueue_read(8'h24, 2'd0, 64'h0000_0000_0000_0002);
        // read from systolic output register
        enqueue_read(8'h18, 2'd3, 64'hFFFF_FFFF_FFFF_FFFF);
        execute_transactions(4);
        finish_transactions();
        data_ready = 0;
        design_busy = 0;

        status = "BURST: INCR8";
        data = new [8];
        data = {64'h8888_8888_8888_8888, 64'h7777_7777_7777_7777,64'h6666_6666_6666_6666,64'h5555_5555_5555_5555,64'h4444_4444_4444_4444,64'h3333_3333_3333_3333,64'h2222_2222_2222_2222,64'h1111_1111_1111_1111};
        enqueue_burst_write(8'h00, 2'd0, BURST_INCR8, data);
        execute_transactions(8); // Burst counts as 8 transactions for 8 beats
        finish_transactions();

        status = "BURST: INCR4";
        data = {64'h8888_8888_8888_8888, 64'h7777_7777_7777_7777,64'h6666_6666_6666_6666,64'h5555_5555_5555_5555,64'h4444_4444_4444_4444,64'h3333_3333_3333_3333,64'h2222_2222_2222_2222,64'h1111_1111_1111_1111};
        enqueue_burst_write(8'h10, 2'd1, BURST_INCR4, data);
        execute_transactions(4); // Burst counts as 8 transactions for 8 beats
        finish_transactions();

        status = "BURST: WRAP8";
        data = {64'h8888_8888_8888_8888, 64'h7777_7777_7777_7777,64'h6666_6666_6666_6666,64'h5555_5555_5555_5555,64'h4444_4444_4444_4444,64'h3333_3333_3333_3333,64'h2222_2222_2222_2222,64'h1111_1111_1111_1111};
        enqueue_burst_read(8'h12, 2'd0, BURST_WRAP8, data);
        execute_transactions(8); // Burst counts as 8 transactions for 8 beats
        finish_transactions();

        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        $finish;
    end
endmodule

/* verilator coverage_on */