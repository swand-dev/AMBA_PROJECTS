///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Microchip Technology INC>
//
// File: Control_logic.v
// File history:
//      <Revision 1.0>: <05/07/2025>: <Changes from previous Behavioral to Structural Design to accomodate better maintainability.>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Control logic to set a register bit to drive the enable for counter to start counting. ENABLE_BIT parameter is set so that whenever a use requires to specify more bits to drive a logic they have the flexibility to define it according to their use case.>
//
// Targeted device: <Family::PolarFireSoC> <Die::MPFS095T> <Package::FCSG325>
// Author: <Swandeep_Sarmah>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

`timescale 1ns / 1ps

module control_logic #(
    parameter CONTROL_WIDTH = 32,
    parameter ENABLE_BIT    = 0
)(
    input  wire                     PCLK,
    input  wire                     PRESETn,

    // APB Interface signals
    input  wire [CONTROL_WIDTH-1:0] ctrl_write_data,
    input  wire                     write_en,      // HIGH during APB write

    // External input to clear control register
    input  wire                     ack_in,

    // Outputs
    output wire                     enable,        // To counter
    output reg                      irq,           // To external interrupt line
    output reg  [CONTROL_WIDTH-1:0] control_reg,
    output reg                      shift_en
);

    assign enable = control_reg[ENABLE_BIT];

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            control_reg <= {CONTROL_WIDTH{1'b0}};
            irq         <= 1'b0;
            shift_en    <= 1'b0;
        end
        else begin
            if (write_en) begin
                control_reg <= ctrl_write_data;
                if (ctrl_write_data[ENABLE_BIT]) begin
                    irq <= 1'b1;
                    //shift_en <= 1'b1;
                end else begin
                    irq <= 1'b0;
                    shift_en <= 1'b0;
                end
            end
            else if (ack_in) begin
                control_reg <= {CONTROL_WIDTH{1'b0}};
                irq <= 1'b0;
                shift_en <= 1'b0;
            end
        end
    end

endmodule