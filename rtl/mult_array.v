
module mult_array (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [7:0] p
);

    // Registers for the input operands
    reg [3:0] a_reg;
    reg [3:0] b_reg;

endmodule
