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

### Bit-by-Bit Layout
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
    <th>Byte #</th><td>0 - 1</td><td>2 - 3</td><td>4</td><td colspan="4">5</td><td>6</td><td colspan="4">7</td><td>8</td>
  </tr>
  <tr>
    <th>Bits</th><td>16</td><td>16</td><td>8</td><td colspan="4">8</td><td>4</td><td colspan="4">4</td><td>8</td>
  </tr>
</table>

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
