module WRITE_MASTER (
    input          iClk,
    input          iReset_n,
    // Control Inputs
    input          Start,           // From CONTROL_SLAVE
    input  [31:0]  Length,          // Total bytes to write
    input  [31:0]  WM_startaddress, // Start address for writing
    // FIFO Interface
    input          FF_empty,        // FIFO empty signal
    output reg     FF_readrequest,  // Request to read from FIFO
    input  [31:0]  FF_q,            // Data read from FIFO
    // Avalon Write Master Interface
    output reg     oWM_write,       // Avalon write signal
    output reg [31:0] oWM_writeaddress, // Avalon write address
    output reg [31:0] oWM_writedata,   // Avalon write data
    output reg [3:0]  oWM_byteenable, // Avalon byte enable
    input          iWM_waitrequest, // Avalon wait request
    // Status Output
    output reg     WM_done          // DMA Write Master Done
);
    // State Machine States
    parameter IDLE           = 3'b000;
    parameter CHECK_FIFO     = 3'b001; // Check if data is available in FIFO
    parameter READ_FIFO      = 3'b010; // Request data from FIFO
    parameter WAIT_FIFO_DATA = 3'b011; // Wait for FIFO data (usually available next cycle)
    parameter START_WRITE    = 3'b100; // Assert write, address, data, byteenable
    parameter WAIT_WRITE_ACK = 3'b101; // Wait for waitrequest=0 first time
    parameter UPDATE_CNT     = 3'b111; // Update counters, check completion

    reg [2:0] current_state, next_state;

    // Internal Registers
    reg [31:0] bytes_remaining;
    reg [31:0] current_address;
    reg [31:0] data_to_write; // Register to hold data from FIFO

    // Initialization and State Register
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n) begin
            current_state   <= IDLE;
            bytes_remaining <= 32'd0;
            current_address <= 32'd0;
            WM_done         <= 1'b0;
            // *** ADD RESET FOR data_to_write ***
            data_to_write   <= 32'd0;
            // *** Outputs are reset below ***
        end else begin
            current_state <= next_state;
            // Update counters in UPDATE_CNT state
            if (current_state == UPDATE_CNT) begin
                current_address <= current_address + 4;
                bytes_remaining <= bytes_remaining - 4;
            end
            // Latch configuration in IDLE state when starting
            if (next_state == CHECK_FIFO && current_state == IDLE) begin
                bytes_remaining <= Length;
                current_address <= WM_startaddress;
                WM_done         <= 1'b0; // Clear done when starting a new transfer
            end
            // Set WM_done when transitioning to IDLE from UPDATE_CNT (last word processed)
            if (current_state == UPDATE_CNT && bytes_remaining <= 4) begin
                 WM_done <= 1'b1;
            end
            // Latch data from FIFO in WAIT_FIFO_DATA state (uses state *before* edge)
            // Moved this inside the 'else' block for clarity, happens concurrently
            if (current_state == READ_FIFO) begin
                 data_to_write <= FF_q;
            end
        end
    end

    // Output Logic (Registered Outputs)
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n) begin
            FF_readrequest   <= 1'b0;
            oWM_write        <= 1'b0;
            oWM_writeaddress <= 32'd0;
            oWM_writedata    <= 32'd0;
            oWM_byteenable   <= 4'b0000;
        end else begin
            // Default assignments for next cycle (registered outputs)
            FF_readrequest <= 1'b0;
            oWM_write      <= 1'b0;
            oWM_byteenable <= 4'b0000;
            // oWM_writeaddress and oWM_writedata hold previous value unless changed

            // Drive outputs based on state (using state *before* edge)
            case (current_state)
                READ_FIFO: begin // State 2
                    FF_readrequest <= 1'b1; // Request data for next cycle
                end
                START_WRITE: begin // State 4
                    oWM_write        <= 1'b1;
                    oWM_writeaddress <= current_address;
                    oWM_writedata    <= FF_q; // Use value latched on *previous* edge
                    oWM_byteenable   <= 4'b1111;
                end
                WAIT_WRITE_ACK: begin // State 5
                    oWM_write        <= 1'b1;          // Keep write asserted
                    oWM_writeaddress <= current_address; // Keep address stable
                    oWM_writedata    <= FF_q;   // Keep data stable
                    oWM_byteenable   <= 4'b1111;      // Keep byteenable asserted
                end
                // In other states, outputs driven low/inactive by defaults above
                default: begin
                end
            endcase
        end
    end

    // Next State Logic (Combinatorial)
    always @(*) begin
        next_state = current_state; // Default to stay in current state
        if (!Start) begin
            next_state = IDLE; // Reset to IDLE if Start is deasserted
        end else
        case (current_state)
            IDLE: begin // State 0
                if (Start && Length > 0) begin
                    next_state = CHECK_FIFO; // -> 1
                end else begin
                    next_state = IDLE; // -> 0
                end
            end
            CHECK_FIFO: begin // State 1
                if (!FF_empty) begin
                    next_state = READ_FIFO; // -> 2
                end else begin
                    if (bytes_remaining > 0 && Start) begin
                       next_state = CHECK_FIFO; // -> 1
                    end else begin
                       next_state = IDLE; // -> 0
                    end
                end
            end
            READ_FIFO: begin // State 2
                next_state = WAIT_FIFO_DATA; // -> 3
            end
            WAIT_FIFO_DATA: begin // State 3
                 next_state = START_WRITE; // -> 4
            end
            START_WRITE: begin // State 4
                // Immediately move to wait if write is asserted
                next_state = WAIT_WRITE_ACK; // -> 5
            end
            WAIT_WRITE_ACK: begin // State 5
                if (!iWM_waitrequest) begin
                    next_state = UPDATE_CNT; // -> 6 (Write accepted)
                end else begin
                    next_state = WAIT_WRITE_ACK; // -> 5 (Keep waiting)
                end
            end
            UPDATE_CNT: begin // State 6
                if (bytes_remaining <= 4) begin // Check before decrement
                    next_state = IDLE; // -> 0 (Transfer complete)
                end else begin
                    next_state = CHECK_FIFO; // -> 1 (More data to write)
                end
            end
            default: next_state = IDLE;
        endcase

    end

endmodule