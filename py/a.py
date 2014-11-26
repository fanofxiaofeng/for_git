s1 = "I'm from China"
s2 = "I am from here, I don't know lala."
s1 = s1.lower()
s2 = s2.lower()
print s1
print s2

data = [[0 for c in range(len(s2) + 1)] for r in range(len(s1) + 1)]
# print data

for r in range(len(data)):
	for c in range(len(data[0])):
		if r == 0 or c == 0:
			data[r][c] = 0
		else:
			if s1[r - 1] == s2[c - 1]:
				data[r][c] = data[r - 1][c - 1] + 1
			else:
				data[r][c] = max(data[r - 1][c], data[r][c - 1])

ans = []
row = len(s1)
col = len(s2)
value = data[row][col]
while value:
	if s1[row - 1] == s2[col - 1]:
		ans.append((row, col))
		row -= 1
		col -= 1
		value -= 1
	else:
		if data[row - 1][col] >= data[row][col - 1]:
			row -= 1
		else:
			col -= 1
# print ans

ans = ans[::-1]
print ans


a = map(lambda x: x[0], ans)
b = map(lambda x: x[1], ans)

print a, b

print s1
sa = [' ' for i in s1]
for i in a:
	sa[i - 1] = '-'
print ''.join(sa)
saa = [' ' for i in s1]
cnt = 0
for i in a:
	cnt += 1
	saa[i - 1] = str(cnt % 10)
print ''.join(saa)

sb = [' ' for i in s2]
for i in b:
	sb[i - 1] = '-'
print s2
print ''.join(sb)

sbb = [' ' for i in s2]
cnt = 0
for i in b:
	cnt += 1
	sbb[i - 1] = str(cnt % 10)
print ''.join(sbb)
