# Convert ASCII character and color code to unsigned integer in little endian form.
# This is a prototype of a C version
def terminal_make(char:str, color:int) -> int:
    return (color << 8) | ord(char)
    
if __name__ == '__main__':
    chars = 'ABCDEFG'
    color = 4
    
    for char in chars:
        uint = terminal_make(char, color)
        print(f"char: {char} ({ord(char)}) - color: {color} = {uint} ({uint:#04x})")

# Output:    
# char: A (65) - color: 4 = 1089 (0x441)
# char: B (66) - color: 4 = 1090 (0x442)
# char: C (67) - color: 4 = 1091 (0x443)
# char: D (68) - color: 4 = 1092 (0x444)
# char: E (69) - color: 4 = 1093 (0x445)
# char: F (70) - color: 4 = 1094 (0x446)
# char: G (71) - color: 4 = 1095 (0x447)
