module axi4 #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,
    parameter MEMORY_DEPTH = 1024
)(
    input  wire                     ACLK,
    input  wire                     ARESETn,

    // Write address channel
    input  wire [ADDR_WIDTH-1:0]    AWADDR,
    input  wire [7:0]               AWLEN,
    input  wire [2:0]               AWSIZE,
    input  wire                     AWVALID,
    output reg                      AWREADY,

    // Write data channel
    input  wire [DATA_WIDTH-1:0]    WDATA,
    input  wire                     WVALID,
    input  wire                     WLAST,
    output reg                      WREADY,

    // Write response channel
    output reg [1:0]                BRESP,
    output reg                      BVALID,
    input  wire                     BREADY,

    // Read address channel
    input  wire [ADDR_WIDTH-1:0]    ARADDR,
    input  wire [7:0]               ARLEN,
    input  wire [2:0]               ARSIZE,
    input  wire                     ARVALID,
    output reg                      ARREADY,

    // Read data channel
    output reg [DATA_WIDTH-1:0]     RDATA,
    output reg [1:0]                RRESP,
    output reg                      RVALID,
    output reg                      RLAST,
    input  wire                     RREADY
);


    // ============================================================
    // Internal memory signals
    // ============================================================

    reg mem_en, mem_we;

    reg [$clog2(MEMORY_DEPTH)-1:0] mem_addr;

    reg [DATA_WIDTH-1:0] mem_wdata;

    wire [DATA_WIDTH-1:0] mem_rdata;


    // ============================================================
    // Address and burst management
    // ============================================================

    reg [ADDR_WIDTH-1:0] write_addr;
    reg [ADDR_WIDTH-1:0] read_addr;

    reg [7:0] write_burst_len;
    reg [7:0] read_burst_len;

    reg [7:0] write_burst_cnt;
    reg [7:0] read_burst_cnt;

    reg [2:0] write_size;
    reg [2:0] read_size;


    wire [ADDR_WIDTH-1:0] write_addr_incr;
    wire [ADDR_WIDTH-1:0] read_addr_incr;

    wire write_addr_valid;
    wire read_addr_valid;


    // ============================================================
    // Stored 4KB boundary result
    // ============================================================

    reg write_boundary_error;
    reg read_boundary_error;


    // ============================================================
    // Address increment calculation
    // ============================================================

    assign write_addr_incr = (1 << write_size);
    assign read_addr_incr  = (1 << read_size);


    // ============================================================
    // 4KB boundary check function
    // ============================================================

    function boundary_cross;

        input [ADDR_WIDTH-1:0] start_addr;
        input [7:0] burst_len;
        input [2:0] burst_size;

        reg [ADDR_WIDTH:0] total_bytes;
        reg [ADDR_WIDTH:0] last_addr;

        begin

            total_bytes =
                ({1'b0, burst_len} + 9'd1) << burst_size;

            last_addr =
                {1'b0, start_addr} +
                total_bytes -
                1'b1;

            boundary_cross =
                (({1'b0, start_addr} >> 12) !=
                 (last_addr >> 12));

        end

    endfunction


    // ============================================================
    // Address range check
    // ============================================================

    assign write_addr_valid =
        (write_addr >> 2) < MEMORY_DEPTH;

    assign read_addr_valid =
        (read_addr >> 2) < MEMORY_DEPTH;


    // ============================================================
    // Memory instance
    // ============================================================

    axi4_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH($clog2(MEMORY_DEPTH)),
        .DEPTH(MEMORY_DEPTH)
    ) mem_inst (
        .clk(ACLK),
        .rst_n(ARESETn),

        .mem_en(mem_en),
        .mem_we(mem_we),

        .mem_addr(mem_addr),

        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata)
    );


    // ============================================================
    // Write FSM
    // ============================================================

    reg [1:0] write_state;

    localparam W_IDLE = 2'd0,
               W_ADDR = 2'd1,
               W_DATA = 2'd2,
               W_RESP = 2'd3;


    // ============================================================
    // Read FSM
    // 4 states still require only 2 bits
    // ============================================================

    reg [1:0] read_state;

    localparam R_IDLE = 2'd0,
               R_ADDR = 2'd1,
               R_WAIT = 2'd2,
               R_DATA = 2'd3;


    // ============================================================
    // Main sequential logic
    // ============================================================

    always @(posedge ACLK or negedge ARESETn) begin

        if (!ARESETn) begin

            // ----------------------------------------------------
            // Reset outputs
            // ----------------------------------------------------

            AWREADY <= 1'b1;
            WREADY  <= 1'b0;

            BVALID <= 1'b0;
            BRESP  <= 2'b00;


            ARREADY <= 1'b1;

            RVALID <= 1'b0;
            RRESP  <= 2'b00;

            RDATA <= {DATA_WIDTH{1'b0}};
            RLAST <= 1'b0;


            // ----------------------------------------------------
            // Reset FSMs
            // ----------------------------------------------------

            write_state <= W_IDLE;
            read_state  <= R_IDLE;


            // ----------------------------------------------------
            // Reset memory signals
            // ----------------------------------------------------

            mem_en <= 1'b0;
            mem_we <= 1'b0;

            mem_addr <=
                {$clog2(MEMORY_DEPTH){1'b0}};

            mem_wdata <=
                {DATA_WIDTH{1'b0}};


            // ----------------------------------------------------
            // Reset burst information
            // ----------------------------------------------------

            write_addr <=
                {ADDR_WIDTH{1'b0}};

            read_addr <=
                {ADDR_WIDTH{1'b0}};


            write_burst_len <= 8'b0;
            read_burst_len  <= 8'b0;


            write_burst_cnt <= 8'b0;
            read_burst_cnt  <= 8'b0;


            write_size <= 3'b0;
            read_size  <= 3'b0;


            // ----------------------------------------------------
            // Reset stored boundary status
            // ----------------------------------------------------

            write_boundary_error <= 1'b0;
            read_boundary_error  <= 1'b0;

        end

        else begin

            // Default memory disable
            mem_en <= 1'b0;
            mem_we <= 1'b0;


            // ====================================================
            // WRITE CHANNEL FSM
            // ====================================================

            case (write_state)


                // ------------------------------------------------
                // W_IDLE
                // ------------------------------------------------

                W_IDLE: begin

                    AWREADY <= 1'b1;
                    WREADY  <= 1'b0;
                    BVALID  <= 1'b0;

                    if (AWVALID && AWREADY) begin

                        write_addr      <= AWADDR;
                        write_burst_len <= AWLEN;
                        write_burst_cnt <= AWLEN;
                        write_size      <= AWSIZE;

                        write_boundary_error <=
                            boundary_cross(
                                AWADDR,
                                AWLEN,
                                AWSIZE
                            );

                        AWREADY <= 1'b0;

                        write_state <= W_ADDR;

                    end

                end


                // ------------------------------------------------
                // W_ADDR
                // ------------------------------------------------

                W_ADDR: begin

                    WREADY <= 1'b1;

                    write_state <= W_DATA;

                end


                // ------------------------------------------------
                // W_DATA
                // ------------------------------------------------

                W_DATA: begin

                    if (WVALID && WREADY) begin

                        if (write_addr_valid &&
                            !write_boundary_error) begin

                            mem_en <= 1'b1;
                            mem_we <= 1'b1;

                            mem_addr <= write_addr >> 2;
                            mem_wdata <= WDATA;

                        end


                        if (WLAST ||
                            write_burst_cnt == 0) begin

                            WREADY <= 1'b0;

                            write_state <= W_RESP;


                            if (!write_addr_valid ||
                                write_boundary_error) begin

                                BRESP <= 2'b10;

                            end

                            else begin

                                BRESP <= 2'b00;

                            end


                            BVALID <= 1'b1;

                        end

                        else begin

                            write_addr <=
                                write_addr +
                                write_addr_incr;

                            write_burst_cnt <=
                                write_burst_cnt - 1'b1;

                        end

                    end

                end


                // ------------------------------------------------
                // W_RESP
                // ------------------------------------------------

                W_RESP: begin

                    if (BREADY && BVALID) begin

                        BVALID <= 1'b0;

                        BRESP <= 2'b00;

                        write_state <= W_IDLE;

                    end

                end


                default: begin

                    write_state <= W_IDLE;

                end

            endcase



            // ====================================================
            // READ CHANNEL FSM
            // ====================================================

            case (read_state)


                // ------------------------------------------------
                // R_IDLE
                // ------------------------------------------------

                R_IDLE: begin

                    ARREADY <= 1'b1;

                    RVALID <= 1'b0;
                    RLAST  <= 1'b0;

                    if (ARVALID && ARREADY) begin

                        read_addr      <= ARADDR;
                        read_burst_len <= ARLEN;
                        read_burst_cnt <= ARLEN;
                        read_size      <= ARSIZE;

                        read_boundary_error <=
                            boundary_cross(
                                ARADDR,
                                ARLEN,
                                ARSIZE
                            );

                        ARREADY <= 1'b0;

                        read_state <= R_ADDR;

                    end

                end


                // ------------------------------------------------
                // R_ADDR
                // Issue first synchronous memory read
                // ------------------------------------------------

                R_ADDR: begin

                    if (read_addr_valid &&
                        !read_boundary_error) begin

                        mem_en <= 1'b1;
                        mem_we <= 1'b0;

                        mem_addr <= read_addr >> 2;

                    end

                    // Wait one cycle for synchronous memory output
                    read_state <= R_WAIT;

                end


                // ------------------------------------------------
                // R_WAIT
                // Give memory time to update mem_rdata
                // ------------------------------------------------

                R_WAIT: begin

                    read_state <= R_DATA;

                end


                // ------------------------------------------------
                // R_DATA
                // Present correct memory data on AXI
                // ------------------------------------------------

                R_DATA: begin

                    if (read_addr_valid &&
                        !read_boundary_error) begin

                        RDATA <= mem_rdata;
                        RRESP <= 2'b00;

                    end

                    else begin

                        RDATA <=
                            {DATA_WIDTH{1'b0}};

                        RRESP <= 2'b10;

                    end


                    RVALID <= 1'b1;

                    RLAST <=
                        (read_burst_cnt == 0);


                    // ---------------------------------------------
                    // AXI read handshake
                    // ---------------------------------------------

                    if (RREADY && RVALID) begin

                        RVALID <= 1'b0;


                        if (read_burst_cnt > 0) begin

                            // Move to next burst beat
                            read_addr <=
                                read_addr +
                                read_addr_incr;

                            read_burst_cnt <=
                                read_burst_cnt - 1'b1;


                            // Issue next synchronous memory read
                            if (!read_boundary_error) begin

                                mem_en <= 1'b1;
                                mem_we <= 1'b0;

                                mem_addr <=
                                    (read_addr +
                                     read_addr_incr) >> 2;

                            end


                            // Wait for next memory result
                            read_state <= R_WAIT;

                        end

                        else begin

                            // Burst finished
                            RLAST <= 1'b0;

                            read_state <= R_IDLE;

                        end

                    end

                end


                default: begin

                    read_state <= R_IDLE;

                end

            endcase

        end

    end


endmodule