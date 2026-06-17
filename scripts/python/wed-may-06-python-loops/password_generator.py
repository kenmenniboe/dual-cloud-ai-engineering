import random


letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
symbols = ['!', '#', '$', '%', '&', '(', ')', '*', '+']

print("Welcome to the PyPassword Generator!\n")
number_of_letters = int(input("How many letters would you like in your password?\n"))
number_of_symbols = int(input(f"How many symbols would you like?\n"))
number_of_numbers = int(input(f"How many numbers would you like?\n"))

# Easy Level

# password = ""

# for character in range(0, number_of_letters):  # In this case we assume the number of letters = 4
#     password += random.choice(letters) # This will give us a random chioce from 1 - 4

# for character in range(0, number_of_symbols):  # In this case we assume the number of symbols = 4
#     password += random.choice(symbols) # This will give us a random chioce from 1 - 4

# for character in range(0, number_of_numbers):  # In this case we assume the number of numbers = 4
#     password += random.choice(numbers) # This will give us a random chioce from 1 - 4
     
# print(password)

# Hard Mode

new_password = []

for character in range(0, number_of_letters):  # In this case we assume the number of letters = 4
    new_password.append(random.choice(letters)) # This will give us a random chioce from 1 - 4

for character in range(0, number_of_symbols):  # In this case we assume the number of symbols = 4
    new_password.append(random.choice(symbols)) # This will give us a random chioce from 1 - 4

for character in range(0, number_of_numbers):  # In this case we assume the number of numbers = 4
    new_password.append(random.choice(numbers)) # This will give us a random chioce from 1 - 4


print(new_password)

random.shuffle(new_password) # This will allow us to shuffle the characters in our new list

str_password = "".join(map(str, new_password)) # this also allow us to convert list of numbers to string

password = f"Your secure password is: {str_password}"
print(password)

