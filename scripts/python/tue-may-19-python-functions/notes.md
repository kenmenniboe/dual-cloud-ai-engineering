# 📓 Python Functions — Detailed Notes

**Date:** Tuesday, May 19, 2026
**Level:** Fundamentals → Intermediate
**Tutor:** Claude (Anthropic)

---

## 📦 Module 01 — What Is a Function?

### Concept
A function is a reusable block of code. You build it once and call it as many times as you need.

### My Analogy 🎂
> *"A function is like baking — you write down the name (define), write the recipe (code), then bake it (call it)."*

### Two Key Moments

| Moment | What it does |
|---|---|
| **Define** | Saves the instructions — nothing runs yet |
| **Call** | Actually runs the instructions |

### Syntax
```python
# Step 1: DEFINE the function
def bake_cake():
    print("Ingredients go in...")
    print("Cake comes out! Yum!")

# Step 2: CALL the function
bake_cake()
```

### Output
```
Ingredients go in...
Cake comes out! Yum!
```

### Key Rule
- `def` is the keyword that tells Python you are defining a function.
- Nothing runs until you **call** the function.
- You can call the same function as many times as you want.

---

## 📦 Module 02 — Parameters, Arguments & F-strings

### Concept
A **parameter** is a blank slot in the function definition.
An **argument** is the actual value you fill that slot with when calling the function.

### My Analogy
> *"The parameter is the blank in the recipe. The argument is what you write in that blank."*

### Syntax
```python
# "flavor" is the PARAMETER — the blank slot
def bake_cake(flavor):
    print(f"Baking a {flavor} cake!")

# "chocolate" is the ARGUMENT — fills the blank
bake_cake("chocolate")
bake_cake("vanilla")
```

### Output
```
Baking a chocolate cake!
Baking a vanilla cake!
```

### F-strings
An f-string is a cleaner way to insert variables into a string.

| Method | Code |
|---|---|
| Concatenation | `"Baking a " + flavor + " cake!"` |
| F-string | `f"Baking a {flavor} cake!"` |

- The `f` before the quote tells Python: *"this string has variables in it"*
- The `{}` tells Python: *"look up this variable and insert its value here"*

### Quiz Code I Wrote
```python
def greet_person(name):
    print(f"Hello {name}!")

greet_person("Kenneth")
```

### Output
```
Hello Kenneth!
```

---

## 📦 Module 03 — Returning Values

### Concept
`print` shows a value and **forgets it**. `return` **hands the value back** to whoever called the function so it can be stored and used later.

### My Words
> *"print prints out and forgets it. return holds the value and gives it back to whoever calls it."*

### Key Difference

```python
# print — shows and forgets
def bake_cake(flavor):
    print(f"A {flavor} cake!")

# return — hands back the value
def bake_cake(flavor):
    return f"A delicious {flavor} cake!"
```

### Catching a Return Value
```python
def make_sandwich(filling):
    return f"Here is your {filling} sandwich."

my_sandwich = make_sandwich("Chicken")
print(my_sandwich)
```

### Output
```
Here is your Chicken sandwich.
```

### Important Rule
If you don't **catch** the return value in a variable, it disappears!
```python
# return hands it back but nobody catches it — disappears
make_sandwich("Chicken")

# Caught and stored
my_sandwich = make_sandwich("Chicken")
```

---

## 📦 Module 04 — Default Parameters

### Concept
A default parameter is a **backup value** used when no argument is provided.

### Syntax
```python
def make_sandwich(filling="cheese", bread="white"):
    return f"Here is your {filling} sandwich on {bread} bread!"
```

### Three Ways to Call It
```python
# No arguments — both defaults used
print(make_sandwich())

# One argument — filling changes, bread uses default
print(make_sandwich("chicken"))

# Both arguments — no defaults needed
print(make_sandwich("chicken", "brown"))
```

### Output
```
Here is your cheese sandwich on white bread!
Here is your chicken sandwich on white bread!
Here is your chicken sandwich on brown bread!
```

### Key Rule
Arguments fill parameters **left to right** by position. Python only uses a default when no argument is provided for that specific parameter.

### Quiz Code I Wrote
```python
def order_coffee(size="medium", type="latte"):
    return f"Here is your {size} {type} coffee!"

my_coffee = order_coffee()
print(my_coffee)

your_coffee = order_coffee("large")
print(your_coffee)

their_coffee = order_coffee("small", "espresso")
print(their_coffee)
```

### Output
```
Here is your medium latte coffee!
Here is your large latte coffee!
Here is your small espresso coffee!
```

---

## 📦 Module 05 — Multiple Return Values

### Concept
A function can return more than one value. Python automatically bundles them into a **tuple**.

### Three Ways to Work With Multiple Return Values

```python
def sandwich_order(filling, bread):
    sandwich = f"A {filling} sandwich on {bread} bread"
    drink = "Orange juice 🍊"
    receipt = "That will be $5.00"
    return sandwich, drink, receipt
```

```python
# 1. Bundle everything — returns a tuple
my_order = sandwich_order("chicken", "brown")
print(my_order)
# ('A chicken sandwich on brown bread', 'Orange juice 🍊', 'That will be $5.00')

# 2. Index into the tuple
print(my_order[0])  # A chicken sandwich on brown bread
print(my_order[1])  # Orange juice 🍊
print(my_order[2])  # That will be $5.00

# 3. Catch each value separately
sandwich, drink, receipt = sandwich_order("chicken", "brown")
```

### Quiz Code I Wrote
```python
def get_weather(city):
    the_city = f"City: {city}"
    temp = f"Temperature: 72 F ⛅️"
    the_conditions = f"Conditions: Sunny ☀️"
    return the_city, temp, the_conditions

place = get_weather("New York")
print(place[0])
print(place[1])
print(place[2])
```

### Output
```
City: New York
Temperature: 72 F ⛅️
Conditions: Sunny ☀️
```

---

## 📦 Module 06 — `*args` (Variable Positional Arguments)

### Concept
`*args` lets a function accept **any number of arguments**. Python bundles them into a **tuple**.

### The `*` Is What Matters
The name `args` is just a convention — you can name it anything. It's the `*` that tells Python to bundle arguments into a tuple.

### Syntax
```python
def grocery_list(*items):
    return items

my_list = grocery_list("milk", "eggs", "bread", "butter")
print(my_list)
```

### Output
```
('milk', 'eggs', 'bread', 'butter')
```

### Indexing `*args`
```python
print(my_list[0])    # milk — first item
print(my_list[-1])   # butter — last item (works for ANY length!)
```

### Key Lesson — Using `items[-1]`
`items[-1]` always gives the **last item** no matter how many arguments were passed. This is better than hardcoding `items[3]` which only works for exactly 4 items.

### Indexing Inside an F-string
```python
def make_sandwich(*toppings):
    return f"Here's your sandwich with the {toppings[0]} toppings"

your_sandwich = make_sandwich("cheese", "lettuce", "tomato")
print(your_sandwich)
```

### Output
```
Here's your sandwich with the cheese toppings
```

### Quiz Code I Wrote
```python
def grocery_list(*items):
    return f"I will go grocery shopping for two items: {items[0]} and {items[-1]}"

my_list = grocery_list("milk", "eggs", "bread", "butter")
print(my_list)
```

### Output
```
I will go grocery shopping for two items: milk and butter
```

---

## 📦 Module 07 — `**kwargs` (Keyword Arguments)

### Concept
`**kwargs` lets a function accept **any number of keyword arguments**. Python bundles them into a **dictionary** of key-value pairs.

### `*args` vs `**kwargs`

| | Symbol | Bundles into | Example |
|---|---|---|---|
| `*args` | Single `*` | Tuple `()` | `('cheese', 'lettuce')` |
| `**kwargs` | Double `**` | Dictionary `{}` | `{'cheese': 'extra'}` |

### Syntax
```python
def make_sandwich(**toppings):
    print(toppings)

make_sandwich(cheese="extra", lettuce="light", tomato="no")
```

### Output
```
{'cheese': 'extra', 'lettuce': 'light', 'tomato': 'no'}
```

### Accessing Values by Key
```python
def order_coffee(**items):
    return f'Your Coffee: {items["size"]}, Type: {items["type"]}'

your_order = order_coffee(size="Large", type="Espresso")
print(your_order)
```

### Output
```
Your Coffee: Large, Type: Espresso
```

### Key Rule
The `**` is what matters — not the name `kwargs`. You can name the parameter anything.

### Quiz Code I Wrote
```python
def book_hotel(**kwargs):
    return f"Your hotel booking is for: {kwargs['city']}, {kwargs['nights']} nights, {kwargs['room_type']} room."

your_booking = book_hotel(city="Paris", nights=3, room_type="Deluxe")
print(your_booking)
```

### Output
```
Your hotel booking is for: Paris, 3 nights, Deluxe room.
```

---

## 📦 Module 08 — Scope (Local vs Global Variables)

### Concept
**Scope** determines where a variable can be accessed.

| Type | Lives | Accessible |
|---|---|---|
| **Local** | Inside the function | Only inside that function |
| **Global** | Outside all functions | Anywhere in the code |

### My Analogy 🏠
> *"Local variables are like bedroom furniture — nobody outside can use them. Global variables are like a park bench — anyone can use them."*

### Reading a Global Variable ✅
```python
name = "Kenneth"  # Global

def greet():
    print(f"Hello {name}!")  # Can read global variable

greet()
```

### Trying to Change a Global Without `global` Keyword ❌
```python
counter = 0

def add_one():
    counter = counter + 1  # ERROR! UnboundLocalError

add_one()
```

### Changing a Global With `global` Keyword ✅
```python
counter = 0

def add_one():
    global counter  # Tell Python to use the OUTSIDE counter
    counter = counter + 1

add_one()
print(counter)  # 1
```

### Accessing a Local Variable Outside — Error ❌
```python
def travel():
    hotel = "Ritz"  # Local variable

travel()
print(hotel)  # NameError: name 'hotel' is not defined
```

### Quiz Code I Wrote
```python
visits = 0

def count_visits():
    global visits
    visits += 1
    print(f"{visits}")

count_visits()
print(visits)
count_visits()
print(visits)
count_visits()
print(visits)
```

### Output
```
1
1
2
2
3
3
```

---

## 📦 Module 09 — Lambda Functions

### Concept
A lambda is a **one-line function**. No `def`, no `return` — it returns the expression automatically.

### Syntax Breakdown

```
lambda parameters: expression
```

| Part | Meaning |
|---|---|
| `lambda` | One-line function keyword |
| `parameters` | What gets passed in |
| `expression` | What it does (returned automatically) |

### Regular Function vs Lambda

```python
# Regular function
def add_numbers(x, y):
    return x + y

# Lambda — same thing, one line
add_numbers = lambda x, y: x + y
```

### When to Use Lambda vs Regular Function

| Use **lambda** when | Use **regular function** when |
|---|---|
| Simple one-line job | Multiple steps needed |
| Used once or inline | Reused many times |
| No complex logic | Needs loops or conditions |

### Storing and Calling a Lambda
```python
greet = lambda name: f"Hello {name}!"
print(greet("Kenneth"))
```

### Output
```
Hello Kenneth!
```

### Passing Lambda Inline
```python
# Instead of naming it, pass it directly
print(process_name("Kenneth", lambda text: text.upper()))
```

### Quiz Code I Wrote
```python
average_numbers = lambda a, b: (a + b) / 2
print(average_numbers(10, 20))
```

### Output
```
15.0
```

### Discount Lambda I Built
```python
discount_price = lambda price, discount: price - discount / 100 * price

final_price = discount_price(100, 10)
print(final_price)
```

### Output
```
90.0
```

---

## 📦 Module 10 — Higher-Order Functions

### Concept
A **higher-order function** is a function that **accepts another function as an argument**.

### Key Insight
In Python, functions can be:
- Stored in variables
- Passed as arguments
- Called inside other functions

### Passing a Named Function
```python
def shout(text):
    return text.upper()

def greet(name, formatter):
    return formatter(f"hello {name}")

print(greet("Kenneth", shout))
```

### Output
```
HELLO KENNETH
```

### Important — No Parentheses When Passing!

| Code | What Python does |
|---|---|
| `greet("Kenneth", shout)` | Passes the function itself ✅ |
| `greet("Kenneth", shout())` | Runs `shout()` immediately ❌ |

### Passing a Lambda Instead
```python
print(greet("Kenneth", lambda text: text + "!"))
```

### Output
```
hello Kenneth!
```

### Power of Higher-Order Functions
Same function, different results depending on what you pass in:

```python
print(process_name("Kenneth", lambda text: text.upper()))  # KENNETH
print(process_name("Kenneth", lambda text: text + " is awesome!"))  # Kenneth is awesome!
```

### Quiz Code I Wrote
```python
def my_quiz(text):
    return text.upper()

def process_name(name, formatter):
    return formatter(f"{name}")

print(process_name("Kenneth", my_quiz))
print(process_name("Kenneth", lambda text: text + " " + "is awesome!"))
```

### Output
```
KENNETH
Kenneth is awesome!
```

---

## 🔄 Bonus — For Loops Inside Functions

### Example 1: Shopping Bill with Discount 🛒
```python
def total_bill(*prices):
    total = 0
    for price in prices:
        total += price
    discount = total * 10 / 100
    total -= discount
    return f"Your total is: ${total:.2f}"

print(total_bill(5.99, 3.50, 2.25))
```

### Output
```
Your total is: $10.57
```

**Key lessons:**
- `total = 0` is the starting point — like a register before scanning
- `+=` is shorthand for `total = total + price`
- Discount goes **outside** the loop so it applies only once
- `:.2f` formats a float to 2 decimal places

### Example 2: Greeting Party Guests 🎉
```python
def greet_guests(*guests):
    for guest in guests:
        if guest == guests[0]:
            print(f"Welcome VIP {guest}! 🌟")
        else:
            print(f"Welcome {guest}!")

greet_guests("Kenneth", "John", "Mary")
```

### Output
```
Welcome VIP Kenneth! 🌟
Welcome John!
Welcome Mary!
```

**Key lessons:**
- `guests[0]` inside the loop accesses the first item in the tuple
- `if guest == guests[0]` checks if the current guest is the first one

### Example 3: Hotel Booking Summary 🏨
```python
def booking_summary(**details):
    total_price = 0
    price_per_night = 150
    for key, value in details.items():
        if key == "nights":
            total_price += value * price_per_night
        print(f"{key}: {value}")
    print(f"Total price: ${total_price:.2f}")

booking_summary(city="Paris", nights=3, room="Deluxe")
```

### Output
```
city: Paris
nights: 3
room: Deluxe
Total price: $450.00
```

**Key lessons:**
- `.items()` breaks the dictionary into key-value pairs
- `for key, value` unpacks each pair
- The `if key == "nights"` finds the specific key to calculate with

---

## ⏱️ Bonus — While Loops Inside Functions

### Key Difference from For Loops

| | `for` loop | `while` loop |
|---|---|---|
| Runs through | A **collection** of items | A **condition** |
| Stops when | Collection runs out | Condition becomes false |
| Risk | None | Infinite loop if condition never changes |

### Example 1: Countdown Timer 🚀
```python
def countdown_timer(start):
    while start > 0:
        print(f"Countdown: {start}")
        start -= 1
    print("Blast off! 🚀")

countdown_timer(5)
```

### Output
```
Countdown: 5
Countdown: 4
Countdown: 3
Countdown: 2
Countdown: 1
Blast off! 🚀
```

### Example 2: Finding an Item in a List 🛒
```python
def find_item(grocery_list, item):
    index = 0
    while index < len(grocery_list):
        if grocery_list[index] == item:
            return f"Found {item}! ✅"
        index += 1
    return f"{item} not in the list! ❌"

print(find_item(["milk", "eggs", "bread", "butter"], "eggs"))
print(find_item(["milk", "eggs", "bread", "butter"], "cheese"))
```

### Output
```
Found eggs! ✅
cheese not in the list! ❌
```

**Key lessons:**
- `return` inside the loop stops the function immediately when item is found
- The **outside** `return` only fires if the loop finishes without finding anything
- `index += 1` prevents an infinite loop by advancing through the list

---

## 🧠 Key Vocabulary Reference

| Term | Definition |
|---|---|
| `def` | Keyword to define a function |
| **Parameter** | The blank slot in a function definition |
| **Argument** | The actual value passed into a function |
| **Return** | Hands a value back to the caller |
| `*args` | Bundles unlimited arguments into a tuple |
| `**kwargs` | Bundles keyword arguments into a dictionary |
| **Local variable** | Lives inside a function only |
| **Global variable** | Lives outside functions, accessible anywhere |
| `global` keyword | Tells Python to use the outside global variable |
| **Lambda** | A one-line anonymous function |
| **Higher-order function** | A function that accepts another function as an argument |
| `:.2f` | Formats a float to 2 decimal places in an f-string |
| `.items()` | Returns key-value pairs from a dictionary |
| `.upper()` | Converts a string to uppercase |
| `.lower()` | Converts a string to lowercase |
| `+=` | Shorthand for `x = x + something` |
| `-=` | Shorthand for `x = x - something` |