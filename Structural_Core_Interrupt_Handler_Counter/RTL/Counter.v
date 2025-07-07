///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Microchip Technology INC>
//
// File: Counter.v
// File history:
//      <Revision 1.0>: <05/07/2025>: <Changes from previous Behavioral to Structural Design to accomodate better maintainability.>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Generic N-Bit Counter defaulted to 32-bit. It can be used for Counting determinism environments.>
//
// Targeted device: <Family::PolarFireSoC> <Die::MPFS095T> <Package::FCSG325>
// Author: <Swandeep_Sarmah>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

`timescale 1ns / 1ps

module counter #(
    parameter n=32)
(
    input wire clk,
    input wire reset_n,
    input wire enable,
    output reg [n-1:0] count);

always @(posedge clk or negedge reset_n) begin
        if(!reset_n)
            count <= {n{1'b0}};
        else if(enable)
            count <= count+1;
    end
endmodule