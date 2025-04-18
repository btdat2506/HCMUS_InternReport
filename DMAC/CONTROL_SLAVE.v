module CONTROL_SLAVE (
    input          iClk,
    input          iReset_n,
    // Avalon Slave Interface
    input          iChipselect,
    input          iRead,
    input          iWrite,
    input  [2:0]   iAddress,
    input  [31:0]  iWritedata,
    output [31:0]  oReaddata,
    // DMA Configuration/Control Outputs
    output [31:0]  RM_startaddress,
    output [31:0]  WM_startaddress,
    output [31:0]  Length,
    output         Start,
    // DMA Status Input
    input          WM_done
);
    // Parameter Definitions for Addresses
    localparam ADDR_READADDRESS  = 3'd0;
    localparam ADDR_WRITEADDRESS = 3'd1;
    localparam ADDR_LENGTH       = 3'd2;
    // Address 3'd3 is unused
    localparam ADDR_CONTROL      = 3'd4;
    localparam ADDR_STATUS       = 3'd5;
    // Addresses 3'd6, 3'd7 are unused

    // Register Definitions
    reg [31:0] readaddress_reg;
    reg [31:0] writeaddress_reg;
    reg [31:0] length_reg;
    reg        control_go;      // Internal GO signal, latched
    reg        status_busy;
    reg        status_done;

    // Output Assignments
    assign RM_startaddress = readaddress_reg;
    assign WM_startaddress = writeaddress_reg;
    assign Length          = length_reg;
    assign Start           = control_go; // Start signal follows the latched GO bit

    // Read Data Output Logic (Combinatorial)
    reg [31:0] readdata_reg;
    assign oReaddata = readdata_reg;

    // Combinatorial block for read data multiplexing
    always @(*) begin
        // Default read data to 0
        readdata_reg = 32'd0;
        if (iChipselect && iRead) begin
            case (iAddress)
                ADDR_READADDRESS:  readdata_reg = readaddress_reg;
                ADDR_WRITEADDRESS: readdata_reg = writeaddress_reg;
                ADDR_LENGTH:       readdata_reg = length_reg;
                ADDR_CONTROL:      readdata_reg = {31'd0, control_go};      // Return current GO bit status
                ADDR_STATUS:       readdata_reg = {30'd0, status_busy, status_done}; // Return Busy and Done status
                default:           readdata_reg = 32'd0; // Reads from unused addresses return 0
            endcase
        end
    end

    // Register Write and State Logic (Sequential)
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n) begin
            readaddress_reg  <= 32'd0;
            writeaddress_reg <= 32'd0;
            length_reg       <= 32'd0;
            control_go       <= 1'b0;
            status_busy      <= 1'b0;
            status_done      <= 1'b0;
        end else begin
            // Handle register writes from CPU
            if (iChipselect && iWrite) begin
                case (iAddress)
                    ADDR_READADDRESS:  readaddress_reg  <= iWritedata;
                    ADDR_WRITEADDRESS: writeaddress_reg <= iWritedata;
                    ADDR_LENGTH:       length_reg       <= iWritedata;
                    ADDR_CONTROL:      control_go       <= iWritedata[0]; // Latch the GO bit from CPU
                    ADDR_STATUS: begin
                        // Bit 0: Write 1 to clear Done status
                        if (iWritedata[0]) begin
                            status_done <= 1'b0;
                        end
                        // Other bits are read-only or unused
                    end
                    default: ; // No action for unused addresses
                endcase
            end

            // Update status based on control_go and WM_done
            // If GO is asserted via CPU write (and not already busy/done), start the operation
            // Check the latched control_go signal *before* it might be cleared by WM_done
            if (control_go && !status_busy && !status_done) begin
                status_busy <= 1'b1;
                status_done <= 1'b0; // Ensure done is clear when starting
            end

            // If the Write Master signals completion THIS cycle
            if (WM_done) begin
                status_busy <= 1'b0;
                status_done <= 1'b1;
                control_go  <= 1'b0; // <<< Clear GO bit automatically on completion
            end

            // If CPU clears GO bit while busy, we might need an abort mechanism (currently ignored)
        end
    end

endmodule