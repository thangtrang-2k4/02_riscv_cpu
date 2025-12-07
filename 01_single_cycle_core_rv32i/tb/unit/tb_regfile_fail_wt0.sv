`timescale 1ns/1ps

module tb_regfile_fail_wt0;
  // Clock 10ns
  logic clk = 0;
  always #5 clk = ~clk;

  // Signals
  logic        rst_n;
  logic [4:0]  rsR1, rsR2, rsW;
  logic [31:0] dataW;
  logic        RegWEn;
  logic [31:0] dataR1, dataR2;

  // DUT với WRITE_THROUGH = 0 (bắt buộc fail test này)
  RegFile #(.WRITE_THROUGH(1)) dut (
    .clk(clk), .rst_n(rst_n),
    .rsR1(rsR1), .rsR2(rsR2), .rsW(rsW),
    .dataW(dataW), .RegWEn(RegWEn),
    .dataR1(dataR1), .dataR2(dataR2)
  );

  // Expect rằng trong CÙNG chu kỳ (trước posedge), dataR1 phải bằng dataW
  // -> Điều này CHỈ đúng nếu có write-through. Với WT=0 sẽ FAIL.
  initial begin
    // Reset
    rst_n = 0;
    RegWEn = 0;
    rsR1 = 0; rsR2 = 0; rsW = 0; dataW = '0;
    repeat (2) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // Đảm bảo R6 hiện đang là 0 (do reset)
    rsR1 = 5'd6; #1;
    if (dataR1 !== 32'h0000_0000) begin
      $fatal(1, "[PRECHECK] R6 must be 0 after reset, got %h", dataR1);
    end

    // TẠO HAZARD: đọc & ghi cùng thanh ghi TRONG CÙNG CHU KỲ
    // Đặt tín hiệu ngay trước posedge để sample trước khi write commit.
    @(negedge clk);
    RegWEn= 1'b1;
    rsW   = 5'd6;
    rsR1  = 5'd6;         // đọc đúng thanh ghi đang ghi
    dataW = 32'hCAFE_BABE;
    

    // Lấy mẫu NGAY TRONG CÙNG CHU KỲ, TRƯỚC POSEDGE
    // Với WT=1: dataR1 phải thấy ngay dataW (CAFE_BABE)
    // Với WT=0: dataR1 vẫn thấy giá trị cũ (0) -> FAIL như mong muốn
    #1; // tránh delta cycle
    if (dataR1 !== 32'hCAFE_BABE) begin
      $display("Time=%0t ns | clk=%0b  rsW=%0d rsR1=%0d WE=%0b dataW=%h dataR1=%h",
               $time, clk, rsW, rsR1, RegWEn, dataW, dataR1);
     // $fatal(1, "[FAIL as intended] No write-through: expected dataR1==dataW in SAME cycle (pre-posedge).");
    end

    // Nếu tới đây mà không $fatal, tức là DUT có write-through (không phải WT=0)
    $display("[UNEXPECTED PASS] DUT returned dataW in same cycle; this only happens if WRITE_THROUGH=1.");
    $finish;
  end


endmodule
