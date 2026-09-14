module axi4_memory #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,    // For 1024 locations
    parameter DEPTH = 1024
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     mem_en,
    input  wire                     mem_we,
    input  wire [ADDR_WIDTH-1:0]    mem_addr,
    input  wire [DATA_WIDTH-1:0]    mem_wdata,
    output reg  [DATA_WIDTH-1:0]    mem_rdata
);

    // Memory array
    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    integer j;


    // ============================================================
    // Synchronous Memory Read / Write
    // ============================================================

    always @(posedge clk) begin

        // Active-low reset
        if (!rst_n) begin

            mem_rdata <= {DATA_WIDTH{1'b0}};

        end

        else if (mem_en) begin

            if (mem_we) begin

                // Write to the requested memory location
                memory[mem_addr] <= mem_wdata;

            end

            else begin

                // Read from the requested memory location
                mem_rdata <= memory[mem_addr];

            end

        end

    end


    // ============================================================
    // Initialize memory contents to zero
    // ============================================================

    initial begin

        for (j = 0; j < DEPTH; j = j + 1)
            memory[j] = {DATA_WIDTH{1'b0}};

    end


endmodule
