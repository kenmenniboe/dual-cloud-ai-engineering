# Notes — Python Conditionals & Control Flow

> Detailed reference for everything covered. Treat this as a mini-tutorial you can return to.

---

## Table of Contents

1. [if / else](#1-if--else)
2. [elif](#2-elif)
3. [Nested if](#3-nested-if)
4. [Multiple if Statements](#4-multiple-if-statements)
5. [Nested if vs elif vs Multiple ifs — Key Differences](#5-nested-if-vs-elif-vs-multiple-ifs--key-differences)
6. [Modulo Operator %](#6-modulo-operator-)
7. [Comparison Operators](#7-comparison-operators)
8. [Logical Operators](#8-logical-operators)
9. [Combining if with input()](#9-combining-if-with-input)
10. [Quick Reference — Rules to Remember](#10-quick-reference--rules-to-remember)

---

## 1. `if` / `else`

The most fundamental decision tool in Python. It asks: **"Is this condition True?"**

- If yes → run the `if` block
- If no → run the `else` block (if one exists)

### Syntax

```python
if condition:
    # runs if condition is True
else:
    # runs if condition is False
```

> ⚠️ The colon `:` at the end of `if` and `else` is required.  
> ⚠️ The indented block below each tells Python what belongs to it.

### Example — Voting Age

```python
age = 18

if age >= 18:
    print("You are allowed to vote!")
else:
    print("You are too young to vote.")
```

**Output:**
```
You are allowed to vote!
```

`age >= 18` evaluates to `True`, so the first block runs.

### Example — Boolean flag

```python
is_hungry = True

if is_hungry:
    print("Eat an apple")
```

If `is_hungry` is `False`, nothing prints — the `if` block is simply skipped.

### Boolean values

| Value | Meaning |
|-------|---------|
| `True` | Yes / condition passes |
| `False` | No / condition fails |

These are called **Boolean values**. Every condition in Python ultimately resolves to one of these two.

---

## 2. `elif`

Used when you need to check **more than two possibilities**. `elif` stands for "else if".

Python works through each condition **top to bottom** and stops the moment one is `True`. Everything after it is skipped.

### Syntax

```python
if condition1:
    # runs if condition1 is True
elif condition2:
    # runs if condition1 is False AND condition2 is True
elif condition3:
    # runs if condition1 and condition2 are False AND condition3 is True
else:
    # runs if none of the above are True
```

**Rules:**
- You can have as many `elif` blocks as you need.
- You can have only **one** `else` (and it's optional).
- Python stops checking after the **first True** condition.

### Example — Weather

```python
temperature = 25

if temperature > 30:
    print("It's really hot today!")
elif temperature > 20:
    print("The weather is nice.")
else:
    print("It's a bit cold.")
```

**Output:**
```
The weather is nice.
```

`temperature > 30` is `False`. `temperature > 20` is `True` → prints and stops. `else` is never reached.

### Example — Grading

```python
score = 80

if score >= 90:
    print("Grade A")
elif score >= 75:
    print("Grade B")
else:
    print("Grade C")
```

**Output:**
```
Grade B
```

---

## 3. Nested `if`

A **nested `if`** is an `if` statement placed inside another `if`. Used when a second condition only makes sense to check **after** the first one passes.

### Syntax

```python
if outer_condition:
    # outer block
    if inner_condition:
        # inner block — only reached if outer is True
```

> ⚠️ If the outer condition is `False`, Python never enters the outer block — so the inner `if` is never checked at all.

### Example — Login + Admin

```python
is_logged_in = True
is_admin = True

if is_logged_in:
    print("Welcome!")
    if is_admin:
        print("Open admin panel")
```

**Output:**
```
Welcome!
Open admin panel
```

### Example — Age + Permission (outer fails)

```python
age = 16
has_permission = True

if age >= 18:
    print("Adult")
    if has_permission:
        print("Can enter VIP")
```

**Output:**
```
(nothing)
```

`age >= 18` is `False` — the entire outer block, including the inner `if`, is skipped.

### Example — Age + ID

```python
age = 18
has_id = True

if age >= 18:
    if has_id:
        print("You can enter!")
    else:
        print("You need an ID.")
else:
    print("Sorry, you're too young.")
```

**Output:**
```
You can enter!
```

**When to use nested `if`:** when one condition must be confirmed before it even makes sense to check the next one.

---

## 4. Multiple `if` Statements

When you write several separate `if` blocks (not `elif`), each condition is **checked independently**. More than one block can run.

### Example

```python
number = 15

if number > 10:
    print("The number is greater than 10.")   # ✅ runs

if number % 2 == 0:
    print("The number is even.")               # ❌ skipped (15 is odd)

if number < 20:
    print("The number is less than 20.")       # ✅ runs
```

**Output:**
```
The number is greater than 10.
The number is less than 20.
```

All three `if` statements are evaluated. Two are `True`, so two blocks run.

**When to use multiple `if`:** when conditions are **unrelated** and more than one can legitimately be true at the same time.

---

## 5. Nested `if` vs `elif` vs Multiple `if`s — Key Differences

This is one of the most important things to understand about conditionals.

### Side-by-side comparison

| | Nested `if` | `elif` | Multiple `if` |
|---|---|---|---|
| **Conditions** | Dependent (inner relies on outer) | Mutually exclusive alternatives | Fully independent |
| **Blocks that run** | Inner only if outer is True | Only the first True block | All blocks whose condition is True |
| **Use case** | Layered / refined logic | Branching choices | Unrelated parallel checks |

### Nested `if` example

```python
age = 18
has_id = True

if age >= 18:          # outer
    if has_id:         # inner — only checked if outer is True
        print("You can enter!")
    else:
        print("You need an ID.")
else:
    print("Sorry, you're too young.")
```

### `elif` example (same theme)

```python
temperature = 25

if temperature > 30:
    print("It's really hot!")
elif temperature > 20:        # only checked if first is False
    print("The weather is nice.")
elif temperature > 10:
    print("It's a bit chilly.")
else:
    print("It's cold!")
```

Only **one** block ever runs.

### Multiple `if` example

```python
grade = 85

if grade >= 70:
    print("You passed!")       # ✅ runs

if grade >= 80:
    print("Great job!")        # ✅ also runs

if grade >= 90:
    print("Outstanding!")      # ❌ skipped
```

**Output:**
```
You passed!
Great job!
```

Two conditions are true, so two blocks run — unlike `elif`, where only the first True one would have fired.

---

## 6. Modulo Operator `%`

The `%` operator returns the **remainder** after division.

```
a % b  →  "What is left over when a is divided by b?"
```

### How to calculate

```
10 % 3  →  10 ÷ 3 = 3 remainder 1  →  result: 1
15 % 4  →  15 ÷ 4 = 3 remainder 3  →  result: 3
8  % 2  →  8  ÷ 2 = 4 remainder 0  →  result: 0
7  % 2  →  7  ÷ 2 = 3 remainder 1  →  result: 1
```

### Example — Even or Odd

```python
number = 7

if number % 2 == 0:
    print("Even")
else:
    print("Odd")
```

**Output:**
```
Odd
```

`7 % 2` is `1` (not `0`), so the condition is `False` → "Odd".

### Example — Checking multiples

```python
if 20 % 5 == 0:
    print("20 is a multiple of 5!")
```

**Output:**
```
20 is a multiple of 5!
```

### Example — Cycling through values in a loop

```python
for i in range(1, 11):
    print(f"{i} % 3 = {i % 3}")
```

**Output:**
```
1 % 3 = 1
2 % 3 = 2
3 % 3 = 0
4 % 3 = 1
5 % 3 = 2
6 % 3 = 0
...
```

Useful for repeating patterns (e.g. every 3rd item, wrapping clock values, game logic).

### Common uses of `%`

| Use case | How |
|----------|-----|
| Even / odd check | `n % 2 == 0` |
| Multiple check | `n % x == 0` |
| Cycle / wrap values | `i % n` resets to 0 after every n steps |

---

## 7. Comparison Operators

Comparison operators compare two values and return `True` or `False`. They are the building blocks of every `if` condition.

### Full table

| Operator | Meaning | Example | Result |
|----------|---------|---------|--------|
| `==` | Equal to | `5 == 5` | `True` |
| `!=` | Not equal to | `5 != 3` | `True` |
| `>` | Greater than | `10 > 5` | `True` |
| `<` | Less than | `3 < 8` | `True` |
| `>=` | Greater than or equal to | `7 >= 7` | `True` |
| `<=` | Less than or equal to | `4 <= 6` | `True` |

### Example

```python
x = 10
y = 5

print(x > y)    # True  — 10 is greater than 5
print(x == y)   # False — 10 is not equal to 5
print(x != y)   # True  — 10 is not equal to 5
```

### Critical rule — `=` vs `==`

| Symbol | Purpose | Example |
|--------|---------|---------|
| `=` | **Assign** a value to a variable | `x = 5` |
| `==` | **Compare** two values (returns True/False) | `x == 5` |

```python
x = 5       # stores 5 in x
x == 5      # asks: "is x equal to 5?" → True
```

Mixing these up is one of the most common beginner mistakes.

---

## 8. Logical Operators

Logical operators let you **combine or reverse** conditions. They return `True` or `False`.

### Full table

| Operator | Meaning | Example | Result |
|----------|---------|---------|--------|
| `and` | Both conditions must be True | `(5 > 2) and (10 > 5)` | `True` |
| `or` | At least one condition must be True | `(5 > 10) or (2 < 3)` | `True` |
| `not` | Reverses the result | `not(5 > 2)` | `False` |

### `and` — both must be True

```python
has_ticket = True
has_id = True

if has_ticket and has_id:
    print("You can enter")
```

**Output:**
```
You can enter
```

If **either** is `False`, the whole condition becomes `False` and the block is skipped.

### `or` — at least one must be True

```python
is_raining = False
is_snowing = True

if is_raining or is_snowing:
    print("Take an umbrella or wear a coat!")
else:
    print("The weather is clear.")
```

**Output:**
```
Take an umbrella or wear a coat!
```

`is_snowing` is `True`, so the condition passes even though `is_raining` is `False`.

### `not` — reverses True/False

```python
is_tired = False

if not is_tired:
    print("Let's go for a run!")
else:
    print("Get some rest!")
```

**Output:**
```
Let's go for a run!
```

`not False` → `True`. The `if` block runs.

### Combined example

```python
age = 20
has_id = True

if age >= 18 and has_id:
    print("Allowed in")
else:
    print("Not allowed")
```

**Output:**
```
Allowed in
```

---

## 9. Combining `if` with `input()`

`input()` captures what a user types. Pairing it with `if` makes programs **interactive** — the output changes based on what the user provides.

> ⚠️ `input()` always returns a **string**. If you need a number, wrap it with `int()`.

### Example — Voting age check

```python
age = int(input("Enter your age: "))

if age >= 18:
    print("You are old enough to vote!")
else:
    print("Sorry, you must be at least 18 to vote.")
```

**How it works:**
1. `input(...)` displays the prompt and waits for the user to type
2. `int(...)` converts the typed string into an integer
3. The `if` condition checks the number and prints the appropriate response

### Example — Password check

```python
password = input("Enter the secret password: ")

if password == "PythonRocks":
    print("Access granted!")
else:
    print("Access denied!")
```

No `int()` needed here — password is compared as a string.

**Use cases for `if` + `input()`:** login systems, quizzes, games, forms, CLI tools.

---

## 10. Quick Reference — Rules to Remember

| Rule | Detail |
|------|--------|
| `if` line ends with `:` | Required — Python will error without it |
| Indentation matters | Code inside `if` / `else` / `elif` must be indented consistently |
| `=` vs `==` | `=` assigns, `==` compares |
| `elif` stops at first `True` | Once a condition matches, the rest are skipped |
| Nested `if` — outer gates inner | Inner block is unreachable if outer condition is `False` |
| Multiple `if` — all checked | Every `if` is independent; more than one can run |
| `input()` returns a string | Use `int()` or `float()` to convert when needed |
| `not False` is `True` | `not` simply flips the Boolean |

### Decision guide — which structure to use?

```
Are the conditions dependent on each other?
    Yes → Nested if

Are the conditions mutually exclusive (only one can be true)?
    Yes → elif

Can multiple conditions be true at the same time?
    Yes → Multiple if statements
```