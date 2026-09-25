# Calculator 2.0

A complete digital calculator designed and built in [CircuitVerse](https://circuitverse.org/), composed of **36 interconnected digital subcircuits**.

Calculator 2.0 is a hardware-oriented digital calculator implementing integer arithmetic, custom floating-point arithmetic, decimal input/output, registers, shifters, sequential division and a clocked control architecture.

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

## 🎬 Demo

The following demonstration shows Calculator 2.0 performing a complete sequence of chained operations:

**187 + 45.23 − 587 = −354.77**
**−354.77 × −25.21 = 8943.7517**
**8943.7517 ÷ 145.25 = 61.5748**

The calculation is performed entirely by the digital circuits implemented in the CircuitVerse project, including the custom decimal floating-point arithmetic and sequential division.

> **Note:** The simulation runs with a **20 Hz clock**. Any visible delays during the calculation are therefore a consequence of the intentionally low simulation clock frequency, not a limitation of the calculator architecture.

[▶️ Watch the demonstration video](VIDEO-LINK)


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

