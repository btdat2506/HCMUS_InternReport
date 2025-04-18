module READ_MASTER (
    input          iClk,
    input          iReset_n,
    input          Start,
    input  [31:0]  Length,
    input  [31:0]  RM_startaddress,
    input          FF_almostfull,
    output reg     FF_writerequest,
    output reg [31:0] FF_data,
    output reg     oRM_read,
    output reg [31:0] oRM_readaddress,
    input          iRM_readdatavalid,
    input          iRM_waitrequest,
    input  [31:0]  iRM_readdata
);
    // State Machine States
    parameter IDLE = 3'b000, CHECK_FIFO = 3'b001, REQUEST = 3'b010, WAIT_DATA = 3'b011, WRITE_FIFO = 3'b100, WAIT_FIFO = 3'b101;
    reg [2:0] current_state, next_state;

    // Internal Registers
    reg [31:0] bytes_remaining;
    reg [31:0] total_bytes;

    // Initialization
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n) begin
            current_state    <= IDLE;
            oRM_read         <= 1'b0;
            oRM_readaddress  <= 32'd0;
            FF_writerequest  <= 1'b0;
            FF_data          <= 32'd0;
            bytes_remaining  <= 32'd0;
            total_bytes      <= 32'd0;
        end else begin
            current_state <= next_state;
            FF_writerequest <= 1'b0;            

            case (current_state)
                IDLE: begin
                    oRM_read        <= 1'b0;
                    FF_writerequest <= 1'b0;
                    if (Start && oRM_readaddress < RM_startaddress + Length) begin
                        bytes_remaining <= Length;
                        oRM_readaddress <= RM_startaddress;
                        total_bytes     <= Length;
                    end
                end
                CHECK_FIFO: begin
                    if (!FF_almostfull) begin
                        oRM_read <= 1'b1;
                    end else begin
                        oRM_read <= 1'b0;
                    end
                end
                REQUEST, WAIT_DATA: begin
                    
                    //oRM_read <= 1'b0;
                end
                WRITE_FIFO: begin
                    if (iRM_readdatavalid) begin
                        //oRM_read        <= 1'b0;
                        FF_writerequest <= 1'b1;
                        FF_data         <= iRM_readdata;
                    end else begin
                        FF_writerequest <= 1'b0;
                    end
                end
                WAIT_FIFO: begin
                    oRM_readaddress <= oRM_readaddress + 4;
                    bytes_remaining <= bytes_remaining - 4;
                end
            endcase
        end
    end

    // Next State Logic
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (Start && oRM_readaddress < RM_startaddress + Length && !FF_almostfull)
                    next_state = CHECK_FIFO;
                else
                    next_state = IDLE;
            end
            CHECK_FIFO: begin
                if (!FF_almostfull)
                    next_state = REQUEST;
                else
                    next_state = CHECK_FIFO;
            end
            REQUEST: begin
                if (iRM_waitrequest)
                    next_state = REQUEST;
                else
                    next_state = WAIT_DATA;
            end
            WAIT_DATA: begin
                if (iRM_readdatavalid)
                    next_state = WRITE_FIFO;
                else
                    next_state = WAIT_DATA;
            end
            WRITE_FIFO: begin
                if (iRM_readdatavalid) begin
                    next_state = WAIT_FIFO;
                end else begin
                    next_state = WRITE_FIFO;
                end
                /* if (bytes_remaining == 32'd0 || oRM_readaddress == RM_startaddress + Length || FF_almostfull)
                    next_state = IDLE;
                else
                    next_state = REQUEST; */
                //next_state = WAIT_FIFO;
            end
            WAIT_FIFO: begin
                if (bytes_remaining == 32'd0 || oRM_readaddress == RM_startaddress + Length || FF_almostfull)
                    next_state = IDLE;
                else
                    next_state = REQUEST;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule

