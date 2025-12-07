module Data_Memory #(
    parameter int DEPTH_WORDS = 1024
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] addr,       // Byte address từ ALU
    input  logic [31:0] dataW,      // SW
    input  logic        MemRW,      // 1: write, 0: read
    output logic [31:0] dataR,      // LW

    // Thêm I/O
    input  logic [7:0]  sw,         // switch ngoài board
    output logic [7:0]  led         // led ngoài board
);
    // RAM
    logic [31:0] mem [0:DEPTH_WORDS-1];

    // Thanh ghi hold LED
    logic [7:0] led_reg;
    assign led = led_reg;

    // Địa chỉ I/O
    localparam logic [31:0] SW_ADDR  = 32'h0001_0000;
    localparam logic [31:0] LED_ADDR = 32'h0001_0004;

    // ---------------- WRITE (sync) ----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_reg <= 8'b0;
        end else begin
            // Ghi LED
            if (MemRW && (addr == LED_ADDR)) begin
                led_reg <= dataW[7:0];
            end

            // Ghi RAM bình thường
            if (MemRW && (addr[1:0] == 2'b00) &&
                (addr[31:2] < DEPTH_WORDS) &&
                (addr != LED_ADDR)) begin
                mem[addr[31:2]] <= dataW;
            end
        end
    end

    // ---------------- READ (comb) ----------------
    always_comb begin
        if (!rst_n) begin
            dataR = 32'b0;
        end else if (!MemRW && addr == SW_ADDR) begin
            // Đọc SW
            dataR = {24'b0, sw};
        end else if (!MemRW && (addr[1:0] == 2'b00) &&
                     (addr[31:2] < DEPTH_WORDS)) begin
            // Đọc RAM
            dataR = mem[addr[31:2]];
        end else begin
            dataR = 32'h0000_0000;
        end
    end

endmodule
