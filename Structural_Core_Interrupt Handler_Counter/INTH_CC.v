///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: INTH_CC.v
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

module INTH_CC( 
    input   wire            PCLK,
    input   wire            PRESETn,
    input   wire            PSEL,
    input   wire            PENABLE,
    input   wire            PWRITE,
    input   wire    [31:0]  PADDR,
    input   wire    [31:0]  PWDATA,
    input   wire    [31:0]  ctrl_reg,
    input   wire            ack_in,
    output  wire            irq,
    output  reg     [31:0]  values [9:0],
    output  wire    [31:0]  value0, value1, value2, value3, value4, value5, value6, value7, value8, value9
);
    wire write_en;
    wire enable;
    wire counter_en;
    assign write_en = (PSEL && PENABLE && PWRITE && (PADDR[15:0] == 16'h0004));
    assign counter_en = enable;
    
    //Internal wires
    wire            [31:0]  count_out;
    wire                    irq_signal;
    wire                    shift_en;
    
    //Register Controlled via APB
    //reg [31:0]  ctrl_reg;
    
    //Control Logic nets wiring
    control_logic u_control_logic (
        .PCLK               (PCLK),
        .PRESETn            (PRESETn),
        .ctrl_write_data    (PWDATA),  // From APB write bus
        .write_en           (write_en),// Connect the write enable
        .ack_in             (ack_in),
        .enable             (enable),
        .irq                (irq),
        .control_reg        (control_reg),
        .shift_en           (shift_en)
    );

    
    //Counter nets wiring
    counter u_counter (
        .clk                (PCLK),
        .reset_n            (PRESETn),
        .enable             (enable),
        .count              (count_out)
    );
    
    //Shift and Save Module nets wiring
    sns_module u_sns_module (
        .clk                (PCLK),
        .reset_n            (PRESETn),
        .shift_en           (shift_en),
        .new_value          (count_out),
        .value0             (value0),
        .value1             (value1),
        .value2             (value2),
        .value3             (value3),
        .value4             (value4),
        .value5             (value5),
        .value6             (value6),
        .value7             (value7),
        .value8             (value8),
        .value9             (value9)
);    
endmodule