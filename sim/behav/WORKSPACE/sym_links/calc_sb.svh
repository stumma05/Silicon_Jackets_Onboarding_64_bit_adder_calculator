class calc_sb #(int DataSize, int AddrSize);

  // Signals needed for the golden model implementation in the scoreboard
  int mem_a [2**AddrSize];
  int mem_b [2**AddrSize];
  logic second_read = 0;
  int unsigned golden_lower_data;
  int unsigned golden_upper_data;
  mailbox #(calc_seq_item #(DataSize, AddrSize)) sb_box;

  function new(mailbox #(calc_seq_item #(DataSize, AddrSize)) sb_box);
    this.sb_box = sb_box;
  endfunction

  task main();
    calc_seq_item #(DataSize, AddrSize) trans;
    forever begin
      sb_box.get(trans);
      // TODO: Implement the scoreboard's core functionality.
      // The scoreboard's task is to verify the DUT's behavior by comparing the
      // data received from the monitor against a golden reference model.

      // Use the transaction flags (`initialize`, `rdn_wr`) to handle three distinct operations:
      // - For initialization, update the scoreboard's local memory (`mem_a` and `mem_b`) to match the DUT's initial SRAM state.
      // - For read operations, compare the data from the SRAM in the DUT to the data stored in the scoreboard's memory.
      //       Think about how to account for the two sequential reads in the DUT for the single write operation. The values
      //       from both read operations need to be used to compare against the calculated values in the DUT when they are written
      //       to SRAM. The second_read, golden_lower_data, and golden_upper_data signals can be used for this purpose.
      // - For write operations, compare the DUT's output to the data calculated by the golden model in the scoreboard.

      // Use `$display` to log successful transactions and `$error` to report mismatches.
      // If a mismatch occurs, use `$finish` to terminate the simulation.

      // --- Handle initialization ---
        if (trans.initialize) begin
          if (!trans.loc_sel) begin
            mem_a[trans.curr_wr_addr] = trans.lower_data;
          end else begin
            mem_b[trans.curr_wr_addr] = trans.lower_data;
          end
          // $display($stime, "SB: Initialized SRAM %s, Addr: 0x%0x, Data: 0x%0x",
          //         !trans.loc_sel ? "A" : "B",
          //         trans.curr_wr_addr,
          //         trans.lower_data);
        end
        // --- Handle read operations ---
        else if (!trans.rdn_wr) begin
          if (!second_read) begin
            // First read in the pair
            golden_lower_data = mem_a[trans.curr_rd_addr] + mem_b[trans.curr_rd_addr];
            second_read = 1'b1;
            //$display("Adding : 0x%0x + 0x%0x = 0x%0x", mem_a[trans.curr_rd_addr], mem_b[trans.curr_rd_addr], golden_lower_data);
          end else begin
            // Second read: compute golden result
            golden_upper_data = mem_a[trans.curr_rd_addr] + mem_b[trans.curr_rd_addr];
            second_read = 1'b0;
            //$display("Adding : 0x%0x + 0x%0x = 0x%0x", mem_a[trans.curr_rd_addr], mem_b[trans.curr_rd_addr], golden_upper_data);
          end

          if ((trans.lower_data != mem_a[trans.curr_rd_addr] || trans.upper_data != mem_b[trans.curr_rd_addr]) && (trans.curr_rd_addr != 'x)) begin
            $error($stime, "SB: READ MISMATCH! Addr: 0x%0x, Expected: 0x%0x_0x%0x, DUT: 0x%0x_0x%0x",
                  trans.curr_rd_addr, trans.upper_data != mem_b[trans.curr_rd_addr], mem_a[trans.curr_rd_addr],
                  trans.upper_data, trans.lower_data);
          end
        end
        // --- Handle write operations ---
        else if (trans.rdn_wr) begin
          // Update golden model
          mem_a[trans.curr_wr_addr] = trans.upper_data;
          mem_b[trans.curr_wr_addr] = trans.lower_data;

          if (((golden_upper_data !== trans.upper_data) || (golden_lower_data !== trans.lower_data)) && (trans.curr_wr_addr != 'x)) begin
              $error($stime, "SB: WRITE MISMATCH! Addr: 0x%0x, Expected: 0x%0x_0x%0x, DUT: 0x%0x_0x%0x",
                    trans.curr_wr_addr, golden_upper_data, golden_lower_data,
                    trans.upper_data, trans.lower_data);
              $finish;
            end

          // $display($stime, "SB: Write verified Addr: 0x%0x, Upper: 0x%0x, Lower: 0x%0x",
          //         trans.curr_wr_addr, trans.upper_data, trans.lower_data);
      end

    end
  endtask

endclass : calc_sb
