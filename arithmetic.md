# Arithmetic Datapath

## 1. Overview

The arithmetic subsystem of **Calculator 2.0** is built hierarchically.

At the lowest level, the project provides integer arithmetic blocks. These blocks are then combined to implement higher-level arithmetic operations, including signed decimal-scaled floating-point addition and multiplication.

The main hierarchy is:

```text
                         Arithmetic subsystem
                                  │
                 ┌────────────────┴────────────────┐
                 │                                 │
          Integer arithmetic                Floating-point
                 │                                 │
       ┌─────────┼──────────┐             ┌───────┴───────┐
       │         │          │             │               │
   my32adder  32bit sub  32bit_product  FP-ADDER       FP-MULTI
       │         │          │
       │         │      ┌───┴────┐
       │         │      │        │
       │         │  32multi2  my32adder
       │         │
       └─────────┴───────────────────────────────────────
```

The arithmetic datapath is therefore not a single monolithic circuit. It is a hierarchy of reusable components.

---

## 2. Integer arithmetic

The integer arithmetic layer contains:

* `my32adder`
* `32bit sub`
* `32multi2`
* `16bit-product`
* `32bit_product`

These circuits operate on binary integer values.

They are used as building blocks by the floating-point arithmetic circuits.

---

## 3. `my32adder`

`my32adder` is the custom 32-bit binary adder used throughout the project.

The project does not rely on the native 32-bit adder because the native component exhibited a bug in the intended configuration.

The custom implementation therefore provides a known and reusable 32-bit addition primitive.

Its main role is:

```text
A + B → 32-bit result
```

It is used directly by higher-level circuits and also appears repeatedly inside the multiplication circuits.

---

## 4. `32bit sub`

`32bit sub` implements signed subtraction of two 32-bit magnitudes.

The circuit first compares the two operands.

If:

```text
A > B
```

the circuit computes:

```text
A - B
```

and produces a positive result.

If:

```text
A <= B
```

the circuit computes:

```text
B - A
```

and marks the result as negative.

Conceptually:

```text
             compare A and B
                    │
          ┌─────────┴─────────┐
          │                   │
        A > B               A ≤ B
          │                   │
        A - B               B - A
          │                   │
       positive            negative
```

This representation is particularly useful to `FP-ADDER`, where the absolute values of two operands with different signs must be compared before subtraction.

---

## 5. `32multi2`

`32multi2` implements multiplication by two.

In binary arithmetic, multiplication by two is equivalent to a left shift:

```text
A × 2 = A << 1
```

Therefore the circuit provides a simple hardware operation that can be used repeatedly to construct larger products.

---

## 6. `16bit-product`

`16bit-product` implements multiplication of two 16-bit integers.

The circuit uses the classical shift-and-add multiplication principle.

For each bit of operand `B`:

* if the bit is `0`, the corresponding partial product is zero;
* if the bit is `1`, the corresponding shifted version of `A` is added to the accumulated result.

Conceptually:

```text
                    B bits
                      │
       ┌──────────────┼──────────────┐
       │              │              │
      B0             B1             ...
       │              │
       ▼              ▼
      A×1            A×2            ...
       │              │
       └───────┬──────┴───────┐
               ▼              │
          partial sums        │
               │              │
               └──────────────┘
                      │
                      ▼
                    A × B
```

The implementation contains:

* `32multi2` ×15
* `my32adder` ×16

The `32multi2` instances generate successive powers-of-two shifts, while the adders accumulate the selected partial products.

This circuit is subsequently used by `5BCD to bin`.

---

## 7. `32bit_product`

`32bit_product` extends the same shift-and-add multiplication principle to 32-bit operands.

Its implementation contains:

* `32multi2` ×31
* `my32adder` ×32

The structure is therefore analogous to `16bit-product`, but extended to the full 32-bit datapath.

Conceptually:

```text
                 32-bit B
                    │
       ┌────────────┼────────────┐
       │            │            │
      B0           B1           ...
       │            │
       ▼            ▼
       A           A << 1       ...
       │            │
       └──────┬─────┘
              ▼
        partial products
              │
              ▼
       32-bit accumulation
              │
              ▼
            A × B
```

`32bit_product` is one of the most reused arithmetic primitives in the project.

It is used by:

* `FP-ADDER`
* `FP-MULTI`
* `FP-DIVISION`
* `8BCD to bin`

---

## 8. Floating-point representation

The floating-point representation used by Calculator 2.0 is **not IEEE-754**.

Instead, the project uses a decimal-scaled representation consisting of three independent pieces of information:

```text
value + decimal-position + sign
```

For example:

```text
345.32
```

is represented as:

```text
value  = 34532
dec    = 2
sign   = positive
```

The integer value contains the digits with the decimal separator temporarily removed.

The decimal-position field specifies how many decimal digits must be placed after the decimal point when displaying the value.

This representation is used by both `FP-ADDER` and `FP-MULTI`.

---

## 9. `FP-ADDER`

`FP-ADDER` implements signed addition and subtraction using the custom decimal-scaled representation.

Its inputs are:

```text
A
B
a_decimal
b_decimal
a_sign
b_sign
```

and its outputs are:

```text
out
out_dec
out_sign
```

### 9.1 Decimal alignment

Before performing the arithmetic operation, the operands must have the same decimal precision.

If one operand has fewer decimal digits, its integer representation is multiplied by the appropriate power of ten.

For example:

```text
345.32
 65.4
```

is represented internally as:

```text
A = 34532   a_dec = 2
B =   654   b_dec = 1
```

The second operand is normalized to:

```text
654 × 10 = 6540
```

Both operands now have two decimal digits.

The maximum decimal count becomes the output decimal count:

```text
out_dec = max(a_dec, b_dec)
```

The implementation supports the required powers of ten:

```text
10^0 = 1
10^1 = 10
10^2 = 100
10^3 = 1000
10^4 = 10000
```

---

## 10. Addition versus subtraction

The signs of the operands determine the arithmetic operation.

The circuit uses the XOR of the two sign bits.

### Same signs

If:

```text
a_sign = b_sign
```

the magnitudes are added.

```text
|A| + |B|
```

The result keeps the common sign.

Therefore:

```text
positive + positive → positive
negative + negative → negative
```

### Different signs

If:

```text
a_sign ≠ b_sign
```

the operation becomes a subtraction of magnitudes.

The two absolute values are compared first.

The smaller magnitude is subtracted from the larger magnitude.

The sign of the result is the sign of the operand having the larger absolute value.

Conceptually:

```text
same sign
    │
    └──→ addition
          │
          └── result keeps common sign


different signs
    │
    └──→ compare |A| and |B|
              │
       ┌──────┴──────┐
       ▼             ▼
     |A|>|B|       |B|>|A|
       │             │
       ▼             ▼
     A - B         B - A
       │             │
     sign A        sign B
```

---

## 11. Example: signed decimal addition

The project uses the example:

```text
-345.32 + 65.4
```

Internal representation:

```text
A = 34532
a_dec = 2
a_sign = negative

B = 654
b_dec = 1
b_sign = positive
```

Decimal alignment gives:

```text
B = 6540
b_dec = 2
```

The signs differ, therefore the magnitudes are subtracted:

```text
34532 - 6540 = 27992
```

Since the magnitude of `A` is larger, the result keeps the sign of `A`.

Therefore:

```text
out     = 27992
out_dec = 2
out_sign = negative
```

which represents:

```text
-279.92
```

---

## 12. `FP-ADDER` internal building blocks

`FP-ADDER` is composed from several lower-level arithmetic blocks:

```text
FP-ADDER
├── multiplexer 8 x 16b ×2
├── my32adder ×1
├── 32bit sub ×2
└── 32bit_product ×2
```

The multiplication hardware is used for decimal alignment.

The adder performs the same-sign case and contributes to the arithmetic datapath.

The subtraction blocks implement the different-sign case and magnitude comparison/subtraction operations.

Thus the floating-point adder is constructed from reusable integer arithmetic primitives rather than from a single specialized arithmetic component.

---

## 13. `FP-MULTI`

`FP-MULTI` implements signed multiplication using the same decimal-scaled representation.

Its inputs are:

```text
A
B
a_dec
b_dec
a_sign
b_sign
```

Its outputs are:

```text
out
out_dec
out_sign
```

The numerical part of the operation is delegated to:

```text
32bit_product
```

---

## 14. Floating-point multiplication

The integer values are multiplied directly:

```text
out = A × B
```

The decimal-position fields are added:

```text
out_dec = a_dec + b_dec
```

This follows directly from decimal fixed-point scaling.

For example, if:

```text
A = 1234
a_dec = 2
```

and:

```text
B = 25
b_dec = 1
```

the represented values are:

```text
12.34 × 2.5
```

The integer multiplication is:

```text
1234 × 25
```

while the decimal count becomes:

```text
2 + 1 = 3
```

---

## 15. Multiplication sign

The output sign is calculated using XOR:

```text
out_sign = a_sign XOR b_sign
```

Therefore:

```text
positive × positive → positive
negative × negative → positive
positive × negative → negative
negative × positive → negative
```

This is the standard sign rule for multiplication, implemented directly in hardware.

---

## 16. `FP-MULTI` hierarchy

The hierarchy is simple:

```text
FP-MULTI
    │
    ▼
32bit_product
    │
    ├── 32multi2 ×31
    └── my32adder ×32
```

`FP-MULTI` therefore adds floating-point metadata handling around the integer multiplication engine:

```text
                ┌─────────────────────┐
                │       FP-MULTI      │
                │                     │
 A ─────────────┤                     │
 B ─────────────┤                     │
 a_dec ─────────┤                     │
 b_dec ─────────┤                     │
 a_sign ────────┤                     │
 b_sign ────────┤                     │
                │                     │
                │  32bit_product      │
                │  out_dec = a+b      │
                │  sign = XOR         │
                └──────────┬──────────┘
                           │
                     out / out_dec
                        / out_sign
```

---

## 17. Overflow handling

The arithmetic floating-point modules use a simple explicit overflow convention.

When an arithmetic operation exceeds the supported representation, the output is forced to zero:

```text
out      = 0
out_dec  = 0
out_sign = 0
```

This convention is used by both:

* `FP-ADDER`
* `FP-MULTI`

It allows the rest of the calculator architecture to receive a well-defined output instead of an undefined or partially valid result.

---

## 18. Arithmetic hierarchy

The complete arithmetic hierarchy can be summarized as:

```text
                    ┌─────────────────┐
                    │  FP-ADDER       │
                    │                 │
                    │ decimal align   │
                    │ sign handling   │
                    │ add / subtract  │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
        multiplexer      my32adder      32bit sub
        8 x 16b                          │
                                         │
                                         ▼
                                    32bit arithmetic


                    ┌─────────────────┐
                    │   FP-MULTI      │
                    │                 │
                    │ integer product │
                    │ decimal counts  │
                    │ sign XOR        │
                    └────────┬────────┘
                             │
                             ▼
                       32bit_product
                             │
                    ┌────────┴────────┐
                    ▼                 ▼
                32multi2          my32adder
```

The important architectural principle is that the floating-point circuits do not replace the integer datapath. They **compose it**.

---

## 19. Role in the calculator

The arithmetic modules are connected to the calculator's shared BUS through the operation-selection logic described in `control-unit.md`.

The arithmetic result is therefore not written directly into the accumulator by the arithmetic module itself.

Instead:

```text
operation
    │
    ▼
FP arithmetic module
    │
    ▼
three-state output
    │
    ▼
shared BUS
    │
    ▼
scheduler-controlled load
    │
    ▼
32bit register
    │
    ▼
accumulator
```

Only the operation selected by `OP-FLAG-REG` is allowed to drive the BUS.

This separates the **calculation of a result** from the **control of when that result is transferred into the accumulator**.

---

## 20. Arithmetic design principles

The arithmetic subsystem follows several consistent design principles:

1. **Hierarchical construction**
   Complex operations are constructed from smaller reusable circuits.

2. **Binary integer datapath**
   The actual arithmetic is performed on binary integer values.

3. **Explicit decimal metadata**
   Decimal position is stored separately rather than encoded using IEEE-754.

4. **Explicit sign handling**
   Sign is represented by a separate signal.

5. **Hardware reuse**
   `my32adder`, `32bit sub`, `32multi2`, and `32bit_product` are reused by higher-level modules.

6. **Separation of datapath and control**
   Arithmetic modules calculate results, while the control unit determines when results are placed on the BUS and loaded into the accumulator.

7. **Deterministic overflow behavior**
   Overflow produces the defined zero representation.

The result is a modular arithmetic datapath in which integer primitives form the computational foundation and the `FP-*` circuits provide the calculator-level signed decimal arithmetic.

