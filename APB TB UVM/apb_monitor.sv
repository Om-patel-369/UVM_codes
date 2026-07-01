class monitor extends uvm_monitor;
virtual apb_int vif;
txn tx,ap_tx;
uvm_analysis_port#(txn) ap;

`uvm_component_utils(monitor)

function new(string name = "MON",uvm_component parent);
super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);

  if(!uvm_config_db#(virtual apb_int)::get(this,"","vif",vif))
`uvm_fatal("MON","vif not set/got")

ap = new("mon_ap",this);
tx = txn::type_id::create("mon_tx");

endfunction

task run_phase(uvm_phase phase);

forever begin
  @(negedge vif.pclk);
//`uvm_info("MON","into the monitor loop",UVM_LOW)

if(vif.psel && vif.penable && vif.pready) begin

tx.paddr = vif.paddr;
tx.pwrite = vif.pwrite;
tx.pslverr =vif.pslverr;
`uvm_info("MON","psel-penable-pready=1 & data captured in tx",UVM_LOW)

if(vif.pwrite) begin
tx.pwdata = vif.pwdata;
`uvm_info("MON","write data captured in tx",UVM_LOW)
end

else begin
tx.prdata = vif.prdata;
`uvm_info("MON","read data captured in tx",UVM_LOW)
end



ap_tx =new tx; 
ap_tx.print();
ap.write(ap_tx);
`uvm_info("MON","tx sent to SB",UVM_LOW)
end
end
endtask
endclass


