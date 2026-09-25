# Floating-Point Representation

## 1. Overview

Calculator 2.0 uses a custom floating-point representation designed specifically for decimal arithmetic.

It is important to distinguish this representation from the IEEE-754 floating-point standard.

The project does **not** represent numbers using:

* an IEEE sign bit;
* a binary exponent;
* an IEEE mantissa/fraction;
* NaN, infinity, or IEEE subnormal values.

Instead, the calculator keeps three separate pieces of information:

```text
value + decimal count + sign
```

For example:

```text
345.32
```

is represented internally as:

```text
value = 34532
decimal count = 2
sign = positive
```

The decimal separator is therefore not physically stored inside the binary value.

It is reconstructed from the separate decimal-count field when the value is displayed or used by another floating-point operation.

---

# 2. Internal representation

A calculator value can be considered conceptually as:

```text
┌─────────────────────────────────────────┐
│              Calculator value           │
├─────────────────┬──────────────┬────────┤
│ integer value   │ decimal count│  sign  │
└─────────────────┴──────────────┴────────┘
```

The three components have different purposes.

### Value

The numerical digits are stored as a binary integer.

### Decimal count

The decimal-count field specifies how many decimal digits belong after the decimal point.

### Sign

A separate signal indicates whether the represented number is positive or negative.

---

# 3. Example

Consider:

```text
345.32
```

The decimal separator is removed from the integer representation:

```text
34532
```

The number of digits after the decimal point is stored separately:

```text
decimal count = 2
```

Therefore:

```text
value     = 34532
dec       = 2
sign      = positive
```

The representation can be reconstructed as:

```text
34532
  ↑
  └── move decimal separator two positions from the right

345.32
```

A negative number uses the same magnitude representation plus a negative sign:

```text
-345.32

value = 34532
dec   = 2
sign  = negative
```

---

# 4. Why use this representation?

The architecture is designed around decimal calculator operations rather than general-purpose scientific floating-point computation.

Keeping the decimal position separately has several advantages for this project:

1. decimal alignment can be performed explicitly;
2. the arithmetic datapath can remain integer-based;
3. decimal digits can be converted directly to and from BCD;
4. the display subsystem can use the decimal-position information directly;
5. sign handling remains independent from the magnitude.

The arithmetic hardware therefore operates primarily on integers while the surrounding logic maintains the decimal semantics.

---

# 5. Decimal scaling

The internal value is effectively a scaled integer.

If:

```text
dec = n
```

the represented numerical value is conceptually:

```text
value / 10^n
```

For example:

```text
value = 34532
dec   = 2
```

represents:

```text
34532 / 100 = 345.32
```

Similarly:

```text
value = 1470
dec   = 0
```

represents:

```text
1470
```

and:

```text
value = 368
dec   = 2
```

represents:

```text
3.68
```

This scaling model is the fundamental numerical convention used by the floating-point subsystem.

---

# 6. Addition and subtraction

`FP-ADDER` receives two values together with their decimal counts and signs:

```text
A
B
a_dec
b_dec
a_sign
b_sign
```

Before the arithmetic operation, the two integer magnitudes must have the same decimal precision.

For example:

```text
345.32 + 65.4
```

is initially represented as:

```text
A = 34532
a_dec = 2

B = 654
b_dec = 1
```

The second operand is scaled:

```text
654 × 10 = 6540
```

so the arithmetic becomes:

```text
34532 + 6540
```

with:

```text
out_dec = 2
```

The resulting integer value is:

```text
41072
```

which represents:

```text
410.72
```

---

# 7. Signed addition

The sign signals determine whether the operation is effectively an addition or subtraction of magnitudes.

If the signs are equal:

```text
positive + positive → addition
negative + negative → addition of magnitudes
```

The common sign is retained.

If the signs differ:

```text
positive + negative
```

becomes a subtraction of magnitudes.

The circuit compares the absolute values first.

The smaller magnitude is subtracted from the larger magnitude.

The sign of the result is the sign of the operand with the larger magnitude.

For example:

```text
-345.32 + 65.4
```

becomes:

```text
34532 - 6540
```

giving:

```text
27992
```

The larger magnitude is the first operand, so the result remains negative:

```text
-279.92
```

---

# 8. Decimal count after addition

For addition and subtraction, the output decimal count is the aligned decimal precision:

```text
out_dec = max(a_dec, b_dec)
```

For example:

```text
12.34 + 5.6
```

uses:

```text
12.34
05.60
```

so:

```text
out_dec = 2
```

The internal operation is therefore:

```text
1234 + 560 = 1794
```

and the result represents:

```text
17.94
```

---

# 9. Multiplication

`FP-MULTI` uses the same representation.

If:

```text
A = integer_A / 10^a_dec
B = integer_B / 10^b_dec
```

then:

```text
A × B =
(integer_A × integer_B) / 10^(a_dec + b_dec)
```

Therefore the integer values can be multiplied directly:

```text
out = A × B
```

while the decimal counts are added:

```text
out_dec = a_dec + b_dec
```

This is why `FP-MULTI` can use the integer `32bit_product` as its arithmetic core.

---

# 10. Multiplication example

Consider:

```text
12.34 × 2.5
```

The internal representations are:

```text
A = 1234
a_dec = 2

B = 25
b_dec = 1
```

The integer multiplication is:

```text
1234 × 25 = 30850
```

The decimal count becomes:

```text
2 + 1 = 3
```

Therefore:

```text
out = 30850
out_dec = 3
```

which represents:

```text
30.850
```

or numerically:

```text
30.85
```

The internal representation deliberately preserves the calculated decimal count.

---

# 11. Multiplication sign

The sign of a multiplication result is calculated using XOR:

```text
out_sign = a_sign XOR b_sign
```

Therefore:

```text
+ × + → +
- × - → +
+ × - → -
- × + → -
```

This is independent of the magnitude calculation.

The integer multiplication engine operates on the magnitudes, while the sign logic determines the sign of the final result.

---

# 12. Division

`FP-DIVISION` also uses the same conceptual representation:

```text
value + decimal count + sign
```

However, division requires a sequential algorithm because the fractional result must be generated from the remainder.

The project configures the floating-point divider to produce:

* the integer quotient;
* one decimal digit;
* a second decimal digit.

Therefore the output decimal count is:

```text
out_dec = n_a + 2 - n_b
```

where the `+2` accounts for the two decimal digits generated by the divider.

---

# 13. Division example

Consider:

```text
56.34 / -15.28
```

The internal values are:

```text
A = 5634
n_a = 2
sign A = positive

B = 1528
n_b = 2
sign B = negative
```

The magnitude division produces:

```text
3.68
```

internally represented as:

```text
value = 368
dec = 2
```

The signs differ, so:

```text
out_sign = negative
```

The final representation is therefore:

```text
out     = 368
out_dec = 2
out_sign = negative
```

which represents:

```text
-3.68
```

---

# 14. Relationship between the three floating-point operations

The three floating-point arithmetic units use the same representation but different arithmetic rules.

```text
┌────────────┬───────────────────────┬──────────────────────┐
│ Operation  │ Integer value         │ Decimal count        │
├────────────┼───────────────────────┼──────────────────────┤
│ Addition   │ aligned A ± aligned B │ max(a_dec,b_dec)     │
│ Multiply   │ A × B                │ a_dec + b_dec        │
│ Division   │ quotient construction│ n_a + 2 - n_b        │
└────────────┴───────────────────────┴──────────────────────┘
```

The sign rules are likewise operation-specific:

```text
Addition:
    equal signs → common sign
    different signs → sign of larger magnitude

Multiplication:
    XOR of signs

Division:
    XOR of signs
```

---

# 15. Decimal alignment versus decimal propagation

There is an important distinction between addition and multiplication.

### Addition

The operands must first be brought to the same scale.

For example:

```text
12.3
 4.56
```

becomes:

```text
12.30
 4.56
```

Internally:

```text
1230
 456
```

The decimal count is aligned before the arithmetic.

### Multiplication

No alignment is required.

The decimal counts simply add:

```text
12.3 × 4.56

dec = 1 + 2 = 3
```

This difference follows directly from the mathematics of decimal scaling.

---

# 16. Decimal count and display

The decimal-count field is also important outside the arithmetic units.

After an arithmetic operation, the result must eventually be displayed.

The binary value is converted to BCD by:

```text
32BIN to BCD
```

The decimal-position information is then used by the display path.

Conceptually:

```text
                  arithmetic result
                         │
              ┌──────────┴──────────┐
              │                     │
          integer value         decimal count
              │                     │
              ▼                     │
        32BIN to BCD                │
              │                     │
              └──────────┬──────────┘
                         ▼
                      DispOut
```

The binary value provides the digits.

The decimal-count information determines where the decimal point belongs.

---

# 17. Decimal representation and BCD

The custom floating-point representation fits naturally with the calculator's BCD-oriented I/O.

The conversion chain is approximately:

```text
binary integer
      │
      ▼
32BIN to BCD
      │
      ▼
decimal digits
      │
      └──── decimal count ────┐
                              │
                              ▼
                           DispOut
```

Conversely, keyboard input follows the opposite direction:

```text
keypad
   │
   ▼
DispInput2
   │
   ▼
BCD digits
   │
   ▼
8BCD to bin
   │
   ▼
binary integer + decimal metadata
```

Thus the decimal-scaled representation is a bridge between the binary arithmetic datapath and the decimal user interface.

---

# 18. Sign representation

The sign is stored separately from the magnitude.

This means that arithmetic modules can treat the numerical value and its sign as separate datapath elements.

For example:

```text
-345.32
```

is conceptually:

```text
magnitude = 34532
decimal   = 2
sign      = 1
```

while:

```text
+345.32
```

uses:

```text
magnitude = 34532
decimal   = 2
sign      = 0
```

The same magnitude datapath can therefore be reused for positive and negative values.

---

# 19. No IEEE-754 semantics

The term "floating-point" in this project refers to the fact that the decimal point can move according to separate metadata.

It should not be interpreted as IEEE-754 floating-point arithmetic.

The project does not use the conventional:

```text
sign | exponent | fraction
```

representation.

Instead it uses:

```text
sign | decimal count | integer magnitude
```

This is closer to a decimal-scaled integer representation with explicit decimal-position metadata.

This distinction is important when describing the architecture or comparing it with conventional CPU floating-point units.

---

# 20. Range and precision

The precision and range of the floating-point subsystem are constrained by the underlying 32-bit integer datapath and by the decimal metadata available in the design.

This means the representation should be understood as a **calculator-oriented fixed-width decimal-scaled system**, rather than as an unrestricted floating-point format.

The number of decimal digits is explicitly managed by the circuits.

The arithmetic units therefore have deterministic hardware limits.

When an operation exceeds the supported representation, the project uses the defined overflow convention:

```text
out      = 0
out_dec  = 0
out_sign = 0
```

---

# 21. Floating-point architecture

The three floating-point arithmetic units can be viewed as a common interface around different integer datapaths:

```text
                       Floating-point layer
                                │
        ┌───────────────────────┼────────────────────────┐
        │                       │                        │
        ▼                       ▼                        ▼
    FP-ADDER                 FP-MULTI              FP-DIVISION
        │                       │                        │
        ▼                       ▼                        ▼
  add/subtract              32bit_product          32bit division
  decimal align             decimal counts         ×3 sequential
  sign selection             sign XOR               decimal digits
        │                       │                        │
        └───────────────────────┴────────────────────────┘
                                │
                                ▼
                  value + decimal count + sign
```

The floating-point layer therefore acts as an abstraction over the lower-level binary arithmetic circuits.

---

# 22. Interaction with the accumulator

The accumulator does not need to understand the internal implementation of each arithmetic operation.

The arithmetic units produce the result in the common representation.

The control system then selects the appropriate operation output and places it on the shared BUS.

The scheduler controls the subsequent transfer into the accumulator.

Conceptually:

```text
FP-ADDER ───┐
            │
FP-MULTI ───┼──→ three-state BUS → accumulator
            │
FP-DIVISION ┘
```

The operation register determines which arithmetic output is allowed to drive the BUS.

This separation keeps the numerical representation independent from the control sequencing.

---

# 23. Numerical data flow

A typical arithmetic operation follows this general path:

```text
decimal input
     │
     ▼
BCD representation
     │
     ▼
binary integer
     │
     ├───────────────┐
     │               │
     ▼               ▼
  magnitude      decimal count
     │               │
     └───────┬───────┘
             ▼
      floating-point
        arithmetic
             │
       ┌─────┴─────┐
       │           │
       ▼           ▼
    magnitude     metadata
       │         sign + dec
       └─────┬─────┘
             ▼
       shared BUS
             │
             ▼
        accumulator
             │
             ▼
       binary → BCD
             │
             ▼
          display
```

This illustrates the central idea of Calculator 2.0:

**binary arithmetic is used internally, while decimal semantics are maintained explicitly by metadata.**

---

# 24. Summary

Calculator 2.0 implements a custom decimal-scaled floating-point system.

Each numerical value is represented by:

```text
value + decimal count + sign
```

The main floating-point operations are:

```text
FP-ADDER
FP-MULTI
FP-DIVISION
```

They share the same numerical representation but apply different rules to the decimal metadata.

For addition:

```text
decimal counts are aligned
```

For multiplication:

```text
decimal counts are added
```

For division:

```text
the divider generates two decimal digits
and the output count is:

out_dec = n_a + 2 - n_b
```

The magnitude is handled by the binary datapath, while sign and decimal position are handled explicitly.

The resulting architecture is therefore neither conventional integer-only arithmetic nor IEEE-754 floating point.

It is a **custom hardware decimal arithmetic system built on a 32-bit binary datapath**, with explicit sign and decimal-position metadata.

