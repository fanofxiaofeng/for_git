import random
f = open('numbers.txt', 'w')
for i in range(20):
	f.write(str(random.randrange(100)) + '\n')	
f.close()
	
