# Operating System :computer:
A collection of notes and experiment codes I do when studied about Operating System.

## Bits & Bytes
![image](https://github.com/user-attachments/assets/969dd630-4c19-46bd-b924-47b337200e25)

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
  
    ```
    Segmen Limit + Base + Access Byte + Flags = 64 bits
    ```

### :large_blue_diamond: Bit-by-Bit Layout
<table>
  <tr>
    <th></th>
    <td>LIMIT (Low)</td>
    <td colspan="2">BASE ADDRESS (Low/Middle)</td>
    <td colspan="4">ACCESS BYTE</td>
    <td>LIMIT (High)</td>
    <td colspan="4">FLAGS</td>
    <td>BASE ADDRESS (High)</td>
  </tr>
  <tr>
    <th>Name</th>
    <td>Limit Low</td>
    <td>Base Low</td>
    <td>Base Middle</td>
    <td>Present (P)</td>
    <td>DPL</td>
    <td>Descriptor Type</td>
    <td>Segment Type</td>
    <td>Limit High</td>
    <td>Granularity (G)</td>
    <td>Size (D/B)</td>
    <td>Long Mode (L)</td>
    <td>AVL</td>
    <td>Base High</td>
  </tr>
  <tr>
    <th>Bit Range</th><td>0-15</td><td>16-31</td><td>32-39</td><td>47</td><td>46-45</td><td>44</td><td>43-40</td><td>48-51</td><td>55</td><td>54</td><td>53</td><td>52</td><td>56-63</td>
  </tr>
  <tr>
    <th>Bits (64 total)</th><td>16</td><td>16</td><td>8</td><td colspan="4">8</td><td>4</td><td colspan="4">4</td><td>8</td>
  </tr>
  <tr>
    <th>Byte (8 total)</th><td>0 - 1</td><td>2 - 3</td><td>4</td><td colspan="4">5</td><td>6</td><td colspan="4">7</td><td>8</td>
  </tr>
</table>

### :large_blue_diamond: Type of Descriptors
1. Code Segment Descriptor
    - Defines a segment containing executable code
2. Data Segment Descriptor
    - Defines a segment containing data
3. System Segment Descriptor
    - Defines system segments used by the OS

### :large_blue_diamond: Segment Limit (20 bits)
- The **Segment Limit** deines the size of the segment (or how far memory can go from the **base address**).
- In GDT, segment limit is 20 bits entry and split into:
    1. Lower 16 bits → LIMIT LOW (bit range: 0-15)
    2. Upper 4 bits → LIMIT HIGH (bit range: 48-51) *This field is combine with FLAGS field and makes up an 8-bit field total*
- **How Granularity (G bit) affects Segment Limit?
  - If G = 0: limit is in bytes → max size = ~1 MB
  - If G = 1: limit is in 4 KB block → max size = ~ 4 GB

    Let:
    ```
    Limit = 0xFFFF ; 20-bit max
    G = 1          ; Granularity = 4KB
    ```

    Then:
    ```
    Effective Segment Size = (Limit + 1) x 4KB
                           = (0xFFFF + 1) x 4KB
                           = 4 GB
    ```

### :large_blue_diamond: Base Address (32 bits)
- The **Base Address** tells the CPU where the segment begins in linear memory.
- In GDT, base address is a 32-bit entry and split into:
  1. Lower 16 bits → BASE LOW (bit range: 16-31) *A lower 2 bytes of a 32-bit address*
  2. Middle 8 bits → BASE MIDDLE (bit range: 32-39) *Next byte of the address*
  3. Upper 8 bits → BASE HIGH (bit range: 56-63) *Final byte of the address*
- Together, they form a full 32-bit linear address of the segment's starting point.

### :large_blue_diamond: Access Byte (8 bits)
- The **Access Byte** defines:
  - Whether segment is **present (Present - P)**
  - Its **privilege level (Descriptor Privilege Level - DPL)**
  - If it is **Code/Data or System segment (Descriptor Type - S)**
  - What kind of operations are allowed: **Read, Write, Execute (Segment Type - T)**
- Access Byte breakdown:

  | Bit Range| Name| Description| Bit|
  |---|---|---|---|
  | 47| Present (P)| Set to **1** if the segment is valid and present in memory| 1|
  | 46-48| DPL| 2-bit value: **00** = Ring 0, **11** = Ring 3| 2|
  | 44| Descriptor Type (S)| **1** = Code/Data segment, **0** = System segment| 1|
  | 43-40| Segment Type (T)| Varies by segment (Read/Write/Execute flags)| 4|

 - Bit-Level view:

   | Bit| 7| 6| 5| 4| 3| 2| 1| 0|
   |---|---|---|---|---|---|---|---|---|
   | Field| P| DPL1| DPL0| S| T3| T2| T1| T0|

- Common Access Byte setting:

  | Segment| Binary| Hex| Meaning|
  |---|---|---|---|
  | Code (RX, Ring 0)| 10011010| 0x9A| Present, DPL = 0, Readable-Executable|
  | Data (RW, Ring 0)| 10010010| 0x92| Present, DPL = 0, Readable-Writable|
  | Code (RX, Ring 3)| 11111010| 0xFA| Present, DPL = 3, Readable-Executable|
  | Data (RW, Ring 3)| 11110010| 0xF2| Present, DPL = 3, Readable-Writable|

#### :small_orange_diamond: Descriptor Privilege Level (DPL)
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

### :large_blue_diamond: FLAGS (4 bits) or Limit High + FLAGS (8 bits)
