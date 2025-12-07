`timescale 1ns/1ps

module tb_regfile_wt_compare;
  // Clock & reset
  logic clk = 0;
  always #5 clk = ~clk; // 10 ns period
  logic rst_n;

  // Shared stimulus to BOTH DUTs
  logic [4:0] rsR1, rsR2, rsW;
  logic [31:0] dataW;
  logic RegWEn;

  // DUT A: WRITE_THROUGH = 1
  logic [31:0] dataR1_wt, dataR2_wt;
  RegFile #(.WRITE_THROUGH(1)) dut_wt (
    .clk(clk), .rst_n(rst_n),
    .rsR1(rsR1), .rsR2(rsR2), .rsW(rsW),
    .dataW(dataW), .RegWEn(RegWEn),
    .dataR1(dataR1_wt), .dataR2(dataR2_wt)
  );

  // DUT B: WRITE_THROUGH = 0
  logic [31:0] dataR1_nwt, dataR2_nwt;
  RegFile #(.WRITE_THROUGH(0)) dut_nwt (
    .clk(clk), .rst_n(rst_n),
    .rsR1(rsR1), .rsR2(rsR2), .rsW(rsW),
    .dataW(dataW), .RegWEn(RegWEn),
    .dataR1(dataR1_nwt), .dataR2(dataR2_nwt)
  );

  // Helper: show a row
  task show(string tag="");
    $display("[%0t] %s  rsW=%0d WE=%0b dataW=%h | rsR1=%0d -> WT:%h  NWT:%h",
      $time, tag, rsW, RegWEn, dataW, rsR1, dataR1_wt, dataR1_nwt);
  endtask

  // Kịch bản tạo HAZARD: đọc & ghi cùng thanh ghi trong cùng chu kỳ
  task do_read_write_same_cycle(input [4:0] r, input [31:0] wdata);
    // Đặt tín hiệu ở giữa chu kỳ để ta có thời gian lấy mẫu TRƯỚC posedge
    @(negedge clk);                 // giữa chu kỳ
    rsW   = r;
    dataW = wdata;
    RegWEn= 1'b1;
    rsR1  = r;                      // đọc đúng thanh ghi đang ghi

    // LẤY MẪU TRƯỚC POSEDGE (khi vẫn trong cùng chu kỳ)
    #1;                             // tránh cùng delta
    show("pre-posedge  (same cycle, BEFORE write is committed)");

    // Commit ghi tại posedge
    @(posedge clk);
    // Sau posedge: cả hai đều đã ghi xong -> đều thấy wdata
    #1;
    show("post-posedge (AFTER write committed)");

    // Thả WE
    RegWEn = 1'b0;
  endtask

  initial begin
    $display("\n=== Compare WRITE_THROUGH (WT) vs NO-WT ===");

    // Reset
    rst_n = 1'b0;
    RegWEn = 0;
    rsR1 = 0; rsR2 = 0; rsW = 0; dataW = 32'h0;
    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    // 0) Sanity: ghi R3 rồi đọc lại (không có hazard)
    rsW=5'd3; dataW=32'hA5A5A5A5; RegWEn=1;
    @(posedge clk); RegWEn=0;
    rsR1=5'd3; #1;
    show("sanity read R3 (no hazard)");

    // 1) CASE CHỨNG MINH: đọc & ghi cùng R6 trong CÙNG CHU KỲ
    //    - TRƯỚC posedge:
    //        WT  -> dataR1_wt  = dataW (bypass)
    //        NWT -> dataR1_nwt = giá trị cũ (0 vì vừa reset)
    //    - SAU posedge: cả 2 cùng thấy dataW
    do_read_write_same_cycle(5'd6, 32'h12345678);

    // 2) Lặp lại với giá trị khác để chắc chắn
    do_read_write_same_cycle(5'd6, 32'hDEADBEEF);

    // 3) Kiểm tra x0 không ghi được
    @(negedge clk);
    rsW=5'd0; dataW=32'hFFFFFFFF; RegWEn=1; rsR1=5'd0;
    #1; show("x0 pre-posedge"); // WT cũng không bypass x0 vì rsW!=0 trong điều kiện hit
    @(posedge clk); RegWEn=0; #1; show("x0 post-posedge");

    $display("\n=== DONE ===");
    #20 $finish;
  end
endmodule
