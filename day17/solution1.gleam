import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/pair
import gleam/regexp
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder.{type Yielder}
import simplifile
import util.{type Vec2Int, Vec2}

type Instruction {
  Instruction(opcode: Opcode, operand: Operand)
}

type Opcode {
  Adv
  Bxl
  Bst
  Jnz
  Bxc
  Out
  Bdv
  Cdv
}

type Operand {
  LiteralOperand(operand: Int)
  RegisterOperand(register: Register)
}

type Register {
  RegisterA
  RegisterB
  RegisterC
}

type Program {
  Program(
    rax: Int,
    rbx: Int,
    rcx: Int,
    rip: Int,
    instructions: Yielder(Instruction),
  )
}

type ProgramInterface {
  ProgramInterface(program: Program, tty: Yielder(Int))
}

pub fn solution(input: String) {
  io.println("Loading " <> input <> ".")
  let assert Ok(content) = simplifile.read(from: input)

  let program =
    content
    |> string.trim_end
    |> parse_program
    |> io.debug

  io.debug(program.instructions |> yielder.to_list)
  let assert Ok(halted) =
    program
    |> ProgramInterface(yielder.from_list([]))
    |> run

  halted.tty
  |> yielder.to_list
  |> list.map(int.to_string)
  |> string.join(",")
  |> io.debug
  1
}

fn parse_program(str: String) -> Program {
  let assert Ok(register_regex) =
    regexp.from_string("Register [ABC]:\\s+(\\d+)")
  let assert Ok(instruction_regex) = regexp.from_string("Program:\\s+(.*)")
  let assert [
    regexp.Match(_, [Some(rax_str)]),
    regexp.Match(_, [Some(rbx_str)]),
    regexp.Match(_, [Some(rcx_str)]),
  ] = regexp.scan(register_regex, str)

  let assert [regexp.Match(_, [Some(instruction_str)])] =
    regexp.scan(instruction_regex, str)

  let assert [rax, rbx, rcx] =
    [rax_str, rbx_str, rcx_str] |> list.filter_map(int.parse)

  let instructions =
    instruction_str
    |> string.split(",")
    |> list.filter_map(int.parse)
    |> list.sized_chunk(2)
    |> list.map(fn(x) {
      let assert [opcode, operand] = x
      parse_instruction(opcode, operand)
    })
    |> yielder.from_list

  Program(rax, rbx, rcx, 0, instructions)
}

fn parse_instruction(opcode: Int, operand: Int) -> Instruction {
  let literal_operand = LiteralOperand(operand)
  let combo_operand = case operand {
    0 | 1 | 2 | 3 -> literal_operand
    4 -> RegisterOperand(RegisterA)
    5 -> RegisterOperand(RegisterB)
    6 -> RegisterOperand(RegisterC)
    7 -> literal_operand
    _ -> panic as "Unknown operand"
  }

  case opcode {
    0 -> Instruction(Adv, combo_operand)
    1 -> Instruction(Bxl, literal_operand)
    2 -> Instruction(Bst, combo_operand)
    3 -> Instruction(Jnz, literal_operand)
    4 -> Instruction(Bxc, literal_operand)
    5 -> Instruction(Out, combo_operand)
    6 -> Instruction(Bdv, combo_operand)
    7 -> Instruction(Cdv, combo_operand)
    _ -> panic as "Unknown opcode"
  }
}

fn run(pi: ProgramInterface) {
  case tick(pi) {
    Error(Nil) -> Ok(pi)
    Ok(new_pi) -> run(new_pi)
  }
}

fn tick(pi: ProgramInterface) -> Result(ProgramInterface, Nil) {
  case yielder.at(pi.program.instructions, pi.program.rip) {
    Error(_) -> Error(Nil)
    Ok(instruction) -> Ok(tick_inner(pi, instruction))
  }
}

fn tick_inner(pi: ProgramInterface, instruction: Instruction) {
  let operand = resolve_operand(pi.program, instruction.operand)
  case instruction.opcode {
    Adv | Bdv | Cdv -> {
      let numerator = pi.program.rax
      let assert Ok(denominator) =
        int.power(2, operand |> int.to_float)
        |> result.map(float.round)

      let r_x = numerator / denominator
      let register = case instruction.opcode {
        Adv -> RegisterA
        Bdv -> RegisterB
        Cdv -> RegisterC
        _ -> panic as "???"
      }
      ProgramInterface(
        pi.program |> set_register(register, r_x) |> slide_rip,
        pi.tty,
      )
    }
    Bst -> {
      let rbx = operand % 8
      ProgramInterface(
        pi.program |> set_register(RegisterB, rbx) |> slide_rip,
        pi.tty,
      )
    }
    Bxc -> {
      let rbx = int.bitwise_exclusive_or(pi.program.rbx, pi.program.rcx)
      ProgramInterface(
        pi.program |> set_register(RegisterB, rbx) |> slide_rip,
        pi.tty,
      )
    }
    Bxl -> {
      let rbx = int.bitwise_exclusive_or(pi.program.rbx, operand)
      ProgramInterface(
        pi.program |> set_register(RegisterB, rbx) |> slide_rip,
        pi.tty,
      )
    }
    Jnz -> {
      case pi.program.rax == 0 {
        True -> ProgramInterface(pi.program |> slide_rip, pi.tty)
        // no slide rip
        False -> ProgramInterface(pi.program |> set_rip(operand), pi.tty)
      }
    }
    Out -> {
      let out = operand % 8
      ProgramInterface(
        pi.program |> slide_rip,
        yielder.concat([pi.tty, [out] |> yielder.from_list]),
      )
    }
  }
}

fn resolve_operand(program: Program, operand: Operand) {
  case operand {
    LiteralOperand(x) -> x
    RegisterOperand(RegisterA) -> program.rax
    RegisterOperand(RegisterB) -> program.rbx
    RegisterOperand(RegisterC) -> program.rcx
  }
}

fn set_register(program: Program, register: Register, value: Int) -> Program {
  case register {
    RegisterA ->
      Program(
        value,
        program.rbx,
        program.rcx,
        program.rip,
        program.instructions,
      )
    RegisterB ->
      Program(
        program.rax,
        value,
        program.rcx,
        program.rip,
        program.instructions,
      )
    RegisterC ->
      Program(
        program.rax,
        program.rbx,
        value,
        program.rip,
        program.instructions,
      )
  }
}

fn set_rip(program: Program, rip: Int) {
  Program(program.rax, program.rbx, program.rcx, rip, program.instructions)
}

fn slide_rip(program: Program) {
  set_rip(program, program.rip + 1)
}
