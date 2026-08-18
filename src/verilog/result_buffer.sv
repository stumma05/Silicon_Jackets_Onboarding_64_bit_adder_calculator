/*
* Module describing a 64-bit result buffer and the mux for controlling where
* in the buffer an adder's result is placed.
* 
* synchronous active high reset on posedge clk
*/
import calculator_pkg::*;

module result_buffer (
    input logic clk_i,                              //clock signal
    input logic rst_i,                              //reset signal

    input logic [DATA_W - 1 : 0] result_i,       //result from ALU
    input logic loc_sel,                            //mux control signal
    output logic [MEM_WORD_SIZE-1 : 0] buffer_o   //64-bit output of buffer
);


    //TODO: Write a sequential block to write the next values into the buffer.
    always_ff @(negedge clk_i) begin
        if (rst_i) begin
            buffer_o <= '0;
        end else begin
            //Place result_i into buffer based on loc_sel
            if (~loc_sel) begin
                buffer_o[DATA_W - 1 : 0] <= result_i[DATA_W - 1 : 0];
            end else begin
                buffer_o[MEM_WORD_SIZE - 1 : DATA_W] <= result_i[DATA_W - 1 : 0];
            end
        end
    end

endmodule