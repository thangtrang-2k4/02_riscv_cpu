module Data_Memory #(
    parameter int    DEPTH_WORDS = 1024        // 4KB = 1024 x 4B
    )(
    input  logic        clk,
    input  logic        rst_n,      // Active-low
    input  logic [31:0] addr,       // Byte address
    input  logic [31:0] dataW,      // Dữ liệu ghi (SW)
    input  logic        MemRW,      // 1: Write (SW), 0: Read (LW)
    output logic [31:0] dataR       // Dữ liệu đọc (LW)
);
    logic [31:0] mem [0:DEPTH_WORDS-1];

    // ----------------------- WRITE (sync) ------------------------
    always_ff @(posedge clk) begin
        if (MemRW && (addr[1:0] == 2'b00) && (addr[31:2] < DEPTH_WORDS)) begin
            mem[addr[31:2]] <= dataW;
        end
    end

    // ----------------------- READ (comb) -------------------------
    always_comb begin
        if (!rst_n) dataR = 32'b0;
        else if (!MemRW && (addr[1:0] == 2'b00) && (addr[31:2] < DEPTH_WORDS))
            dataR = mem[addr[31:2]];
        else
            dataR = 32'h0000_0000;
    end
endmodule
