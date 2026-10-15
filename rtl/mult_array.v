module mult_array (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [7:0] p
);

    // Input registers
    reg [3:0] a_reg;
    reg [3:0] b_reg;

    // Partial products
    wire [3:0] pp0;
    wire [3:0] pp1;
    wire [3:0] pp2;
    wire [3:0] pp3;

    // Generate partial products using AND gates
    assign pp0 = a_reg & {4{b_reg[0]}};
    assign pp1 = a_reg & {4{b_reg[1]}};
    assign pp2 = a_reg & {4{b_reg[2]}};
    assign pp3 = a_reg & {4{b_reg[3]}};

    // Intermediate sums and carries
    wire [3:0] sum1;
    wire [3:0] sum2;
    wire [3:0] sum3;

    wire c1, c2, c3, c4;
    wire c5, c6, c7, c8;
    wire c9, c10, c11, c12;

    // First adder row
    full_adder fa0 (
        .a(pp0[1]),
        .b(pp1[0]),
        .cin(1'b0),
        .sum(sum1[0]),
        .cout(c1)
    );

    full_adder fa1 (
        .a(pp0[2]),
        .b(pp1[1]),
        .cin(c1),
        .sum(sum1[1]),
        .cout(c2)
    );

    full_adder fa2 (
        .a(pp0[3]),
        .b(pp1[2]),
        .cin(c2),
        .sum(sum1[2]),
        .cout(c3)
    );

    full_adder fa3 (
        .a(1'b0),
        .b(pp1[3]),
        .cin(c3),
        .sum(sum1[3]),
        .cout(c4)
    );

    // Second adder row
    full_adder fa4 (
        .a(sum1[1]),
        .b(pp2[0]),
        .cin(1'b0),
        .sum(sum2[0]),
        .cout(c5)
    );

    full_adder fa5 (
        .a(sum1[2]),
        .b(pp2[1]),
        .cin(c5),
        .sum(sum2[1]),
        .cout(c6)
    );

    full_adder fa6 (
        .a(sum1[3]),
        .b(pp2[2]),
        .cin(c6),
        .sum(sum2[2]),
        .cout(c7)
    );

    full_adder fa7 (
        .a(c4),
        .b(pp2[3]),
        .cin(c7),
        .sum(sum2[3]),
        .cout(c8)
    );

    // Third adder row
    full_adder fa8 (
        .a(sum2[1]),
        .b(pp3[0]),
        .cin(1'b0),
        .sum(sum3[0]),
        .cout(c9)
    );

    full_adder fa9 (
        .a(sum2[2]),
        .b(pp3[1]),
        .cin(c9),
        .sum(sum3[1]),
        .cout(c10)
    );

    full_adder fa10 (
        .a(sum2[3]),
        .b(pp3[2]),
        .cin(c10),
        .sum(sum3[2]),
        .cout(c11)
    );

    full_adder fa11 (
        .a(c8),
        .b(pp3[3]),
        .cin(c11),
        .sum(sum3[3]),
        .cout(c12)
    );

    // Register inputs and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0000;
            b_reg <= 4'b0000;
            p     <= 8'b00000000;
        end
        else begin
            a_reg <= a;
            b_reg <= b;

            p[0] <= pp0[0];
            p[1] <= sum1[0];
            p[2] <= sum2[0];
            p[3] <= sum3[0];
            p[4] <= sum3[1];
            p[5] <= sum3[2];
            p[6] <= sum3[3];
            p[7] <= c12;
        end
    end

endmodule