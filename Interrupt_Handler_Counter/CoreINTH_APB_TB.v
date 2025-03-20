//FSM (Finite State Machine) based Testbech to validate CoreINTH_APB
//Created by Swandeep_S on 13th feb 2025 using Verilog
`timescale 1ns/100ps

module First_Active_TB;

    reg PCLK;
    reg PRESETn;
    reg PSEL;
    reg PENABLE;
    reg PWRITE;
    reg [15:0] PADDR;
    reg [31:0] PWDATA;
    wire [31:0] PRDATA;
    reg PREADY;
    wire PSLVERR;
    wire linux_irq;
    wire lim_irq;
    wire itim_irq;
    reg linux_ack;
    reg lim_ack;
    reg itim_ack;
    reg [3:0] state;
    integer iteration;
    
    // Instantiate the DUT (Device Under Test)
    APB_INT_Count dut (
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
        .linux_irq(linux_irq),
        .lim_irq(lim_irq),
        .itim_irq(itim_irq),
        .linux_ack(linux_ack),
        .lim_ack(lim_ack),
        .itim_ack(itim_ack)
    );

    // Clock generation (50 MHz)
    initial begin
        PCLK = 0;
        forever #10 PCLK = ~PCLK;  // Clock period = 20ns
    end
    
    // Test states
    typedef enum {
        RESET,
        READ_VERSION,
        GENERATE_LINUX_IRQ,
        DEASSERT_LINUX_IRQ,
        GENERATE_LIM_IRQ,
        DEASSERT_LIM_IRQ,
        GENERATE_ITIM_IRQ,
        DEASSERT_ITIM_IRQ,
        FINISH
    } state_t;

    state_t current_state;

    // Test Procedure
    initial begin
        // Initialize signals
        PRESETn = 0; PSEL = 0; PENABLE = 0; PWRITE = 0;
        PADDR = 16'h0000; PWDATA = 32'h00000000; PREADY =0;
        linux_ack = 0; lim_ack = 0; itim_ack = 0;
        iteration = 0; state = 0;
        current_state = RESET;

        #20 PRESETn = 1;  // Release reset
    end
    
    always @(posedge PCLK) begin
            $display("Time: %t", $time);
            $display("Linux Count: 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h", 
                dut.linux_count[0], dut.linux_count[1], dut.linux_count[2], 
                dut.linux_count[3], dut.linux_count[4], dut.linux_count[5],
                dut.linux_count[6], dut.linux_count[7], dut.linux_count[8], 
                dut.linux_count[9]);
            $display("LIM Count: 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h", 
                dut.lim_count[0], dut.lim_count[1], dut.lim_count[2], 
                dut.lim_count[3], dut.lim_count[4], dut.lim_count[5],
                dut.lim_count[6], dut.lim_count[7], dut.lim_count[8], 
                dut.lim_count[9]);
            $display("ITIM Count: 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h 0x%h", 
                dut.itim_count[0], dut.itim_count[1], dut.itim_count[2], 
                dut.itim_count[3], dut.itim_count[4], dut.itim_count[5],
                dut.itim_count[6], dut.itim_count[7], dut.itim_count[8], 
                dut.itim_count[9]);
            $display("Your Counters have Finished Counting, Deja Vu!");
    end
    
    // State machine
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            current_state <= RESET;
        end else begin
                case (current_state)
                    RESET: begin
                    // Reset all signals and move to next state
                        PSEL <= 0; PENABLE <= 0; PWRITE <= 0;
                        PADDR <= 16'h0000; PWDATA <= 32'h00000000;
                        linux_ack <= 0; lim_ack <= 0; itim_ack <= 0;
                        current_state <= READ_VERSION;
                    end

                    READ_VERSION: begin
                        PSEL <= 1; PENABLE <= 1; PWRITE <= 0; PADDR <= 16'h0000;
                        #20;  // Wait for one clock cycle
                        $display("Read VERSION Register: PRDATA = 0x%h", PRDATA);
                        PSEL <= 0; PENABLE <= 0;
                        current_state <= GENERATE_LINUX_IRQ;
                    end

                    GENERATE_LINUX_IRQ: begin
                        PSEL <= 1; PENABLE <= 1; PWRITE <= 1; PADDR <= 16'h0004;
                        PWDATA <= 32'h00000001;
                        #20;  // Wait for one clock cycle
                        $display("Write to Control Register for Linux IRQ: PWDATA = 0x%h", PWDATA);
                        PSEL <= 0; PENABLE <= 0;
                        //#200;   //Wait for 10 clock cycles
                        current_state <= DEASSERT_LINUX_IRQ;
                    end

                    DEASSERT_LINUX_IRQ: begin
                        linux_ack <= 1;
                        #20;  // Wait for one clock cycle
                        $display("Deassert Linux IRQ with linux_ack = %b", linux_ack);
                        linux_ack <= 0;
                        current_state <= GENERATE_LIM_IRQ;
                    end

                    GENERATE_LIM_IRQ: begin
                        PSEL <= 1; PENABLE <= 1; PWRITE <= 1; PADDR <= 16'h0008;
                        PWDATA <= 32'h00000105;
                        #20;  // Wait for one clock cycle
                        $display("Write to Control Register for LIM IRQ: PWDATA = 0x%h", PWDATA);
                        PSEL <= 0; PENABLE <= 0;
                        //#200;   //Wait for 10 clock cycles
                        current_state <= DEASSERT_LIM_IRQ;
                    end

                    DEASSERT_LIM_IRQ: begin
                        lim_ack <= 1;
                        #20;  // Wait for one clock cycle
                        $display("Deassert LIM IRQ with lim_ack = %b", lim_ack);
                        lim_ack <= 0;
                        current_state <= GENERATE_ITIM_IRQ;
                    end

                    GENERATE_ITIM_IRQ: begin
                        PSEL <= 1; PENABLE <= 1; PWRITE <= 1; PADDR <= 16'h000C;
                        PWDATA <= 32'h00000201;
                        #20;  // Wait for one clock cycle
                        $display("Write to Control Register for ITIM IRQ: PWDATA = 0x%h", PWDATA);
                        PSEL <= 0; PENABLE <= 0;
                        //#200;   //Wait for 10 clock cycles
                        current_state <= DEASSERT_ITIM_IRQ;
                    end

                    DEASSERT_ITIM_IRQ: begin
                        itim_ack <= 1;
                        #20;  // Wait for one clock cycle
                        $display("Deassert ITIM IRQ with itim_ack = %b", itim_ack);
                        itim_ack <= 0;
                        current_state <= FINISH;
                    end
                        
                    FINISH: begin
                    if (iteration < 5) begin
                        iteration = iteration + 1;
                        current_state <= RESET;
                    end else begin
                            $display("All iterations completed.");
                            current_state <= RESET;
                        end
                    end

                    default: begin
                        $display("Error: Unknown state!");
                        $finish;
                    end
                endcase
        end
    end
endmodule