# Calculator 2.0

A complete digital calculator built in [CircuitVerse](https://circuitverse.org/), composed of **36 interconnected digital subcircuits**.

Calculator 2.0 implements integer and custom floating-point arithmetic, decimal input/output, registers, shifters, multiplication, subtraction and sequential division, together with a clocked control architecture.

## Try Online

Open the project directly in CircuitVerse:

**[Try Calculator 2.0 Online](https://circuitverse.org/users/277858/projects/calculator-2-0-f989b00f-29e5-4bbf-9f99-15c320fc85be/simulator)**

No installation is required.

## Run Offline

Download:

`Calculator-2.0-Offline.zip`

The package contains:

* `calculator37.cv` — the complete Calculator 2.0 project
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

## Project Structure

The canonical source project is:

```text
calculator37.cv
```

It contains all 36 circuits in a single CircuitVerse project.

The offline simulator is distributed separately in:

```text
Calculator-2.0-Offline/
```

## Documentation

Additional documentation describes:

* overall architecture
* control unit
* arithmetic circuits
* division
* floating-point arithmetic
* all 36 circuits and their dependencies

## License

See the repository for licensing information.

