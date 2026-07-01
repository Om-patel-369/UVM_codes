
`define num_of_tx 50

class seq_c extends uvm_sequence #(txn);
txn tx,rtx;

  `uvm_object_utils(seq_c)

function new(string name ="seq");
super.new("seq");
endfunction

task body();
tx = txn::type_id::create("seq_tx");
  rtx = txn::type_id::create("seq_rtx");
  
  repeat(`num_of_tx) begin

  wait_for_grant();
    assert(tx.randomize with {pwrite==1;});
send_request(tx);
wait_for_item_done();
  
wait_for_grant();
    assert(rtx.randomize with {pwrite==0;paddr==tx.paddr;});
send_request(rtx);
wait_for_item_done();

end
endtask
endclass





