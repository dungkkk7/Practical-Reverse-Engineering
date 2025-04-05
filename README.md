# Practical Reverse Engineering - x86 Assembly Examples

## Overview

This repository contains various x86 assembly examples and resources for learning and practicing reverse engineering concepts. The examples are written in NASM (Netwide Assembler) syntax and cover a wide range of topics, including basic operations, string manipulation, memory management, and control flow.

## Folder Structure

```
.
├── .gitattributes
├── Assembly x86 Architech.md
├── basic of md file.md
├── ecx_ebx.asm
├── edi.asm
├── edx.asm
├── esp_ebp.asm
├── image-1.png
├── image-2.png
├── image-3.png
├── image-4.png
├── image.png
├── memcpy.asm
├── memset.asm
├── Practical Reverse Engineering x86, x64, ARM, Windows Kernel, Reversing Tools, and Obfuscation.pdf
├── strchr.asm
├── strcmp.asm
├── strlenX86.asm
```

### Key Files

- **Assembly x86 Architech.md**: A comprehensive guide to x86 architecture, including register usage, instruction sets, and examples of common operations.
- **basic of md file.md**: A markdown tutorial for writing and formatting `.md` files.
- **memcpy.asm**: Implementation of the `memcpy` function in x86 assembly.
- **memset.asm**: Implementation of the `memset` function in x86 assembly.
- **strcmp.asm**: Implementation of the `strcmp` function in x86 assembly.
- **strlenX86.asm**: Implementation of the `strlen` function in x86 assembly.
- **strchr.asm**: Implementation of the `strchr` function in x86 assembly.
- **ecx_ebx.asm**, **edi.asm**, **edx.asm**, **esp_ebp.asm**: Examples demonstrating the use of specific x86 registers.
- **Practical Reverse Engineering.pdf**: A reference book covering reverse engineering concepts for x86, x64, ARM, Windows Kernel, and more.

### Images

- **image.png**, **image-1.png**, **image-2.png**, **image-3.png**, **image-4.png**: Visual aids used in the markdown documentation.

## How to Use

1. **Assemble and Link**: Use NASM to assemble the `.asm` files and link them using a linker like `ld`.
   ```bash
   nasm -f elf32 file.asm -o file.o
   ld -m elf_i386 file.o -o file
   ./file
   ```

2. **Learn from Examples**: Open the `.asm` files to study how common functions like `strlen`, `strcmp`, and `memcpy` are implemented in assembly.

3. **Read Documentation**: Refer to `Assembly x86 Architech.md` for detailed explanations of x86 architecture and instructions.

4. **Experiment**: Modify the assembly files or write your own to deepen your understanding of x86 assembly.

## Prerequisites

- **NASM**: Install NASM to assemble the `.asm` files.
- **Linux Environment**: The examples are designed for a 32-bit Linux environment. Use `ld` for linking.
- **Basic Assembly Knowledge**: Familiarity with x86 assembly syntax and concepts is recommended.

## Topics Covered

- **Registers**: Usage of general-purpose registers like `EAX`, `EBX`, `ECX`, `EDX`, and special-purpose registers like `ESP`, `EBP`.
- **String Manipulation**: Functions like `strlen`, `strcmp`, `strchr`, and `memset`.
- **Memory Operations**: Examples of `mov`, `lea`, `stos`, and `scas` instructions.
- **Control Flow**: Implementation of loops, if-else, and switch-case structures in assembly.
- **Reverse Engineering**: Insights into analyzing and understanding compiled assembly code.

## Contributing

Feel free to contribute by:
- Adding new examples or improving existing ones.
- Reporting issues or suggesting enhancements.
- Sharing your insights or questions in the Issues section.

## License

This repository is for educational purposes only. Refer to the `Practical Reverse Engineering.pdf` for its respective copyright and usage terms.

## References

- [NASM Documentation](https://www.nasm.us/doc/)
- [Practical Reverse Engineering](https://www.wiley.com/en-us/Practical+Reverse+Engineering%3A+x86%2C+x64%2C+ARM%2C+Windows+Kernel%2C+Reversing+Tools%2C+and+Obfuscation-p-9781118787311)

Happy learning and reverse engineering!