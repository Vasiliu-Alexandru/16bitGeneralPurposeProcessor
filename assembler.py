class Assembler:
    def __init__(self):
        self.opcodes = {
            'LOAD': '000000', 'STORE': '000001', 'MOV':  '000010', 'BRA':  '000011',
            'JMP':  '000100', 'RET':   '000101', 'PUSH': '000110', 'POP':  '000111',
            'BRZ':  '010000', 'BRN':   '010001', 'BRC':  '010010', 'BRO':  '010011',
            'ADD':  '100000', 'SUB':   '100001', 'MUL':  '100010', 'DIV':  '100011',
            'MOD':  '100100', 'INC':   '100101', 'DEC':  '100110', 'CMP':  '100111',
            'AND':  '110000', 'OR':    '110001', 'XOR':  '110010', 'NOT':  '110011',
            'TST':  '110100', 'LSL':   '111000', 'LSR':  '111001', 'RSL':  '111010',
            'RSR':  '111011'
        }
        # Branches and JMP use a full 10-bit address
        self.address_only = {'BRA', 'BRZ', 'BRN', 'BRC', 'BRO', 'JMP'}
        # PUSH and POP only need the Register bit
        self.reg_only = {'PUSH', 'POP'}
        # No arguments
        self.no_args = {'RET'}

    def assemble(self, asm_text):
        lines = [l.split(';')[0].strip() for l in asm_text.strip().split('\n')]
        
        # --- PASS 1: Map Labels ---
        labels = {}
        cleaned_instructions = []
        address_counter = 0

        for line in lines:
            if not line: continue
            if ':' in line:
                label_name, _, rest = line.partition(':')
                labels[label_name.strip()] = address_counter
                line = rest.strip()
            
            if line:
                cleaned_instructions.append(line)
                address_counter += 1

        # --- PASS 2: Generate Binary ---
        output = []
        for line in cleaned_instructions:
            parts = line.replace(',', ' ').split()
            inst = parts[0].upper()
            opcode = self.opcodes[inst]

            def get_val(val_str):
                return labels[val_str] if val_str in labels else int(val_str, 0)

            if inst in self.address_only:
                # [Opcode 6b][Addr 10b]
                addr = get_val(parts[1])
                binary = opcode + format(addr & 0x3FF, '010b')
            
            elif inst in self.reg_only:
                # [Opcode 6b][RegSel 1b][Padding 9b]
                reg_bit = '0' if parts[1].upper() == 'X' else '1'
                binary = opcode + reg_bit + '0' * 9
                
            elif inst in self.no_args:
                # [Opcode 6b][Padding 10b]
                binary = opcode + '0' * 10

            else:
                # Default: [Opcode 6b][RegSel 1b][Addr/Val 9b]
                reg_bit = '0' if parts[1].upper() == 'X' else '1'
                addr = get_val(parts[2])
                binary = opcode + reg_bit + format(addr & 0x1FF, '09b')
            
            output.append(binary)
        
        return "\n".join(output)

# Example Usage:
code = """
    MOV Y, 10       ; Loop counter (10 iterations)
    MOV X, 1        ; Starting value to push

PUSH_LOOP:
    PUSH X
    MUL X, 3
    DEC Y, 0
    BRZ POP_START
    BRA PUSH_LOOP

POP_START:
    MOV Y, 10
POP_LOOP:
    POP X
    STORE X, 0x1FE
    DEC Y, 0
    BRZ EXIT
    BRA POP_LOOP

EXIT:
    BRA EXIT
"""

asm = Assembler()
print(asm.assemble(code))