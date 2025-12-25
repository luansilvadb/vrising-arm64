# Deep Research: The "Interpreter Bootstrap" Solution (Clean & Unique)

## The Problem
The standardized, copy-paste solution (`tsxcloud`) was rejected for a valid reason: reliability on third-party artifacts. However, the technical hurdle remains:
**Box64's JIT compiler crashes during Il2CppInterop's highly parallel assembly generation.**

## The Unique Solution: "Safe Generation Mode"

Instead of relying on external files or complex cross-compilation toolchains, we solve the crash *at runtime* by leveraging Box64's own versatility.

### The Mechanism
1.  **Detection**: The script checks if `BepInEx/interop` assemblies are missing.
2.  **Mode Switch**: If missing, it engages **Safe Generation Mode**.
    - Sets `BOX64_DYNAREC=0`.
    - This **completely disables the JIT compiler** and forces Box64 to run as a pure Interpreter.
    - **Effect**: It is significantly slower, BUT it is thread-safe and immune to the specific JIT crashes caused by Il2CppInterop.
3.  **Bootstrapping**:
    - The server is launched in a background process with a 300-second (5-minute) timeout.
    - We monitor the `interop` folder.
    - Once assemblies appear (indicating successful generation), the slow interpreter process is killed.
4.  **Resume**:
    - `BOX64_DYNAREC` is re-enabled (default 1).
    - The server boots normally with high performance for gameplay.

### Why this is better
-   **Zero External Dependencies**: No reliance on `tsxcloud` or other "donor" images.
-   **Self-Healing**: If you delete the `interop` folder, it just regenerates itself safely on the next boot.
-   **Hardware Agnostic**: Works on any ARM64 chip (Ampere, Raspberry Pi, Apple Silicon) because it doesn't rely on pre-compiled binaries matching a specific kernel or architecture quirk.

### Implementation Details
-   **File**: `scripts/setup_bepinex.sh`
-   **Function**: `setup_bepinex()` logic was rewritten to handle the download (standard GitHub release) and then the "Safe Generation" logic.
