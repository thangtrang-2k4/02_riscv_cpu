module IMEM #(
    parameter int    DEPTH_WORDS = 1024        // 4KB = 1024 x 4B
)(
             input  logic rst_n,
             input  logic [31:0] addr,
             output logic [31:0] inst
);
   // Dung lượng: 1024 word (4KB)
   logic [31:0] inst_mem [0:(DEPTH_WORDS - 1)];

   // ==== đọc instruction ====
   always_comb begin
     if (!rst_n)
       inst = 32'd0;                          // reset → ra 0
     else if (addr[31:2] < DEPTH_WORDS)
       inst = inst_mem[addr[31:2]];           // word addressing (bỏ 2 bit thấp)
     else
       inst = 32'h00000013;                   // ngoài phạm vi → NOP (ADDI x0,x0,0)
   end
   //assign inst = (!rst_n) ? 32'd0 : inst_mem[addr[31:2]];
   // ==== nạp nội dung chương trình ====
   initial begin
     $readmemh("C:/Users/trsng/Desktop/HOC_TAP/Do_an_2/rv32i/rv32i_single_de2/sw/out/counter.hex", inst_mem);
//#0;
   end



endmodule
