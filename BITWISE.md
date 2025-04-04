## AND (&)
```
5 & 6
5 = 0101
6 = 0110
---------
4 = 0100
```

## OR (|)
```
5 | 6
5 = 0101
6 = 0110
---------
7 = 0111
```

## XOR (^)
```
5 ^ 6
5 = 0101
6 = 0110
---------
3 = 0011
```

## NOT (~)
```
~6
6  = 0110
~6 = 1001
```

## SHIFT LEFT (<<) 
```
M << N = M * 2^N
```

## SHIFT RIGHT (>>)
```
M >> N = M / 2^N (unsigned values)
```

---
# Common Bitwise Pattern & Use Cases
## 1. Set A Specific Bit
- Use Case: enable a flag, e.g. `enable_interrupt |= (1 << 3)`
```c
x |= (1 << n); // Sets bit n to 1
```

## 2. Clear a Specific Bit
- Use Case: disablea a flag, e.g. `control_reg &= ~(1 << 7)`
```c
x &= ~(1 << n); // Sets bit n to 0
```

## 3. Toggle a Specific Bit
- Use Case: switch state, e.g. `led ^= (1 << 2)`
```c
x ^= (1 << n); // Flips bit n (1 becomes 0, 0 becomes 1)
```

## 4. Check If a Bit is Set
- Use Case: test flag, e.g. check if `write permission` is enabled
```c
if (x & (1 << n)) {
  // bit is 1
}
```

## 5. Mask Out Bits (Extract Bits)
- Use Case: Decode field inside a packed byte, e.g. `x & 0x0F` extracts lower 4 bits from x
```c
x & mask
```

## 6. Combine Multiple Fields (Bit Packing)
- Use Case: Pack two 4-bit fields into 1 byte. E.g, for VGA
```c
result = (field1 << 4) | field2;
```

## 7. Unpack / Extract Specific Fields
- Use Case: Decode packed data, extract high/low nibbles
```c
field1 = (x >> 4) & 0x0F;
field2 = x & 0x0F;
```

## 8. Invert All Bits
- Use Case: Bitwise inversion, such as creating a mask for clearing
```c
x = ~x
```

## 9. Align to Nearest Power of 2
- Use Case: Memory alignment. E.g 4KB page boundary
```c
x = (x + (align - 1)) & ~(align -1);
```

## 10. Check if Number is a Power of 2
- Use Case: Validation for memory sie, CPU Flag, etc.
```c
if (x && !(x & (x - 1)))
```
