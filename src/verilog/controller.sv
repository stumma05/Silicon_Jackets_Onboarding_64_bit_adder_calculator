import calculator_pkg::*;

module controller (
  	input  logic              clk_i,
    input  logic              rst_i,
  
  	// Memory Access
    input  logic [ADDR_W-1:0] read_start_addr,
    input  logic [ADDR_W-1:0] read_end_addr,
    input  logic [ADDR_W-1:0] write_start_addr,
    input  logic [ADDR_W-1:0] write_end_addr,
  
  	// Control
    output logic write,
    output logic [ADDR_W-1:0] w_addr,
    output logic [MEM_WORD_SIZE-1:0] w_data,

    output logic read,
    output logic [ADDR_W-1:0] r_addr,
    input  logic [MEM_WORD_SIZE-1:0] r_data,

  	// Buffer Control (1 = upper, 0, = lower)
    output logic              buffer_control,
  
  	// These go into adder
  	output logic [DATA_W-1:0]       op_a,
    output logic [DATA_W-1:0]       op_b,
  
    input  logic [MEM_WORD_SIZE-1:0]       buff_result
  
); 
	//TODO: Write your controller state machine as you see fit. 
	//HINT: See "6.2 Two Always BLock FSM coding style" from refmaterials/1_fsm_in_systemVerilog.pdf
	// This serves as a good starting point, but you might find it more intuitive to add more than two always blocks.

	
  	state_t state, next;

	//State reg, other registers as needed
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			state <= S_IDLE;
			r_addr <= read_start_addr;
			w_addr <= write_start_addr;
			buffer_control <= 1'b1;
		end else
			state <= next;
		
		
		case (state)
			S_READ: begin
				buffer_control <= ~buffer_control;
				r_addr <= r_addr + 1;
				op_a[DATA_W - 1 : 0] = r_data[MEM_WORD_SIZE - 1 : DATA_W];
				op_b[DATA_W - 1 : 0] = r_data[DATA_W - 1 : 0];
			end
			S_WRITE: begin
				w_addr <= w_addr + 1;
			end
		endcase


	end

	always_ff @(negedge clk_i) begin
		case (state) 
			S_IDLE: begin
				read <= 1'b1;
			end
			S_READ: begin
				read <= 1'b0;
			end

			S_WRITE: begin
				write <= 1'b0;
			end
		endcase

		case (next)
			S_READ:
				read <= 1'b1;
			S_WRITE:
				write <= 1'b1;

		endcase
	end
	
	//Next state logic, outputs
	always_comb begin
		case (state)
			S_IDLE: begin
				if (!rst_i) next = S_READ;
				else next = S_IDLE;
			end
			S_READ: begin
				next = S_ADD;
			end
			S_ADD: begin
				if (~buffer_control) begin
					next = S_READ;
				end else begin
					w_data = buff_result;
					next = S_WRITE;
				end
			end
			S_WRITE: begin
				w_data = buff_result;
				if (w_addr >= write_end_addr | r_addr >= read_end_addr) next = S_END;
				else next = S_READ;
			end
			S_END: begin
				if (!rst_i) next = S_END;
				else next = S_IDLE;
			end
		endcase
	end

endmodule
