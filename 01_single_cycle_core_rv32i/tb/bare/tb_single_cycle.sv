timeunit 1ps; timeprecision 1ps;

module tb_single_cycle;

  logic clk = 0;
  logic rst_n = 0;

  localparam string prog_hex = "/home/trangthang/documents/hoc_tap/do_an_2/single_cycle_core_rv32i/sw/out/comp.hex";

  // đưa sign_base ra khỏi initial
  localparam int unsigned sign_base = 32'h1000 >> 2; // 0x1000/4

  // dut
  single_cycle #(
    .DEPTH_WORDS(2048),
    .IMEM_INIT  (prog_hex)
  ) dut (
    .clk  (clk),
    .rst_n(rst_n)
    // .a0_out()
  );

  // clock 100mhz
  always #400 clk = ~clk;

  // reset
  initial begin
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
  end

  // run & check
  initial begin


    $display("[%0t] start simulation with %s", $time, prog_hex);

    // chạy đủ dài
    repeat (200) @(posedge clk);

    // đọc signature (giả sử mảng trong data_memory tên là 'mem')
    // nếu tên khác, đổi 'mem' cho đúng
    if (^dut.u_dmem.dataR[sign_base +: 8] === 1'bx) begin
      $display("warning: signature area contains x.");
    end else begin
      $display("signature:");
      for (int i = 0; i < 8; i++) begin
        $display("  sig[%0d] = 0x%08x", i, dut.u_dmem.dataR[sign_base + i]);
      end
    end

    $finish;
  end
endmodule
