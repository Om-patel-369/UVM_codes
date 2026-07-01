class driver extends uvm_driver#(txn);
virtual apb_int vif;
txn tx;

`uvm_component_utils(driver)

function new(string name ="drv",uvm_component parent);
super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db#(virtual apb_int)::get(this,"","vif",vif))
`uvm_fatal("DRV","vif not set/got")
endfunction

task run_phase(uvm_phase phase);

forever begin

seq_item_port.get_next_item(tx);
tx.print();
`uvm_info("DRV","got tx in driver",UVM_LOW)

@(vif.tb_cb);

vif.psel<=1;               //setup_phase
vif.pwrite <= tx.pwrite;   //pwrite =1=write else 0=read
vif.paddr <= tx.paddr;

if(tx.pwrite)
vif.pwdata <= tx.pwdata;

`uvm_info("DRV","set-up phase:req data driven on intf",UVM_LOW)
@(vif.tb_cb);             //on next clk access_phase
vif.penable<=1;
`uvm_info("DRV","access phase:penable=1",UVM_LOW)
//@(vif.tb_cb);

while(!vif.pready)begin     //
@(vif.tb_cb);
`uvm_info("DRV","waiting for pready=1",UVM_LOW)
end

 @(vif.tb_cb);
vif.penable<=0;
vif.psel<=0;
vif.pwrite <='bx; 
vif.paddr  <='bx;

seq_item_port.item_done();
`uvm_info("DRV","done with driving",UVM_LOW)
end
endtask
endclass

