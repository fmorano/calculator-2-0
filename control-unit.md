# Calculator 2.0 — Control Unit

## 1. Overview

The control path of Calculator 2.0 coordinates the transfer of data, the selection of the active arithmetic operation, and the sequencing of multi-cycle operations.

The main control circuits are:

* `when start`
* `OP FLAGS-temp`
* `OP-FLAG-REG`
* `N-phase scheduler`

The control path works together with the shared BUS and the three-state output buffers of the arithmetic units.

The fundamental principle is that **the operation selected by the user is not immediately treated as the effective operation**. It is first stored temporarily and then transferred into the effective operation register at a defined clock phase.

This provides deterministic sequencing between:

* loading the accumulator;
* clearing the input;
* updating the active operation;
* enabling the appropriate arithmetic result onto the BUS.

---

## 2. Control-path organization

The main control relationship is:

```text
                 USER OPERATION
                    +  ×  :
                      │
                      ▼
              ┌────────────────┐
              │ OP FLAGS-temp  │
              └───────┬────────┘
                      │
                      │ phase 2
                      ▼
              ┌────────────────┐
              │ OP-FLAG-REG    │
              └───────┬────────┘
                      │
                      │ operation state
                      ▼
          ┌──────────────────────────┐
          │ arithmetic output enable │
          │ / three-state buffers    │
          └────────────┬─────────────┘
                       │
                       ▼
                      BUS
```

The `N-phase scheduler` determines when the transfer from `OP FLAGS-temp` to `OP-FLAG-REG` occurs.

`when start` determines which control sequence has to be initiated depending on the key pressed by the user.

---

## 3. `OP FLAGS-temp`

`OP FLAGS-temp` is the temporary operation register.

It stores the operation selected by the user, such as:

```text
+
×
:
```

The operation flags are mutually exclusive.

When one operation is selected:

* its flag becomes active;
* the other operation flags are cleared.

The temporary register therefore represents the **operation requested by the user**, but not yet necessarily the operation currently active in the arithmetic datapath.

This distinction is important because the calculator must complete the required data-transfer phase before changing the effective operation state.

---

## 4. `OP-FLAG-REG`

`OP-FLAG-REG` stores the operation that is actually active for the next calculation sequence.

Its value is loaded from `OP FLAGS-temp` during phase 2 of the scheduler.

Conceptually:

```text
OP FLAGS-temp
      │
      │ clock / phase 2
      ▼
OP-FLAG-REG
```

This delayed transfer prevents the newly selected operation from being applied too early.

It also provides a stable control state that can be used by the rest of the circuit to select the correct arithmetic path.

---

## 5. Why two operation registers are required

The two registers have different purposes.

### `OP FLAGS-temp`

Stores:

> **What operation has just been selected?**

### `OP-FLAG-REG`

Stores:

> **What operation is currently active?**

The distinction is particularly important when an operation is selected while the accumulator and input registers are still being updated.

The control sequence is therefore:

```text
user selects operation
        │
        ▼
OP FLAGS-temp
        │
        │ wait for defined scheduler phase
        ▼
OP-FLAG-REG
```

This prevents the arithmetic control state from changing before the corresponding data-transfer operation has occurred.

---

## 6. `N-phase scheduler`

`N-phase scheduler` is a generic sequential phase generator.

Its purpose is to execute a defined number of clock phases after being enabled.

The implementation consists conceptually of:

```text
              enable
                │
                ▼
        ┌────────────────┐
clock ─►│ enable logic   │
        └───────┬────────┘
                │
                ▼
           ┌─────────┐
           │ counter │
           └────┬────┘
                │
                ▼
           ┌─────────┐
           │ decoder │
           └────┬────┘
                │
         phase outputs
```

The scheduler uses an enable flip-flop so that the sequence can be started and subsequently stopped.

The counter advances while the scheduler is enabled.

The decoder converts the counter state into individual phase signals.

When the required number of phases has been completed, reset logic stops the sequence and returns the scheduler to its initial state.

---

## 7. Two-phase operation in `Main`

Although the scheduler is generic, `Main` uses only two phases.

### Phase 1 — load accumulator

The first phase performs:

```text
BUS → accumulator
```

The current value present on the BUS is loaded into the `32bit register` representing the accumulator.

This is the data-transfer phase.

### Phase 2 — update control state

The second phase performs two actions:

```text
clear input
+
OP FLAGS-temp → OP-FLAG-REG
```

These actions occur during the same control phase.

Therefore phase 2 simultaneously:

1. prepares the input circuitry for the next number;
2. commits the selected operation as the effective operation.

The complete normal sequence is:

```text
             PHASE 1
                │
                ▼
        BUS → accumulator
                │
                ▼
             PHASE 2
                │
        ┌───────┴────────┐
        ▼                ▼
   clear input     update operation
                       │
                       ▼
                OP-FLAG-REG
```

---

## 8. `when start`

`when start` coordinates the beginning of the operation sequences.

For the operators:

```text
+
×
:
```

the selected operation is first stored in `OP FLAGS-temp`.

The preliminary two-phase scheduler sequence is then initiated.

The purpose is to establish the correct accumulator and operation state before the next operand is processed.

---

## 9. Normal operation sequence

For addition and multiplication, the general control sequence can be represented as:

```text
User selects operation
        │
        ▼
OP FLAGS-temp
        │
        ▼
start scheduler
        │
        ▼
Phase 1
BUS → accumulator
        │
        ▼
Phase 2
clear input
+
OP FLAGS-temp → OP-FLAG-REG
        │
        ▼
new operand can be entered
        │
        ▼
next operation / =
```

The scheduler therefore acts as a small sequencing unit between successive calculator operations.

---

## 10. Special control path for division

Division is different because `FP-DIVISION` is a sequential multi-cycle operation.

When the user selects `:`:

```text
:
│
▼
OP FLAGS-temp
```

The preliminary control sequence is still used.

However, when `=` is pressed, the control logic checks the current effective operation.

If:

```text
OP-FLAG-REG == :
```

the calculator starts:

```text
FP-DIVISION
```

instead of directly executing the normal two-phase scheduler operation.

The simplified control path is:

```text
                 "="
                  │
                  ▼
           OP-FLAG-REG
                  │
            ┌─────┴─────┐
            │           │
          ":"        other op
            │           │
            ▼           ▼
      FP-DIVISION    scheduler
```

---

## 11. Division completion

`FP-DIVISION` operates over multiple clock cycles.

When the operation is complete, its completion signal is active-low.

The completion path is:

```text
FP-DIVISION
     │
     │ active-low done
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
scheduler trigger
```

The flip-flop provides the required clocked delay before the completion event is used by the control logic.

The resulting signal triggers the scheduler.

The scheduler then performs the post-division transfer sequence:

```text
Phase 1:
division result → accumulator

Phase 2:
clear input
+
update operation state as required
```

Therefore the end of division is explicitly connected back into the normal control mechanism.

---

## 12. Shared BUS and operation selection

The arithmetic units share the same BUS.

Their outputs are connected through three-state buffer chains.

Only the chain corresponding to the active operation is enabled.

Conceptually:

```text
                 OP-FLAG-REG
                      │
                      ▼
             operation selection
                      │
          ┌───────────┼───────────┐
          │           │           │
          ▼           ▼           ▼
       FP-ADDER     FP-MULTI   FP-DIVISION
       3-state      3-state     3-state
          │           │           │
          └───────────┼───────────┘
                      │
                      ▼
                     BUS
```

This is a mutually exclusive bus-driving scheme.

The control logic therefore does not merely select which arithmetic unit performs an operation. It also determines which arithmetic output is allowed to drive the shared data path.

---

## 13. `AC` and initial state

The `AC` key provides a clear/reset operation used before starting normal calculator input.

In the observed circuit behavior, pressing `AC` before starting the calculation is required for the input sequence to begin correctly.

The exact cause of this observed requirement is not asserted here as a simulator bug or a register-initialization defect; the behavior is documented as an observed property of the current implementation.

---

## 14. Control-state summary

The control path can be summarized as:

```text
                 USER INPUT
                     │
             ┌───────┴────────┐
             │                │
          operator             =
             │                │
             ▼                ▼
      OP FLAGS-temp     check OP-FLAG-REG
             │                │
             ▼                │
       N-phase scheduler      │
             │                │
       ┌─────┴─────┐          │
       ▼           ▼          │
    Phase 1      Phase 2      │
       │           │          │
       ▼           ▼          │
      BUS→AC    clear input   │
                  +           │
             temp → active    │
                              │
                    ┌─────────┴─────────┐
                    │                   │
                  ":"                other op
                    │                   │
                    ▼                   ▼
              FP-DIVISION          scheduler
                    │
                    ▼
               completion
                    │
                    ▼
               scheduler
                    │
                    ▼
              result → AC
```

---

## 15. Architectural role of the control unit

The control unit is responsible for maintaining the temporal relationship between the calculator's state and its datapath.

Its main responsibilities are:

1. recording the user's selected operation;
2. transferring the selected operation into the effective operation register at the correct phase;
3. sequencing BUS-to-accumulator transfers;
4. clearing the input at the correct time;
5. selecting the arithmetic output allowed to drive the BUS;
6. launching the special sequential division path;
7. detecting division completion and returning control to the normal scheduler.

The result is a small synchronous control system coordinating the calculator datapath rather than a purely combinational selection network.

