// fpga_top_de2.sv — Top cho Terasic DE2 (Cyclone II)
module fpga_top_de2 (
  input  wire        CLOCK_50,     // osc 50 MHz
  input  wire [3:0]  KEY,          // nút bấm (active-low)
  input  wire [17:0] SW,           // 18 switch (ko dùng cũng được)
  output wire [7:0]  LEDG,         // 8 LED xanh
  output wire [17:0] LEDR          // 18 LED đỏ
);
  // Reset: KEY0 (nhả = 1)
  wire rst_n = KEY[0];

  // ===== Chia clock cho CPU =====
  // SW0 = 0: chạy chậm ~10 Hz để nhìn LED
  // SW0 = 1: chạy full 50 MHz
  localparam int DIV = 2_500_000;      // 50e6/(2*2.5e6) ≈ 10 Hz
  reg [21:0] divcnt;
  reg        slow_clk;

  always @(posedge CLOCK_50 or negedge rst_n) begin
    if (!rst_n) begin
      divcnt   <= '0;
      slow_clk <= 1'b0;
    end else begin
      if (divcnt == DIV-1) begin
        divcnt   <= '0;
        slow_clk <= ~slow_clk;
      end else begin
        divcnt <= divcnt + 1;
      end
    end
  end

  wire cpu_clk = (SW[0]) ? CLOCK_50 : slow_clk; // chọn tốc độ bằng SW0

  // ===== Core =====
  wire [31:0] a0;  // mirror x10 (đã thêm cổng a0_out trong single_cycle)
  single_cycle #(
    .DEPTH_WORDS(1024)
  ) core (
    .clk    (cpu_clk),
    .rst_n  (rst_n),
    .a0_out (a0)
  );

  // ===== LED =====
  assign LEDG[3:0]  = a0[3:0];      // hiển thị bộ đếm 4-bit
  assign LEDG[7:4]  = 4'b0001;

  // Dùng LED đỏ để “heartbeat”: chớp theo slow_clk
  assign LEDR[0]    = slow_clk;
  assign LEDR[17:1] = 17'h0;

endmodule
