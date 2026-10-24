`timescale 1ns/1ps

module tb_mult;
    reg        clk, rst_n;
    reg  [3:0] a, b;
    wire [7:0] p;

    integer i, j, errors, checked;

    mult_array dut (.clk(clk), .rst_n(rst_n), .a(a), .b(b), .p(p));

    // 10 ns clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // waveform (dumps all signals below tb_mult)
    initial begin
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);
    end

    initial begin
        errors  = 0;
        checked = 0;

        // reset low for 2 cycles
        rst_n = 1'b0; a = 4'd0; b = 4'd0;
        repeat (2) @(posedge clk);
        @(negedge clk) rst_n = 1'b1;

        // demo vector for the waveform screenshot: 6 x 7 = 42
        @(negedge clk) begin a = 4'd6; b = 4'd7; end
        repeat (4) @(posedge clk);

        // exhaustive test: 256 vectors
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                @(negedge clk) begin a = i[3:0]; b = j[3:0]; end
                repeat (2) @(posedge clk);   // 2-cycle latency
                #3;                          // let outputs settle
                checked = checked + 1;
                if (p !== (i * j)) begin
                    errors = errors + 1;
                    $display("MISMATCH: a=%0d b=%0d expected=%0d got=%0d",
                             i, j, i * j, p);
                end
            end
        end

        if (errors == 0)
            $display("PASS: %0d vectors checked, 0 errors", checked);
        else
            $display("FAIL: %0d vectors checked, %0d errors", checked, errors);
        $finish;
    end
endmodule