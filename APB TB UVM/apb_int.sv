interface apb_int(input bit pclk,input bit preset);
	logic psel;
	logic pwrite;
	logic penable;
	logic pready;
	logic pslverr; //optional
	logic [7:0] paddr;
	logic [31:0] pwdata;
	logic [31:0]prdata;

  clocking dut_cb @(posedge pclk);
  input psel,pwdata,pwrite,paddr,penable;
  output prdata,pready,pslverr;
  endclocking

  clocking tb_cb @(posedge pclk);
  output psel,pwdata,pwrite,paddr,penable;
  input prdata,pready,pslverr;
  endclocking

endinterface

