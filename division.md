# Division Datapath

## 1. Overview

The division subsystem of **Calculator 2.0** implements binary long division as a sequential hardware algorithm.

The project contains several generations of the same fundamental algorithm:

```text
4 bit division
      │
      ▼
16 bit division
      │
      ▼
32bit division
      │
      ▼
FP-DIVISION
```

The first three circuits operate on binary integer values.

`FP-DIVISION` builds on the 32-bit divider to implement the calculator's decimal-scaled signed division.

The fundamental principle is the same as long division performed manually:

1. bring the next dividend bit into the remainder;
2. compare remainder and divisor;
3. subtract when possible;
4. generate one quotient bit;
5. repeat for the remaining significant bits.

The hardware implements these operations sequentially over multiple clock cycles.

---

## 2. Binary long division

For unsigned binary values, the basic operation is:

```text
Dividend / Divisor = Quotient + Remainder
```

At each iteration the current remainder is shifted left and the next dividend bit is introduced.

The resulting temporary remainder is compared with the divisor.

If:

```text
remainder >= divisor
```

the divisor is subtracted and the corresponding quotient bit becomes `1`.

Otherwise:

```text
remainder < divisor
```

and the quotient bit becomes `0`.

Conceptually:

```text
                    next dividend bit
                           │
                           ▼
                 ┌──────────────────┐
                 │ shift remainder   │
                 │ left + insert bit │
                 └────────┬─────────┘
                          │
                          ▼
                  compare with divisor
                          │
                 ┌────────┴────────┐
                 │                 │
          remainder >= divisor   remainder < divisor
                 │                 │
                 ▼                 ▼
             subtract           unchanged
                 │                 │
                 └────────┬────────┘
                          │
                          ▼
                    quotient bit
```

One iteration produces one quotient bit.

---

# 3. `4 bit division`

`4 bit division` is the elementary implementation of the binary long-division algorithm.

It operates on a 4-bit dividend and uses sequential clock cycles to process the dividend bits.

The circuit contains a remainder path, a dividend path, a divisor input and quotient generation logic.

The operation is divided into two logical subphases.

### Phase 1

The remainder is shifted left and the next dividend bit is inserted.

### Phase 2

The new remainder is compared with the divisor.

If the remainder is greater than or equal to the divisor:

```text
remainder = remainder - divisor
quotient bit = 1
```

Otherwise:

```text
quotient bit = 0
```

The process is repeated for all dividend bits.

A counter and flip-flop logic determine when the required number of cycles has been completed.

---

## 4. Two-subphase structure

The 4-bit divider uses two alternating logical subphases.

```text
clock
  │
  ▼
┌───────────────┐
│ subphase 1    │
│ shift/load    │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ subphase 2    │
│ compare/sub   │
└───────┬───────┘
        │
        └──── repeat
```

A toggle flip-flop alternates the two subphases.

During the first subphase, multiplexing selects the shifted remainder and the next dividend bit.

During the second, the circuit selects either:

* the unchanged remainder, or
* the result of the subtraction.

This structure makes the sequential algorithm explicit in hardware.

---

# 5. `16 bit division`

`16 bit division` is a direct generalization of the 4-bit divider.

The algorithm remains unchanged:

```text
shift remainder
      ↓
insert next dividend bit
      ↓
compare with divisor
      ↓
subtract if possible
      ↓
generate quotient bit
      ↓
repeat
```

The main difference is the width of the datapath.

The 16-bit implementation therefore demonstrates that the algorithm is independent of the particular word size.

The 4-bit circuit is the compact conceptual prototype, while the 16-bit circuit applies the same method to a larger integer range.

---

# 6. `32bit division`

`32bit division` is the optimized 32-bit implementation used by the higher-level calculator architecture.

It preserves the same long-division algorithm while replacing the elementary fixed-width structures with reusable modular components.

Its main supporting blocks are:

```text
32bit division
├── 32 Load/L Shift
├── 32-R-Shift
├── 32 pos shift
└── reverse
```

These four blocks have distinct functions.

---

# 7. Remainder path: `32 Load/L Shift`

`32 Load/L Shift` is the datapath used for the **remainder register**.

It is important to distinguish this circuit from the quotient shifter.

Its operation alternates between two functions:

```text
load
  ↓
shift left
  ↓
load
  ↓
shift left
  ↓
...
```

Thus the same register can first receive its required value and subsequently participate in the repeated left-shift operation of the division algorithm.

The circuit is constructed from four 8-bit `8 Load/LShift` modules:

```text
32 Load/L Shift
        │
   ┌────┼────┬────┐
   ▼    ▼    ▼    ▼
   8    8    8    8
 Load/Load/Load/Load/
 LShift LShift LShift LShift
```

During division, this path represents the evolving remainder.

It therefore implements the hardware equivalent of:

```text
remainder = (remainder << 1) | next_dividend_bit
```

followed, when applicable, by the subtraction of the divisor.

---

# 8. Quotient path: `32-R-Shift`

`32-R-Shift` has a different role.

It is specifically used to **construct the quotient**.

It is a 32-bit right shifter constructed from four `8bit R shift` modules:

```text
32-R-Shift
     │
 ┌───┼───┬───┐
 ▼   ▼   ▼   ▼
 8   8   8   8
bit bit bit bit
R   R   R   R
shift shift shift shift
```

As the division algorithm produces quotient bits, the bits are progressively inserted into the quotient path.

The right-shift organization allows the quotient to be assembled sequentially.

The important distinction is therefore:

```text
32 Load/L Shift  → remainder
32-R-Shift       → quotient
```

They are not two versions of the same function.

---

# 9. `32 pos shift`

The standard long-division algorithm can process all 32 positions of a 32-bit dividend.

However, the leading zero bits do not contribute useful work.

`32 pos shift` optimizes the algorithm by locating the most significant set bit of the dividend.

It scans the dividend starting from the most significant bit.

Leading zeros are skipped.

When the first `1` is found, the circuit begins outputting the significant dividend bits one at a time.

Conceptually:

```text
000000000001101010...
            ↑
          first 1
            │
            ▼
          bit 11
          bit 10
          bit 9
          ...
          bit 0
```

The `cout` output provides the current dividend bit to the division datapath.

---

# 10. Division duration

Because `32 pos shift` skips leading zeros, the duration of the 32-bit division depends on the number of significant bits in the dividend.

If the most significant set bit is:

```text
bit 0
```

only one significant bit must be processed.

Therefore:

```text
cycles = 1
```

If the most significant set bit is:

```text
bit 5
```

the significant portion contains bits:

```text
5, 4, 3, 2, 1, 0
```

so:

```text
cycles = 6
```

If the most significant set bit is:

```text
bit 31
```

all 32 positions are significant:

```text
cycles = 32
```

Therefore the duration is:

```text
1 ≤ cycles ≤ 32
```

and, more precisely:

```text
cycles = position_of_MSB + 1
```

for a non-zero dividend.

This is a hardware optimization of the original fixed-width algorithm.

---

# 11. One division iteration

Each significant dividend bit passes through the same logical sequence.

```text
                  dividend bit
                       │
                       ▼
              ┌─────────────────┐
              │ remainder shift │
              │     left        │
              └────────┬────────┘
                       │
                       ▼
               insert dividend bit
                       │
                       ▼
              compare remainder
                 with divisor
                       │
             ┌─────────┴─────────┐
             │                   │
       remainder >= divisor   remainder < divisor
             │                   │
             ▼                   ▼
       subtract divisor      no subtraction
             │                   │
             ▼                   ▼
       quotient bit = 1     quotient bit = 0
             │                   │
             └─────────┬─────────┘
                       │
                       ▼
                 next iteration
```

This is the same algorithm used by the 4-bit and 16-bit versions.

---

# 12. Quotient bit ordering

There is an implementation-specific detail in the quotient datapath.

During the sequential construction of the quotient, the bits are generated in the opposite order from the conventional representation required at the output.

The first generated quotient bit therefore ends up on the side corresponding to the least significant position.

Consequently, the intermediate quotient is effectively reversed:

```text
intermediate:

LSB ... MSB
```

rather than:

```text
normal representation:

MSB ... LSB
```

This is why the divider contains the `reverse` circuit.

---

# 13. `reverse`

`reverse` restores the conventional ordering of the quotient bits.

Its purpose is therefore not to perform arithmetic.

It performs a representation correction:

```text
generated quotient
       │
       ▼
    reverse
       │
       ▼
conventional quotient
```

This block is required because of the direction in which quotient bits are accumulated by the sequential hardware.

---

# 14. Complete 32-bit division datapath

The complete structure can be summarized as:

```text
                         Dividend
                            │
                            ▼
                    ┌───────────────┐
                    │ 32 pos shift  │
                    └───────┬───────┘
                            │
                     significant bit
                            │
                            ▼
                    ┌───────────────┐
                    │    Remainder  │
                    │ 32 Load/LShift│
                    └───────┬───────┘
                            │
                            ▼
                      compare/subtract
                            │
                 ┌──────────┴──────────┐
                 │                     │
                 ▼                     ▼
              remainder             quotient bit
                                         │
                                         ▼
                                  32-R-Shift
                                         │
                                         ▼
                                     reverse
                                         │
                                         ▼
                                     Quotient
```

The divisor participates in the compare/subtract stage.

The remainder path and quotient path therefore evolve together during each sequential iteration.

---

# 15. Evolution of the divider

The three integer division circuits represent an evolution of the same algorithm.

### 4-bit version

The 4-bit implementation makes the algorithm explicit and easy to inspect.

```text
4-bit data
fixed number of positions
explicit sequential phases
```

### 16-bit version

The 16-bit circuit generalizes the same architecture.

```text
16-bit data
same long-division algorithm
larger datapath
```

### 32-bit version

The 32-bit circuit preserves the algorithm while introducing reusable and optimized blocks.

```text
32-bit data
modular registers/shifters
MSB position detection
variable execution length
quotient reversal
```

The evolution is therefore not a change of mathematical algorithm.

It is an evolution of the hardware implementation of the same algorithm.

---

# 16. `FP-DIVISION`

`FP-DIVISION` adds the calculator-level floating-point representation to the 32-bit integer divider.

Its inputs contain:

```text
A
B
n_a
n_b
a_sign
b_sign
```

where `n_a` and `n_b` represent the number of decimal digits associated with the two operands.

The outputs are:

```text
out
out_dec
out_sign
```

The circuit performs signed decimal-scaled division.

---

# 17. Floating-point sign

The sign of the division result is calculated using XOR:

```text
out_sign = a_sign XOR b_sign
```

Therefore:

```text
positive / positive → positive
negative / negative → positive
positive / negative → negative
negative / positive → negative
```

The magnitude calculation is performed independently of the sign.

---

# 18. Decimal-position calculation

The decimal position of the result is calculated as:

```text
out_dec = n_a + 2 - n_b
```

The `+2` is intentional.

The 32-bit divider is configured to produce two decimal digits for the result.

Therefore the floating-point division reserves two positions after the decimal point.

Conceptually:

```text
n_a
 │
 ├───────┐
 │       │
 ▼       ▼
+ 2  -  n_b
 │       │
 └───┬───┘
     ▼
  out_dec
```

---

# 19. Three division stages

`FP-DIVISION` uses three instances of `32bit division`.

They are used to obtain:

1. the integer quotient;
2. the first decimal digit;
3. the second decimal digit.

The structure is:

```text
                 A / B
                   │
                   ▼
          ┌─────────────────┐
          │ 32bit division  │
          │ integer part    │
          └────────┬────────┘
                   │
                quotient
                   │
                remainder
                   │
                   ▼
                 × 10
                   │
                   ▼
          ┌─────────────────┐
          │ 32bit division  │
          │ first decimal   │
          └────────┬────────┘
                   │
                digit 1
                remainder
                   │
                   ▼
                 × 10
                   │
                   ▼
          ┌─────────────────┐
          │ 32bit division  │
          │ second decimal  │
          └────────┬────────┘
                   │
                digit 2
```

The three divisions are therefore chained through the remainder.

---

# 20. Remainder propagation

The fractional digits are obtained from the remainder of the previous division.

After the integer division:

```text
remainder₀ = A mod B
```

the remainder is multiplied by ten:

```text
remainder₁ = remainder₀ × 10
```

and divided again:

```text
digit₁ = remainder₁ / B
```

The new remainder is then multiplied by ten again:

```text
remainder₂ = new_remainder × 10
```

and divided again:

```text
digit₂ = remainder₂ / B
```

This is the hardware equivalent of the familiar decimal long-division procedure.

---

# 21. Example: `56.34 / -15.28`

The project uses the example:

```text
56.34 / -15.28
```

The internal representation is:

```text
A = 5634
n_a = 2
a_sign = positive

B = 1528
n_b = 2
b_sign = negative
```

The integer division produces:

```text
5634 / 1528 = 3
```

with a remainder.

The remainder is then multiplied by ten and divided again to obtain the first decimal digit.

The process is repeated once more for the second decimal digit.

The resulting magnitude is:

```text
368
```

with:

```text
out_dec = 2
```

and the sign is negative because the input signs differ.

Therefore the represented result is:

```text
-3.68
```

---

# 22. Quotient normalization

The integer quotient and the two decimal digits are combined into the internal integer representation.

Because two decimal digits are produced, the integer quotient is scaled by:

```text
100
```

before the final decimal digits are incorporated.

The value `100` is represented in binary as:

```text
1100100
```

The final result therefore represents:

```text
integer_part × 100 + decimal_digits
```

For:

```text
3.68
```

the internal value becomes:

```text
368
```

with:

```text
out_dec = 2
```

---

# 23. BCD conversion inside `FP-DIVISION`

The two decimal digits produced by the division stages are decimal digits represented in BCD.

`5BCD to bin` is used to convert the relevant BCD representation into binary.

The resulting binary value is then combined with the scaled integer quotient.

This allows the final result to return to the same internal representation used by the other floating-point arithmetic units:

```text
value + decimal count + sign
```

---

# 24. `FP-DIVISION` hierarchy

The direct dependencies are:

```text
FP-DIVISION
├── 32bit division ×3
│   ├── 32 Load/L Shift
│   │   └── 8 Load/LShift ×4
│   ├── 32-R-Shift
│   │   └── 8bit R shift ×4
│   ├── 32 pos shift
│   └── reverse
├── 32bit_product ×3
│   ├── 32multi2 ×31
│   └── my32adder ×32
├── 5BCD to bin
│   ├── 16bit-product ×4
│   └── my32adder ×4
└── my32adder
```

The three `32bit division` instances perform the sequential division stages.

The multiplication blocks provide the required multiplication-by-ten and scaling operations.

`5BCD to bin` converts the generated decimal information back into the binary datapath representation.

---

# 25. Division completion

`FP-DIVISION` is a sequential circuit.

Its completion signal is active-low.

When the division finishes, the completion signal is therefore inverted before being used by the surrounding control logic.

The resulting signal is delayed by a flip-flop and then fed to an OR gate.

The OR output triggers the scheduler used to transfer the result back into the accumulator.

Conceptually:

```text
FP-DIVISION
     │
     │ done (active-low)
     ▼
   inverter
     │
     ▼
 flip-flop
     │
     ▼
   OR gate
     │
     ▼
N-phase scheduler
     │
     ▼
BUS → accumulator
```

This is how the sequential arithmetic operation reconnects to the normal calculator control flow.

---

# 26. Division and the accumulator

The divider does not directly replace the accumulator.

Instead, the division result is made available to the common arithmetic BUS.

After completion, the control logic starts the appropriate scheduler sequence.

The result is then transferred:

```text
FP-DIVISION
      │
      ▼
three-state BUS path
      │
      ▼
BUS
      │
      ▼
32bit register
      │
      ▼
accumulator
```

The decimal-position information is handled separately by the calculator's decimal metadata path.

---

# 27. Complete division architecture

The complete conceptual hierarchy is:

```text
                         DIVISION
                            │
             ┌──────────────┴──────────────┐
             │                             │
       Binary division              Floating-point
             │                       division
             │                             │
     ┌───────┼────────┐                    ▼
     │       │        │              FP-DIVISION
     ▼       ▼        ▼                    │
   4 bit   16 bit   32 bit                  │
  division division division                │
                         │                  │
                         ├──────────────────┤
                         │                  │
                         ▼                  ▼
                 32bit division ×3    decimal scaling
                         │                  │
                         ├── remainder      │
                         ├── quotient       │
                         └── MSB scan       │
                                            │
                                            ▼
                                     final value +
                                  decimal count + sign
```

---

# 28. Design principles

The division subsystem follows several architectural principles.

### Reuse of the algorithm

The 4-bit, 16-bit and 32-bit dividers implement the same mathematical long-division procedure.

### Sequential execution

Division is inherently implemented as a multi-cycle operation.

One significant dividend bit is processed per division iteration.

### Modular datapath

The 32-bit implementation separates:

* remainder storage and shifting;
* quotient construction;
* dividend-bit scanning;
* quotient bit reordering.

### Variable execution time

The 32-bit divider does not necessarily process all 32 positions.

The `32 pos shift` block eliminates leading zero positions.

Therefore:

```text
1 ≤ division cycles ≤ 32
```

for a non-zero dividend.

### Separation of arithmetic and control

The divider performs the arithmetic sequence.

The control unit determines when the result is placed on the common BUS and loaded into the accumulator.

---

# 29. Summary

The division subsystem evolved from a transparent 4-bit implementation into a modular 32-bit sequential divider and finally into the floating-point division unit used by the calculator.

The central algorithm remains binary long division:

```text
shift remainder
      ↓
insert dividend bit
      ↓
compare
      ↓
subtract if possible
      ↓
generate quotient bit
      ↓
repeat
```

The optimized 32-bit implementation divides the responsibilities among dedicated blocks:

```text
32 Load/L Shift → remainder
32-R-Shift      → quotient
32 pos shift    → significant dividend bits
reverse         → quotient ordering
```

`FP-DIVISION` then extends this integer divider to the calculator's decimal-scaled representation by performing three sequential divisions:

```text
integer quotient
      ↓
first decimal digit
      ↓
second decimal digit
```

The resulting value is returned in the same general representation used throughout the floating-point datapath:

```text
value + decimal count + sign
```

This makes `FP-DIVISION` a direct architectural extension of the project's binary division engine rather than an independent arithmetic mechanism.

