`timescale 1ns/1ps

module tb_single_cycle;

  logic clk = 0;
  logic rst_n = 0;

  localparam string PROG_HEX = "/home/trangthang/Documents/Hoc_Tap/Do_an_2/rv32i-core/sw/out/program_all.hex";

  // Đưa SIGN_BASE ra khỏi initial
  localparam int unsigned SIGN_BASE = 32'h1000 >> 2; // 0x1000/4

  // DUT
  single_cycle #(
    .DEPTH_WORDS(2048),
    .IMEM_INIT  (PROG_HEX)
  ) dut (
    .clk  (clk),
    .rst_n(rst_n)
    // .a0_out()
  );

  // Clock 100MHz
  always #5 clk = ~clk;

  // Reset
  initial begin
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
  end

  // Run & check
  initial begin


    $display("[%0t] Start simulation with %s", $time, PROG_HEX);

    // chạy đủ dài
    repeat (2000) @(posedge clk);

    // Đọc signature (giả sử mảng trong Data_Memory tên là 'mem')
    // Nếu tên khác, đổi 'mem' cho đúng
    if (^dut.u_dmem.dataR[SIGN_BASE +: 8] === 1'bX) begin
      $display("WARNING: Signature area contains X.");
    end else begin
      $display("Signature:");
      for (int i = 0; i < 8; i++) begin
        $display("  sig[%0d] = 0x%08x", i, dut.u_dmem.dataR[SIGN_BASE + i]);
      end
    end

    $finish;
  end
endmodule
