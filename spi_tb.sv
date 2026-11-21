interface spi_if(input logic clk);
    logic       rst_n;
    logic [7:0] tx_data;
    logic       start;
    logic       ready;
    logic [7:0] rx_data;
    logic       done;
    logic       sclk;
    logic       mosi;
    logic       miso;
    logic       cs_n;
    logic [7:0] slave_tx_data;
endinterface

module spi_slave (
    input  wire       sclk,
    input  wire       cs_n,
    input  wire       mosi,
    output reg        miso,
    input  wire [7:0] slave_tx_data
);
    reg [7:0] shift_reg;
    reg [2:0] bit_count;

    always @(negedge cs_n) begin
        shift_reg <= slave_tx_data;
        bit_count <= 3'd0;
        miso      <= slave_tx_data[7];
    end

    always @(posedge sclk) begin
        if (!cs_n) begin
            shift_reg <= {shift_reg[6:0], mosi};
            bit_count <= bit_count + 1'b1;
        end
    end

    always @(negedge sclk) begin
        if (!cs_n && bit_count != 3'd0) begin
            miso <= shift_reg[7];     
        end
    end
endmodule

class spi_transaction;
  rand logic [7:0]tx_data;
  rand logic [7:0]slave_tx_data;
  logic [7:0]rx_data;
  
  function void do_randomize();
    tx_data= 8'($urandom_range(254, 1));
    slave_tx_data= 8'($urandom_range(254, 1));
  endfunction
endclass

class spi_driver;
  virtual spi_if vif;
  function new(virtual spi_if vif);
    this.vif = vif;
    endfunction
    
  task drive_packet(spi_transaction tr);
    while (vif.ready ==1'b0) begin
        @(posedge vif.clk);
      end
      vif.tx_data = tr.tx_data;
      vif.slave_tx_data= tr.slave_tx_data;
      
      @(posedge vif.clk);
      vif.start= 1'b1;
      @(posedge vif.clk);
      vif.start= 1'b0;
      
      @(posedge vif.done);
      #1;
        $display("Master Sent: 0x%h | Slave Sent: 0x%h | Master Received (rx_data): 0x%h", tr.tx_data, tr.slave_tx_data, vif.rx_data);
  endtask
endclass

class spi_scoreboard;
  int pass_count=0;
  int fail_count=0;
  function void check_packet(spi_transaction tr);
    if (tr.rx_data == tr.slave_tx_data) begin
      pass_count++;
      $display("[SCOREBOARD PASS] Expected : 0x%h | Actual rx_data : 0x%h", tr.slave_tx_data, tr.rx_data);
    end else begin
      fail_count++;
      $display("[SCOREBOARD FAIL] Expected : 0x%h | Actual rx_data : 0x%h", tr.slave_tx_data, tr.rx_data);
    end
  endfunction
  
  function void report();
    $display("\n===========================");
    $display("FINAL VERIFICATION REPORT");
    $display("TOTAL PASSED %Od, TOTAL FAILED %0d", pass_count, fail_count);
    $display("==========================\n");
  endfunction
endclass

class spi_monitor;
  virtual spi_if vif;
  spi_scoreboard sb;
  
  function new( virtual spi_if vif, spi_scoreboard sb);
    this.vif = vif;
    this.sb = sb;
  endfunction
  
  task run();
    spi_transaction montr;
    forever begin
      wait(vif.done == 1'b1);
      @(posedge vif.clk);
      montr = new();
      montr.tx_data = vif.tx_data;
      montr.slave_tx_data = vif.slave_tx_data;
      montr.rx_data = vif.rx_data;
      sb.check_packet(montr);
    end
  endtask
endclass
  

module testbench_top;
  bit clk;
  always #5 clk=~clk;
  spi_if intf(clk);
  spi_master u_master(
    .clk(intf.clk), .rst_n(intf.rst_n), .tx_data(intf.tx_data), .start(intf.start),
        .ready(intf.ready), .rx_data(intf.rx_data), .done(intf.done),
        .sclk(intf.sclk), .mosi(intf.mosi), .miso(intf.miso), .cs_n(intf.cs_n)
  );
  spi_slave u_slave(
    .sclk(intf.sclk), .cs_n(intf.cs_n), .mosi(intf.mosi), .miso(intf.miso),
        .slave_tx_data(intf.slave_tx_data)
  );
  
   initial begin
        #15000; 
        $display("[ERROR] Watchdog Timeout!");
        $finish;
    end
  
  initial begin
    spi_driver dvr;
    spi_transaction tx;
    spi_scoreboard sb;
    spi_monitor mon;
    $dumpfile("dump.vcd");
    $dumpvars(0, testbench_top);
    intf.rst_n= 1'b0;
    intf.start= 1'b0;
    #20 intf.rst_n= 1'b1;
    #20
    dvr= new(intf);
    sb = new();
    mon = new(intf, sb);
    
    fork
      mon.run();
    join_none
    repeat (10) begin
      tx= new();
      tx.do_randomize();
      dvr.drive_packet(tx);
    end
    #50
    sb.report();
    $finish;
  end
endmodule
