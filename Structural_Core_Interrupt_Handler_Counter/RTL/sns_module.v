///////////////////////////////////////////////////////////////////////////////////////////////////
//
// Author: Swandeep_Sarmah
// About: SNS referers to Shift aNd Save functionality that is going to store upto 10 values and keep shifting like a FIFO
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

`timescale 1ns / 1ps

module sns_module#(
    parameter integer DATA_WIDTH = 32
)(
    input wire clk,
    input wire reset_n,
    input wire shift_en,
    input wire [DATA_WIDTH-1:0] new_value,

    output wire [DATA_WIDTH-1:0] value0,
    output wire [DATA_WIDTH-1:0] value1,
    output wire [DATA_WIDTH-1:0] value2,
    output wire [DATA_WIDTH-1:0] value3,
    output wire [DATA_WIDTH-1:0] value4,
    output wire [DATA_WIDTH-1:0] value5,
    output wire [DATA_WIDTH-1:0] value6,
    output wire [DATA_WIDTH-1:0] value7,
    output wire [DATA_WIDTH-1:0] value8,
    output wire [DATA_WIDTH-1:0] value9
);

    reg [DATA_WIDTH-1:0] internal_values [0:9];

    assign value0 = internal_values[0];
    assign value1 = internal_values[1];
    assign value2 = internal_values[2];
    assign value3 = internal_values[3];
    assign value4 = internal_values[4];
    assign value5 = internal_values[5];
    assign value6 = internal_values[6];
    assign value7 = internal_values[7];
    assign value8 = internal_values[8];
    assign value9 = internal_values[9];

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            internal_values[0] <= 0;
            internal_values[1] <= 0;
            internal_values[2] <= 0;
            internal_values[3] <= 0;
            internal_values[4] <= 0;
            internal_values[5] <= 0;
            internal_values[6] <= 0;
            internal_values[7] <= 0;
            internal_values[8] <= 0;
            internal_values[9] <= 0;
        end else if (shift_en) begin
            internal_values[9] <= internal_values[8];
            internal_values[8] <= internal_values[7];
            internal_values[7] <= internal_values[6];
            internal_values[6] <= internal_values[5];
            internal_values[5] <= internal_values[4];
            internal_values[4] <= internal_values[3];
            internal_values[3] <= internal_values[2];
            internal_values[2] <= internal_values[1];
            internal_values[1] <= internal_values[0];
            internal_values[0] <= new_value;
        end
    end

endmodule