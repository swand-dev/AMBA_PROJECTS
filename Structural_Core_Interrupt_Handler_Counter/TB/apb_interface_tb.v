///////////////////////////////////////////////////////////////////////////////////////////////////
//
// Author: Swandeep Sarmah
// About: Testbench for IP block
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

`timescale 1ns/100ps

module apb_interface_tb;

    // APB signals
    reg             PCLK;
    reg             PRESETn;
    reg             PSEL;
    reg             PENABLE;
    reg             PWRITE;
    reg     [31:0]  PADDR;
    reg     [31:0]  PWDATA;
    wire    [31:0]  PRDATA;
    wire            PREADY;
    wire            PSLVERR;

    // Interrupt & ACK
    wire    irq;
    reg     ack_in;

    // FSM state and loop counter
    typedef enum reg [2:0] {
        RESET,
        WRITE_CTRL,
        WAIT_IRQ_HIGH,
        SET_ACK,
        WAIT_IRQ_LOW,
        FINISH
    } state_t;

    state_t current_state;
    integer iteration;

    // Instantiate DUT
    apb_interface dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .irq(irq),
        .ack_in(ack_in)
    );

    //assign PREADY = 1'b1;
    // Clock generation
    initial begin
        PCLK = 0;
        forever #10 PCLK = ~PCLK;  // 50MHz clock
    end

    // Initial setup
    initial begin
        // Reset all signals
        PSEL = 0;
        PENABLE = 0;
        PWRITE = 0;
        PADDR = 16'h0004;
        PWDATA = 32'h00000000;
        ack_in = 0;
        PRESETn = 0;
        iteration = 0;
        current_state = RESET;

        #50;
        PRESETn = 1;  // Release reset
    end

    // FSM logic
    always @(posedge PCLK) begin
        case (current_state)

            RESET: begin
                PSEL <= 0;
                PENABLE <= 0;
                PWRITE <= 0;
                ack_in <= 0;
                if (PRESETn) begin
                    current_state <= WRITE_CTRL;
                end
            end

            WRITE_CTRL: begin
                PSEL <= 1;
                PENABLE <= 1;
                PWRITE <= 1;
                PADDR <= 16'h0004;           // Control register address
                PWDATA <= 32'h00000001;      // Set bit[0] to start count
                $display("Cycle %0d: Writing 0x1 to Control Register at time %t", iteration+1, $time);
                current_state <= WAIT_IRQ_HIGH;
            end

            WAIT_IRQ_HIGH: begin
                PSEL <= 0;
                PENABLE <= 0;
                PWRITE <= 0;
                if (irq) begin
                    $display("Cycle %0d: IRQ asserted at time %t", iteration+1, $time);
                    current_state <= SET_ACK;
                end
            end

            SET_ACK: begin
                ack_in <= 1;
                $display("Cycle %0d: Acknowledging IRQ at time %t", iteration+1, $time);
                current_state <= WAIT_IRQ_LOW;
            end

            WAIT_IRQ_LOW: begin
                if (!irq) begin
                    ack_in <= 0;
                    $display("Cycle %0d: IRQ deasserted, count should have shifted.", iteration+1);
                    iteration <= iteration + 1;
                    if (iteration < 5)
                        current_state <= RESET;
                    else
                        current_state <= FINISH;
                end
            end

            FINISH: begin
                $display("All 5 iterations completed successfully at time %t", $time);
                $stop;
            end

            default: begin
                $display("Invalid state detected");
                $stop;
            end

        endcase
    end

endmodule