# Circuit Catalog

## 1. Overview

The CircuitVerse project **Calculator 2.0** contains 36 digital subcircuits.

The project is intentionally organized as a hierarchy of reusable modules.

Some circuits are directly part of the execution path of the current calculator.

Others are intermediate, foundational, didactic, or evolutionary implementations that document how the architecture developed.

The canonical source is the CircuitVerse project file:

```text
calculator37.cv
```

All 36 circuits are contained in this single `.cv` project.

---

# 2. Circuit classification

The circuits can be grouped into the following functional categories.

### Control

* `when start`
* `OP FLAGS-temp`
* `OP-FLAG-REG`
* `N-phase scheduler`
* `4phase scheduler`

### Registers and storage

* `4 bit register`
* `8bitregister`
* `16bit register`
* `32bit register`

### Input

* `DispInput2`
* `8BCD to bin`

### Output

* `32BIN to BCD`
* `DispOut`

### Integer arithmetic

* `my32adder`
* `32bit sub`
* `32multi2`
* `16bit-product`
* `32bit_product`

### Shifting and bit manipulation

* `8 Load/LShift`
* `32 Load/L Shift`
* `8bit R shift`
* `32-R-Shift`
* `32 pos shift`
* `8bit l-shifter`
* `32bit l-shifter`
* `reverse`

### Division

* `4 bit division`
* `16 bit division`
* `32bit division`
* `FP-DIVISION`

### Floating-point arithmetic

* `FP-ADDER`
* `FP-MULTI`

### Auxiliary datapath

* `multiplexer 8 x 16b`

### Top level

* `Main`

---

# 3. Circuit inventory

The following list follows the exact circuit order stored in the `.cv` project.

---

## 3.1 `OP FLAGS-temp`

**Category:** Control

Temporary operation register.

It stores the operation selected by the user before that operation becomes the active operation of the calculator.

The control logic ensures that the operation flags are mutually exclusive.

For example, selecting `+`, `×`, or `:` activates the corresponding flag while clearing the alternatives.

The value is later transferred to `OP-FLAG-REG` by the scheduler.

**Used by:**

* `Main`

---

## 3.2 `4 bit division`

**Category:** Division / Didactic

Four-bit implementation of binary long division.

It demonstrates the fundamental sequential algorithm:

1. shift the remainder;
2. insert the next dividend bit;
3. compare with the divisor;
4. subtract when possible;
5. generate one quotient bit.

The implementation uses two logical subphases for each division step.

This circuit is not directly used by `Main`.

It represents the conceptual starting point of the division architecture.

**Used by:**

* none

**Role:** Didactic / evolutionary

---

## 3.3 `32multi2`

**Category:** Integer arithmetic

Multiplies a value by two using a binary left shift.

```text
A × 2 = A << 1
```

It is used as a primitive inside the multiplier hierarchy.

**Used by:**

* `16bit-product` ×15
* `32bit_product` ×31

---

## 3.4 `my32adder`

**Category:** Integer arithmetic

Custom 32-bit binary adder.

It is used instead of the native 32-bit adder because the project required a reliable custom implementation.

It is one of the most reused arithmetic primitives.

**Used by:**

* `16bit-product` ×16
* `32bit_product` ×32
* `5BCD to bin` ×4
* `FP-ADDER`
* `FP-DIVISION`
* `8BCD to bin` ×8

---

## 3.5 `16bit-product`

**Category:** Integer arithmetic

16-bit multiplication using shift-and-add partial products.

The circuit uses:

* `32multi2` ×15
* `my32adder` ×16

Each bit of the multiplier determines whether the corresponding shifted partial product contributes to the accumulated result.

**Used by:**

* `5BCD to bin` ×4

---

## 3.6 `32bit sub`

**Category:** Integer arithmetic

32-bit magnitude subtraction with sign handling.

The operands are compared before subtraction.

If `A > B`, the result is:

```text
A - B
```

with positive sign.

Otherwise:

```text
B - A
```

is calculated and the result is marked negative.

This circuit is particularly important to `FP-ADDER`.

**Used by:**

* `single-digit-converter2`
* `FP-ADDER` ×2

---

## 3.7 `8bitregister`

**Category:** Register / Storage

Eight-bit register implemented using eight D flip-flops.

The register is loaded on the appropriate clock impulse.

Reset logic initializes the stored value.

**Used by:**

* `16bit register` ×2

---

## 3.8 `16bit register`

**Category:** Register / Storage

16-bit register constructed from two `8bitregister` instances.

The 16-bit input is divided into two 8-bit portions.

**Used by:**

* `32bit register` ×2

---

## 3.9 `32bit register`

**Category:** Register / Storage

32-bit register constructed from two `16bit register` instances.

It is the main numeric storage element used by the calculator.

In `Main`, this register stores the numerical value of the **accumulator**.

**Used by:**

* `single-digit-converter2`
* `Main`

---

## 3.10 `4phase scheduler`

**Category:** Control / Didactic

Sequential four-phase scheduler.

Each clock step activates a different phase.

It is used by `single-digit-converter2`.

**Used by:**

* `single-digit-converter2`

---

## 3.11 `single-digit-converter2`

**Category:** Binary → BCD

Converts part of a binary value into one BCD decimal digit.

It receives a binary value and a reference corresponding to a decimal power of ten.

Repeated subtraction determines how many times the reference can be removed from the current remainder.

The result is:

* one BCD digit;
* a remainder passed to the next decimal stage.

**Used by:**

* `32BIN to BCD` ×9

---

## 3.12 `32BIN to BCD`

**Category:** Output conversion

Converts a 32-bit binary integer into decimal digits represented in BCD.

It contains nine `single-digit-converter2` stages.

The decimal references cover:

```text
100,000,000
10,000,000
1,000,000
100,000
10,000
1,000
100
10
1
```

The resulting BCD digits are used by the display subsystem.

**Used by:**

* `Main`

---

## 3.13 `5BCD to bin`

**Category:** Input conversion

Converts five BCD decimal digits into a binary integer.

The decimal digits are multiplied by their corresponding powers of ten and then summed.

The implementation contains:

* `16bit-product` ×4
* `my32adder` ×4

**Used by:**

* `FP-DIVISION`

---

## 3.14 `16 bit division`

**Category:** Division / Didactic

16-bit generalization of the 4-bit binary long-division circuit.

It preserves the same algorithm while increasing the datapath width.

The circuit is not directly reached from `Main`.

**Used by:**

* none

**Role:** Didactic / evolutionary

---

## 3.15 `4 bit register`

**Category:** Register / Storage

Four-bit register implemented with four D flip-flops.

In `Main`, it stores the decimal-count metadata associated with the accumulator.

This value indicates how many decimal digits belong after the decimal point.

It therefore does **not** contain the numerical accumulator itself.

**Used by:**

* `DispInput2`
* `Main`

---

## 3.16 `DispInput2`

**Category:** Input

Keyboard/display input subsystem.

It contains nine 4-bit registers.

As decimal digits are entered, the stored digits are shifted and the visible input is updated.

The circuit provides the BCD representation of the entered decimal digits.

**Used by:**

* `Main`

---

## 3.17 `8 Load/LShift`

**Category:** Shifting / Register

Eight-bit load/left-shift register.

It can first load an input value and subsequently participate in the sequential left-shift process.

**Used by:**

* `32 Load/L Shift` ×4

---

## 3.18 `32 Load/L Shift`

**Category:** Shifting / Division datapath

32-bit load/left-shift register constructed from four `8 Load/LShift` blocks.

In the division architecture, this is specifically the **remainder register path**.

Its operation alternates between:

```text
load
shift left
load
shift left
...
```

It should not be confused with `32-R-Shift`, which constructs the quotient.

**Used by:**

* `32bit division`

---

## 3.19 `8bit R shift`

**Category:** Shifting

Eight-bit right shifter.

**Used by:**

* `32-R-Shift` ×4

---

## 3.20 `32-R-Shift`

**Category:** Shifting / Division datapath

32-bit right shifter constructed from four `8bit R shift` blocks.

In the division architecture, it is specifically used to construct the **quotient** progressively.

**Used by:**

* `32bit division`

---

## 3.21 `32 pos shift`

**Category:** Bit scanning / Division optimization

Scans a 32-bit dividend from the most significant bit.

Leading zeros are skipped.

Once the first `1` is found, the significant dividend bits are emitted sequentially.

The output `cout` supplies the current dividend bit to the division datapath.

This reduces division time to the number of significant bits in the dividend.

Therefore, for a non-zero 32-bit dividend:

```text
1 ≤ cycles ≤ 32
```

**Used by:**

* `32bit division`

---

## 3.22 `reverse`

**Category:** Bit manipulation / Division

Reverses the bit ordering of the intermediate quotient.

The sequential quotient-generation process produces the quotient bits in reverse order.

`reverse` restores the conventional MSB-to-LSB representation.

**Used by:**

* `32bit division`

---

## 3.23 `32bit division`

**Category:** Division

Optimized 32-bit binary long divider.

It combines:

* `32 Load/L Shift` for the remainder;
* `32-R-Shift` for the quotient;
* `32 pos shift` for significant dividend scanning;
* `reverse` for quotient ordering.

The fundamental algorithm remains binary long division.

Each significant dividend bit produces one quotient bit.

The number of iterations is therefore determined by the position of the most significant set bit.

**Used by:**

* `FP-DIVISION` ×3

---

## 3.24 `32bit_product`

**Category:** Integer arithmetic

32-bit shift-and-add multiplier.

It contains:

* `32multi2` ×31
* `my32adder` ×32

It is the main integer multiplication engine of the calculator.

**Used by:**

* `FP-ADDER` ×2
* `FP-DIVISION` ×3
* `FP-MULTI`
* `8BCD to bin` ×8

---

## 3.25 `FP-DIVISION`

**Category:** Floating-point arithmetic

Signed decimal-scaled floating-point division.

It uses three `32bit division` instances to calculate:

1. integer quotient;
2. first decimal digit;
3. second decimal digit.

The remainder from one stage is multiplied by ten before the next stage.

The output sign is:

```text
a_sign XOR b_sign
```

The decimal count is:

```text
out_dec = n_a + 2 - n_b
```

Direct dependencies:

* `32bit division` ×3
* `32bit_product` ×3
* `5BCD to bin` ×1
* `my32adder` ×1

**Used by:**

* `Main`

---

## 3.26 `multiplexer 8 x 16b`

**Category:** Auxiliary datapath

8-input, 16-bit multiplexer.

It is used inside `FP-ADDER` to select among the required decimal-scaling values and datapath alternatives.

**Used by:**

* `FP-ADDER` ×2

---

## 3.27 `FP-ADDER`

**Category:** Floating-point arithmetic

Signed decimal-scaled addition/subtraction.

Inputs include:

```text
A
B
a_dec
b_dec
a_sign
b_sign
```

Outputs include:

```text
out
out_dec
out_sign
```

The signs determine whether the magnitudes must be added or subtracted.

Before arithmetic, operands are aligned to the same decimal precision.

For different signs, the magnitudes are compared and the smaller is subtracted from the larger.

Direct dependencies:

* `multiplexer 8 x 16b` ×2
* `my32adder`
* `32bit sub` ×2
* `32bit_product` ×2

**Used by:**

* `Main`

---

## 3.28 `FP-MULTI`

**Category:** Floating-point arithmetic

Signed decimal-scaled multiplication.

The numerical multiplication is delegated to `32bit_product`.

The decimal counts are added:

```text
out_dec = a_dec + b_dec
```

The sign is calculated with XOR:

```text
out_sign = a_sign XOR b_sign
```

**Used by:**

* `Main`

---

## 3.29 `DispOut`

**Category:** Output

Display subsystem.

It receives decimal digits in BCD and drives the corresponding hexadecimal displays.

The decimal-count information is used to determine the decimal-point position.

Leading zeros are suppressed according to the display logic.

**Used by:**

* `Main`

---

## 3.30 `8BCD to bin`

**Category:** Input conversion

Converts the BCD representation of the entered decimal value into a binary integer.
# Circuit Catalog

## 1. Overview

The CircuitVerse project **Calculator 2.0** contains 36 digital subcircuits.

The project is intentionally organized as a hierarchy of reusable modules.

Some circuits are directly part of the execution path of the current calculator.

Others are intermediate, foundational, didactic, or evolutionary implementations that document how the architecture developed.

The canonical source is the CircuitVerse project file:

```text
calculator37.cv
```

All 36 circuits are contained in this single `.cv` project.

---

# 2. Circuit classification

The circuits can be grouped into the following functional categories.

### Control

* `when start`
* `OP FLAGS-temp`
* `OP-FLAG-REG`
* `N-phase scheduler`
* `4phase scheduler`

### Registers and storage

* `4 bit register`
* `8bitregister`
* `16bit register`
* `32bit register`

### Input

* `DispInput2`
* `8BCD to bin`

### Output

* `32BIN to BCD`
* `DispOut`

### Integer arithmetic

* `my32adder`
* `32bit sub`
* `32multi2`
* `16bit-product`
* `32bit_product`

### Shifting and bit manipulation

* `8 Load/LShift`
* `32 Load/L Shift`
* `8bit R shift`
* `32-R-Shift`
* `32 pos shift`
* `8bit l-shifter`
* `32bit l-shifter`
* `reverse`

### Division

* `4 bit division`
* `16 bit division`
* `32bit division`
* `FP-DIVISION`

### Floating-point arithmetic

* `FP-ADDER`
* `FP-MULTI`

### Auxiliary datapath

* `multiplexer 8 x 16b`

### Top level

* `Main`

---

# 3. Circuit inventory

The following list follows the exact circuit order stored in the `.cv` project.

---

## 3.1 `OP FLAGS-temp`

**Category:** Control

Temporary operation register.

It stores the operation selected by the user before that operation becomes the active operation of the calculator.

The control logic ensures that the operation flags are mutually exclusive.

For example, selecting `+`, `×`, or `:` activates the corresponding flag while clearing the alternatives.

The value is later transferred to `OP-FLAG-REG` by the scheduler.

**Used by:**

* `Main`

---

## 3.2 `4 bit division`

**Category:** Division / Didactic

Four-bit implementation of binary long division.

It demonstrates the fundamental sequential algorithm:

1. shift the remainder;
2. insert the next dividend bit;
3. compare with the divisor;
4. subtract when possible;
5. generate one quotient bit.

The implementation uses two logical subphases for each division step.

This circuit is not directly used by `Main`.

It represents the conceptual starting point of the division architecture.

**Used by:**

* none

**Role:** Didactic / evolutionary

---

## 3.3 `32multi2`

**Category:** Integer arithmetic

Multiplies a value by two using a binary left shift.

```text
A × 2 = A << 1
```

It is used as a primitive inside the multiplier hierarchy.

**Used by:**

* `16bit-product` ×15
* `32bit_product` ×31

---

## 3.4 `my32adder`

**Category:** Integer arithmetic

Custom 32-bit binary adder.

It is used instead of the native 32-bit adder because the project required a reliable custom implementation.

It is one of the most reused arithmetic primitives.

**Used by:**

* `16bit-product` ×16
* `32bit_product` ×32
* `5BCD to bin` ×4
* `FP-ADDER`
* `FP-DIVISION`
* `8BCD to bin` ×8

---

## 3.5 `16bit-product`

**Category:** Integer arithmetic

16-bit multiplication using shift-and-add partial products.

The circuit uses:

* `32multi2` ×15
* `my32adder` ×16

Each bit of the multiplier determines whether the corresponding shifted partial product contributes to the accumulated result.

**Used by:**

* `5BCD to bin` ×4

---

## 3.6 `32bit sub`

**Category:** Integer arithmetic

32-bit magnitude subtraction with sign handling.

The operands are compared before subtraction.

If `A > B`, the result is:

```text
A - B
```

with positive sign.

Otherwise:

```text
B - A
```

is calculated and the result is marked negative.

This circuit is particularly important to `FP-ADDER`.

**Used by:**

* `single-digit-converter2`
* `FP-ADDER` ×2

---

## 3.7 `8bitregister`

**Category:** Register / Storage

Eight-bit register implemented using eight D flip-flops.

The register is loaded on the appropriate clock impulse.

Reset logic initializes the stored value.

**Used by:**

* `16bit register` ×2

---

## 3.8 `16bit register`

**Category:** Register / Storage

16-bit register constructed from two `8bitregister` instances.

The 16-bit input is divided into two 8-bit portions.

**Used by:**

* `32bit register` ×2

---

## 3.9 `32bit register`

**Category:** Register / Storage

32-bit register constructed from two `16bit register` instances.

It is the main numeric storage element used by the calculator.

In `Main`, this register stores the numerical value of the **accumulator**.

**Used by:**

* `single-digit-converter2`
* `Main`

---

## 3.10 `4phase scheduler`

**Category:** Control / Didactic

Sequential four-phase scheduler.

Each clock step activates a different phase.

It is used by `single-digit-converter2`.

**Used by:**

* `single-digit-converter2`

---

## 3.11 `single-digit-converter2`

**Category:** Binary → BCD

Converts part of a binary value into one BCD decimal digit.

It receives a binary value and a reference corresponding to a decimal power of ten.

Repeated subtraction determines how many times the reference can be removed from the current remainder.

The result is:

* one BCD digit;
* a remainder passed to the next decimal stage.

**Used by:**

* `32BIN to BCD` ×9

---

## 3.12 `32BIN to BCD`

**Category:** Output conversion

Converts a 32-bit binary integer into decimal digits represented in BCD.

It contains nine `single-digit-converter2` stages.

The decimal references cover:

```text
100,000,000
10,000,000
1,000,000
100,000
10,000
1,000
100
10
1
```

The resulting BCD digits are used by the display subsystem.

**Used by:**

* `Main`

---

## 3.13 `5BCD to bin`

**Category:** Input conversion

Converts five BCD decimal digits into a binary integer.

The decimal digits are multiplied by their corresponding powers of ten and then summed.

The implementation contains:

* `16bit-product` ×4
* `my32adder` ×4

**Used by:**

* `FP-DIVISION`

---

## 3.14 `16 bit division`

**Category:** Division / Didactic

16-bit generalization of the 4-bit binary long-division circuit.

It preserves the same algorithm while increasing the datapath width.

The circuit is not directly reached from `Main`.

**Used by:**

* none

**Role:** Didactic / evolutionary

---

## 3.15 `4 bit register`

**Category:** Register / Storage

Four-bit register implemented with four D flip-flops.

In `Main`, it stores the decimal-count metadata associated with the accumulator.

This value indicates how many decimal digits belong after the decimal point.

It therefore does **not** contain the numerical accumulator itself.

**Used by:**

* `DispInput2`
* `Main`

---

## 3.16 `DispInput2`

**Category:** Input

Keyboard/display input subsystem.

It contains nine 4-bit registers.

As decimal digits are entered, the stored digits are shifted and the visible input is updated.

The circuit provides the BCD representation of the entered decimal digits.

**Used by:**

* `Main`

---

## 3.17 `8 Load/LShift`

**Category:** Shifting / Register

Eight-bit load/left-shift register.

It can first load an input value and subsequently participate in the sequential left-shift process.

**Used by:**

* `32 Load/L Shift` ×4

---

## 3.18 `32 Load/L Shift`

**Category:** Shifting / Division datapath

32-bit load/left-shift register constructed from four `8 Load/LShift` blocks.

In the division architecture, this is specifically the **remainder register path**.

Its operation alternates between:

```text
load
shift left
load
shift left
...
```

It should not be confused with `32-R-Shift`, which constructs the quotient.

**Used by:**

* `32bit division`

---

## 3.19 `8bit R shift`

**Category:** Shifting

Eight-bit right shifter.

**Used by:**

* `32-R-Shift` ×4

---

## 3.20 `32-R-Shift`

**Category:** Shifting / Division datapath

32-bit right shifter constructed from four `8bit R shift` blocks.

In the division architecture, it is specifically used to construct the **quotient** progressively.

**Used by:**

* `32bit division`

---

## 3.21 `32 pos shift`

**Category:** Bit scanning / Division optimization

Scans a 32-bit dividend from the most significant bit.

Leading zeros are skipped.

Once the first `1` is found, the significant dividend bits are emitted sequentially.

The output `cout` supplies the current dividend bit to the division datapath.

This reduces division time to the number of significant bits in the dividend.

Therefore, for a non-zero 32-bit dividend:

```text
1 ≤ cycles ≤ 32
```

**Used by:**

* `32bit division`

---

## 3.22 `reverse`

**Category:** Bit manipulation / Division

Reverses the bit ordering of the intermediate quotient.

The sequential quotient-generation process produces the quotient bits in reverse order.

`reverse` restores the conventional MSB-to-LSB representation.

**Used by:**

* `32bit division`

---

## 3.23 `32bit division`

**Category:** Division

Optimized 32-bit binary long divider.

It combines:

* `32 Load/L Shift` for the remainder;
* `32-R-Shift` for the quotient;
* `32 pos shift` for significant dividend scanning;
* `reverse` for quotient ordering.

The fundamental algorithm remains binary long division.

Each significant dividend bit produces one quotient bit.

The number of iterations is therefore determined by the position of the most significant set bit.

**Used by:**

* `FP-DIVISION` ×3

---

## 3.24 `32bit_product`

**Category:** Integer arithmetic

32-bit shift-and-add multiplier.

It contains:

* `32multi2` ×31
* `my32adder` ×32

It is the main integer multiplication engine of the calculator.

**Used by:**

* `FP-ADDER` ×2
* `FP-DIVISION` ×3
* `FP-MULTI`
* `8BCD to bin` ×8

---

## 3.25 `FP-DIVISION`

**Category:** Floating-point arithmetic

Signed decimal-scaled floating-point division.

It uses three `32bit division` instances to calculate:

1. integer quotient;
2. first decimal digit;
3. second decimal digit.

The remainder from one stage is multiplied by ten before the next stage.

The output sign is:

```text
a_sign XOR b_sign
```

The decimal count is:

```text
out_dec = n_a + 2 - n_b
```

Direct dependencies:

* `32bit division` ×3
* `32bit_product` ×3
* `5BCD to bin` ×1
* `my32adder` ×1

**Used by:**

* `Main`

---

## 3.26 `multiplexer 8 x 16b`

**Category:** Auxiliary datapath

8-input, 16-bit multiplexer.

It is used inside `FP-ADDER` to select among the required decimal-scaling values and datapath alternatives.

**Used by:**

* `FP-ADDER` ×2

---

## 3.27 `FP-ADDER`

**Category:** Floating-point arithmetic

Signed decimal-scaled addition/subtraction.

Inputs include:

```text
A
B
a_dec
b_dec
a_sign
b_sign
```

Outputs include:

```text
out
out_dec
out_sign
```

The signs determine whether the magnitudes must be added or subtracted.

Before arithmetic, operands are aligned to the same decimal precision.

For different signs, the magnitudes are compared and the smaller is subtracted from the larger.

Direct dependencies:

* `multiplexer 8 x 16b` ×2
* `my32adder`
* `32bit sub` ×2
* `32bit_product` ×2

**Used by:**

* `Main`

---

## 3.28 `FP-MULTI`

**Category:** Floating-point arithmetic

Signed decimal-scaled multiplication.

The numerical multiplication is delegated to `32bit_product`.

The decimal counts are added:

```text
out_dec = a_dec + b_dec
```

The sign is calculated with XOR:

```text
out_sign = a_sign XOR b_sign
```

**Used by:**

* `Main`

---

## 3.29 `DispOut`

**Category:** Output

Display subsystem.

It receives decimal digits in BCD and drives the corresponding hexadecimal displays.

The decimal-count information is used to determine the decimal-point position.

Leading zeros are suppressed according to the display logic.

**Used by:**

* `Main`

---

## 3.30 `8BCD to bin`

**Category:** Input conversion

Converts the BCD representation of the entered decimal value into a binary integer.

