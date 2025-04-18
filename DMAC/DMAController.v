module DMAController (
    input          iClk,
    input          iReset_n,
    // Avalon Slave Interface
    input          iChipselect,
    input          iRead,
    input          iWrite,
    input  [2:0]   iAddress,
    input  [31:0]  iWritedata,
    output [31:0]  oReaddata,
    // Avalon Read Master Interface
    output         oRM_read,
    output [31:0]  oRM_readaddress,
    input          iRM_readdatavalid,
    input          iRM_waitrequest,
    input  [31:0]  iRM_readdata,
    // Avalon Write Master Interface
    output         oWM_write,
    output [31:0]  oWM_writeaddress,
    output [31:0]  oWM_writedata,
    output [3:0]   oWM_byteenable, // <<< ADDED PORT
    input          iWM_waitrequest
);
    // Internal Signals
    wire           Start;
    wire [31:0]    Length;
    wire [31:0]    RM_startaddress;
    wire [31:0]    WM_startaddress;
    wire           WM_done;
    // FIFO Signals
    wire           FF_almostfull;
    wire           FF_writerequest;
    wire [31:0]    FF_data;
    wire           FF_empty;
    wire [31:0]    FF_q;
    wire           FF_readrequest;

    // Instantiate CONTROL_SLAVE
    CONTROL_SLAVE u_CONTROL_SLAVE (
        .iClk(iClk),
        .iReset_n(iReset_n),
        .iChipselect(iChipselect),
        .iRead(iRead),
        .iWrite(iWrite),
        .iAddress(iAddress),
        .iWritedata(iWritedata),
        .oReaddata(oReaddata),
        .RM_startaddress(RM_startaddress),
        .WM_startaddress(WM_startaddress),
        .Length(Length),
        .Start(Start),
        .WM_done(WM_done)
    );

    // Instantiate READ_MASTER (Use revised version)
    READ_MASTER u_READ_MASTER (
        .iClk(iClk),
        .iReset_n(iReset_n),
        .Start(Start),
        .Length(Length),
        .RM_startaddress(RM_startaddress),
        .FF_almostfull(FF_almostfull),
        .FF_writerequest(FF_writerequest),
        .FF_data(FF_data),
        .oRM_read(oRM_read),
        .oRM_readaddress(oRM_readaddress),
        .iRM_readdatavalid(iRM_readdatavalid),
        .iRM_waitrequest(iRM_waitrequest),
        .iRM_readdata(iRM_readdata)
    );

    // Instantiate WRITE_MASTER (Use revised version with byteenable)
    WRITE_MASTER u_WRITE_MASTER (
        .iClk(iClk),
        .iReset_n(iReset_n),
        .Start(Start),
        .Length(Length),
        .WM_startaddress(WM_startaddress),
        .FF_empty(FF_empty),
        .FF_readrequest(FF_readrequest),
        .FF_q(FF_q),
        .oWM_write(oWM_write),
        .oWM_writeaddress(oWM_writeaddress),
        .oWM_writedata(oWM_writedata),
        .oWM_byteenable(oWM_byteenable), // <<< CONNECTED PORT
        .iWM_waitrequest(iWM_waitrequest),
        .WM_done(WM_done)
    );

    // Instantiate FIFO
    wire FF_full;
    FIFO_IP	FIFO_IP_inst (
        .aclr (~iReset_n),
        .clock ( iClk ),
        .data ( FF_data ),
        .rdreq ( FF_readrequest ),
        .wrreq ( FF_writerequest ),
        .almost_full ( FF_almostfull ),
        .empty ( FF_empty ),
        .full ( FF_full ),
        .q ( FF_q )
	);

endmodule