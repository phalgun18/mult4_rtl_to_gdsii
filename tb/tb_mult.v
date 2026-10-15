`timescale 1ns/1ps

module tb_mult;

    // Inputs to the DUT
    reg        clk;
    reg        rst_n;
    reg  [3:0] a;
    reg  [3:0] b;

    // Output from the DUT
    wire [7:0] p;

    // DUT = Design Under Test
    mult_array dut (
        .clk   (clk),
        .rst_n (rst_n),
        .a     (a),
        .b     (b),
        .p     (p)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Test cases
    initial begin

        // -------------------------
        // RESET
        // -------------------------
        rst_n = 1'b0;
        a = 4'd0;
        b = 4'd0;

        @(posedge clk);
        @(posedge clk);

        rst_n = 1'b1;

        // -------------------------
        // TEST 1: 3 × 5 = 15
        // -------------------------
        a = 4'd3;
        b = 4'd5;

        @(posedge clk);
        @(posedge clk);

        $display("Test 1: 3 x 5 = %d", p);

        // -------------------------
        // TEST 2: 7 × 2 = 14
        // -------------------------
        a = 4'd7;
        b = 4'd2;

        @(posedge clk);
        @(posedge clk);

        $display("Test 2: 7 x 2 = %d", p);

        // -------------------------
        // TEST 3: 15 × 15 = 225
        // -------------------------
        a = 4'd15;
        b = 4'd15;

        @(posedge clk);
        @(posedge clk);

        $display("Test 3: 15 x 15 = %d", p);

        // -------------------------
        // TEST 4: 0 × 9 = 0
        // -------------------------
        a = 4'd0;
        b = 4'd9;

        @(posedge clk);
        @(posedge clk);

        $display("Test 4: 0 x 9 = %d", p);

        // End simulation
        $finish;

    end

endmodule