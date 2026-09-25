# Calculator 2.0 — Architecture

## Overview

Calculator 2.0 is a 32-bit digital calculator implemented in CircuitVerse.

The project is contained in a single CircuitVerse `.cv` file and is composed of 36 subcircuits. The current calculator architecture uses 32 of them directly from `Main`; four additional circuits are retained as didactic, constructive, or evolutionary modules.

The architecture is organized into five functional areas:

- **Input**
- **Control path**
- **Datapath / storage**
- **Arithmetic units**
- **Output**

The calculator performs signed decimal-scaled floating-point arithmetic for addition, subtraction, multiplication, and division.

The floating-point representation is custom and is not IEEE-754. A numerical value is represented by:

- a 32-bit integer value with the decimal point temporarily removed;
- a decimal-digit count (`a_dec`, `b_dec`, etc.);
- a sign bit.

For example, `345.32` is represented as value `34532`, decimal digits `2`, sign positive.

## 1. High-level architecture

```text
                         INPUT
                           │
                           ▼
                    ┌─────────────┐
                    │ DispInput2  │
                    └──────┬──────┘
                           │ BCD
                           ▼
                    ┌─────────────┐
                    │ 8BCD to bin │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │     BUS     │
                    └──────┬──────┘
                           │
                           ▼
                 ┌──────────────────┐
                 │   ACCUMULATOR    │
                 │  32bit register  │
                 └────────┬─────────┘
                          │
             ┌────────────┼────────────┐
             │            │            │
             ▼            ▼            ▼
        ┌────────┐   ┌────────┐   ┌────────────┐
        │FP-ADDER│   │FP-MULTI│   │FP-DIVISION │
        └────┬───┘   └────┬───┘   └──────┬─────┘
             │            │              │
             └────────────┼──────────────┘
                          │
                          ▼
                    ┌─────────────┐
                    │     BUS     │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │32BIN to BCD │
                    └──────┬──────┘
                           │
                           ▼
                      ┌────────┐
                      │DispOut │
                      └────────┘
```

The `4 bit register` associated with the accumulator stores the decimal-digit count (`a_dec`) and therefore travels conceptually alongside the numerical accumulator value.

## 2. Input subsystem

### `DispInput2`

`DispInput2` receives the decimal digits entered by the user.

It contains nine 4-bit registers and represents the entered digits in BCD form. As digits are entered, the register contents shift so that the displayed input is updated.

Its output is therefore a BCD representation of the number entered by the user.

### `8BCD to bin`

`8BCD to bin` converts the BCD input into a binary numerical value.

It uses eight decimal positions. Each position is multiplied by its corresponding power of ten and the partial results are accumulated using the project's 32-bit arithmetic blocks.

The resulting binary value can then be transferred through the BUS and stored in the accumulator.

## 3. Datapath and storage

### 32-bit accumulator

The main numerical accumulator is implemented by `32bit register`.

It stores the integer representation of the current calculator value, with the decimal point removed.

For example:

```text
345.32
```

is stored numerically as:

```text
34532
```

The decimal position is stored separately in the 4-bit register.

### `4 bit register`

In `Main`, the `4 bit register` is used as the accumulator decimal-count register.

It stores `a_dec`, i.e. the number of decimal digits associated with the accumulator value.

The numerical value and its decimal position are therefore kept as separate pieces of state:

```text
32bit register  → numerical value
4 bit register  → decimal-digit count
sign            → sign of the value
```

## 4. Shared BUS

The calculator uses a shared BUS for transferring numerical results between the functional blocks.

The arithmetic units do not continuously drive the BUS. Their outputs are connected through **three-state buffer chains**.

Only one operation's buffer chain is enabled at a time.

Conceptually:

```text
                    OP-FLAG-REG
                         │
                         │ operation selection
                         ▼
              ┌─────────────────────┐
              │ buffer enable logic │
              └──────────┬──────────┘
                         │
             ┌───────────┼───────────┐
             │           │           │
             ▼           ▼           ▼
          FP-ADDER     FP-MULTI   FP-DIVISION
        three-state   three-state  three-state
             │           │           │
             └───────────┼───────────┘
                         │
                         ▼
                        BUS
                         │
                         ▼
                    ACCUMULATOR
```

The operation stored in `OP-FLAG-REG` determines which operation's output is allowed to drive the BUS.

This provides mutually exclusive access to the shared data path: two arithmetic units must not drive the BUS simultaneously.

The BUS is therefore both a data-transfer path and a shared resource whose driver is selected by the control logic.

## 5. Control path

The control path determines when data is transferred and which operation is active.

Its main blocks are:

- `when start`
- `OP FLAGS-temp`
- `OP-FLAG-REG`
- `N-phase scheduler`

### `OP FLAGS-temp`

`OP FLAGS-temp` temporarily stores the operation selected by the user.

The operation flags are mutually exclusive: selecting one operation activates its corresponding flag while clearing the other operation flags.

The selected operation is not immediately treated as the effective operation for the next arithmetic cycle.

### `OP-FLAG-REG`

`OP-FLAG-REG` stores the effective operation.

During phase 2 of the scheduler, the selected operation is transferred from `OP FLAGS-temp` into `OP-FLAG-REG`.

This separation is intentional: the operation selected by the user is applied on the appropriate subsequent cycle rather than being used prematurely.

### `N-phase scheduler`

`N-phase scheduler` is a generic sequential controller.

Its implementation uses:

- a clock;
- an enable flip-flop;
- a counter;
- a decoder;
- reset logic.

The counter advances while the scheduler is enabled and the decoder generates the phase signals.

In `Main`, only two phases are required:

```text
Phase 1:
BUS → accumulator

Phase 2:
clear input
+
OP FLAGS-temp → OP-FLAG-REG
```

Thus the scheduler coordinates both data transfer and control-state update.

## 6. Operation start sequence

The `when start` circuit coordinates the beginning of calculator operations.

For the operators `+`, `×`, and `:`, the selected operation first enters the temporary operation register and the preliminary two-phase sequence is started.

The two phases are:

```text
Phase 1 → load accumulator from BUS
Phase 2 → clear input and transfer operation flag
```

The purpose is to ensure that the accumulator and operation state are updated in the correct cycle order.

For `=`, division has a special control path.

If the effective operation is `:`, `FP-DIVISION` is started instead of immediately executing the normal two-phase scheduler sequence.

## 7. Arithmetic subsystem

The three principal arithmetic units are:

- `FP-ADDER`
- `FP-MULTI`
- `FP-DIVISION`

They operate on the project's custom decimal-scaled representation.

### `FP-ADDER`

Addition and subtraction are selected according to the operand signs.

- same signs → addition of magnitudes;
- different signs → subtraction of magnitudes.

For subtraction, the larger absolute value is selected as the minuend and its sign becomes the result sign.

Decimal positions are aligned before the arithmetic operation.

### `FP-MULTI`

Multiplication operates on the integer representations of the operands.

The decimal count of the result is:

```text
out_dec = a_dec + b_dec
```

The result sign is:

```text
out_sign = a_sign XOR b_sign
```

### `FP-DIVISION`

Division is sequential and is based on binary long division.

It uses three 32-bit division operations to produce:

1. the integer quotient;
2. the first decimal digit;
3. the second decimal digit.

The result therefore has two generated decimal digits.

Its decimal count is:

```text
out_dec = n_a + 2 - n_b
```

The division result is returned to the shared BUS when the sequential division has completed.

## 8. Division completion and return to the datapath

`FP-DIVISION` is a sequential operation.

Its completion signal is active-low. The signal is:

1. inverted;
2. delayed through a flip-flop;
3. used through an OR gate to trigger the scheduler.

The scheduler then performs the required post-operation transfer, including loading the result into the accumulator and clearing the input state.

This makes division a multi-cycle operation with an explicit completion-to-control feedback path.

## 9. Output subsystem

### `32BIN to BCD`

The binary result is converted back into decimal BCD form.

The converter is constructed from nine `single-digit-converter2` stages.

Each stage extracts one decimal digit using repeated subtraction against the corresponding decimal reference value.

### `DispOut`

`DispOut` receives the BCD digits and sends them to the corresponding display elements.

The decimal position is also decoded so that the decimal point is shown at the correct position.

Leading zeros can be suppressed according to the display logic.

## 10. Main functional organization

The `Main` circuit directly instantiates 13 subcircuits:

1. `FP-ADDER`
2. `4 bit register`
3. `32bit register`
4. `32BIN to BCD`
5. `DispOut`
6. `DispInput2`
7. `8BCD to bin`
8. `FP-MULTI`
9. `OP FLAGS-temp`
10. `N-phase scheduler`
11. `OP-FLAG-REG`
12. `FP-DIVISION`
13. `when start`

These blocks form the active top-level calculator architecture.

## 11. Supporting arithmetic and sequential blocks

The top-level units are built from lower-level reusable circuits.

Important examples include:

- `32bit_product`
- `my32adder`
- `32bit sub`
- `32bit register`
- `16bit register`
- `8bitregister`
- `32bit division`
- `32 Load/L Shift`
- `32-R-Shift`
- `32 pos shift`
- `reverse`
- BCD conversion blocks
- scheduler and register primitives

The resulting architecture is hierarchical rather than monolithic: complex functions are assembled from smaller reusable digital circuits.

## 12. Didactic and evolutionary circuits

Four circuits are not directly reachable from `Main` in the current calculator:

- `4 bit division`
- `16 bit division`
- `8bit l-shifter`
- `32bit l-shifter`

They are retained in the project because they document the construction and evolution of the design.

In particular, the division path evolved through:

```text
4 bit division
      ↓
16 bit division
      ↓
32bit division
      ↓
FP-DIVISION
```

The left-shifter modules are also separate from `32 Load/L Shift`: the former are simpler dedicated shifters, while `Load/L Shift` combines loading and shifting and is used in the division datapath.

## 13. Architectural summary

Calculator 2.0 can therefore be understood as two cooperating systems:

```text
┌──────────────────────────────────────────────────────┐
│                    CONTROL PATH                      │
│                                                      │
│  when start → OP FLAGS-temp → OP-FLAG-REG           │
│                         │                            │
│                         ▼                            │
│                  N-phase scheduler                   │
└─────────────────────────┬────────────────────────────┘
                          │ control
                          ▼
┌──────────────────────────────────────────────────────┐
│                     DATAPATH                         │
│                                                      │
│ Input → BCD→binary → BUS → accumulator               │
│                           │                          │
│                    ┌──────┼──────┐                   │
│                    ▼      ▼      ▼                   │
│                  ADD    MULT     DIV                 │
│                    │      │      │                   │
│                    └──────┼──────┘                   │
│                           │                          │
│                           BUS                        │
│                            │                         │
│                     binary→BCD → display             │
└──────────────────────────────────────────────────────┘
```

The central architectural principles are:

1. **shared BUS with mutually exclusive three-state drivers;**
2. **separate control path and datapath;**
3. **explicit storage of numerical value and decimal position;**
4. **modular arithmetic units;**
5. **sequential control for multi-cycle operations;**
6. **hierarchical reuse of lower-level digital circuits;**
7. **custom decimal-scaled floating-point representation.**
