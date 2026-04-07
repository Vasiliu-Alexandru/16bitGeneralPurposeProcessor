module dff(
    input      clk,
    input      reset,
    input      d,
    output reg q
);
    always @(posedge clk or posedge reset) begin
        if(reset)
            q <= 1'b0;
        else    
            q <= d;
    end
endmodule

module dff_set(
    input      clk,
    input      set,
    input      d,
    output reg q
);
    always @(posedge clk or posedge set) begin
        if(set)
            q <= 1'b1;
        else    
            q <= d;
    end
endmodule

module counter_4b(
    input clk,
    input reset,
    input incr,
    output [3:0] count,
    output count15
);

    wire d0, d1, d2, d3;

    // Bit 0 flips if incr is 1
    assign d0 = count[0] ^ incr;

    // Bit 1 flips if (incr == 1) AND (count[0] == 1)
    assign d1 = count[1] ^ (incr & count[0]);

    // Bit 2 flips if (incr == 1) AND (bits 0 and 1 are 1)
    assign d2 = count[2] ^ (incr & count[0] & count[1]);

    // Bit 3 flips if (incr == 1) AND (bits 0, 1, and 2 are 1)
    assign d3 = count[3] ^ (incr & count[0] & count[1] & count[2]);

    // Instantiate 4 DFFs
    dff ff0 (.clk(clk), .reset(reset), .d(d0), .q(count[0]));
    dff ff1 (.clk(clk), .reset(reset), .d(d1), .q(count[1]));
    dff ff2 (.clk(clk), .reset(reset), .d(d2), .q(count[2]));
    dff ff3 (.clk(clk), .reset(reset), .d(d3), .q(count[3]));

    // count15 - high only when 1111 (15)
    assign count15 = count[3] & count[2] & count[1] & count[0];

endmodule

module counter_5b_decr( // reset with value 10000
    input clk,
    input reset,
    input decr,
    output [4:0] count,
    output count0
);

    wire d0, d1, d2, d3, d4;

    // Decrement Logic (Borrow Look-ahead)
    assign d0 = count[0] ^ decr;
    assign d1 = count[1] ^ (decr & ~count[0]);
    assign d2 = count[2] ^ (decr & ~count[0] & ~count[1]);
    assign d3 = count[3] ^ (decr & ~count[0] & ~count[1] & ~count[2]);
    assign d4 = count[4] ^ (decr & ~count[0] & ~count[1] & ~count[2] & ~count[3]);

    // Instantiate 5 DFFs 
    // Bits 0-3 reset to 0
    dff ff0 (.clk(clk), .reset(reset), .d(d0), .q(count[0]));
    dff ff1 (.clk(clk), .reset(reset), .d(d1), .q(count[1]));
    dff ff2 (.clk(clk), .reset(reset), .d(d2), .q(count[2]));
    dff ff3 (.clk(clk), .reset(reset), .d(d3), .q(count[3]));


    dff_set ff4 (.clk(clk), .set(reset), .d(d4), .q(count[4]));

    // count0 - high only when 00000
    assign count0 = ~count[4] & ~count[3] & ~count[2] & ~count[1] & ~count[0];

endmodule



module register_sp #(parameter N = 10)(
    input  wire         clk,
    input  wire         reset,
    input  wire [N-1:0] d,
    input  wire         load,
    input  wire         incr,
    input  wire         decr,
    output reg  [N-1:0] q
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= {N{1'b0}};
        else if (load)
            q <= d;
        else if (decr)
            q <= q - 1;
        else if (incr)
            q <= q + 1;
    end
endmodule

module mux2_1(
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire y
);

    assign y = (a & ~sel) | (b & sel);
endmodule

module flag_register(
    input  wire clk,
    input  wire reset,
    input  wire we,
    input  wire z_in,
    input  wire n_in,
    input  wire c_in,
    input  wire o_in,
    output wire zero,
    output wire negative,
    output wire carry,
    output wire overflow
);
    wire [3:0] mux_out;
    mux2_1 mux1(zero,     z_in, we, mux_out[0]);
    mux2_1 mux2(negative, n_in, we, mux_out[1]);
    mux2_1 mux3(carry,    c_in, we, mux_out[2]);
    mux2_1 mux4(overflow, o_in, we, mux_out[3]);

    dff ff1(clk, reset, mux_out[0], zero);
    dff ff2(clk, reset, mux_out[1], negative);
    dff ff3(clk, reset, mux_out[2], carry);
    dff ff4(clk, reset, mux_out[3], overflow);

endmodule


module register #(parameter N = 16)(
    input  wire        clk,
    input  wire        reset,      // synchronous reset
    input  wire [N-1:0] d,         // data input for load
    output reg  [N-1:0] q           // register output
);

    always @(posedge clk or posedge reset) begin
        if (reset) 
            q <= {N{1'b0}};
        else 
            q <= d;
    end
endmodule

module register_inc #(
    parameter N = 16
)(
    input             clk, 
    input             reset,
    input             incr,
    output reg [N-1:0] q
);
    localparam INCR_AMOUNT = 1;

    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= {N{1'b0}};      // reset to 0
        else if (incr)
            q <= q + INCR_AMOUNT;
        // else retain value
    end

endmodule

module register_inc_load #(
    parameter N = 16
)(
    input             clk, 
    input             reset,
    input             incr,
    input      [N-1:0] d,
    input             load,
    output reg [N-1:0] q
);
    localparam INCR_AMOUNT = 1;

    always @(posedge clk or posedge reset) begin
        if (reset)
            q <= {N{1'b0}};      // reset to 0
        else if (load)
            q <= d;
        else if (incr)
            q <= q + INCR_AMOUNT;
        // else retain value
    end

endmodule


module register_load #(parameter N = 16)(
    input  wire        clk,
    input  wire        reset,      // synchronous reset
    input  wire [N-1:0] d,         // data input for load
    input  wire        load,        // load enable
    output reg  [N-1:0] q           // register output
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= {N{1'b0}};         // reset register to 0
        end else if (load) begin
            q <= d;                 // load input data
        end
        // else retain value
    end

endmodule

module mux32_1(
    input  [31:0] in,
    input  [4:0]  sel,
    output        y
);
    assign y = in[sel];
endmodule

module mux16_1(
    input  [15:0] in,
    input  [3:0]  sel,
    output        y
);
    assign y = in[sel];
endmodule

module microcode_rom #(
    parameter ADDR_WIDTH = 7,
    parameter DATA_WIDTH = 16,
    parameter MEMFILE    = "microcode.bin"
)(
    input  wire [ADDR_WIDTH-1:0] addr,
    output reg  [DATA_WIDTH-1:0] data
);

    reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];

    initial begin
        $readmemb(MEMFILE, rom);
    end

    always @(*) begin
        data = rom[addr];
    end
    
endmodule


module instruction_decoder_rom (
    input  wire [5:0] addr,    // 6-bit address for 64 lines
    output wire [6:0] data     // 7-bit data output
);
    reg [6:0] rom_memory [0:63];

    initial begin
        $readmemh("opcode2addr.hex", rom_memory);
    end

    // asynchronous read
    assign data = rom_memory[addr];

endmodule


module dec_3_8(
    input [2:0] a,
    input       en,
    output [7:0] d
);
    assign d[0] = en & ~a[2] & ~a[1] & ~a[0];
    assign d[1] = en & ~a[2] & ~a[1] &  a[0];
    assign d[2] = en & ~a[2] &  a[1] & ~a[0];
    assign d[3] = en & ~a[2] &  a[1] &  a[0];
    assign d[4] = en &  a[2] & ~a[1] & ~a[0];
    assign d[5] = en &  a[2] & ~a[1] &  a[0];
    assign d[6] = en &  a[2] &  a[1] & ~a[0];
    assign d[7] = en &  a[2] &  a[1] &  a[0];
endmodule

module dec_5_32(
    input  [4:0]  a,
    input en,
    output [31:0] d
);
    // wires for enable signals
    wire en0, en1, en2, en3;

    // Decode the top two bits (4 and 3) to choose which 3-to-8 block to enable
    assign en0 = en & ~a[4] & ~a[3]; // Represents index 0-7
    assign en1 = en & ~a[4] &  a[3]; // Represents index 8-15
    assign en2 = en &  a[4] & ~a[3]; // Represents index 16-23
    assign en3 = en &  a[4] &  a[3]; // Represents index 24-31

    // Instantiate four 3-to-8 decoders
    // Each one handles 8 bits of the 32-bit output
    dec_3_8 inst0 (.a(a[2:0]), .en(en0), .d(d[7:0]));
    dec_3_8 inst1 (.a(a[2:0]), .en(en1), .d(d[15:8]));
    dec_3_8 inst2 (.a(a[2:0]), .en(en2), .d(d[23:16]));
    dec_3_8 inst3 (.a(a[2:0]), .en(en3), .d(d[31:24]));

endmodule

module mux2_1_16b(
    input  [15:0] a,
    input  [15:0] b,
    input         sel,
    output [15:0] y
);
    assign y = sel ? b : a;
endmodule


module MicroProgrammedControlUnit(
    input wire clk,
    input wire reset,
    input wire [5:0] opcode,
    input wire [15:0] external_conditions,
    output wire [24:0] c
);

    wire [6:0] UPC_out;
    wire [6:0] upc_d_in;

    wire [15:0] microinstruction;
    
    // Internal Control Signals
    wire UPC_load, UPC_incr;

    wire [6:0] mapped_address;
    wire branch_condition;

    microcode_rom #(7, 16, "microcode.bin") ucode_rom (
        .addr(UPC_out),
        .data(microinstruction)
    );

    // Microinstruction Fields
    wire [3:0]  CS = microinstruction[15:12];
    wire [6:0]  BA = microinstruction[11:5];
    wire [4:0]  CF = microinstruction[4:0];

    instruction_decoder_rom u1 (
        .addr(opcode),
        .data(mapped_address)
    );

    //  Determine uPC Input
    // If CS is 1000b (Dispatch), use mapper. Otherwise use Branch Address (BA).

    wire cs1000 = CS[3] & ~CS[2] & ~CS[1] & ~CS[0]; // if CS is 1000 cs1000 signal is 1

    mux2_1  mux0(.a(BA[0]), .b(mapped_address[0]), .sel(cs1000), .y(upc_d_in[0]));
    mux2_1  mux1(.a(BA[1]), .b(mapped_address[1]), .sel(cs1000), .y(upc_d_in[1]));
    mux2_1  mux2(.a(BA[2]), .b(mapped_address[2]), .sel(cs1000), .y(upc_d_in[2]));
    mux2_1  mux3(.a(BA[3]), .b(mapped_address[3]), .sel(cs1000), .y(upc_d_in[3]));
    mux2_1  mux4(.a(BA[4]), .b(mapped_address[4]), .sel(cs1000), .y(upc_d_in[4]));
    mux2_1  mux5(.a(BA[5]), .b(mapped_address[5]), .sel(cs1000), .y(upc_d_in[5]));
    mux2_1  mux6(.a(BA[6]), .b(mapped_address[6]), .sel(cs1000), .y(upc_d_in[6]));
    // the code above is equivalent with this: wire [6:0] upc_d_in = (CS == 4'b1000) ? mapped_address : BA

    register_inc_load #(7) micro_program_counter (
        .clk(clk),
        .reset(reset),
        .d(upc_d_in),
        .load(UPC_load),
        .incr(UPC_incr),
        .q(UPC_out)
    );

    // 4'b0000 -> All bits are 0
    wire is_seq  = ~CS[3] & ~CS[2] & ~CS[1] & ~CS[0]; 

    // 4'b1111 -> All bits are 1
    wire is_jump =  CS[3] &  CS[2] &  CS[1] &  CS[0]; 

    // 4'b1000 -> MSB is 1, others are 0
    wire is_disp =  cs1000;

// --- Output Logic ---

// UPC_load logic:
// 1. High if we are in Jump (1111) OR Dispatch (1000)
// 2. High if we are NOT in Sequential (0000) AND branch_condition is true (Default case)
    assign UPC_load = is_jump | is_disp | (branch_condition & ~is_seq);

    // UPC_incr logic:
    // 1. High if we are in Sequential (0000)
    // 2. High if we are NOT in Jump (1111) AND NOT in Dispatch (1000) AND branch_condition is false (Default case)
    assign UPC_incr = is_seq | (~branch_condition & ~is_jump & ~is_disp);

    mux16_1 mux(
        .in(external_conditions),
        .sel(CS),
        .y(branch_condition)
    );

    wire [31:0] dec_out;

    // decode control signals
    dec_5_32 control_signal_decoder(
        .a(CF),
        .en(~reset),
        .d(dec_out)
    );
    
    assign c[0]    = dec_out[1];                            // c0
    assign c[1]    = dec_out[2] | dec_out[26] | dec_out[27];// c1
    assign c[4:2]  = dec_out[5:3]; // c2, c3, c4, c5
    assign c[5]    = dec_out[6] | dec_out[28]; // c5
    assign c[6]    = dec_out[7] | dec_out[26]; // c6
    assign c[7]    = dec_out[8] | dec_out[28];     // c7
    assign c[8]    = dec_out[9] | dec_out[29]; // c8
    assign c[11:9] = dec_out[12:10];           // c9, c10, c11
    assign c[12]   = dec_out[13] | dec_out[27];// c12
    assign c[13]   = dec_out[14];
    assign c[14]   = dec_out[15] | dec_out[29];
    assign c[24:15] = dec_out[25:16];

endmodule

module Memory2KB (
    input          clk,
    input          WE,
    input  [9:0]  addr,    // 16-bit address allows 65536 locations
    input  [15:0]  data_in, // 16-bit word size [cite: 34]
    output [15:0]  data_out
);

    reg [15:0] mem [0:1023];    
    reg [15:0] data_out_reg;
    
    assign data_out = data_out_reg;

    // Combinational read (Asynchronous)
    always @(*) begin
        data_out_reg = mem[addr];
    end

    // Write on rising clock edge (Synchronous)
    always @(posedge clk) begin
        if (WE)
            mem[addr] <= data_in;
    end

    // Initialize memory
    initial begin

        $readmemb("program.bin", mem); 

    end
endmodule


module ALU(
    input wire  [15:0] operand1,
    input wire  [15:0] operand2,
    input wire  [5:0]  opcode,
    output reg  [15:0] result,
    output reg         c_out,
    output reg         v_out
);
    reg [16:0] temp_res;

    always @(*) begin
        temp_res = 17'b0;
        c_out = 1'b0;
        v_out = 1'b0;
        
        case(opcode)
            6'b000010: temp_res = {1'b0, operand2}; // MOV
            
            6'b100000: begin // ADD
                temp_res = {1'b0, operand1} + {1'b0, operand2};
                // Overflow: (pos+pos=neg) OR (neg+neg=pos)
                v_out = (operand1[15] == operand2[15]) && (temp_res[15] != operand1[15]);
                c_out = temp_res[16];
            end

            6'b100001, 6'b100111: begin // SUB / CMP
                temp_res = {1'b0, operand1} - {1'b0, operand2};
                // Overflow: (pos-neg=neg) OR (neg-pos=pos)
                v_out = (operand1[15] != operand2[15]) && (temp_res[15] != operand1[15]);
                c_out = temp_res[16];
            end

            6'b100101: begin // INC
                temp_res = {1'b0, operand1} + 17'd1;
                v_out = (operand1 == 16'h7FFF); // Max positive to negative
                c_out = temp_res[16];
            end

            6'b100110: begin // DEC
                temp_res = {1'b0, operand1} - 17'd1;
                v_out = (operand1 == 16'h8000); // Max negative to positive
                c_out = temp_res[16];
            end

            6'b110000: temp_res = {1'b0, operand1 & operand2};
            6'b110001: temp_res = {1'b0, operand1 | operand2};
            6'b110010: temp_res = {1'b0, operand1 ^ operand2};
            6'b110011: temp_res = {1'b0, ~operand1};
            
            6'b111000: temp_res = {1'b0, operand1 << operand2[3:0]}; // LSL
            6'b111001: temp_res = {1'b0, operand1 >> operand2[3:0]}; // LSR

            default: temp_res = 17'b0;
        endcase
        
        result = temp_res[15:0];
    end
endmodule

module sign_extend_9_to_16(
    input  [8:0] in,
    output [15:0] out
);

assign out = {{7{in[8]}}, in};  // replicate sign bit 7 times

endmodule

module BoothRadix_Registers (
    input  wire        clk,
    input  wire        reset,     // synchronous reset
    input  wire        loadA,
    input  wire        load_inits,
    input  wire        shift,
    input  wire [15:0] A_d,
    input  wire [15:0] Q_d,
    input  wire [15:0] M_d,

    output reg  [15:0] A_q,
    output reg  [15:-1] Q_q,       // Q[15:0] plus Q[-1]
    output reg  [15:0] M_q,

    output wire        Qis01,
    output wire        Qis10
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        A_q <= 16'd0;
        Q_q <= 17'd0;
        M_q <= 16'd0;
    end
    else if (load_inits) begin  // Q and M loaded together
        A_q <= 16'd0;          // A is cleared when we start a new mult
        M_q <= M_d;
        Q_q <= {Q_d, 1'b0};    // Load Q and initialize Q_{-1} to 0
    end
    else if (shift) begin
        {A_q, Q_q} <= {A_q[15], A_q, Q_q[15:0]};
    end
    else if (loadA) begin      // Used for adding/subtracting M to A
        A_q <= A_d;
    end
end

    assign Qis01 = ({Q_q[0], Q_q[-1]} == 2'b01);
    assign Qis10 = ({Q_q[0], Q_q[-1]} == 2'b10);

endmodule

module Restoring_Registers(
    input clk,
    input reset, 
    input shift_left,
    input loadA,
    input set_q0,
    input reset_q0,

    input [16:0] A_d,
    input [15:0] Q_d,
    input [15:0] M_d,
    output reg [16:0] A_q,
    output reg [15:0] Q_q,
    output reg [15:0] M_q
);
    always@(posedge clk or posedge reset) begin
        if(reset) begin
            A_q <= 17'd0;
            Q_q <= 16'd0;
            M_q <= 16'd0;
        end 
    else begin
        if(shift_left) begin
            {A_q, Q_q} <= {A_q[15:0], Q_q, 1'b0};
        end
        if (loadA) begin
            A_q <= A_d;
        end
        if(set_q0) begin
            Q_q[0] <= 1;
        end
        if(reset_q0) begin
            Q_q[0] <= 0;
        end
    end
end
endmodule

module Processor(
    input clk,
    input reset
);
    wire [24:0] c;
    wire [15:0] program_counter, address_register, data_register, memory_out, instruction_register, X_register, Y_register, alu_out, accumulator_register,stack_pointer;   /*synthesis syn_keep=1*/
    wire [15:0] cond;
        wire [15:0] A_reg, M_reg;
    wire reg_sel, reg_sel_mux_y;


    mux2_1 reg_sel_mux(
        .a(reg_sel), 
        .b(data_register[9]), 
        .sel(c[3]), 
        .y(reg_sel_mux_y)
    );
    
    dff reg_sel_ff (
        .clk(clk),
        .reset(reset),
        .d(reg_sel_mux_y),
        .q(reg_sel)
    );

    // --- General Purpose Register Mux (Used by Mmeory and ALU) ---
    wire [15:0] gen_purpose_reg;
    mux2_1_16b gp_reg_mux(
        .a(X_register),
        .b(Y_register),
        .sel(reg_sel),
        .y(gen_purpose_reg)
    );

    // --- Memory Input Mux ---
    wire [15:0] ram_data_in;
    mux2_1_16b ram_in_mux(
        .a(gen_purpose_reg),
        .b(program_counter),
        .sel(c[14]),
        .y(ram_data_in)
    );

    Memory2KB ram(
        .clk(clk),
        .WE(c[8]),
        .addr(address_register),
        .data_in(ram_data_in), 
        .data_out(memory_out)
    );

    // --- AR Source Mux (Nested Ternary Logic) ---
    // Original: c[12] ? SP : (c[6] ? DR_addr : PC)
    wire [15:0] ar_internal_mux;
    mux2_1_16b ar_mux_stage1(
        .a(program_counter),
        .b({7'b0, data_register[8:0]}),
        .sel(c[6]),
        .y(ar_internal_mux)
    );

    wire [15:0] ar_final_d;
    mux2_1_16b ar_mux_stage2(
        .a(ar_internal_mux),
        .b(stack_pointer),
        .sel(c[12]),
        .y(ar_final_d)
    );

    register_load #(16) AR (
        .clk(clk),
        .reset(1'b0),
        .d(ar_final_d),
        .load(c[1]),
        .q(address_register)
    );

    // --- X/Y Register Input Mux ---
    wire [15:0] xy_reg_input;
    mux2_1_16b xy_input_mux(
        .a(accumulator_register),
        .b(data_register),
        .sel(c[7]),
        .y(xy_reg_input)
    );
    wire [15:-1] Q_reg;
    register_load #(16) X (
        .clk(clk),
        .reset(1'b0),
        .d(c[20] ? Q_reg[15:0] : xy_reg_input),
        .load((c[5] & ~reg_sel) | (c[20] & ~reg_sel)),
        .q(X_register)
    );

    register_load #(16) Y (
        .clk(clk),
        .reset(1'b0),
        .d(c[20] ? Q_reg[15:0] : xy_reg_input),
        .load(c[5] & reg_sel | (c[20] & reg_sel)),
        .q(Y_register)
    );

    // --- Other Processor Components ---
    register_load #(16) DR (
        .clk(clk),
        .reset(1'b0),
        .d(memory_out),
        .load(c[2]),
        .q(data_register)
    );

    register_load #(16) IR (
        .clk(clk),
        .reset(1'b0),
        .d(data_register),
        .load(c[3]),
        .q(instruction_register)
    );

    MicroProgrammedControlUnit CU (
        .clk(clk), 
        .reset(reset),
        .opcode(instruction_register[15:10]),
        .external_conditions(cond),
        .c(c)
    );

    register_inc_load #(16) PC (
        .clk(clk),
        .reset(c[0]),
        .incr(c[3]),
        .d(address_register),
        .load(c[9]),
        .q(program_counter)
    );
    
    register_sp #(16) StackPointer (
        .clk(clk),
        .reset(c[0]),
        .d(16'b0),
        .load(1'b0),
        .incr(c[13]),
        .decr(c[11]),
        .q(stack_pointer)
    );

    register_load #(16) AC (
        .clk(clk),
        .reset(reset),
        .d(alu_out),
        .load(c[4]),
        .q(accumulator_register)
    );

    wire [15:0] sign_extend_unit_out;
    sign_extend_9_to_16 SignExtendUnit(data_register[8:0], sign_extend_unit_out);


    wire c16c17 = c[16] | c[17];
    wire alu_c_out, alu_v_out;

    ALU arithmetic_logic_unit(
        .operand1(c16c17 ? A_reg : gen_purpose_reg), 
        .operand2(c16c17 ? M_reg : sign_extend_unit_out), 
        .opcode(c[16] ? 6'b100000 : (c[17] ? 6'b100001 : instruction_register[15:10])),
        .result(alu_out),
        .c_out(alu_c_out),
        .v_out(alu_v_out)
    );

    wire Qis01, Qis10;

    BoothRadix_Registers BR2_regs (
        .clk(clk),
        .reset(reset),
        .loadA(c16c17),
        .load_inits(c[15]),
        .shift(c[18]),
        .A_d(alu_out),
        .Q_d(sign_extend_unit_out),
        .M_d(gen_purpose_reg),

        .A_q(A_reg),
        .Q_q(Q_reg),
        .M_q(M_reg),

        .Qis01(Qis01),
        .Qis10(Qis10)
    );


    wire count15;
    counter_4b counter(
        .clk(clk),
        .reset(c[15] | reset),
        .incr(c[19]),
        .count(),
        .count15(count15)
    );


    wire count0;
    counter_5b_decr cnt(
        .clk(clk),
        .reset(c[15] | reset),
        .decr(c[19]),
        .count(),
        .count0(count0)
    );

    Restoring_Registers DIV_regs(
        .clk(clk),
        .reset(c[15] | reset),
        .shift_left(c[16]),
        .loadA(),
        .set_q0(c[22]),
        .reset_q0(c[23]),
        
        .A_d(),
        .Q_d(),
        .M_d(),

        .A_q(),
        .Q_q(),
        .M_q()
    );

// --- Flag Register Logic ---
    wire flag_write;
    wire z_in, n_in, c_in, o_in;
    wire zero, negative, carry, overflow;

    flag_register flags (
        .clk(clk),
        .reset(reset),
        .we(flag_write),
        .z_in(z_in),
        .n_in(n_in),
        .c_in(c_in),
        .o_in(o_in),
        .zero(zero),
        .negative(negative),
        .carry(carry),
        .overflow(overflow)
    );

    // c[20] is your load signal for X/Y from the multiplier result
    assign z_in = c[20] ? (A_reg == 16'b0 && Q_reg[15:0] == 16'b0) : (alu_out == 16'b0);
    assign n_in = c[20] ? A_reg[15] : alu_out[15];
    
    assign c_in = alu_c_out; 
    assign o_in = alu_v_out;
    
    assign cond[1] = zero;
    assign cond[2] = negative;
    assign cond[3] = carry;
    assign cond[4] = overflow;
    assign cond[5] = Qis01;
    assign cond[6] = Qis10;
    assign cond[7] = count15;
    assign cond[15:8] = 0;
    assign cond[0] = 0;

    // Add c[20] to flag_write so flags update when the multiplication result is "finalized"
    assign flag_write = c[4] | c[11] | c[20];

endmodule

module Processor_tb();
    reg clk, reset;
    integer count; // Variable to track the occurrence number
    
    // Instantiate the Processor
    Processor p(clk, reset);

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    initial begin
        clk = 0; 
        reset = 1; 
        count = 1; // Initialize the counter
        #28 reset = 0;
        
        $display("\n--- INSTRUCTION TRACE START ---");
        $display("No. | Hex Value | Decimal Value");
        $display("-------------------------------");
    end

    always @(posedge clk) begin
        if (!reset) begin
            if (p.address_register == 16'h1fe && p.c[8]) begin
                $display("%0d   | 0x%h    | %0d", 
                         count, 
                         p.ram_data_in, 
                         p.ram_data_in);
                
                count = count + 1; // Increment the counter for the next hit
            end
        end
    end
endmodule