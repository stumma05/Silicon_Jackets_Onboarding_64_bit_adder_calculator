module calc_tb_top;

  import calc_tb_pkg::*;
  import calculator_pkg::*;

  parameter int DataSize = DATA_W;
  parameter int AddrSize = ADDR_W;
  logic clk = 0;
  logic rst;
  state_t state;
  logic [DataSize-1:0] rd_data;

  calc_if #(.DataSize(DataSize), .AddrSize(AddrSize)) calc_if(.clk(clk));
  top_lvl my_calc(
    .clk(clk),
    .rst(calc_if.reset),
    `ifdef VCS
    .read_start_addr(calc_if.read_start_addr),
    .read_end_addr(calc_if.read_end_addr),
    .write_start_addr(calc_if.write_start_addr),
    .write_end_addr(calc_if.write_end_addr)
    `endif
    `ifdef CADENCE
    .read_start_addr(calc_if.calc.read_start_addr),
    .read_end_addr(calc_if.calc.read_end_addr),
    .write_start_addr(calc_if.calc.write_start_addr),
    .write_end_addr(calc_if.calc.write_end_addr)
    `endif
  );

  assign rst = calc_if.reset;
  assign state = my_calc.u_ctrl.state;
  `ifdef VCS
  assign calc_if.wr_en = my_calc.write;
  assign calc_if.rd_en = my_calc.read;
  assign calc_if.wr_data = my_calc.w_data;
  assign calc_if.rd_data = my_calc.r_data;
  assign calc_if.ready = my_calc.u_ctrl.state == S_END;
  assign calc_if.curr_rd_addr = my_calc.r_addr;
  assign calc_if.curr_wr_addr = my_calc.w_addr;
  assign calc_if.loc_sel = my_calc.buffer_control;
  `endif
  `ifdef CADENCE
  assign calc_if.calc.wr_en = my_calc.write;
  assign calc_if.calc.rd_en = my_calc.read;
  assign calc_if.calc.wr_data = my_calc.w_data;
  assign calc_if.calc.rd_data = my_calc.r_data;
  assign calc_if.calc.ready = my_calc.u_ctrl.state == S_END;
  assign calc_if.calc.curr_rd_addr = my_calc.r_addr;
  assign calc_if.calc.curr_wr_addr = my_calc.w_addr;
  assign calc_if.calc.loc_sel = my_calc.buffer_control;
  `endif

  calc_tb_pkg::calc_driver #(.DataSize(DataSize), .AddrSize(AddrSize)) calc_driver_h;
  calc_tb_pkg::calc_sequencer #(.DataSize(DataSize), .AddrSize(AddrSize)) calc_sequencer_h;
  calc_tb_pkg::calc_monitor #(.DataSize(DataSize), .AddrSize(AddrSize)) calc_monitor_h;
  calc_tb_pkg::calc_sb #(.DataSize(DataSize), .AddrSize(AddrSize)) calc_sb_h;

  always #5 clk = ~clk;

  task write_sram(input [AddrSize-1:0] addr, input [DataSize-1:0] data, input logic block_sel);
    @(posedge clk);
    if (!block_sel) begin
      my_calc.sram_A.mem[addr] = data;
    end
    else begin
      my_calc.sram_B.mem[addr] = data;
    end
    calc_driver_h.initialize_sram(addr, data, block_sel);
  endtask

  initial begin
    `ifdef VCS
    $fsdbDumpon;
    $fsdbDumpfile("simulation.fsdb");
    $fsdbDumpvars(0, calc_tb_top, "+mda", "+all", "+trace_process");
    $fsdbDumpMDA;
    `endif
    `ifdef CADENCE
    $shm_open("waves.shm");
    $shm_probe("AC");
    `endif

    calc_monitor_h = new(calc_if);
    calc_sb_h = new(calc_monitor_h.mon_box);
    calc_sequencer_h = new();
    calc_driver_h = new(calc_if, calc_sequencer_h.calc_box);
    fork
      calc_monitor_h.main();
      calc_sb_h.main();
    join_none
    
    //SRAM test
    $display("Read/Write SRAM test");
    $display("SRAM A");
    calc_if.cb.loc_sel <= 1'b0;
    calc_if.cb.wr_data <= 3214532;
    calc_if.cb.curr_wr_addr <= 0;
    calc_if.cb.wr_en <= 1'b1;
    repeat(2) @(posedge clk);
    calc_if.cb.wr_en <= 1'b0;
    repeat(2) @(posedge clk);
    calc_if.cb.curr_rd_addr <= 0;
    calc_if.cb.rd_en <= 1'b1;
    repeat(2) @(posedge clk);
    if (calc_if.cb.rd_data != 3214532) begin
      $display("SRAM Read/Write error");
    end else begin
      $display("SRAM Read/Write Success");
    end
    calc_if.cb.rd_en <= 1'b0;

    $display("SRAM B");
    calc_if.cb.loc_sel <= 1'b1;
    calc_if.cb.wr_data <= 3214532;
    calc_if.cb.curr_wr_addr <= 0;
    calc_if.cb.wr_en <= 1'b1;
    repeat(2) @(posedge clk);
    calc_if.cb.wr_en <= 1'b0;
    repeat(2) @(posedge clk);
    calc_if.cb.curr_rd_addr <= 0;
    calc_if.cb.rd_en <= 1'b1;
    repeat(2) @(posedge clk);
    if (calc_if.cb.rd_data != 3214532) begin
      $display("SRAM Read/Write error");
    end else begin
      $display("SRAM Read/Write Success");
    end
    calc_if.cb.rd_en <= 1'b0;

    repeat(10) @(posedge clk);
    



    // Directed part
    $display("Directed Testing");

    $display("Testing state transitions");
    write_sram(0, 123, 0);
    write_sram(0, 3425, 1);
    write_sram(1, 856874, 0);
    write_sram(1, 12709, 1);
    fork
      calc_driver_h.start_calc(0, 1, 2, 2);
      begin
        wait (state == S_READ);
        $display("[%0t] Applying reset", $time);
        calc_if.cb.reset <= 1'b1;       // Assert reset
        repeat(5) @(calc_if.cb);     // Wait 5 clock cycles
        calc_if.cb.reset <= 1'b0;       // Deassert reset
        @(calc_if.cb);               // Wait 1 more cycle
        $display("[%0t] Reset deasserted", $time);
      end
    join

    repeat(10) @(posedge clk);

    write_sram(0, 123, 0);
    write_sram(0, 3425, 1);
    write_sram(1, 856874, 0);
    write_sram(1, 12709, 1);
    fork
      calc_driver_h.start_calc(0, 1, 2, 2);
      begin
        wait (state == S_WRITE);
        $display("[%0t] Applying reset", $time);
        calc_if.cb.reset <= 1'b1;       // Assert reset
        repeat(5) @(calc_if.cb);     // Wait 5 clock cycles
        calc_if.cb.reset <= 1'b0;       // Deassert reset
        @(calc_if.cb);               // Wait 1 more cycle
        $display("[%0t] Reset deasserted", $time);
      end
    join

    repeat(10) @(posedge clk);

    write_sram(0, 123, 0);
    write_sram(0, 3425, 1);
    write_sram(1, 856874, 0);
    write_sram(1, 12709, 1);
    fork
      calc_driver_h.start_calc(0, 1, 2, 2);
      begin
        wait (state == S_ADD);
        $display("[%0t] Applying reset", $time);
        calc_if.cb.reset <= 1'b1;       // Assert reset
        repeat(5) @(calc_if.cb);     // Wait 5 clock cycles
        calc_if.cb.reset <= 1'b0;       // Deassert reset
        @(calc_if.cb);               // Wait 1 more cycle
        $display("[%0t] Reset deasserted", $time);
      end
    join

    repeat(10) @(posedge clk);

    // Test case 1 - normal addition
    $display("Test case 1 - normal addition");
    // TODO: Finish test case 1
    write_sram(0, 123, 0);
    write_sram(0, 3425, 1);
    write_sram(1, 856874, 0);
    write_sram(1, 12709, 1);
    calc_driver_h.start_calc(0, 1, 2, 2);
    repeat(20) @(posedge clk);
    // Test case 2 - addition with overflow
    $display("Test case 2 - addition with overflow");
    // TODO: Finish test case 2

    write_sram(0, 32'hFFFFFFFF, 0);
    write_sram(0, 32'hFFFFFFFF, 1);
    write_sram(1, 32'hFFFFFFFF, 0);
    write_sram(1, 32'hFFFFFFFF, 1);
    calc_driver_h.start_calc(0, 1, 2, 2);
    repeat(20) @(posedge clk);

    // TODO: Add test cases according to your test plan. If you need additional test cases to reach
    // 96% coverage, make sure to add them to your test plan
    //Boundary Tests
    $display("Boundary Testing");

    $display("Testing 0 + 0");
    write_sram(0, 0, 0);
    write_sram(0, 0, 1);
    write_sram(1, 0, 0);
    write_sram(1, 0, 1);
    calc_driver_h.start_calc(0, 1, 2, 2);
    repeat(20) @(posedge clk);

    $display("Testing 0 + MAX");
    write_sram(0, 32'hFFFFFFFF, 0);
    write_sram(0, 0, 1);
    write_sram(1, 32'hFFFFFFFF, 0);
    write_sram(1, 0, 1);
    calc_driver_h.start_calc(0, 1, 2, 2);
    repeat(20) @(posedge clk);

    
    // Random part
    $display("Randomized Testing");
    // TODO: Finish randomized testing
    // HINT: The sequencer is responsible for generating random input sequences. How can the
    // sequencer and driver be combined to generate multiple randomized test cases?

    for (int j = 0; j < 50; j++) begin
      $display("Random Cycle %0d", j);
      for (int i = 0; i < 2 ** AddrSize; i++) begin
        write_sram(i, $random, 0);
        write_sram(i, $random, 1);
      end

      repeat (10) @(posedge clk);

      calc_sequencer_h.gen(1);
      calc_driver_h.drive();

      repeat (100) @(posedge clk);
    end

    repeat (10) @(posedge clk);

    $display("TEST PASSED");
    $finish;
  end

  /********************
        ASSERTIONS
  *********************/

  // TODO: Add Assertions

  property RESET;
    @(posedge clk)
        calc_if.reset |=> (state === S_IDLE);
  endproperty

  assert property (RESET)
    else $error("Reset is active but DUT did not reset to IDLE. Current state as int: %0d", state);

  property BUFFER_TOGGLING;
    @(posedge clk)
        (state == S_READ) |=> $changed(calc_if.loc_sel);
  endproperty

  assert property (BUFFER_TOGGLING)
    else $error("Buffer Select not toggling.");

  property CHECK_CURRENT_ADDRS;
    @(posedge clk) disable iff ($isunknown(state) || state != S_IDLE || state != S_END)
        (calc_if.curr_rd_addr <= calc_if.read_end_addr && calc_if.curr_rd_addr >= calc_if.read_start_addr) 
        && (calc_if.curr_wr_addr <= calc_if.write_end_addr && calc_if.curr_wr_addr >= calc_if.write_start_addr);
  endproperty
  
  assert property (CHECK_CURRENT_ADDRS)
      else $error("Current read/write addrs out of range.");

endmodule
