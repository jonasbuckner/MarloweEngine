#!/usr/bin/env python3
"""
Printer Method Generator

This script automates adding new methods to the Zig printer infrastructure.
It modifies print.zig, printer_face.zig, and optionally frontend implementations.

Usage:
    python3 add_printer_method.py "pub fn methodName(self: Self, arg1: Type1, comptime arg2: Type2) ReturnType"

Options:
    --frontends    Also add implementations to frontends (e.g., tui.zig)
    --files        Comma-separated list of files to update (default: src/ui/print.zig,src/ui/printer_face.zig)
    --help         Show this help message
"""

import re
import sys
import os
import argparse
from typing import List, Dict, Tuple, Optional

# Regular expression to parse Zig function signatures
FN_REGEX = r"pub\s+fn\s+(\w+)\s*\(\s*(.*?)\s*\)\s*(.*)"
PARAM_REGEX = r"(comptime)?\s*(\w+)\s*:\s*([^,]+)"

def parse_function_signature(signature: str) -> Dict:
    """Parse a Zig function signature into components."""
    match = re.match(FN_REGEX, signature)
    if not match:
        raise ValueError(f"Invalid function signature: {signature}")

    func_name = match.group(1)
    params_str = match.group(2)
    return_type = match.group(3)

    # Parse parameters
    params = []
    if params_str:
        param_matches = re.finditer(PARAM_REGEX, params_str)
        for param_match in param_matches:
            is_comptime = param_match.group(1) is not None
            param_name = param_match.group(2)
            param_type = param_match.group(3).strip()
            params.append({
                'name': param_name,
                'type': param_type,
                'comptime': is_comptime
            })

    return {
        'name': func_name,
        'params': params,
        'return_type': return_type.strip()
    }

def find_self_param(params: List[Dict]) -> Optional[Dict]:
    """Find the 'self' parameter in the params list."""
    for param in params:
        if param['name'] == 'self':
            return param
    return None

def find_insertion_point_in_printer(content: str) -> int:
    """Find a safe insertion point for a new method in the Printer struct."""
    # Find the Printer struct definition
    printer_struct_pattern = r"return struct {(.*?)};.*?\n"
    printer_struct_match = re.search(printer_struct_pattern, content, re.DOTALL)

    if not printer_struct_match:
        print("Warning: Couldn't find the Printer struct definition")
        return -1

    # Find the last function in the struct
    struct_content = printer_struct_match.group(1)
    pub_fn_pattern = r"pub fn (\w+)\s*\([^)]*\)[^{]*{"
    pub_fn_matches = list(re.finditer(pub_fn_pattern, struct_content))

    if not pub_fn_matches:
        print("Warning: No public functions found in Printer struct")
        return -1

    # Get the last function in the struct
    last_fn_match = pub_fn_matches[-1]
    fn_name = last_fn_match.group(1)

    # Find the end of this function by tracking braces
    fn_start = printer_struct_match.start(1) + last_fn_match.start()
    brace_count = 0
    fn_end = -1

    # Skip to the opening brace of the function
    opening_brace_pos = content.find('{', fn_start)
    if opening_brace_pos == -1:
        return -1

    i = opening_brace_pos
    while i < len(content):
        if content[i] == '{':
            brace_count += 1
        elif content[i] == '}':
            brace_count -= 1
            if brace_count == 0:
                fn_end = i + 1
                break
        i += 1

    if fn_end == -1:
        return -1

    return fn_end

def modify_print_zig(file_path: str, func_info: Dict) -> bool:
    """Add the function to the Printer struct in print.zig."""
    if not os.path.exists(file_path):
        print(f"Error: File not found: {file_path}")
        return False

    with open(file_path, 'r') as f:
        content = f.read()

    # Prepare function implementation
    self_param = find_self_param(func_info['params'])
    if not self_param:
        print("Error: Function must have a 'self' parameter")
        return False

    # Remove self from params for forwarding
    params_without_self = [p for p in func_info['params'] if p['name'] != 'self']

    # Create the parameter list for the function declaration
    param_decl = []
    for param in func_info['params']:
        param_part = ""
        if param['comptime']:
            param_part += "comptime "
        param_part += f"{param['name']}: {param['type']}"
        param_decl.append(param_part)

    # Create the argument list for the forwarding call
    forwarding_args = []
    for param in params_without_self:
        forwarding_args.append(param['name'])

    if len(param_decl) > 1:
        sig_params = f"self: Self, {', '.join(param_decl[1:])}"
    else:
        sig_params = "self: Self"

    # Build function implementation
    implementation = f"""

        pub fn {func_info['name']}({sig_params}) {func_info['return_type']} {{
            return self.frontend.{func_info['name']}({', '.join(forwarding_args)});
        }}"""

    # Find a safe insertion point in the Printer struct
    insertion_point = find_insertion_point_in_printer(content)
    if insertion_point == -1:
        # Fallback: Look for format function which is usually the last one
        format_pattern = r"pub fn format\s*\([^)]*\)[^{]*{.*?}"
        format_match = re.search(format_pattern, content, re.DOTALL)
        if format_match:
            insertion_point = format_match.end()
        else:
            # Last resort: look for the struct end
            struct_end_pattern = r"    };.*?\n"
            match = re.search(struct_end_pattern, content)
            if match:
                insertion_point = match.start()
            else:
                print("Error: Couldn't find a safe insertion point in the Printer struct")
                return False

    # Insert the function at the determined position
    new_content = content[:insertion_point] + implementation + content[insertion_point:]

    with open(file_path, 'w') as f:
        f.write(new_content)

    print(f"Successfully updated {file_path}")
    return True

def modify_printer_face_zig(file_path: str, func_info: Dict) -> bool:
    """Add the function to the PrinterFace struct in printer_face.zig."""
    if not os.path.exists(file_path):
        print(f"Error: File not found: {file_path}")
        return False

    with open(file_path, 'r') as f:
        content = f.read()

    # Handle comptime parameters specially
    has_comptime_params = any(p['comptime'] for p in func_info['params'] if p['name'] != 'self')

    # Prepare the function pointer field
    func_name = func_info['name']
    func_pointer_name = func_name + "Fn"

    # Create parameter list for function pointer
    pointer_params = ["ctx: *const anyopaque"]
    for param in func_info['params']:
        if param['name'] != 'self':
            # Skip comptime for function pointer fields
            if not param['comptime']:
                pointer_params.append(f"{param['name']}: {param['type']}")

    if func_info['return_type'].startswith('!'):
        return_type = f"anyerror{func_info['return_type']}"
    else:
        return_type = func_info['return_type']

    func_pointer_field = f"    {func_pointer_name}: *const fn({', '.join(pointer_params)}) {return_type},"

    # Add function pointer field to PrinterFace struct
    struct_field_pattern = r"    // Instance pointer.*?\n    ctx: \*const anyopaque,"
    match = re.search(struct_field_pattern, content)
    if not match:
        print("Error: Couldn't find where to insert function pointer field")
        return False

    insertion_point = match.start()
    # Insert before the ctx field
    new_content = content[:insertion_point] + func_pointer_field + "\n" + content[insertion_point:]
    content = new_content

    # Prepare the wrapper method
    wrapper_params = []
    for param in func_info['params']:
        if param['name'] != 'self':
            param_part = ""
            if param['comptime']:
                param_part += "comptime "
            param_part += f"{param['name']}: {param['type']}"
            wrapper_params.append(param_part)

    wrapper_args = ["self.ctx"]
    for param in func_info['params']:
        if param['name'] != 'self' and not param['comptime']:
            wrapper_args.append(param['name'])

    wrapper_method = f"""
    pub fn {func_name}(self: *const PrinterFace{', ' if wrapper_params else ''}{', '.join(wrapper_params)}) {func_info['return_type']} {{
        return self.{func_pointer_name}({', '.join(wrapper_args)});
    }}
"""

    # Add wrapper method to PrinterFace
    methods_end_pattern = r"};.*?\n\n// Helper function"
    match = re.search(methods_end_pattern, content)
    if not match:
        print("Error: Couldn't find where to insert wrapper method")
        return False

    insertion_point = match.start()
    new_content = content[:insertion_point] + wrapper_method + content[insertion_point:]
    content = new_content

    # Prepare the implementation function
    impl_func_name = func_name + "Impl"
    impl_params = ["ctx: *const anyopaque"]
    for param in func_info['params']:
        if param['name'] != 'self' and not param['comptime']:
            impl_params.append(f"{param['name']}: {param['type']}")

    impl_method = f"""
        pub fn {impl_func_name}({', '.join(impl_params)}) {func_info['return_type']} {{
            const self = @as(PtrType, @ptrCast(@alignCast(ctx)));
            return self.{func_name}({', '.join([p['name'] for p in func_info['params'] if p['name'] != 'self'])});
        }}
"""

    # Add implementation function to Impls struct
    impls_end_pattern = r"    };.*?\n\n    return PrinterFace{"
    match = re.search(impls_end_pattern, content)
    if not match:
        print("Error: Couldn't find where to insert implementation function")
        return False

    insertion_point = match.start()
    new_content = content[:insertion_point] + impl_method + content[insertion_point:]
    content = new_content

    # Add function pointer to PrinterFace initialization
    init_end_pattern = r"        .ctx = @ptrCast\(@alignCast\(printer\)\),.*?\n    };"
    match = re.search(init_end_pattern, content)
    if not match:
        print("Error: Couldn't find where to insert function pointer initialization")
        return False

    insertion_point = match.start()
    init_line = f"        .{func_pointer_name} = Impls.{impl_func_name},"
    new_content = content[:insertion_point] + init_line + "\n" + content[insertion_point:]

    with open(file_path, 'w') as f:
        f.write(new_content)

    print(f"Successfully updated {file_path}")
    return True

def find_insertion_point_in_frontend(content: str, struct_name: str) -> int:
    """Find a safe insertion point for a new method in a frontend file."""
    # Find the last public function in the struct
    pub_fn_pattern = r"pub fn (\w+)\s*\([^)]*\)[^{]*{"
    pub_fn_matches = list(re.finditer(pub_fn_pattern, content))

    if not pub_fn_matches:
        print(f"Warning: No public functions found in {struct_name}")
        # Try to find the struct definition at least
        struct_pattern = f"pub const {struct_name} = struct {{(.*?)}}"
        struct_match = re.search(struct_pattern, content, re.DOTALL)
        if struct_match:
            # Insert at the beginning of the struct body
            return struct_match.start(1) + 1
        return -1

    # For each pub fn found, check if it's actually inside our struct
    for match in reversed(pub_fn_matches):
        fn_name = match.group(1)
        # Look for the function signature with the struct as the self type
        fn_sig_pattern = fr"pub fn {fn_name}\s*\(\s*(?:self|_)\s*:\s*(?:\*const)?\s*{struct_name}"
        if re.search(fn_sig_pattern, content):
            # Find the end of this function
            fn_start = match.start()
            brace_count = 0
            fn_end = -1

            # Skip the opening brace of the function
            opening_brace_pos = content.find('{', fn_start)
            if opening_brace_pos == -1:
                continue

            i = opening_brace_pos
            while i < len(content):
                if content[i] == '{':
                    brace_count += 1
                elif content[i] == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        fn_end = i + 1
                        break
                i += 1

            if fn_end != -1:
                return fn_end

    return -1

def modify_frontend_zig(file_path: str, func_info: Dict) -> bool:
    """Add the function to a frontend implementation (e.g., tui.zig)."""
    if not os.path.exists(file_path):
        print(f"Error: File not found: {file_path}")
        return False

    with open(file_path, 'r') as f:
        content = f.read()

    # Find the struct name from the file
    struct_pattern = r"pub const (\w+) = struct {"
    struct_match = re.search(struct_pattern, content)
    if not struct_match:
        print(f"Error: Couldn't find struct definition in {file_path}")
        return False

    struct_name = struct_match.group(1)

    # Prepare function implementation
    params = []
    for param in func_info['params']:
        if param['name'] == 'self':
            params.append(f"{param['name']}: *const {struct_name}")
        else:
            param_part = ""
            if param['comptime']:
                param_part += "comptime "
            param_part += f"{param['name']}: {param['type']}"
            params.append(param_part)

    param_stubs = '\n'.join([f"        _ = {p['name']};" for p in func_info['params']])
    # Create simple stub implementation
    implementation = f"""

    pub fn {func_info['name']}({', '.join(params)}) {func_info['return_type']} {{
{param_stubs}
        // TODO: Implement this method
        @compileError("Method {func_info['name']} not implemented for {struct_name}");
    }}"""

    # Find a safe insertion point
    insertion_point = find_insertion_point_in_frontend(content, struct_name)
    if insertion_point == -1:
        print(f"Error: Couldn't find a safe insertion point in {file_path}")
        return False

    # Insert the function at the determined position
    new_content = content[:insertion_point] + implementation + content[insertion_point:]

    with open(file_path, 'w') as f:
        f.write(new_content)

    print(f"Successfully updated {file_path}")
    return True

def main():
    parser = argparse.ArgumentParser(description='Add a method to the Zig printer infrastructure')
    parser.add_argument('signature', help='Zig function signature to add')
    parser.add_argument('--frontends', action='store_true', help='Add implementations to frontends')
    parser.add_argument('--files', default='src/ui/print.zig,src/ui/printer_face.zig',
                       help='Comma-separated list of files to update')

    args = parser.parse_args()

    try:
        func_info = parse_function_signature(args.signature)
        print(f"Parsed function: {func_info['name']}")

        files = args.files.split(',')
        for file in files:
            if 'print.zig' in file:
                modify_print_zig(file, func_info)
            elif 'printer_face.zig' in file:
                modify_printer_face_zig(file, func_info)

        if args.frontends:
            frontend_files = ['src/ui/tui.zig']  # Add more frontends as needed
            for file in frontend_files:
                modify_frontend_zig(file, func_info)

        print("Operations completed successfully!")

    except Exception as e:
        print(f"Error: {e}")
        return 1

    return 0

if __name__ == "__main__":
    sys.exit(main())
