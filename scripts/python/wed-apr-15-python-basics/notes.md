# Day 01 — Detailed Notes (Python Basics)

## 1. `print()` Function

Used to display output to the console.

```python
print("Hello, Kenneth!")
```

* Accepts strings, variables, expressions
* Automatically adds a newline at the end

---

## 2. Strings

A string is a sequence of characters enclosed in quotes.

```python
"Hello"
'World'
```

### Key Points:

* Can use single or double quotes
* Must be consistent
* Used for text storage and manipulation

---

## 3. Newline Character (`\n`)

Forces output onto a new line.

```python
print("Hello\nKenneth!")
```

### Behavior:

* No extra spaces unless explicitly added
* Equivalent to pressing Enter

---

## 4. String Concatenation

Combining strings using `+`.

```python
first_name = "Kenneth"
last_name = "Smith"
print(first_name + " " + last_name)
```

### Notes:

* Must ensure all operands are strings
* Space `" "` must be explicitly added

---

## 5. `input()` Function

Captures user input.

```python
name = input("What is your name? ")
print("Hello, " + name)
```

### Important:

* Always returns a string
* Prompt text improves UX

### Example Run:

```
What is your name? Kenneth
Hello, Kenneth
```

---

## 6. Comments

Used for documentation and clarity.

```python
# This is a comment
print("Hello")  # Inline comment
```

### Notes:

* Ignored during execution
* Useful for debugging and collaboration

---

## 7. Variables

Used to store data.

```python
x = 5
message = "Hello World"
```

### Rules:

* Cannot start with a number
* No spaces
* Case-sensitive

### Best Practices:

```python
user_name = "Kenneth"
MAX_SPEED = 120
```

---

## 8. `len()` Function

Returns the length of a sequence.

```python
message = "Hello, Kenneth!"
print(len(message))
```

### Output:

```
15
```

### Works With:

* Strings
* Lists

```python
numbers = [10, 20, 30, 40]
print(len(numbers))  # Output: 4
```

---

## 9. Debugging Observation

### Common Mistake:

```python
rint("Hello")
```

**Issue:** Typo → Missing `p` in `print`

---

## 10. Screenshot Placeholder (Optional)

```
[Screenshot: Terminal output showing Python execution]

[Screenshot: Code editor with main.py]
```

---

## Summary

This session established the core primitives of Python:

* Output (`print`)
* Input (`input`)
* Data types (strings)
* Basic operations (concatenation, length)
* Code readability (comments, naming)

These concepts form the baseline for all future Python development.

---

In additions to the notes above

# Day 01 — Detailed Notes: Python Basics

---

## 1. What is a SyntaxError?

A `SyntaxError` is Python's way of saying:
> *"I don't understand what you're trying to say."*

Python has grammar rules, just like English. When your code breaks one of those rules,
Python raises a `SyntaxError` **before** it even runs your code.

### Example
```python
# ❌ Missing closing parenthesis
print("Hello, world!"

# SyntaxError: '(' was never closed
```

```python
# ✅ Fixed
print("Hello, world!")
```

### Common Causes of SyntaxErrors
| Mistake                  | Bad Example              | Fixed Example          |
|--------------------------|--------------------------|------------------------|
| Missing closing bracket  | `print("hi"`             | `print("hi")`          |
| Missing colon            | `if x == 5`              | `if x == 5:`           |
| Misspelled keyword       | `whille True:`           | `while True:`          |
| Mismatched quotes        | `print("hello')`         | `print("hello")`       |

---

## 2. Strings & Quote Rules

A string in Python is a sequence of characters enclosed in quotes.
Quotes show where the string begins and where it ends.

### The Golden Rule
> Strings must start and end with the **same type of quote** — and vice versa!

```python
# ✅ Both valid
print("Hello!")
print('Hello!')

# ❌ Mismatched quotes — SyntaxError
print("Hello!')
```

---

## 3. Handling Apostrophes & Double Quotes Inside Strings

### Apostrophes inside a string
If your string contains an apostrophe `'`, use **double quotes** on the outside.

```python
# ❌ Single quotes on outside — SyntaxError
# Python sees 'It' as the full string, then gets confused
print('It's a beautiful day in the neighborhood')

# ✅ Double quotes on outside — works perfectly
print("It's a beautiful day in the neighborhood")
```

### Double quotes inside a string
If your string contains double quotes `"`, use **single quotes** on the outside.

```python
# ✅ Single quotes on outside — works perfectly
print('She said "Wow, Python is fun!"')

# Output: She said "Wow, Python is fun!"
```

> **Note:** When the outer quotes are different from the inner quotes, you do NOT
> need backslashes `\`. Backslashes are only needed in specific escape situations.

---

## 4. The print() Function

`print()` tells Python to display whatever is inside the parentheses on the screen.

```python
print("Hello, Kenneth!")
# Output: Hello, Kenneth!
```

### Newline Character `\n`
`\n` starts a new line — like pressing Enter on your keyboard.

```python
print("Hello\nKenneth!")
# Output:
# Hello
# Kenneth!
```

---

## 5. String Concatenation

Concatenation means joining strings together using the `+` operator.

```python
first_name = "Kenneth"
last_name = "Smith"
full_name = first_name + " " + last_name
print(full_name)
# Output: Kenneth Smith
```

---

## 6. Variables

Variables are containers that store values.

```python
x = 5
y = "Hello World"
user_name = "Kenneth"
```

### Rules for Naming Variables
- Must start with a letter (A–Z, a–z) or underscore `_`
- Can contain letters, digits, and underscores
- Cannot start with a digit
- Cannot use Python keywords like `for`, `if`, `class`
- Case-sensitive: `score` and `Score` are different variables

### Best Practices
- Use descriptive names: `user_age` is better than `x`
- Use `snake_case` for multi-word names: `total_price`, `is_valid`
- Use `UPPERCASE` for constants: `MAX_SPEED = 120`

---

## 7. f-strings (Formatted Strings)

f-strings let you reference variables directly inside a string.
Add an `f` before the opening quote, then wrap variables in `{}`.

```python
# ❌ Wrong — this is JavaScript syntax, not Python
print("The number of characters in your name is ${user_name}")

# ✅ Correct — Python f-string
user_name = "Kenneth"
print(f"The number of characters in your name is {user_name}")
# Output: The number of characters in your name is Kenneth
```

---

## 8. The len() Function

`len()` counts the number of characters in a string (or items in a list).

```python
message = "Hello, Kenneth!"
print(len(message))
# Output: 15

# Combined with f-string
user_name = "Kenneth"
print(f"The number of characters in your name is {len(user_name)}")
# Output: The number of characters in your name is 7
```

---

## 9. The input() Function

`input()` gets input from the user. The result is always treated as a string.

```python
name = input("What is your name? ")
print("Hello, " + name + "!")
# If user types "Kenneth":
# Output: Hello, Kenneth!
```

---

## 10. Comments

Comments are notes in your code that Python ignores. They start with `#`.

```python
# This is a comment — Python ignores this line
print("Hello, Kenneth!")  # This prints a greeting
```

> **Shortcut:** On macOS, press `Command + /` to comment/uncomment a line.

---

## Screenshot Placeholders

- [ ] Screenshot: SyntaxError in terminal from mismatched quotes
- [ ] Screenshot: f-string output in terminal
- [ ] Screenshot: input() function prompt in terminal
- [ ] Screenshot: len() output in terminal