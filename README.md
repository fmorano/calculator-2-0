# Calculator 2.0

A complete digital calculator **designed and built from scratch in CircuitVerse**, starting from basic logic gates and elementary digital components.

Calculator 2.0 is not based on pre-built arithmetic or calculator modules imported from external sources. **Every circuit is built from the basic logic gates and elementary components provided by the CircuitVerse simulator.**

The project is designed not only to demonstrate a working calculator, but also to provide a way to **understand how a complete digital calculator can be designed and built from the ground up**. Nothing is assumed: the project progressively exposes the fundamental building blocks, from binary arithmetic and data representation to floating-point operations, input/output conversion and the final control architecture.

Calculator 2.0 is therefore both a working digital calculator and a practical exploration of how a complex digital system can be constructed step by step from elementary logic components.

## 🚀 Try Online

**[Open Calculator 2.0 in CircuitVerse](https://circuitverse.org/users/277858/projects/calculator-2-0-f989b00f-29e5-4bbf-9f99-15c320fc85be/simulator)**

No installation required.

## 💾 Run Offline

Download the complete offline package:

**[Calculator-2.0-Offline.zip](./Calculator-2.0-Offline.zip)**

The package contains:

* `Calculator-2.0.cv` — the complete CircuitVerse project
* `run.sh` — launcher for Linux
* `run.bat` — launcher for Windows
* a local CircuitVerse simulator runtime

### Linux

Extract the ZIP and run:

```bash
./run.sh
```

The simulator opens automatically in the browser.

### Windows

Extract the ZIP and double-click:

```text
run.bat
```

Python must be installed on the system.

### Import the Calculator 2.0 Project

After starting the offline simulator, import the Calculator 2.0 project:

1. Open the **Project** menu in the CircuitVerse simulator.
2. Select **Import Project**.
3. Browse to the extracted `Calculator-2.0-Offline` folder.
4. Select:

```text
Calculator-2.0.cv
```

5. Confirm the import.

The complete Calculator 2.0 project, including all **36 interconnected circuits**, will then be loaded into the local simulator.


## 🎬 Demo

The following demonstration shows Calculator 2.0 performing a complete sequence of chained operations:

**187 + 45.23 − 587 = −354.77**<br>
**−354.77 × −25.21 = 8943.7517**<br>
**8943.7517 ÷ 145.25 = 61.5748**

The calculation is performed entirely by the digital circuits implemented in the CircuitVerse project, including the custom decimal floating-point arithmetic and sequential division.

> **Note:** The simulation runs with a **20 Hz clock**. Any visible delays during the calculation are therefore a consequence of the intentionally low simulation clock frequency, not a limitation of the calculator architecture.

<video src="https://github.com/user-attachments/assets/db77724a-06a3-43e5-8054-d779186bd469" controls width="800"></video>

## 🧭 Conceptual Map — Suggested Learning Path

Calculator 2.0 contains 36 interconnected circuits. Exploring them in an arbitrary order can quickly become confusing, because some circuits are complete functional blocks that can be studied independently, while others are mainly support circuits used inside larger blocks.

The following path reflects the learning and development path followed during the construction of the project. It is not intended as a mandatory order, but as a practical way to approach the circuits progressively, from the basic arithmetic blocks to the complete calculator.

### 1. Binary Arithmetic

The first step is to study the **binary arithmetic circuits**.

Whenever different versions of the same concept exist with different word lengths, it is preferable to start with the smaller version. The larger versions generally extend the same concept without introducing fundamentally new ideas.

These circuits can be studied and tested independently: by changing the inputs using the switches, the corresponding output can be observed directly.

Start with:

* `my32adder` — 32-bit binary addition
* `32bit sub` — 32-bit binary subtraction
* `16bit-product` — 16-bit binary multiplication; `32bit_product` is its larger extension
* `4 bit division` — 4-bit binary division; `16 bit division` and `32bit division` extend the same concept

At this stage the focus is entirely on understanding how binary arithmetic is implemented in digital logic.

### 2. Binary Floating-Point Arithmetic

Once the basic binary arithmetic is understood, the next step is to examine the circuits with the `FP-` prefix.

These circuits build upon the binary arithmetic blocks studied previously and implement the custom floating-point representation used by Calculator 2.0.

* `FP-ADDER` — 32-bit floating-point addition and subtraction
* `FP-MULTI` — 32-bit floating-point multiplication
* `FP-DIVISION` — 32-bit floating-point division

These circuits are particularly important because they form the arithmetic core of the calculator.

### 3. From Decimal Input to Binary

The next question is:

**How does a decimal number entered by the user become a 32-bit binary number that can be processed by the arithmetic circuits?**

Two circuits answer this question.

* `DispInput2` — provides the decimal input interface. The digits are selected using switches and displayed on the output display. Each decimal digit is represented internally as a BCD nibble: 4 bits representing the values from 0 to 9.
* `8BCD to bin` — converts the eight BCD decimal digits into a 32-bit binary number that can be passed to the binary arithmetic circuits.

This step connects the human-readable decimal input with the binary datapath.

### 4. From Binary Back to Decimal

The reverse process must then be understood:

**How does a binary result become a decimal representation that can be read by a human?**

Two circuits are involved.

* `32BIN to BCD` — converts a 32-bit binary number into its corresponding BCD representation, with each decimal digit represented by 4 bits.
* `DispOut` — handles the final display representation of a signed floating-point number.

At this point, the complete path from decimal input to binary computation and back to decimal output can be understood.

### 5. Finally: `Main`

Only after understanding the previous blocks does it make sense to approach `Main`.

`Main` is the **general control unit of Calculator 2.0**. It brings together the arithmetic, floating-point, input, conversion and output circuits explored in the previous steps.

Rather than being the starting point of the exploration, `Main` is the point where the concepts studied throughout the project are finally assembled into the complete calculator.

**This is where the exploration of the project comes together.**


## Project Source

The canonical CircuitVerse project is:

```text
Calculator-2.0.cv
```

It contains all **36 circuits in a single `.cv` project file**.

The source project and offline runtime are distributed together so that the project can be reproduced and explored locally.

## Architecture

The project contains 36 digital circuits organized into several functional areas:

* input and display
* registers and data storage
* arithmetic
* binary/BCD conversion
* shifting
* integer division
* floating-point arithmetic
* operation control
* clocked scheduling
* main calculator integration

The central circuit is `Main`.

The architecture uses a shared BUS with controlled three-state outputs, dedicated operation registers, sequential control phases and reusable arithmetic blocks.

## Floating-Point Representation

Calculator 2.0 does **not** use IEEE-754 floating point.

It uses a custom decimal-scaled representation:

```text
345.32 → integer value 34532 + decimal position 2
```

The sign and decimal position are handled separately.

This representation is used by:

* `FP-ADDER`
* `FP-MULTI`
* `FP-DIVISION`

## Division Architecture

The division architecture evolved through several generations:

```text
4 bit division
      ↓
16 bit division
      ↓
32 bit division
      ↓
FP-DIVISION
```

The 32-bit implementation uses dedicated load/shift, right-shift, MSB detection and bit-reversal circuits.

## Documentation

- [Architecture](./architecture.md) — overall system architecture and data flow
- [Control Unit](./control-unit.md) — clock, scheduling and operation control
- [Arithmetic](./arithmetic.md) — adders, subtraction and multiplication
- [Division](./division.md) — integer and sequential division architecture
- [Floating Point](./floating-point.md) — custom decimal floating-point arithmetic
- [Circuits](./circuits.md) — description of all 36 circuits and their dependencies

## Project Structure

The canonical source project is:

```text
Calculator-2.0.cv
```

It contains all 36 circuits in a single CircuitVerse project.

The offline simulator is distributed separately in:

```text
Calculator-2.0-Offline/
```

## License

See the repository for licensing information.

