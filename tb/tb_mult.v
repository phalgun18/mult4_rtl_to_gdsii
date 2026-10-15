`timescale 1ns/1ps

module tb_mult;

    // ------------------------------------------------
    // Inputs to the DUT
    // ------------------------------------------------
    reg        clk;
    reg        rst_n;
    reg  [3:0] a;
    reg  [3:0] b;

    // ------------------------------------------------
    // Output from the DUT
    // ------------------------------------------------
    wire [7:0] p;

    // ------------------------------------------------
    // DUT = Design Under Test
    // ------------------------------------------------
    mult_array dut (
        .clk   (clk),
        .rst_n (rst_n),
        .a     (a),
        .b     (b),
        .p     (p)
    );

    // ------------------------------------------------
    // Clock generation
    // Clock period = 10 ns
    // ------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------
    // Waveform generation
    // ------------------------------------------------
    initial begin
        $dumpfile("multiplier.vcd");
        $dumpvars(0, tb_mult);

        // Internal multiplier signals
        $dumpvars(0, tb_mult.dut.a_reg);
        $dumpvars(0, tb_mult.dut.b_reg);

        $dumpvars(0, tb_mult.dut.pp0);
        $dumpvars(0, tb_mult.dut.pp1);
        $dumpvars(0, tb_mult.dut.pp2);
        $dumpvars(0, tb_mult.dut.pp3);

        $dumpvars(0, tb_mult.dut.sum1);
        $dumpvars(0, tb_mult.dut.sum2);
        $dumpvars(0, tb_mult.dut.sum3);

        // Carry signals
        $dumpvars(0, tb_mult.dut.c1);
        $dumpvars(0, tb_mult.dut.c2);
        $dumpvars(0, tb_mult.dut.c3);
        $dumpvars(0, tb_mult.dut.c4);

        $dumpvars(0, tb_mult.dut.c5);
        $dumpvars(0, tb_mult.dut.c6);
        $dumpvars(0, tb_mult.dut.c7);
        $dumpvars(0, tb_mult.dut.c8);

        $dumpvars(0, tb_mult.dut.c9);
        $dumpvars(0, tb_mult.dut.c10);
        $dumpvars(0, tb_mult.dut.c11);
        $dumpvars(0, tb_mult.dut.c12);
    end

    // ------------------------------------------------
    // TEST CASES
    // ------------------------------------------------
    initial begin

        // ------------------------------------------------
        // RESET
        // ------------------------------------------------
        rst_n = 1'b0;
        a     = 4'd0;
        b     = 4'd0;

        @(posedge clk);
        @(posedge clk);

        rst_n = 1'b1;

        // ------------------------------------------------
        // TEST 1: 3 × 5 = 15
        // ------------------------------------------------
        a = 4'd3;
        b = 4'd5;

        @(posedge clk);
        @(posedge clk);

        $display("Test 1: 3 x 5 = %d", p);

        // ------------------------------------------------
        // TEST 2: 7 × 2 = 14
        // ------------------------------------------------
        a = 4'd7;
        b = 4'd2;

        @(posedge clk);
        @(posedge clk);

        $display("Test 2: 7 x 2 = %d", p);

        // ------------------------------------------------
        // TEST 3: 15 × 15 = 225
        // ------------------------------------------------
        a = 4'd15;
        b = 4'd15;

        @(posedge clk);
        @(posedge clk);

        $display("Test 3: 15 x 15 = %d", p);

        // ------------------------------------------------
        // TEST 4: 0 × 9 = 0
        // ------------------------------------------------
        a = 4'd0;
        b = 4'd9;

        @(posedge clk);
        @(posedge clk);

        $display("Test 4: 0 x 9 = %d", p);

        // ------------------------------------------------
        // End simulation
        // ------------------------------------------------
        #10;
        $finish;

    end

endmodule