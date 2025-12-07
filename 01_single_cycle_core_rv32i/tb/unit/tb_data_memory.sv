`timescale 1ns/1ps

module tb_data_memory;

  // ----------------------------------------------------------
  // Tham số test (khớp với DUT)
  // ----------------------------------------------------------
  localparam int TB_DEPTH_WORDS = 1024;
  localparam int TB_LAST_IDX    = TB_DEPTH_WORDS - 1;
  localparam int TB_LAST_ADDR   = (TB_LAST_IDX << 2);      // 0x00000FFC
  localparam int IDX_0014       = (32'h0000_0014 >> 2);    // <<-- moved here

  // Clock 10ns
  logic clk = 0;
  always #5 clk = ~clk;

  // DUT I/O
  logic        rst_n;     // active-low theo DUT
  logic [31:0] addr;
  logic [31:0] dataW;
  logic        MemRW;     // 1: write (SW), 0: read (LW)
  logic [31:0] dataR;

  // DUT
  Data_Memory #(
    .DEPTH_WORDS(TB_DEPTH_WORDS),
    .MEM_INIT   ("")
  ) dut (
    .clk   (clk),
    .rst_n (rst_n),
    .addr  (addr),
    .dataW (dataW),
    .MemRW (MemRW),
    .dataR (dataR)
  );

  // Scoreboard
  logic [31:0] score [0:TB_DEPTH_WORDS-1];

  function bit is_aligned(input [31:0] a);
    return (a[1:0] == 2'b00);
  endfunction

  function bit in_range_byteaddr(input [31:0] a);
    return (a[31:2] < TB_DEPTH_WORDS);
  endfunction

  task do_sw(input [31:0] a, input [31:0] d);
    @(negedge clk);
      addr  = a;
      dataW = d;
      MemRW = 1'b1;
    @(posedge clk); // commit

    if (is_aligned(a) && in_range_byteaddr(a))
      score[a[31:2]] = d;

    @(negedge clk);
      MemRW = 1'b0;
  endtask

  task do_lw_and_check(input [31:0] a, input bit expect_valid);
    @(negedge clk);
      addr  = a;
      MemRW = 1'b0;
    #1;

    if (expect_valid && is_aligned(a) && in_range_byteaddr(a)) begin
      if (dataR !== score[a[31:2]])
        $fatal(1, "[LW MISMATCH] addr=%h  got=%h  exp=%h", a, dataR, score[a[31:2]]);
      else
        $display("[%0t] LW  @%08h -> %08h  (OK)", $time, a, dataR);
    end else begin
      if (dataR !== 32'h0000_0000)
        $fatal(1, "[LW BAD] addr=%h ngoài/không align mà dataR=%h (exp 0)", a, dataR);
      else
        $display("[%0t] LW* @%08h -> %08h  (ngoài/không align => 0, OK)", $time, a, dataR);
    end
  endtask

  // Tests
  initial begin
    $display("\n=== TB: Data_Memory (rst_n active-low) address special cases ===");

    // Reset + init
    rst_n = 0; MemRW = 0; addr = '0; dataW = '0;
    for (int i=0; i<TB_DEPTH_WORDS; i++) score[i] = '0;

    repeat (2) @(posedge clk);
    rst_n = 1;

    // 1) SW/LW aligned
    do_sw(32'h0000_0000, 32'hDEAD_BEEF);
    do_lw_and_check(32'h0000_0000, 1);

    do_sw(32'h0000_0004, 32'hCAFE_BABE);
    do_lw_and_check(32'h0000_0004, 1);

    // 2) Misaligned WRITE
    do_sw(32'h0000_0002, 32'h1111_2222);
    do_lw_and_check(32'h0000_0000, 1);

    // 3) Overwrite then read
    do_sw(32'h0000_0000, 32'h1122_3344);
    do_lw_and_check(32'h0000_0000, 1);

    // 4) Last address
    do_sw(TB_LAST_ADDR, 32'hA5A5_5A5A);
    do_lw_and_check(TB_LAST_ADDR, 1);

    // 5) Out-of-range
    do_sw(32'h0000_1000, 32'hBADC_0DE0);
    do_lw_and_check(32'h0000_1000, 0);

    // 6) Fast address change while reading
    do_sw(32'h0000_0008, 32'h0102_0304);
    do_sw(32'h0000_000C, 32'h0506_0708);

    @(negedge clk);
      MemRW = 1'b0;
      addr  = 32'h0000_0008; #1;
      $display("[%0t] FastRead A addr=%h dataR=%h (exp %h)", $time, addr, dataR, score[addr[31:2]]);
      addr  = 32'h0000_000C; #1;
      $display("[%0t] FastRead B addr=%h dataR=%h (exp %h)", $time, addr, dataR, score[addr[31:2]]);

    // 7) Read-while-write SAME address
    do_sw(32'h0000_0010, 32'hAAAA_BBBB);
    @(negedge clk);
      addr  = 32'h0000_0010;
      MemRW = 1'b0; #1;
      $display("[%0t] R/W same PRE-posedge: dataR=%h (expect OLD=%h)",
               $time, dataR, score[addr[31:2]]);
      MemRW = 1'b1;
      dataW = 32'hCCCC_DDDD;
    @(posedge clk);
      score[addr[31:2]] = 32'hCCCC_DDDD;

    @(negedge clk);
      MemRW = 1'b0; #1;
      if (dataR !== score[addr[31:2]])
        $fatal(1, "[R/W same] POST-posedge mismatch: got=%h exp=%h", dataR, score[addr[31:2]]);
      else
        $display("[%0t] R/W same POST-posedge: dataR=%h (OK NEW)", $time, dataR);

    // 8) Read-while-write DIFFERENT address
    do_sw(32'h0000_0018, 32'h0BAD_F00D); // data cho đọc
    @(negedge clk);
      MemRW = 1'b0; addr = 32'h0000_0018; #1;
      $display("[%0t] RW-diff PRE:  read@18=%h (exp %h)", $time, dataR, score[addr[31:2]]);
      MemRW = 1'b1; addr = 32'h0000_0014; dataW = 32'hD00D_F00D;
    @(posedge clk);
      score[IDX_0014] = 32'hD00D_F00D;

    @(negedge clk);
      MemRW = 1'b0; addr = 32'h0000_0018; #1;
      if (dataR !== score[addr[31:2]])
        $fatal(1, "[RW-diff] read corrupted: got=%h exp=%h", dataR, score[addr[31:2]]);
      else
        $display("[%0t] RW-diff POST: read@18=%h (OK)", $time, dataR);

    $display("\n=== ALL CASES DONE OK ===");
    #20 $finish;
  end

endmodule
