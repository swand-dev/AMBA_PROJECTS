///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: apb_interface.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::PolarFireSoC> <Die::MPFS095T> <Package::FCSG325>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

`timescale 1ns / 1ps

module apb_interface (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [31:0] PADDR,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output wire        PREADY,
    output reg         PSLVERR,
    input  wire        ack_in,
    output wire        irq
);

    parameter test = 7;
    // Internal control register and output values array
    reg [31:0] ctrl_reg;
    //reg [31:0] shifted_values [9:0];

    // PREADY is high when selected and enabled
    assign PREADY = PSEL && PENABLE;

    // INTH_CC module instantiation
    wire [31:0] value0, value1, value2, value3, value4, value5, value6, value7, value8, value9;

    INTH_CC u_inth_cc (
        .PCLK     (PCLK),
        .PRESETn  (PRESETn),
        .PSEL     (PSEL),
        .PENABLE  (PENABLE),
        .PWRITE   (PWRITE),
        .PADDR    (PADDR),
        .PWDATA   (PWDATA),
        //.PRDATA   (PRDATA),
        .ack_in   (ack_in),
        .irq      (irq),
        .ctrl_reg (ctrl_reg), // don't forget to connect this!
    
        .value0   (value0),
        .value1   (value1),
        .value2   (value2),
        .value3   (value3),
        .value4   (value4),
        .value5   (value5),
        .value6   (value6),
        .value7   (value7),
        .value8   (value8),
        .value9   (value9)
);


    // Write operation
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            ctrl_reg <= 32'b0;
            PSLVERR  <= 1'b0;
        end else if (PSEL && PENABLE && PWRITE) begin
            case (PADDR[15:0])
                16'h0004: begin
                    ctrl_reg <= PWDATA;
                    PSLVERR  <= 1'b0;
                end
                32'h10, 32'h14, 32'h18, 32'h1C,
                32'h20, 32'h24, 32'h28, 32'h2C,
                32'h30, 32'h34: begin
                    // Trying to write to a read-only counter register
                    PSLVERR <= 1'b1;
                end
                default: begin
                    PSLVERR <= 1'b1; // Invalid address
                end
            endcase
        end else begin
            PSLVERR <= 1'b0; // No write error
        end
    end

    // Read operation
    always @(*) begin
        PRDATA  = 32'h00000000;
        PSLVERR = 1'b0;

        if (PSEL && !PWRITE) begin
            case (PADDR[7:0])
                16'h04: PRDATA = ctrl_reg;
                32'h10: PRDATA = value0;
                32'h14: PRDATA = value1;
                32'h18: PRDATA = value2;
                32'h1C: PRDATA = value3;
                32'h20: PRDATA = value4;
                32'h24: PRDATA = value5;
                32'h28: PRDATA = value6;
                32'h2C: PRDATA = value7;
                32'h30: PRDATA = value8;
                32'h34: PRDATA = value9;
                default: begin
                    PRDATA  = 32'h00000000;
                    PSLVERR = 1'b1; // Invalid address
                end
            endcase
        end
    end

endmodule