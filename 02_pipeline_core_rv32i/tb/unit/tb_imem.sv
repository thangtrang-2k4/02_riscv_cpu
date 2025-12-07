`timescale 1ns/1ps
module tb_imem;
  // ---- signals ----
  logic clk = 0;
  logic rst_n = 0;
  logic [31:0] pc, pc_next;
  logic [31:0] inst;

  // ---- DUT chain: PC -> add4 -> IMEM ----
  Program_Counter u_pc (
    .clk    (clk),
    .rst_n  (rst_n),
    .pc_next(pc_next),
    .pc   (pc)          // ✅ đúng tên cổng
  );

  Adder u_adder (
    .a (pc),
    .b (32'd4),
    .c (pc_next)
  );

  IMEM #(
    .DEPTH_WORDS(1024),
    .INIT_FILE  ("/home/trangthang/Documents/Hoc_Tap/Do_an_2/rv32i-core/sw/out/nop_sled.hex")
  ) dut (
    .rst_n (rst_n),
    .addr  (pc),
    .inst  (inst)
  );

  // clock 50 MHz
  always #10 clk = ~clk;

  // stimulus
  initial begin
    $display("=== TB start ===");
    // giữ reset 5 chu kỳ
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
    // chạy thêm 5000 chu kỳ
    repeat (5000) @(posedge clk);
    $finish;
  end

  // (tuỳ chọn) in quan sát
  initial begin
    $monitor("[%0t] pc=%h inst=%h", $time, pc, inst);
  end
endmodule
