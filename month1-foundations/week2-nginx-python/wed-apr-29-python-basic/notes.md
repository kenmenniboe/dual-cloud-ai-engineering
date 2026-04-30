# 🐍 Python Notes — Randomisation & Lists
**Date:** Wednesday, 29 April  
**Folder:** `wed-apr-29-python-basic/`  
**Level:** Fundamentals → Intermediate

---

## 📦 Module 1 — What is a List?

### Concept
A **list** is a container that stores multiple items together in one place, in a specific order.

```python
lunchbox = ["sandwich", "apple", "juice", "cookie"]
```

- Square brackets `[ ]` create the list
- Items are separated by commas `,`
- Each item has a **position number** called an **index**, starting from **0**

### Index Positions
```python
fruits = ["mango", "banana", "grape", "orange"]
#           0          1        2         3

print(fruits[0])  # mango
print(fruits[1])  # banana
print(fruits[2])  # grape
print(fruits[3])  # orange
```

> ⚠️ Python always starts counting from **0**, not 1!

### Negative Indexing
You can count from the **back** of the list using negative numbers:
```python
print(fruits[-1])  # orange  (last item)
print(fruits[-2])  # grape   (second to last)
```

### Counting Items — `len()`
```python
toys = ["teddy", "lego", "car", "doll", "ball"]
print(len(toys))  # 5
```

> ⚠️ The list has 5 items but the last index is **4** — because we start from 0!

### IndexError
An `IndexError` happens when you try to access an index that doesn't exist:
```python
fruits = ["apple", "banana", "cherry"]
print(fruits[3])  # IndexError! Valid indexes are only 0, 1, 2
```

Safe way to avoid it:
```python
if index < len(fruits):
    print(fruits[index])
else:
    print("Invalid index!")
```

---

## ✏️ Module 2 — Adding, Removing & Changing List Items

### Adding — `.append()`
Adds a new item to the **end** of the list:
```python
lunchbox = ["sandwich", "apple", "juice"]
lunchbox.append("cookie")
print(lunchbox)
# ["sandwich", "apple", "juice", "cookie"]
```

### Adding at a Specific Position — `.insert()`
```python
fruits = ["apple", "banana"]
fruits.insert(1, "orange")  # inserts at index 1
print(fruits)
# ["apple", "orange", "banana"]
```

### Removing — `.remove()`
Removes an item by **name**:
```python
lunchbox.remove("apple")
print(lunchbox)
# ["sandwich", "juice", "cookie"]
```

### Removing by Index — `.pop()`
Removes an item at a specific **index** (or the last item if no index given):
```python
fruits.pop(0)   # removes first item
fruits.pop()    # removes last item
```

### Changing an Item
Use the index to swap an item for something new:
```python
colours = ["red", "blue", "green"]
colours[1] = "yellow"
print(colours)
# ["red", "yellow", "green"]
```

> ⚠️ Remember: index **1** is the **second** item, not the first!

### Sorting & Reversing
```python
fruits.sort()     # sorts alphabetically / numerically
fruits.reverse()  # reverses the order
```

---

## 🔄 Module 3 — Looping Through a List

### Concept
A `for` loop visits **every item** in a list, one by one, automatically.

```python
lunchbox = ["sandwich", "apple", "juice", "cookie"]

for item in lunchbox:
    print(item)

# sandwich
# apple
# juice
# cookie
```

### How to Read It
```python
for item in lunchbox:
```
- `for` → start the loop
- `item` → temporary name for each item (you can call it anything!)
- `in lunchbox` → look inside this list

> The loop runs **once for every item** in the list.

### Real Example — Personalised Messages
```python
students = ["Emma", "Liam", "Olivia", "Noah"]

for student in students:
    print("Good morning, " + student + "!")

# Good morning, Emma!
# Good morning, Liam!
# Good morning, Olivia!
# Good morning, Noah!
```

> ⚠️ Code inside the loop must be **indented** (tab or 4 spaces)

---

## 🎲 Module 4 — Randomisation

### What is the `random` Module?
A **module** is like a toolbox full of useful tools. The `random` module gives Python the ability to make random choices.

```python
import random
```

> Always put `import random` at the very **top** of your code!

### Picking One Random Item — `random.choice()`
```python
prizes = ["teddy", "lego", "doll", "car", "ball"]
winner = random.choice(prizes)
print(winner)   # different every time!
```

### Shuffling a List — `random.shuffle()`
Mixes up the whole list in a random order:
```python
cards = ["Ace", "King", "Queen", "Jack"]
random.shuffle(cards)
print(cards)
# ["Queen", "Ace", "Jack", "King"]  ← random order every time!
```

### Random Floating Point Number — `random.random()`
Picks a random decimal number between 0 and 1:
```python
print(random.random())  # e.g. 0.7432...
```

---

## 🔗 Module 5 — Putting It All Together

### Combining Lists + Loops + Randomisation
```python
import random

students = ["Emma", "Liam", "Olivia", "Noah", "Sophia"]
students.append("Kenneth")   # add a new student

random.shuffle(students)     # mix everyone up

for student in students:     # loop through the list
    print(student)

winner = random.choice(students)  # pick one lucky winner!
print("The winner is: " + winner)
```

### Real-World Flow — Raffle Machine
```
1. Store names in a list
2. Append any late entries
3. Shuffle the list
4. Loop through and announce everyone
5. Pick a random winner
```

---

## 🔢 Intermediate Module 1 — `random.randint()`

### Concept
Picks a **random whole number** between two numbers — **including both ends**.

```python
import random

number = random.randint(1, 10)   # could be 1, 2, 3... all the way to 10
print(number)
```

### Semi-Open Range vs randint
| Function | Includes start? | Includes end? |
|---|---|---|
| `range(1, 5)` | Yes | No (stops at 4) |
| `random.randint(1, 5)` | Yes | Yes (can produce 5) |

> `range()` uses a **semi-open range** — it includes the start but excludes the end.

### Dice Roller Example
```python
import random

dice = random.randint(1, 6)
print("You rolled: " + str(dice))
```

> ⚠️ `str()` converts a number to text so you can join it with a string!

### Using `randint` to Pick a Random Index
```python
fruits = ["mango", "banana", "grape", "orange"]
random_index = random.randint(0, 3)
print(fruits[random_index])   # picks a random fruit!
```

### Lottery Number Generator
```python
import random

print("Your lottery numbers are:")
for i in range(5):
    number = random.randint(1, 50)
    print(number)
```

---

## 🍰 Intermediate Module 2 — List Slicing

### Concept
Grab a **specific chunk** of a list using `list[start:stop]`.

> ⚠️ The **stop** index is NOT included — think of it as a door you go up to but don't walk through!

```python
numbers = [10, 20, 30, 40, 50, 60, 70]
#            0   1   2   3   4   5   6

print(numbers[1:4])   # [20, 30, 40]
```

### Slicing Variations

```python
numbers = [10, 20, 30, 40, 50, 60, 70]

# Leave out start → grabs from the beginning
print(numbers[:3])    # [10, 20, 30]

# Leave out stop → grabs to the end
print(numbers[4:])    # [50, 60, 70]

# Negative index → counts from the back
print(numbers[-2:])   # [60, 70]
```

### Combining Slicing + Randomisation
```python
import random

numbers = [10, 20, 30, 40, 50, 60, 70, 80]
chunk = numbers[2:6]       # [30, 40, 50, 60]
random.shuffle(chunk)      # shuffled version of the chunk
print(chunk)
```

---

## ✨ Intermediate Module 3 — List Comprehensions

### Concept
A **list comprehension** builds a new list in just **one line** of code — a powerful shortcut!

**Normal way — 4 lines:**
```python
numbers = [1, 2, 3, 4, 5]
doubled = []
for number in numbers:
    doubled.append(number * 2)
```

**List comprehension — 1 line:**
```python
doubled = [number * 2 for number in numbers]
# [2, 4, 6, 8, 10]
```

### How to Read It
```python
new_list = [expression for item in old_list]
```
Read as: *"Give me `expression` for every `item` in `old_list`"*

### With a Condition — Filtering
```python
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# Only even numbers
evens = [number for number in numbers if number % 2 == 0]
# [2, 4, 6, 8, 10]

# Only odd numbers
odds = [number for number in numbers if number % 2 != 0]
# [1, 3, 5, 7, 9]
```

> `%` is the **modulo** operator — it gives the **remainder** after division.
> `2 == 0` means "equal to 0" | `!= 0` means "not equal to 0"

### Real Examples
```python
# Square every number
squared = [n * n for n in [1, 2, 3, 4, 5]]
# [1, 4, 9, 16, 25]

# Convert names to uppercase
names = ["emma", "liam", "olivia"]
upper = [name.upper() for name in names]
# ["EMMA", "LIAM", "OLIVIA"]

# Apply a 50% sale to prices
prices = [100, 200, 300, 400, 500]
sale = [price * 0.5 for price in prices]
# [50.0, 100.0, 150.0, 200.0, 250.0]

# Filter passing scores (above 50)
scores = [30, 55, 45, 70, 80, 25, 60]
passing = [score for score in scores if score > 50]
# [55, 70, 80, 60]
```

> ⚠️ `[score > 50 for score in scores]` gives `[True, False, True...]` — NOT the actual scores!
> Always put the **item name** before `for` if you want the actual values.

---

## 🎮 Applied — Rock Paper Scissors Walkthrough

### Full Code
```python
import random

rock = '''
    _______
---'   ____)
      (_____)
      (_____)
      (____)
---.__(___)
'''

paper = '''
    _______
---'   ____)____
          ______)
          _______)
         _______)
---.__________)
'''

scissors = '''
    _______
---'   ____)____
          ______)
       __________)
      (____)
---.__(___)
'''

game_images = [rock, paper, scissors]

welcome_message = "Welcome to the \"ROCK\", \"PAPER\", \"SCISSORS\" game.\n"
print(welcome_message)

user_choice = int(input("What do you choose? Type 0 for Rock, 1 for Paper or 2 for Scissors.\n"))
if user_choice >= 0 and user_choice <= 2:
    print(game_images[user_choice])

computer_choice = random.randint(0, 2)
print(f"Computer choose: ")
print(game_images[computer_choice])

if user_choice >= 3 or user_choice < 0:
    print("You lose! You type an invalid input")
elif user_choice == 0 and computer_choice == 2:
    print("You win!")
elif computer_choice == 0 and user_choice == 2:
    print("You lose!")
elif computer_choice > user_choice:
    print("You lose!")
elif user_choice > computer_choice:
    print("You Win!")
elif computer_choice == user_choice:
    print("It's a draw!")
```

### Key Concepts Used
| Line / Concept | What It Does |
|---|---|
| `import random` | Loads the random toolbox |
| `''' ... '''` | Triple quotes — stores multi-line text (ASCII art) |
| `game_images = [rock, paper, scissors]` | List storing the 3 pictures |
| `int(input(...))` | Asks for input and converts it to a number |
| `\"` | Escape character — puts a real `"` inside a string |
| `\n` | Escape character — creates a new line |
| `random.randint(0, 2)` | Computer picks 0, 1 or 2 randomly |
| `game_images[user_choice]` | Uses the number as an index to get the right picture |
| `f"Computer choose: "` | f-string — can embed variables inside strings |
| `if / elif` chain | Checks conditions one by one to find the winner |

### Logic Table
| Condition | Result |
|---|---|
| `user_choice >= 3 or user_choice < 0` | Invalid input → lose |
| `user_choice == 0 and computer_choice == 2` | Rock beats Scissors → win |
| `computer_choice == 0 and user_choice == 2` | Rock beats Scissors → lose |
| `computer_choice > user_choice` | Computer wins |
| `user_choice > computer_choice` | Player wins |
| `computer_choice == user_choice` | Draw |

### Known Bug
The computer still picks a random number even if the player types an invalid input (e.g. 99). Fix: move `computer_choice` logic inside the valid input block.

---

## 🗂️ Quick Reference Cheat Sheet

```python
import random

# --- LISTS ---
my_list = ["a", "b", "c"]       # create
my_list.append("d")              # add to end
my_list.insert(1, "x")          # add at index
my_list.remove("b")             # remove by name
my_list.pop(0)                  # remove by index
my_list[0] = "z"                # change item
len(my_list)                    # count items
my_list.sort()                  # sort
my_list.reverse()               # reverse

# --- SLICING ---
my_list[1:3]                    # index 1 up to (not including) 3
my_list[:2]                     # from beginning to index 2
my_list[2:]                     # from index 2 to end
my_list[-2:]                    # last 2 items

# --- LOOPS ---
for item in my_list:
    print(item)

# --- RANDOMISATION ---
random.choice(my_list)          # pick 1 random item
random.shuffle(my_list)         # shuffle in place
random.randint(1, 10)           # random whole number 1–10
random.random()                 # random decimal 0–1

# --- LIST COMPREHENSIONS ---
doubled = [x * 2 for x in my_list]
evens   = [x for x in my_list if x % 2 == 0]

# --- CONVERSIONS ---
str(42)                         # number → text
int("42")                       # text → number
```