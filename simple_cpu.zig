const std = @import("std");

const OpCode = enum(u16) {
    opMov = 0,
    opAdd = 1,
    opSub = 2,
    opAnd = 3,
    opOr = 4,
    opSl = 5,
    opSr = 6,
    opSra = 7,
    opLdl = 8,
    opLdh = 9,
    opCmp = 10,
    opJe = 11,
    opJmp = 12,
    opLd = 13,
    opSt = 14,
    opHlt = 15,
};

const Register = enum(u16) {
    reg0 = 0,
    reg1 = 1,
    reg2 = 2,
    reg3 = 3,
    reg4 = 4,
    reg5 = 5,
    reg6 = 6,
    reg7 = 7,
};

var rom: [256]u16 = undefined;

pub fn main() !void {
    var ram: [256]u16 = undefined;
    var reg: [8]u16 = undefined;
    var ir: u16 = undefined;

    assemble();

    var pc: u16 = 0;
    var flag_eq: u16 = 0;

    while (true) {
        ir = rom[pc];
        std.debug.print("pc={x:04}  ir={x:04}  reg0={d:5}  reg1={d:5}  reg2={d:5}  reg3={d:5}\n", .{ pc, ir, reg[0], reg[1], reg[2], reg[3] });

        pc = pc + 1;

        switch (getOpCode(ir)) {
            @intFromEnum(OpCode.opMov) => {
                reg[getRegA(ir)] = reg[getRegB(ir)];
            },
            @intFromEnum(OpCode.opAdd) => {
                reg[getRegA(ir)] = reg[getRegA(ir)] + reg[getRegB(ir)];
            },
            @intFromEnum(OpCode.opSub) => {
                reg[getRegA(ir)] = reg[getRegA(ir)] - reg[getRegB(ir)];
            },
            @intFromEnum(OpCode.opAnd) => {
                reg[getRegA(ir)] = reg[getRegA(ir)] & reg[getRegB(ir)];
            },
            @intFromEnum(OpCode.opOr) => {
                reg[getRegA(ir)] = reg[getRegA(ir)] | reg[getRegB(ir)];
            },
            @intFromEnum(OpCode.opSl) => {
                reg[getRegA(ir)] = reg[getRegA(ir)] << 1;
            },
            @intFromEnum(OpCode.opSr) => {
                reg[getRegA(ir)] = reg[getRegA(ir)] >> 1;
            },
            @intFromEnum(OpCode.opSra) => {
                reg[getRegA(ir)] = (reg[getRegA(ir)] & 0x8000) | (reg[getRegA(ir)] >> 1);
            },
            @intFromEnum(OpCode.opLdl) => {
                reg[getRegA(ir)] = (reg[getRegA(ir)] & 0xFF00) | (getData(ir) & 0x00FF);
            },
            @intFromEnum(OpCode.opLdh) => {
                reg[getRegA(ir)] = (getData(ir) << 8) | (reg[getRegA(ir)] & 0x00FF);
            },
            @intFromEnum(OpCode.opCmp) => {
                flag_eq = if (reg[getRegA(ir)] == reg[getRegB(ir)]) 1 else 0;
            },
            @intFromEnum(OpCode.opJe) => {
                if (flag_eq == 1) {
                    pc = getAddr(ir);
                }
            },
            @intFromEnum(OpCode.opJmp) => {
                pc = getAddr(ir);
            },
            @intFromEnum(OpCode.opLd) => {
                reg[getRegA(ir)] = ram[getAddr(ir)];
            },
            @intFromEnum(OpCode.opSt) => {
                ram[getAddr(ir)] = reg[getRegA(ir)];
            },
            @intFromEnum(OpCode.opHlt) => {
                break;
            },
            else => {},
        }
    }

    std.debug.print("ram[64] = {d}\n", .{ram[64]});
}

fn getOpCode(ir: u16) u16 {
    return (ir >> 11) & 0x000F;
}

fn getRegA(ir: u16) u16 {
    return (ir >> 8) & 0x0007;
}

fn getRegB(ir: u16) u16 {
    return (ir >> 5) & 0x0007;
}

fn getData(ir: u16) u16 {
    return ir & 0x00FF;
}

fn getAddr(ir: u16) u16 {
    return ir & 0x00FF;
}

fn assemble() void {
    rom[0] = asmLdh(Register.reg0, 0);
    rom[1] = asmLdl(Register.reg0, 0);
    rom[2] = asmLdh(Register.reg1, 0);
    rom[3] = asmLdl(Register.reg1, 1);
    rom[4] = asmLdh(Register.reg2, 0);
    rom[5] = asmLdl(Register.reg2, 0);
    rom[6] = asmLdh(Register.reg3, 0);
    rom[7] = asmLdl(Register.reg3, 10);
    rom[8] = asmAdd(Register.reg2, Register.reg1);
    rom[9] = asmAdd(Register.reg0, Register.reg2);
    rom[10] = asmSt(Register.reg0, 64);
    rom[11] = asmCmp(Register.reg2, Register.reg3);
    rom[12] = asmJe(14);
    rom[13] = asmJmp(8);
    rom[14] = asmHlt();
}

fn asmMov(regA: Register, regB: Register) u16 {
    return (@intFromEnum(OpCode.opMov) << 11) | (@intFromEnum(regA) << 8) | (@intFromEnum(regB) << 5);
}

fn asmAdd(regA: Register, regB: Register) u16 {
    return (@intFromEnum(OpCode.opAdd) << 11) | (@intFromEnum(regA) << 8) | (@intFromEnum(regB) << 5);
}

fn asmSub(regA: Register, regB: Register) u16 {
    return (@intFromEnum(OpCode.opSub) << 11) | (@intFromEnum(regA) << 8) | (@intFromEnum(regB) << 5);
}

fn asmAnd(regA: Register, regB: Register) u16 {
    return (@intFromEnum(OpCode.opAnd) << 11) | (@intFromEnum(regA) << 8) | (@intFromEnum(regB) << 5);
}

fn asmOr(regA: Register, regB: Register) u16 {
    return (@intFromEnum(OpCode.opOr) << 11) | (@intFromEnum(regA) << 8) | (@intFromEnum(regB) << 5);
}

fn asmSl(regA: Register) u16 {
    return (@intFromEnum(OpCode.opSl) << 11) | (@intFromEnum(regA) << 8);
}

fn asmSr(regA: Register) u16 {
    return (@intFromEnum(OpCode.opSr) << 11) | (@intFromEnum(regA) << 8);
}

fn asmSra(regA: Register) u16 {
    return (@intFromEnum(OpCode.opSra) << 11) | (@intFromEnum(regA) << 8);
}

fn asmLdl(regA: Register, data: u16) u16 {
    return (@intFromEnum(OpCode.opLdl) << 11) | (@intFromEnum(regA) << 8) | data;
}

fn asmLdh(regA: Register, data: u16) u16 {
    return (@intFromEnum(OpCode.opLdh) << 11) | (@intFromEnum(regA) << 8) | data;
}

fn asmCmp(regA: Register, regB: Register) u16 {
    return (@intFromEnum(OpCode.opCmp) << 11) | (@intFromEnum(regA) << 8) | (@intFromEnum(regB) << 5);
}

fn asmJe(addr: u16) u16 {
    return (@intFromEnum(OpCode.opJe) << 11) | addr;
}

fn asmJmp(addr: u16) u16 {
    return (@intFromEnum(OpCode.opJmp) << 11) | addr;
}

fn asmLd(regA: Register, addr: u16) u16 {
    return (@intFromEnum(OpCode.opLd) << 11) | (@intFromEnum(regA) << 8) | addr;
}

fn asmSt(regA: Register, addr: u16) u16 {
    return (@intFromEnum(OpCode.opSt) << 11) | (@intFromEnum(regA) << 8) | addr;
}

fn asmHlt() u16 {
    return @intFromEnum(OpCode.opHlt) << 11;
}
