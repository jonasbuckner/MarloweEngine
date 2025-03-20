# Printer Method Generator: Implementation Details

## How It Works

This script automates adding new printer methods to your codebase by:

1. **Parsing the function signature** using regular expressions to extract:
   - Function name
   - Parameters (names, types, and whether they're comptime)
   - Return type

2. **Updating print.zig** by:
   - Adding a forwarding method to the `Printer` struct that calls through to the frontend

3. **Updating printer_face.zig** by:
   - Adding a function pointer field to the `PrinterFace` struct
   - Adding a wrapper method that calls through the function pointer
   - Adding an implementation function in the `Impls` struct
   - Adding the function pointer to the `PrinterFace` initialization

4. **Optionally updating frontend files** like tui.zig by:
   - Adding a stub implementation that will trigger a compile error until properly implemented

## Special Handling for Comptime Parameters

The script detects `comptime` parameters and handles them specially:

- In `PrinterFace`, function pointers can't have comptime parameters, so they're removed from the function pointer type
- If your function uses comptime parameters extensively, you may need to use the strategy we used for directional movement, where we create separate non-comptime functions for each case

## Limitations

1. **Regular Expression Parsing**: The script uses regex to parse Zig code, which has limitations. Complex function signatures might not be parsed correctly.

2. **File Structure Assumptions**: The script assumes certain patterns in your files. If you significantly change the structure, you may need to update the regex patterns.

3. **Limited Type Handling**: Functions with complex types (e.g., anonymous structs, complex unions) might not be parsed correctly.

4. **Manual Refinement Needed**: The script provides a starting point, but you may need to manually refine the generated code, especially for complex functions.

5. **No Error Handling Generation**: The script doesn't automatically generate error handling code, so you'll need to add that manually.

## Best Practices

1. **Review Generated Code**: Always review the generated code for correctness.

2. **Backup Files**: Make backups before running the script on important files.

3. **Start Simple**: Begin with simple function signatures before trying complex ones.

4. **Implement Frontend Methods**: Remember to implement the methods in the frontend files (the script only generates stub implementations).

5. **Test After Each Addition**: Compile and test after adding each new method to catch issues early.

## Usage Examples

# Basic usage - Add a simple method
`python3 utils/add_printer_method.py "pub fn clearScreen(self: Self) \!void"`

# Add a method with parameters
`python3 utils/add_printer_method.py "pub fn drawBox(self: Self, x: usize, y: usize, width: usize, height: usize) \!void"`

# Add a method with comptime parameters (will be handled specially)
`python3 utils/add_printer_method.py "pub fn setColor(self: Self, comptime color: []const u8) \!void"`

# Also add implementations to frontend files like tui.zig
`python3 utils/add_printer_method.py "pub fn hideCursor(self: Self) \!void" --frontends`

# Specify custom file paths
`python3 utils/add_printer_method.py "pub fn beep(self: Self) \!void" --files path/to/print.zig,path/to/printer_face.zig`
