class axi_transaction;

    typedef enum bit {READ = 1'b0, WRITE = 1'b1} op_t;

    rand op_t         op;
    rand bit [15:0]   addr;
    rand bit [7:0]    len;       // AXI encoding: number of beats - 1
    rand bit [2:0]    size;      // bytes/beat = 2**size
    rand bit [31:0]   data[];    // one entry per beat

    // Fields filled by driver/monitor when useful
    bit  [31:0]       read_data[];
    bit  [1:0]        response;
    bit               saw_last;

    // Used only to stop the driver cleanly at the end of a test.
    bit               end_of_test = 0;

    constraint c_supported_size {
        size inside {[0:2]};     // 1, 2, or 4 bytes per beat for a 32-bit DUT
    }

    constraint c_reasonable_len {
        len inside {[0:7]};      // keep random bursts compact; directed tests can override
    }

    constraint c_data_size {
        data.size() == (len + 1);
    }

    constraint c_alignment {
        (addr % (1 << size)) == 0;
    }

    // Most random traffic stays inside the implemented 4 KB memory window.
    constraint c_mostly_valid_addr {
        addr dist {
            [16'h0000:16'h0FFF] :/ 90,
            [16'h1000:16'hFFFF] :/ 10
        };
    }

    function new();
    endfunction

    function int unsigned beats();
        return int'(len) + 1;
    endfunction

    function axi_transaction copy();
        axi_transaction c = new();
        c.op          = this.op;
        c.addr        = this.addr;
        c.len         = this.len;
        c.size        = this.size;
        c.response    = this.response;
        c.saw_last    = this.saw_last;
        c.end_of_test = this.end_of_test;

        c.data = new[this.data.size()];
        foreach (this.data[i])
            c.data[i] = this.data[i];

        c.read_data = new[this.read_data.size()];
        foreach (this.read_data[i])
            c.read_data[i] = this.read_data[i];

        return c;
    endfunction

    function void display(string tag = "AXI_TR");
        $display("[%0t] %s op=%s addr=0x%04h len=%0d(beats=%0d) size=%0d response=%02b",
                 $time, tag, (op == WRITE) ? "WRITE" : "READ",
                 addr, len, beats(), size, response);
        if (op == WRITE) begin
            foreach (data[i])
                $display("    WDATA[%0d] = 0x%08h", i, data[i]);
        end
        else begin
            foreach (read_data[i])
                $display("    RDATA[%0d] = 0x%08h", i, read_data[i]);
        end
    endfunction

endclass
