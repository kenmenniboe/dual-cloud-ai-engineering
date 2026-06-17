# 📝 Python Loops — Detailed Notes
**Date:** Wednesday, May 06, 2026
**Topic:** Python Loops (Fundamentals + Intermediate)

---

## 🟢 FUNDAMENTALS

---

### Module 1 — What is a Loop?

A loop lets Python repeat a task without you writing the same line over and over.
Programmers follow the **DRY** principle — **Don't Repeat Yourself!**

**Real-world analogy:**
A vending machine goes through the same steps for every customer:
check money → dispense snack → give change. That repeated process is a loop.

**Key idea:**
> Do something → again and again → until it's told to stop.

---

### Module 2 — The `for` Loop

A `for` loop says: *"For each item in this group — do something."*

**Syntax:**
```python
for variable in collection:
    # code to repeat
```

**Example:**
```python
for name in ["Bob", "Sue", "Tom"]:
    print(name)
```

**Output:**
```
Bob
Sue
Tom
```

**Rules to remember:**
- Start with the keyword `for`
- End the `for` line with a colon `:`
- The indented code below runs for each item
- Python goes through each item **one at a time**, in order

---

### Module 3 — The `range()` Function

`range()` generates a sequence of numbers to loop through — no list needed.

**Default (starts at 0):**
```python
for number in range(5):
    print(number)
```

**Output:**
```
0
1
2
3
4
```

> ⚠️ Python always starts counting from **0**, not 1.
> `range(5)` gives you 5 numbers: 0, 1, 2, 3, 4

**Key rule:** `range(n)` gives you `n` numbers, ending at `n-1`.

---

### Module 4 — The `while` Loop

A `while` loop keeps running **as long as a condition is true**.

**Syntax:**
```python
while condition:
    # code to repeat
```

**Example:**
```python
count = 1

while count <= 3:
    print(count)
    count = count + 1
```

**Output:**
```
1
2
3
```

**Rules to remember:**
- Always update your counter (`count = count + 1`) — forgetting this causes an **infinite loop!**
- An infinite loop runs forever because the condition never becomes false

**`for` vs `while`:**
| `for` loop | `while` loop |
|------------|--------------|
| Repeats a set number of times | Repeats as long as something is true |
| Good when you know how many times | Good when you don't know how many times |

---

### Module 5 — `break` and `continue`

Two keywords that control what happens inside a loop.

**`break` — stops the loop completely:**
```python
for number in range(5):
    if number == 3:
        break
    print(number)
```

**Output:**
```
0
1
2
```
> Loop stops the moment it hits 3. The number 3 is never printed.

---

**`continue` — skips one item and keeps going:**
```python
for number in range(5):
    if number == 3:
        continue
    print(number)
```

**Output:**
```
0
1
2
4
```
> Python skips 3 but continues with 4 and beyond.

**Summary:**
- `break` → 🛑 Stop the whole loop
- `continue` → ⏭️ Skip this one, keep going

---

## 🟡 INTERMEDIATE

---

### Module 1 — Nested Loops

A **nested loop** is a loop inside another loop.

**Real-world analogy:**
A school with 3 classrooms, each with 2 students.
- Outer loop → each classroom
- Inner loop → each student in that classroom

**Example:**
```python
for classroom in range(3):
    for student in range(2):
        print("👦 student")
```

**Output:** Prints `👦 student` **6 times** (3 × 2 = 6)

**Important rule:**
Always use **different variable names** for outer and inner loops.
If you reuse the same variable name, the inner loop overwrites the outer loop's value!

```python
# ❌ Wrong — both use "letter", inner loop overwrites outer
for letter in "KENNETH":
    for letter in range(2):
        print(letter)  # prints 0, 1 — not the actual letter!

# ✅ Correct — different variable names
for letter in "KENNETH":
    for number in range(2):
        print(letter)  # prints each letter twice
```

**Output of correct version:**
```
K
K
E
E
N
N
N
N
E
E
T
T
H
H
```

---

### Module 2 — `range()` with Start & Step

The full version of `range()` takes three arguments:

```python
range(start, stop, step)
```

| Argument | Meaning |
|----------|---------|
| `start` | Where to begin |
| `stop` | Where to stop (not included) |
| `step` | How much to jump each time |

**Example — count by 2s:**
```python
for number in range(0, 10, 2):
    print(number)
```

**Output:**
```
0
2
4
6
8
```

**Example — count by 3s starting at 1:**
```python
for number in range(1, 10, 3):
    print(number)
```

**Output:**
```
1
4
7
```
> Always work it out manually: 1 → 1+3=4 → 4+3=7 → 7+3=10 (stop! 10 is not less than 10)

---

### Module 3 — Looping Through Strings

Python treats a string like a list of letters — you can loop through each character one at a time.

**Example:**
```python
for letter in "hello":
    print(letter)
```

**Output:**
```
h
e
l
l
o
```

**Your own example:**
```python
for letter in "KENNETH":
    print(letter)
```

> Prints each of the 7 letters — capitals stay capitals!

---

### Module 4 — `enumerate()`

`enumerate()` gives you **two things** at once while looping:
1. The **position** (index) of the item
2. The **item** itself

**Example:**
```python
for position, name in enumerate(["Ken", "Amy", "Joe"]):
    print(position, name)
```

**Output:**
```
0 Ken
1 Amy
2 Joe
```

> ⚠️ Position starts at **0**, just like `range()`

**Why use it?**
A normal `for` loop only gives you the item. `enumerate()` gives you the item **and** where it is in the list — useful when position matters.

---

### Module 5 — `else` with Loops

A loop can have an `else` block that runs **after the loop finishes normally**.

**Example — loop finishes normally:**
```python
for number in range(3):
    print(number)
else:
    print("Loop is done!")
```

**Output:**
```
0
1
2
Loop is done!
```

**Example — loop stopped by `break`:**
```python
for number in range(5):
    if number == 3:
        break
    print(number)
else:
    print("All done!")
```

**Output:**
```
0
1
2
```
> `"All done!"` is **never printed** because `break` stopped the loop early.

**Rule:**
- Loop ends normally → `else` **runs**
- Loop ends with `break` → `else` **does NOT run**

---

## 🔨 Real Code Worked Through

### Adding numbers 1 to 100

```python
total_number = 0

for number in range(1, 101):
    total_number += number

print(total_number)
```

**Output:** `5050`

**Key concepts used:**
- `+=` is shorthand for `total_number = total_number + number`
- `print` is **outside** the loop → runs only once, showing the final total
- If `print` were **inside** the loop → it would print 100 times (running total)

---

### Inside vs Outside a Loop

```python
# print INSIDE — runs 100 times
for number in range(1, 101):
    total_number += number
    print(total_number)  # shows running total every step

# print OUTSIDE — runs once
for number in range(1, 101):
    total_number += number
print(total_number)  # shows final answer only
```

> **Rule:** Put code inside a loop if you want it repeated. Put it outside if you only want it once.

---

### Password Generator (Real World Project)

```python
import random

letters = ['a', 'b', ..., 'Z']
numbers = ['0', '1', ..., '9']
symbols = ['!', '#', '$', ...]

number_of_letters = int(input("How many letters?\n"))
number_of_symbols = int(input("How many symbols?\n"))
number_of_numbers = int(input("How many numbers?\n"))

new_password = []

for character in range(0, number_of_letters):
    new_password.append(random.choice(letters))

for character in range(0, number_of_symbols):
    new_password.append(random.choice(symbols))

for character in range(0, number_of_numbers):
    new_password.append(random.choice(numbers))

random.shuffle(new_password)

str_password = "".join(map(str, new_password))
print(f"Your secure password is: {str_password}")
```

**How it works step by step:**
1. `import random` → opens the random toolbox
2. Three lists store all possible letters, numbers, symbols
3. `input()` asks the user how many of each they want
4. `int()` wraps `input()` because input always returns a string — we convert it to a number
5. Three `for` loops pick random characters and `.append()` them to the list
6. `random.shuffle()` shuffles the list **in place** (same list, random order)
7. `"".join(map(str, new_password))` converts the list into a clean string
8. f-string prints the final password

**Key concept — `map(str, numbers)`:**
```python
# map(str, numbers) converts each number to a string
# So [1, 2, 3] becomes ["1", "2", "3"]
# Then "".join() glues them together → "123"
```

> Python can't join numbers directly — they must be strings first!

---

## 📌 Quick Reference Cheat Sheet

```python
# for loop
for item in collection:
    print(item)

# range (basic)
for i in range(5):          # 0 1 2 3 4
    print(i)

# range (start, stop, step)
for i in range(1, 10, 2):   # 1 3 5 7 9
    print(i)

# while loop
count = 0
while count < 3:
    print(count)
    count += 1

# break
for i in range(5):
    if i == 3:
        break               # stops at 3

# continue
for i in range(5):
    if i == 3:
        continue            # skips 3

# nested loop
for row in range(3):
    for col in range(2):
        print("X")          # prints 6 times

# enumerate
for index, item in enumerate(["a", "b", "c"]):
    print(index, item)      # 0 a / 1 b / 2 c

# else with loop
for i in range(3):
    print(i)
else:
    print("done")           # runs only if no break
```