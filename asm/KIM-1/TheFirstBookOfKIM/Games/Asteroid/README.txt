ASTEROID
BY STAN OCKERS

YOU ARE PILOTING YOUR SPACECRAFT BETWEEN MARS AND JUPITER WHEN
YOU ENCOUNTER A DENSE PORTION OF THE ASTEROID BELT. PRESS KEY
ZERO TO MOVE LEFT, THREE TO MOVE RIGHT. WHEN YOUR CRAFT IS HIT
THE DISPLAY WILL GIVE A NUMBER TO INDICATE HOW SUCESSFUL YOU
WERE. THE PROGRAM STARTS AT 0200.

CHANGES -
YOU CAN MAKE YOUR OWN ASTEROID FIELD STARTING AT 02D5. THE
GROUP COUNT,(C02B6), WILL HAVE TO BE CHANGED IF THE FIELD SIZE
DIFFERS. THE SPEED OF THE CRAFT MOVING THROUGH THE FIELD IS
CONTROLLED BY 027E. WHAT ABOUT A VARYING SPEED, SLOW AT FIRST
AND SPEEDING UP AS YOU GET INTO THE FIELD? WHAT ABOUT A FINAL
"DESTINATION COUNT" AND A SIGNAL TO INDICATE YOU HAVE REACHED
YOUR DESTINATION? HOW ABOUT ALLOWING A HIT OR TWO BEFORE YOU
ARE FINALLY DISABLED?


Note from User Agrucho on YouTube:

The program doesn't work on some KIM-1 replicas and emulators. I found
the problem. The replicas and emulators only have the RIOT 3, Asteroid
was written to use the RIOT 2 timer. I modified the code to use the
RIOT 3 timer, all good now, thanks. To use RIOT 3 Timer instead of
RIOT 2 timer: change at 0280 from 06 to 46; change at 0283 from 07 to
47.
