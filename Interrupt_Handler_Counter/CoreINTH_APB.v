//AMBA-APB based Interrupt Handler Acknowledge Counter RTL
//Created by Swandeep_S on 13th feb 2025 using Verilog
//`timescale 1ns / 1ps

module APB_INT_Count#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16
) 
(
    input  wire                     PCLK,        // APB Clock
    input  wire                     PRESETn,     // APB Reset (active low)
    input  wire                     PSEL,        // APB Select
    input  wire                     PENABLE,     // APB Enable
    input  wire                     PWRITE,      // APB Write Enable
    input  wire [ADDR_WIDTH-1:0]    PADDR,       // APB Address
    input  wire [DATA_WIDTH-1:0]    PWDATA,      // APB Write Data
    output reg  [DATA_WIDTH-1:0]    PRDATA,      // APB Read Data
    output reg                      PREADY,      // APB Ready
    output reg                      PSLVERR,     // APB Slave Error
    output  wire                    linux_irq,   // Linux interrupt input
    output  wire                    lim_irq,     // Bare Metal LIM interrupt input
    output  wire                    itim_irq,    // Bare Metal ITIM interrupt input
    input  wire                     linux_ack,   // Linux interrupt acknowledgment
    input  wire                     lim_ack,     // Bare Metal LIM interrupt acknowledgment
    input  wire                     itim_ack     // Bare Metal ITIM interrupt acknowledgment
);

    // Register definitions for control and interrupt count registers
    reg [DATA_WIDTH-1:0] control_regs[0:3];          // Control registers (0x0 to 0xC)
    reg [DATA_WIDTH-1:0] linux_count[0:9];           // Linux interrupt count registers (0x10 to 0x38)
    reg [DATA_WIDTH-1:0] lim_count[0:9];             // LIM interrupt count registers (0x40 to 0x78)
    reg [DATA_WIDTH-1:0] itim_count[0:9];            // ITIM interrupt count registers (0x80 to 0xB8)

    // Error indication
    reg invalid_access;  // Internal flag for invalid access

       // Shift and update functions with counter incrementer
    task shift_up(output reg [DATA_WIDTH-1:0] count_array[0:9]);
        integer i;
        for (i = 9; i > 0; i = i - 1) begin
            count_array[i] = count_array[i - 1];
        end
    endtask

    //Shift and update logic for linux interrupt counters
    always @(posedge PCLK) begin
        if (!PRESETn) begin
            integer x;
            for (x = 0; x < 10; x = x + 1) begin
                linux_count[x] <= {DATA_WIDTH{1'b0}};
            end
        end else if (linux_irq) begin
            linux_count[0] <= linux_count[0] + 1;
        end else if (linux_ack) begin
            integer j;
            for (j = 9; j > 0; j = j - 1) begin
                linux_count[j] <= linux_count[j-1];
            end
            linux_count[0] <= 0;
        end
    end

    //Shift and update logic for lim interrupt counters
    always @(posedge PCLK) begin
        if (!PRESETn) begin
            integer y;
            for (y = 0; y < 10; y = y + 1) begin
                lim_count[y] <= {DATA_WIDTH{1'b0}};
            end
        end else if (lim_irq) begin
            lim_count [0] <= lim_count[0] + 1;
        end else if (lim_ack) begin
            integer k;
            for (k = 9; k > 0; k = k - 1) begin 
                lim_count[k] <= lim_count[k-1];
            end
            lim_count[0] <= 0;
        end
    end

    //Shift and update logic for itim interrupt counters
    always @(posedge PCLK) begin
        if (!PRESETn) begin
            integer z;
            for (z = 0; z < 10; z = z + 1) begin
                itim_count[z] <= {DATA_WIDTH{1'b0}};
            end
        end else if (itim_irq) begin
            itim_count [0] <= itim_count[0] + 1;
        end else if (itim_ack) begin
            integer l;
            for (l = 9; l > 0; l = l - 1) begin
                itim_count[l] <= itim_count[l-1];
            end
            itim_count[0] <= 0;
        end
    end 
    

    //Version Register
    localparam [31:0] VERSION = 32'h0000_0001; // Example: Version 1.0.0

    //Control Register assignment
    assign linux_irq = control_regs[1][0];
    assign lim_irq = control_regs[2][0];
    assign itim_irq = control_regs[3][0];
    
    // IRQ handling logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            // Reset all registers and error flags
            integer i;
            for (i = 1; i < 4; i = i + 1) control_regs[i] <= {DATA_WIDTH{1'b0}};
            PREADY <= 1'b0;
            PRDATA <= {DATA_WIDTH{1'b0}};
            PSLVERR <= 1'b0;
            invalid_access <= 1'b0;
        end else begin
            PREADY <= 1'b1;
            PSLVERR <= 1'b0;

            if (linux_ack) begin
                control_regs[1][0] <= 0;
            end

            if (lim_ack) begin
                control_regs[2][0] <= 0;
            end            

            if (itim_ack) begin
                control_regs[3][0] <= 0;
            end
                

            // APB Read/Write operations with error handling
            invalid_access <= 1'b0;

            if (PSEL && PENABLE) begin
                if (PWRITE) begin // Write operation
                    case (PADDR)
                        16'h0000, 16'h0004, 16'h0008, 16'h000C:
                            control_regs[(PADDR >> 2)] <= PWDATA;
                        default: begin
                            invalid_access <= 1'b1;  // Attempt to write to an invalid or read-only register
                        end
                    endcase
                end else begin
                    // Read operation and counter register assignment
                    case (PADDR)
                        16'h0000: PRDATA <= VERSION;
                        16'h0004, 16'h0008, 16'h000C: PRDATA <= control_regs[(PADDR >> 2)];
                        16'h0010: PRDATA <= linux_count[0];
                        16'h0014: PRDATA <= linux_count[1];
                        16'h0018: PRDATA <= linux_count[2];
                        16'h001C: PRDATA <= linux_count[3];
                        16'h0020: PRDATA <= linux_count[4];
                        16'h0024: PRDATA <= linux_count[5];
                        16'h0028: PRDATA <= linux_count[6];
                        16'h002C: PRDATA <= linux_count[7];
                        16'h0030: PRDATA <= linux_count[8];
                        16'h0034: PRDATA <= linux_count[9];
                        16'h0040: PRDATA <= lim_count[0];
                        16'h0044: PRDATA <= lim_count[1];
                        16'h0048: PRDATA <= lim_count[2];
                        16'h004C: PRDATA <= lim_count[3];
                        16'h0050: PRDATA <= lim_count[4];
                        16'h0054: PRDATA <= lim_count[5];
                        16'h0058: PRDATA <= lim_count[6];
                        16'h005C: PRDATA <= lim_count[7];
                        16'h0060: PRDATA <= lim_count[8];
                        16'h0064: PRDATA <= lim_count[9];
                        16'h0080: PRDATA <= itim_count[0];
                        16'h0084: PRDATA <= itim_count[1];
                        16'h0088: PRDATA <= itim_count[2];
                        16'h008C: PRDATA <= itim_count[3];
                        16'h0090: PRDATA <= itim_count[4];
                        16'h0094: PRDATA <= itim_count[5];
                        16'h0098: PRDATA <= itim_count[6];
                        16'h009C: PRDATA <= itim_count[7];
                        16'h00A0: PRDATA <= itim_count[8];
                        16'h00A4: PRDATA <= itim_count[9];
                        default: begin
                            PRDATA <= {DATA_WIDTH{1'b0}};  // Default read value for invalid addresses
                            invalid_access <= 1'b1;        // Set error flag for invalid address
                        end
                    endcase
                end 

                // Set PSLVERR if an invalid access was detected
                if (invalid_access) begin
                    PSLVERR <= 1'b1;
                    PREADY <= 1'b0;  // Stall the transaction on error
                end else begin
                    PSLVERR <= 1'b0;
                    PREADY <= 1'b1;  // Complete the transaction if no error
                end
            end else begin
                    PREADY <= 1'b0;  //PREADY always driven low when no READ or WRITE is initiated in the APB bus
            end
        end
    end
endmodule