`timescale 1ns/1ps
module tb_hazards;
  import rv32_pkg::*;

  // clock & reset
  logic clk = 1;
  always #5 clk = ~clk;   // 100 MHz
  logic rst_n;

  // DUT
  localparam string IMEM_FILE = "/home/trangthang/Documents/Hoc_Tap/Do_an_2/pipeline_core_rv32i/sw/out/comp.hex"; // sửa đường dẫn nếu cần

  RV32I_Pipline #(
    .DEPTH_WORDS(2048),
    .IMEM_INIT (IMEM_FILE)
  ) dut (
    .clk   (clk),
    .rst_n (rst_n)
  );

  // helper đọc thanh ghi (chỉnh path cho đúng RegFile của bạn)
  function automatic logic [31:0] get_reg (int idx);
    return dut.u_regfile.rf[idx];   // đổi theo tên mảng regfile của bạn
  endfunction

  initial begin : TEST
    // --------- KHAI BÁO TRƯỚC, KHÔNG GÁN Ở ĐÂY ---------
    automatic logic [31:0] exp_s0, exp_s1, exp_t3, exp_t4, exp_t0;
    automatic logic [31:0] got_s0, got_s1, got_t3, got_t4, got_t0;

    // --------- STATEMENTS SAU KHAI BÁO ---------
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;

    // chạy đủ lâu
    repeat (120) @(posedge clk);

    // gán giá trị kỳ vọng
    exp_s0 = 32'h0000_0100;
    exp_s1 = 32'h0000_002A;
    exp_t3 = 32'h0000_012A;
    exp_t4 = 32'h0000_0000;
    exp_t0 = 32'h0000_0100;

    // đọc kết quả thực tế
    got_s0 = get_reg(8);   // s0=x8
    got_s1 = get_reg(9);   // s1=x9
    got_t3 = get_reg(28);  // t3=x28
    got_t4 = get_reg(29);  // t4=x29
    got_t0 = get_reg(5);   // t0=x5

    $display("s0=%h (exp %h)  s1=%h (exp %h)  t3=%h (exp %h)  t4=%h (exp %h)  t0=%h (exp %h)",
              got_s0,exp_s0, got_s1,exp_s1, got_t3,exp_t3, got_t4,exp_t4, got_t0,exp_t0);

    // assert
    assert (got_s0 == exp_s0) else $error("s0 mismatch");
    assert (got_s1 == exp_s1) else $error("s1 mismatch (load-use or EX->ID base hazard)");
    assert (got_t3 == exp_t3) else $error("t3 mismatch (uses s1)");
    assert (got_t4 == exp_t4) else $error("t4 mismatch (uses s1)");
    assert (got_t0 == exp_t0) else $error("t0 mismatch");

    $finish;
  end

endmodule
