class txn extends uvm_sequence_item;
  rand bit [7:0] paddr;
	rand bit [31:0] pwdata;
	bit [31:0] prdata;
  rand bit pwrite; // write=1,read=0
	bit psel;
	bit penable;
	bit pready;
	bit pslverr;

  `uvm_object_utils_begin(txn)
  `uvm_field_int(paddr,UVM_DEFAULT+UVM_DEC)
  `uvm_field_int(pwdata,UVM_DEFAULT+UVM_DEC)
  `uvm_field_int(pwrite,UVM_DEFAULT)
  `uvm_field_int(prdata,UVM_DEFAULT+UVM_DEC)
  `uvm_field_int(psel,UVM_DEFAULT)
  `uvm_field_int(penable,UVM_DEFAULT)
  `uvm_field_int(pready,UVM_DEFAULT)
  `uvm_field_int(pslverr,UVM_DEFAULT)
  `uvm_object_utils_end

function new(string name = "txn");
super.new(name);
endfunction
  
  constraint map {pwdata inside {[0:999]};}

endclass

