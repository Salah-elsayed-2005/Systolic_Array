# 🧠 AHB-Compatible Systolic Array Accelerator

An 8x8 SystemVerilog systolic array accelerator designed for fast, hardware-level neural network inference. It features a fully compliant AHB-Lite subordinate interface, allowing it to seamlessly integrate into standard SoC architectures to stream input vectors and weights without burdening the CPU.

## ✨ Key Specs & Features
* **Architecture:** 8x8 weight-stationary systolic array.
* **Datapath:** INT8 quantization for inputs, weights, biases, and outputs.
* **Performance:** Maximum inference latency of 75 clock cycles at a 100 MHz system clock.
* **Activations:** Programmable support for ReLU, Binary, Identity, and Leaky ReLU (α = 0.5).
* **Bus Interface:** AHB-Lite subordinate with `hready` transaction stall support and `hresp` error handling.

## 🏗️ Hardware Modules


* **AHB Subordinate:** Decodes memory-mapped reads/writes and handles all bus protocol communication.
* **Controller (FSM):** Orchestrates dataflow, polls status flags, and controls weight loading timing.
* **Data Buffer:** Interfaces with an SRAM model to safely stage multiplication inputs, weights, and outputs.
* **Systolic Array:** 64 Processing Elements (PEs) parallelizing MAC operations via a 64-bit input stream.
* **Post-Processing:** Dedicated bias addition and activation units to handle non-linear network behaviors.

## 🗺️ Memory Map

| Address | Register | Access | Description |
| :--- | :--- | :---: | :--- |
| `0x00` | **Weight** | W | Loads 8-byte weight values into the internal buffer. |
| `0x08` | **Input** | W | Streams input vectors to the array. |
| `0x10` | **Bias** | R/W | Holds the bias offset for the current inference operation. |
| `0x18` | **Output** | R | Used by the manager to pull final inference results. |
| `0x20` | **Error** | R | Flags buffer occupancy overflow or busy-state write attempts. |
| `0x22` | **Control** | R/W | Asserts the start of an inference or the loading of weights. |
| `0x23` | **Status** | R | Polled to check if the design is busy or if data is ready. |
| `0x24` | **Activation** | R/W | Dynamically selects between the four available activation functions. |

