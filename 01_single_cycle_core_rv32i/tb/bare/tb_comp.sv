`timescale 1ns/1ps

module tb_comp;

  // Clock & reset
  logic clk   = 0;
  logic rst_n = 0;

  // Sửa lại đường dẫn này cho đúng project của bạn
  localparam string PROG_HEX    = "/home/trangthang/Documents/Hoc_Tap/Do_an_2/single_cycle_core_rv32i/sw/out/comp.hex";
  localparam int    DEPTH_WORDS = 2048;

  // Base address mảng: 0x00010000 -> index theo word = 0x00010000 / 4
  localparam int unsigned BASE_WORD = 32'h0001_0000 >> 2;

  // DUT
  single_cycle #(
    .DEPTH_WORDS(DEPTH_WORDS),
    .IMEM_INIT  (PROG_HEX)
  ) dut (
    .clk  (clk),
    .rst_n(rst_n)
  );

  // Clock 100 MHz: chu kỳ 10 ns
  always #5 clk = ~clk;

  // Helper đọc thanh ghi (chỉnh path nếu RegFile khác tên)
  function automatic logic [31:0] get_reg (int idx);
    return dut.u_regfile.rf[idx];
  endfunction

  initial begin : TEST
    // ==== KHAI BÁO TẤT CẢ BIẾN Ở ĐÂY ====
    automatic logic [31:0] sum_x3, i_x8, x14;
    automatic logic [31:0] m0, m1, m2, m3;

    automatic logic [31:0] exp_m0, exp_m1, exp_m2, exp_m3;
    automatic logic [31:0] exp_sum, exp_i, exp_x14;
    // ====================================

    // Reset
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;

    $display("[%0t] Start simulation single_cycle with %s", $time, PROG_HEX);

    // Cho chương trình chạy đủ lâu để tới 'done' loop
    repeat (200) @(posedge clk);

    // Đọc thanh ghi
    sum_x3 = get_reg(3);   // x3 = sum
    i_x8   = get_reg(8);   // x8 = i
    x14    = get_reg(14);  // x14 sau BEQ NOT taken

    // Đọc mảng trong DMEM (giả sử RAM là u_dmem.dataR)
    m0 = dut.u_dmem.dataR[BASE_WORD + 0];
    m1 = dut.u_dmem.dataR[BASE_WORD + 1];
    m2 = dut.u_dmem.dataR[BASE_WORD + 2];
    m3 = dut.u_dmem.dataR[BASE_WORD + 3];

    $display("=== SINGLE CYCLE RESULT ===");
    $display("x3 (sum)   = 0x%08x (dec %0d)", sum_x3, sum_x3);
    $display("x8 (i)     = 0x%08x (dec %0d)", i_x8,   i_x8);
    $display("x14        = 0x%08x (dec %0d)", x14,    x14);

    $display("Array @ 0x00010000 (word index %0d):", BASE_WORD);
    $display("  m[0] = 0x%08x", m0);
    $display("  m[1] = 0x%08x", m1);
    $display("  m[2] = 0x%08x", m2);
    $display("  m[3] = 0x%08x", m3);

    // GÁN EXPECTED Ở ĐÂY
    exp_m0 = 32'd10;
    exp_m1 = 32'd20;
    exp_m2 = 32'hFFFF_FFFB;  // -5
    exp_m3 = 32'd15;

    exp_sum = 32'd40;
    exp_i   = 32'd4;
    exp_x14 = 32'd1;

    // Assertions
    assert (m0 == exp_m0) else $error("SINGLE: mem[0] mismatch");
    assert (m1 == exp_m1) else $error("SINGLE: mem[1] mismatch");
    assert (m2 == exp_m2) else $error("SINGLE: mem[2] mismatch");
    assert (m3 == exp_m3) else $error("SINGLE: mem[3] mismatch");

    assert (sum_x3 == exp_sum)
      else $error("SINGLE: x3 (sum) mismatch - load/store hoặc add sai?");
    assert (i_x8 == exp_i)
      else $error("SINGLE: x8 (i) mismatch - loop/branch BLT sai?");
    assert (x14 == exp_x14)
      else $error("SINGLE: x14 mismatch - BEQ NOT taken xử lý sai?");

    $display("SINGLE_CYCLE: All checks passed.");
    $finish;
  end

endmodule
