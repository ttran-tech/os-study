# Linker Script
## Purpose
- A linker script tells the linker (ld) how to organize and place compiled code and data in memory.

## Key Concepts
### Object Files & Symbols
- Object files contain compiled machine code + metadata.

- Symbols represent addresses (functions, variables).

- Symbols may be defined in one file and used (undefined) in others.

### Sections
- `.text` – executable code (e.g., your kernel functions)

- `.rodata` – read-only data (e.g., const strings)

- `.data` – initialized global/static variables

- `.bss` – uninitialized global/static variables (zeroed at startup)

- `.isr_vector` – interrupt vector table (if needed)

## SECTION Command
- Used to organize output sections by combining input sections:

```
SECTIONS {
  .text : {
    *(.text)
    *(.text*)
  }
}
```

*Wildcard `*` collects all `.text` sections from all input files.*

## Memory Layout (Placement)
🧾 Implicit Placement
- Linker auto-places sections in memory.
- Uses location counter . to track where it is.

🧾 Explicit Placement
- Set absolute memory locations:
```
.text 0x00100000 : { *(.text) }
```

🧾 Using Regions
- Define named memory regions for Flash, RAM, etc.:
```
MEMORY {
  FLASH (rx) : ORIGIN = 0x08000000, LENGTH = 1M
  RAM   (rwx): ORIGIN = 0x20000000, LENGTH = 256K
}

SECTIONS {
  .text : { *(.text) } > FLASH
  .data : { *(.data) } > RAM AT > FLASH
}
```
- `VMA = RAM`, `LMA = FLASH`
- `AT >` sets load location (e.g., for bootloaders).

## Symbols in Linker Script
- Define custom symbols to use in C/ASM:
```
.data : {
  _data_start = .;
  *(.data)
  _data_end = .;
}
_data_size = _data_end - _data_start;
_data_loadaddr = LOADADDR(.data);
```

- Then reference in C:
```
extern uint8_t _data_start, _data_size, _data_loadaddr;
```

## Section Optimization
- `-ffunction-sections`, `-fdata-sections` = place each func/var in own section.

- Use `--gc-sections` to remove unused sections.

- Use `KEEP(...)` to prevent critical sections from being removed.