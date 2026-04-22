island_image = '''___________________________________________________|
 / \-----     ---------  -----------     -------------- ------    ---|
 \_/_________________________________________________________________|
 |~ ~~ ~~~ ~ ~ ~~~ ~ _____.----------._ ~~~  ~~~~ ~~   ~~  ~~~~~ ~~~~|
 |  _   ~~ ~~ __,---'_       "         `. ~~~ _,--.  ~~~~ __,---.  ~~|
 | | \___ ~~ /      ( )   "          "   `-.,' (') \~~ ~ (  / _\ \~~ |
 |  \    \__/_   __(( _)_      (    "   "     (_\_) \___~ `-.___,'  ~|
 |~~ \     (  )_(__)_|( ))  "   ))          "   |    "  \ ~~ ~~~ _ ~~|
 |  ~ \__ (( _( (  ))  ) _)    ((     \//    " |   "    \_____,' | ~|
 |~~ ~   \  ( ))(_)(_)_)|  "    ))    //\ " __,---._  "  "   "  /~~~|
 |    ~~~ |(_ _)| | |   |   "  (   "      ,-'~~~ ~~~ `-.   ___  /~ ~ |
 | ~~     |  |  |   |   _,--- ,--. _  "  (~~  ~~~~  ~~~ ) /___\ \~~ ~|
 |  ~ ~~ /   |      _,----._,'`--'\.`-._  `._~~_~__~_,-'  |H__|  \ ~~|
 |~~    / "     _,-' / `\ ,' / _'  \`.---.._          __        " \~ |
 | ~~~ / /   .-' , / ' _,'_  -  _ '- _`._ `.`-._    _/- `--.   " " \~|
 |  ~ / / _-- `---,~.-' __   --  _,---.  `-._   _,-'- / ` \ \_   " |~|
 | ~ | | -- _    /~/  `-_- _  _,' '  \ \_`-._,-'  / --   \  - \_   / |
 |~~ | \ -      /~~| "     ,-'_ /-  `_ ._`._`-...._____...._,--'  /~~|
 | ~~\  \_ /   /~~/    ___  `---  ---  - - ' ,--.     ___        |~ ~|
 |~   \      ,'~~|  " (o o)   "         " " |~~~ \_,-' ~ `.     ,'~~ |
 | ~~ ~|__,-'~~~~~\    \ /      "  "   "    /~ ~~   O ~ ~~`-.__/~ ~~~|
 |~~~ ~~~  ~~~~~~~~`.______________________/ ~~~    |   ~~~ ~~ ~ ~~~~|
 |____~jrei~__~_______~~_~____~~_____~~___~_~~___~\_|_/ ~_____~___~__|
 / \----- ----- ------------  ------- ----- -------  --------  -------
 \_/__________________________________________________________________/
\n'''
print(island_image)

wel_message = "Welcome to the great magical Treasure Island!\n"
print(wel_message)

mission_statment = "On this magical Treasure Island, your goal is to find the hidden mystery treasure.\n"
print(mission_statment)

choice1 = input('Now your journey begins, you\'re at a crossroad, where do you want to go?\n           Type "left" or "right"\n').lower()

if choice1 == "left":
    choice2 = input("Good choice, you've made to a lake and there isn't a boat. Type 'swim' to get across or 'wait' to wait for a boat.\n").lower()
    if choice2 == "wait":
        choice3 = input("Good job! You've arrived at the island umharmed. There is a house with three doors, 'RED', 'YELLOW', and 'BLUE'. You will need to choice a color, which color do you choice?\n").lower()
        if choice3 == "red":
            print("You've entered a room full of fire. Game Over!")
        elif choice3 == "yellow":
            print("Yov've entered a room of beast. Game Over!")
        elif choice3 == "blue":
            print("Excellent choice!!! You found the mestery treasure, 'YOU WIM'")
    else:
        print("You got attacked by an angry trout. Game Over!")        

else:
    print("You got lost, better luck next time. Game Over!")