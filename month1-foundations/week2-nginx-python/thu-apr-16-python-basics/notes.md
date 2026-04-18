# Python Fundamentals – Detailed Notes
> A mini-tutorial covering every core concept, with examples and annotated output.

---

## 1. Data Types

> "What kind of data is inside the variable?"

Python has four primitive (core) data types you need to master first.

---

### 1.1 Integer (`int`)
Whole numbers — positive, negative, or zero. No decimal point.

```python
x = 10    # positive
y = -5    # negative
z = 0     # zero

print(type(x))  # <class 'int'>
```

**Output:**
```
<class 'int'>
```

> ✅ Used for counting, looping, and whole-number math.

---

### 1.2 Float (`float`)
Numbers with a decimal point. More precise than integers.

```python
x = 10.5
y = -3.14
z = 0.0

print(type(x))  # <class 'float'>
```

**Output:**
```
<class 'float'>
```

> ⚠️ Division `/` **always** returns a float, even with two integers:
> ```python
> print(10 / 2)  # 5.0  ← float, not 5
> ```

---

### 1.3 String (`str`)
Text wrapped in single `'` or double `"` quotes.

```python
message = "Hello, Kenneth!"
print(message)
print(type(message))
```

**Output:**
```
Hello, Kenneth!
<class 'str'>
```

**String Operations:**

```python
# Concatenation
first = "Kenneth"
last  = "Smith"
full  = first + " " + last
print(full)          # Kenneth Smith

# Length
print(len("Python")) # 6

# Indexing (subscripting)
word = "Python"
print(word[0])       # P   ← first character
print(word[-1])      # n   ← last character

# Newline character
print("Hello\nKenneth!")
```

**Output:**
```
Kenneth Smith
6
P
n
Hello
Kenneth!
```

---

### 1.4 Boolean (`bool`)
Only two possible values: `True` or `False`.

```python
is_raining = True
is_sunny   = False

print(is_raining)        # True
print(type(is_raining))  # <class 'bool'>

# Booleans come from comparisons:
print(10 > 5)   # True
print(3 == 7)   # False
```

**Output:**
```
True
<class 'bool'>
True
False
```

---

## 2. Variables

A variable is a **named label** pointing to a stored value.

```python
x    = 5
name = "Kenneth"

# Variables can be reassigned:
x = 10
print(x)  # 10
```

> 📌 Python is dynamically typed — you don't declare the type, Python figures it out.

---

## 3. Type Checking with `type()`

```python
x = 10
y = "Hello, Kenneth!"
z = True
w = 3.14

print(type(x))  # <class 'int'>
print(type(y))  # <class 'str'>
print(type(z))  # <class 'bool'>
print(type(w))  # <class 'float'>
```

**Output:**
```
<class 'int'>
<class 'str'>
<class 'bool'>
<class 'float'>
```

---

## 4. Type Conversion (Type Casting)

Changing a value from one type to another.

### 4.1 Implicit (Python does it automatically)

```python
x      = 10     # int
y      = 2.5    # float
result = x + y  # Python promotes int → float

print(result)        # 12.5
print(type(result))  # <class 'float'>
```

### 4.2 Explicit (You do it manually)

```python
# String → Integer
number = int("50")
print(number)        # 50

# Integer → String
age = 25
print(str(age))      # "25"

# Float → Integer (truncates — does NOT round)
pi = 3.99
print(int(pi))       # 3   ← decimal chopped off, not rounded
```

> ❌ Invalid conversions will crash:
> ```python
> int("hello")  # ValueError: invalid literal for int()
> ```

---

## 5. Mathematical Operators

| Operator | Name | Example | Result |
|---|---|---|---|
| `+` | Addition | `2 + 3` | `5` |
| `-` | Subtraction | `7 - 2` | `5` |
| `*` | Multiplication | `3 * 4` | `12` |
| `/` | Division (float) | `10 / 2` | `5.0` |
| `//` | Integer Division | `7 // 2` | `3` |
| `%` | Modulus (remainder) | `7 % 2` | `1` |
| `**` | Exponent | `2 ** 3` | `8` |

```python
a = 10
b = 3

print(a + b)   # 13
print(a - b)   # 7
print(a * b)   # 30
print(a / b)   # 3.3333...
print(a // b)  # 3
print(a % b)   # 1
print(a ** b)  # 1000
```

---

## 6. Order of Operations — PEMDAS

Python follows strict math order:

```
1. ( )   Parentheses
2. **    Exponents
3. * / // %   Multiplication & Division (left → right)
4. + -   Addition & Subtraction (left → right)
```

```python
print(2 + 3 * 4)      # 14  ← multiplication happens first
print((2 + 3) * 4)    # 20  ← parentheses force addition first
print(2 ** 3 + 1)     # 9   ← exponent before addition
print(10 - 4 // 2)    # 8   ← integer division before subtraction
```

**Output:**
```
14
20
9
8
```

---

## 7. The `round()` Function

```python
print(round(3.6))       # 4
print(round(3.2))       # 3
print(round(3.14159, 2)) # 3.14  ← 2 decimal places
print(round(5.6789, 1))  # 5.7
```

> ⚠️ **Banker's Rounding** — when exactly at `.5`, Python rounds to the nearest **even** number:
> ```python
> print(round(2.5))  # 2  ← rounds DOWN to even
> print(round(3.5))  # 4  ← rounds UP to even
> ```

---

## 8. Comparison Operators

Return `True` or `False`.

| Operator | Meaning | Example | Result |
|---|---|---|---|
| `>` | Greater than | `5 > 3` | `True` |
| `<` | Less than | `2 < 1` | `False` |
| `==` | Equal to | `4 == 4` | `True` |
| `!=` | Not equal to | `4 != 4` | `False` |
| `>=` | Greater or equal | `5 >= 5` | `True` |
| `<=` | Less or equal | `3 <= 2` | `False` |

```python
print(10 > 5)    # True
print(3 == 7)    # False
print(4 != 4)    # False
print(5 >= 5)    # True
```

---

## 9. Logical Operators

Combine multiple boolean conditions.

| Operator | Rule | Example | Result |
|---|---|---|---|
| `and` | Both must be `True` | `True and False` | `False` |
| `or` | At least one `True` | `True or False` | `True` |
| `not` | Flips the value | `not True` | `False` |

```python
print(True and False)   # False
print(True or False)    # True
print(not True)         # False

age = 20
has_id = True
print(age >= 18 and has_id)  # True
```

---

## 10. Assignment Operators

Shorthand operators that update a variable in place.

```python
x = 5

x += 3   # x = x + 3  → 8
x -= 2   # x = x - 2  → 6
x *= 4   # x = x * 4  → 24
x /= 3   # x = x / 3  → 8.0
x //= 2  # x = x // 2 → 4.0
x %= 3   # x = x % 3  → 1.0
x **= 2  # x = x ** 2 → 1.0

print(x)  # 1.0
```

---

## 11. Indexing & Slicing

Access individual items or ranges from ordered sequences (strings, lists).

### Indexing

```python
word = "Python"
#       0 1 2 3 4 5   ← positive index
#      -6-5-4-3-2-1   ← negative index

print(word[0])   # P
print(word[2])   # t
print(word[-1])  # n
print(word[-2])  # o
```

### Slicing

```python
# [start : stop]   (stop is exclusive)
nums = [1, 2, 3, 4, 5]
print(nums[1:3])     # [2, 3]
print(nums[0:5:2])   # [1, 3, 5]  ← every 2nd item
print(nums[::-1])    # [5, 4, 3, 2, 1]  ← reversed
```

---

## 12. Lists

Ordered, mutable collections of items.

```python
my_list = [1, 2, 3]

# Add an item
my_list.append(4)
print(my_list)   # [1, 2, 3, 4]

# Access by index
print(my_list[0])   # 1
print(my_list[-1])  # 4
```

---

## 13. f-Strings (Formatted String Literals)

The modern way to embed variables inside strings.

```python
name = "Kenneth"
age  = 25

print(f"Hello, my name is {name} and I am {age} years old.")
```

**Output:**
```
Hello, my name is Kenneth and I am 25 years old.
```

**Inline expressions and formatting:**

```python
price    = 19.99
discount = 5
final    = price - discount

print(f"The final price after discount is ${final:.2f}")
```

**Output:**
```
The final price after discount is $14.99
```

> `:.2f` inside `{}` forces 2 decimal places on a float.

**You can even call functions inside `{}`:**

```python
name = "kenneth"
print(f"Name: {name.upper()}")  # Name: KENNETH
```

---

## Quick Reference Cheat Sheet

```python
# Types
type(5)         # int
type(3.14)      # float
type("hi")      # str
type(True)      # bool

# Conversion
int("10")       # 10
float(5)        # 5.0
str(99)         # "99"

# Math
7 // 2          # 3   (integer division)
7 % 2           # 1   (remainder)
2 ** 8          # 256 (power)

# String tricks
"Hi" + " Ken"   # "Hi Ken"
len("Python")   # 6
"Python"[0]     # "P"
"Python"[-1]    # "n"

# round()
round(3.5)      # 4
round(2.5)      # 2  ← banker's rounding
round(3.14159, 2) # 3.14

# f-string
f"{name} is {age}"
f"{price:.2f}"
```