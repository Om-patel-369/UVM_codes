// Code your design here
module apb_slave(apb_int intf);

  logic [31:0] mem [256];
  
  always @(posedge intf.pclk) begin
    @(negedge intf.pclk);
    
    if(intf.psel) begin
    @(posedge intf.pclk);
      $display($time,"  just before pready=1");
    intf.pready <=1;
  end
  end

  always@(posedge intf.pclk) begin

  if(intf.preset) begin       //reset condition
  intf.prdata<=0;
  intf.pready<=0;
  end

else begin
  
  #1;
  
  if( intf.psel && intf.penable && intf.pwrite)begin   //write condition
    mem[intf.paddr] <= intf.pwdata;
intf.pslverr<=0;
    $display($time,"  DUT:pready=1 and data written-> %0d",mem[intf.paddr]);
    @(posedge intf.pclk);   //deassert on next cycle
intf.pready<=0;
    $display($time,"  DUT:pready=0 -w ");

end

  else if(intf.psel && intf.penable && (!intf.pwrite)) begin //read condition

intf.pready<=1;
intf.prdata <= mem[intf.paddr];
intf.pslverr <=0;

    $display($time,"  DUT:pready=1 and read data -> %0d",mem[intf.paddr]);
    @(posedge intf.pclk);   //deassert on next cycle
intf.pready<=0;

    $display($time,"  DUT:pready=0 -r");
end

end
end
endmodule