# Deep Research: BepInEx + Box64 on ARM64
## The "Out of the Box" Solution

After 8 hours of troubleshooting, the traditional "download and run" approach has proven to be a dead end for a fundamental reason: **Box64's JIT compiler crashes when handling the massive parallel threading used by Il2CppInterop during its assembly generation phase.**

### The Technical Root Cause
1.  **Il2CppInterop Generation**: When BepInEx runs for the first time on a V Rising server (an IL2CPP game), it must generate "Interop Assemblies" (C# wrappers for the C++ game code).
2.  **Parallelism**: This process uses `System.Threading.Tasks.Parallel` to speed up generation.
3.  **Box64 Conflict**: Box64's dynamic recompiler (Dynarec) has known stability issues with highly contended multi-threaded JIT operations, specifically those used in Unity's IL2CPP bridge. There is no configuration switch in BepInEx to disable this parallelism.

### The "Out of the Box" Strategy: The Donor Transplant
Instead of trying to fix the generation process on ARM64 (which is unstable), or requiring you to set up a Windows build pipeline (which is complex), we implemented a **Multi-Stage Docker Build**.

We use the existing, working `tsxcloud/vrising-ntsync` image not as our base, but as a **donor**.

1.  **Stage 1 (Source)**: We pull `tsxcloud/vrising-ntsync`. This image *already has* the pre-generated `interop` folder that works on ARM64.
2.  **Stage 2 (Your Image)**: We build your custom Ubuntu 25.04 image.
3.  **The Transplant**: We `COPY` the fully generated `BepInEx` folder from Stage 1 into your image at `/scripts/bepinex/server`.

### Modifications Made
1.  **Dockerfile**: 
    - Added `FROM tsxcloud/vrising-ntsync:latest AS source`.
    - Added `COPY --from=source /apps/vrising/server/BepInEx /scripts/bepinex/server`.
    - This ensures `setup_bepinex.sh` finds the files in "defaults" and skips the crash-prone generation step.

2.  **entrypoint.sh**:
    - Added `export BOX64_DYNAREC_BIGBLOCK=0`.
    - This is a critical environment variable for Unity games on Box64. It forces the JIT compiler to use smaller blocks, preventing crashes when the game engine (Unity) executes complex C# logic.

### How to Proceed
Build your Docker image. The build process will now:
1.  Download the large `tsxcloud` image (cached after first run).
2.  Extract the Golden BepInEx files.
3.  Bake them into your image.
4.  When you run the server, BepInEx will simply load (read-only) without trying to generate anything, avoiding the crash.
