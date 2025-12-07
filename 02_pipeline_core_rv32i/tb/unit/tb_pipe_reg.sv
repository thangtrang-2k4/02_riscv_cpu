`timescale 1ns/1ps

module tb_pipe_reg;

  localparam int W = 32;

  logic         clk;
  logic         rst_n;
  logic         en;
  logic         flush;
  logic [W-1:0] d;
  logic [W-1:0] bubble;
  logic [W-1:0] q;

  logic [W-1:0] data_exp;
  logic [W-1:0] data_act;

  // Clock 10ns
  initial clk = 1;
  always #5 clk = ~clk;

  // DUT
  pipe_reg #(.W(W)) dut (
    .clk    (clk),
    .rst_n  (rst_n),      
    .en     (en),
    .flush  (flush),
    .d      (d),
    .bubble (bubble),
    .q      (q)
  );

  initial begin 
    rst_n  = 0;
    en     = 0;
    flush  = 0;
    bubble = 32'h00000013;  // addi x0, x0, 0
    d      = '0;

    #20 rst_n = 1;   // release reset

    // -------------------------
    // Case 1: Enable update
    // -------------------------
    $display("\n[CASE 1] en=1, flush=0 -> q=d");
    flush    = 0;
    en       = 1;
    data_exp = 32'h11112222;
    write(data_exp);
    read(data_act);
    comp(data_exp, data_act);

    data_exp = 32'h71512922;
    write(data_exp);
    read(data_act);
    comp(data_exp, data_act);

    data_exp = 32'h11452222;
    write(data_exp);
    read(data_act);
    comp(data_exp, data_act);

    // -------------------------
    // Case 2: Stall (hold value)
    // -------------------------
    $display("\n[CASE 2] en=0, flush=0 -> q hold");
    en       = 0;
    data_exp = data_act;      // kỳ vọng q giữ giá trị cũ
    write(32'hAAAA_BBBB);     // đổi d nhưng q không được đổi
    read(data_act);
    comp(data_exp, data_act);

    // -------------------------
    // Case 3: Flush
    // -------------------------
    $display("\n[CASE 3] flush=1 -> q=bubble");
    flush    = 1;
    en       = 1;
    data_exp = bubble;
    write(32'hCCCC_DDDD);     // d gì cũng phải bị bỏ
    read(data_act);
    comp(data_exp, data_act);
    // -------------------------
    // Case 4: Stall & Flush
    // -------------------------
    $display("\n[CASE 3] flush=1 -> q=bubble");
    flush    = 0;
    en       = 1;
    data_exp = 32'h11112222;
    write(data_exp);
    read(data_act);
    comp(data_exp, data_act);

    flush    = 1;
    en       = 0;
    data_exp = bubble;
    write(32'hCCCC_DDDD);     // d gì cũng phải bị bỏ
    read(data_act);
    comp(data_exp, data_act);
   
    $display("\n[TEST DONE]");
    #20 $finish;
  end

  task write (input logic [W-1:0] data);
    d = data;          // setup trước cạnh
    @(posedge clk);    // DUT chốt dữ liệu
  endtask

  task read (output logic [W-1:0] data);
    @(negedge clk);    // lấy q sau cạnh lên 1 nửa chu kỳ
    data = q;
  endtask

  task comp (input logic [W-1:0] data_exp,
             input logic [W-1:0] data_act);
    if (data_exp === data_act)
      $display("  PASS: exp=%h, act=%h", data_exp, data_act);
    else
      $display("  FAIL: exp=%h, act=%h", data_exp, data_act);
  endtask

endmodule
