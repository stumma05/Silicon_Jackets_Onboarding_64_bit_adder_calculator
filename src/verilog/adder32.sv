/*
* Module describing a 32-bit ripple carry adder, with no carry output or input
*/
import calculator_pkg::*;

module adder32 (
    input logic [DATA_W - 1 : 0] a_i,
    input logic [DATA_W - 1 : 0] b_i,
    output logic [DATA_W - 1 : 0] sum_o
);

    //TODO: use a generate block to chain together 32 full adders. 
    // Imagine you are connecting 32 single-bit adder modules together.

    logic carry[DATA_W - 1 : 0];

    full_adder fa0 (
        .a(a_i[0]),
        .b(b_i[0]),
        .cin(1'b0),
        .s(sum_o[0]),
        .cout(carry[0])
    );

    genvar i; 
    generate
        for (i = 1; i < DATA_W; i++) begin: adder_links
            full_adder fa (
                .a(a_i[i]),
                .b(b_i[i]),
                .cin(carry[i - 1]),
                .s(sum_o[i]),
                .cout(carry[i])
            );
        end
        
    endgenerate

endmodule