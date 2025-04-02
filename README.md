# os-study
A collection of ASM and C snippet while I study on operating system

## x86 Type & Size
| Type| Meaning| Size|
|---|---|---|
| db| Byte| 1 byte (8 bits)|
| dw| Word| 2 bytes (16 bits)|
| dd| Doubleword| 4 bytes (32 bits)|
| dq| Quadword| 8 bytes (64 bits)|

## Global Descriptor Table (GDT)
- GDT is a ***blueprint*** that tells the CPU how to configure memory segments before switching to Protected Mode.
- A GDT Entry is 8 bytes long or 64 bits total.

### GDT Entry Layout (8 Bytes Total)

| Byte #| Field| Bit Range| Description|
|---|---|---|---|
| 0-1| Limit| 16 (0-15)| Lower 16 bits of segment limit|
| 2-3| Base| 16 (0-15)| Lower 16 bits of base address|
| 4| Base| 8 (16-23)| Middle 8 bits of base address|
| 5| Access Byte| 8| 8 bits contain DPL, segment type, and flags|
| 6| Limit| 4| High 4 bits of segment limit|
| 7| Flags| 4| G, D/B|
| 8| Base| 8 (24-31)| High 8 bits of base address|

<table>
  <tr>
    <th>Byte</th>
    <th>Bit Range</th>
    <th>Bits</th>
    <th>Name</th>
    <th>Description</th>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
</table>

### Bit-by-Bit Layout



### Descriptor Privilege Level (DPL)
- DPL is a 2-bit field inside a GDT entry which defines who is allowed to access a particular segment.
- DPL is part of the Access Byte, which is 5th byte (byte 5) in GDT entry (see GDT Entry Layout)

  | DPL Value| Privilege Level| Meaning|
  | ---| ---| ---|
  | 0 (Highest Priv.)| Ring 0| Kernel/OS|
  | 1| Ring 1| Rarely used|
  | 2| Ring 2| Rarely used|
  | 3 (Least Priv.)| Ring 3| User Applications|

- How DPL Work?
  - When a program tries to use a segment, the CPU checks:
    1. Current CPL: Current Privilege Level (stored in CS register's low 2 bits)
    2. DPL: Targer Segment's Descriptor Privilege Level (Target DPL)
    3. RPL: Requestor Privilege Level (low 2 bits of the selector)
  - The CPU compares CPL, DPL, and RPL to decide if access is allowed:
    - If not → General Protection Fault.

### Type of Descriptors
1. Code Segment Descriptor
    - Defines a segment containing executable code
2. Data Segment Descriptor
    - Defines a segment containing data
3. System Segment Descriptor
    - Defines system segments used by the OS
