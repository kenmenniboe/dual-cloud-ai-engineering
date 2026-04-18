# Python Fundamentals – README

## What I Learned

A foundational overview of Python's core building blocks: how data is stored, typed, manipulated, and operated on.

---

## Topics Covered

| Topic | Summary |
|---|---|
| **Data Types** | `int`, `float`, `str`, `bool` — the four core types |
| **Variables** | Named containers that store values |
| **Type Checking** | `type()` reveals what kind of data a variable holds |
| **Type Conversion** | `int()`, `float()`, `str()` cast between types |
| **String Operations** | Concatenation, `len()`, indexing, `\n`, f-strings |
| **Math Operators** | `+`, `-`, `*`, `/`, `//`, `%`, `**` |
| **Order of Operations** | PEMDAS — parentheses first, exponents second |
| **`round()`** | Rounds floats; uses banker's rounding at `.5` |
| **Assignment Operators** | `=`, `+=`, `-=`, `*=`, `//=`, etc. |
| **Comparison Operators** | `>`, `<`, `==`, `!=` — return `True` or `False` |
| **Logical Operators** | `and`, `or`, `not` — combine boolean conditions |
| **Indexing & Slicing** | Access individual or ranges of items by position |
| **Lists** | Ordered collections; `.append()` to add items |
| **f-Strings** | Modern string formatting using `f"...{var}..."` |

---

## Key Outputs / Takeaways

- Every value in Python has a **type** — knowing it matters for operations and comparisons.
- Division `/` **always** returns a float; use `//` to stay in integers.
- Strings support indexing: `"Python"[0]` → `"P"`, `"Python"[-1]` → `"n"`.
- `round(2.5)` → `2` (banker's rounding — rounds to nearest even).
- f-strings replace messy concatenation: `f"Hello, {name}!"` is cleaner and supports inline expressions.
- Type conversion allows mixing data sources: `int("50")` → `50`.

---

## Stack

- Language: **Python 3**
- Environment: PyCharm / terminal