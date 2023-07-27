import matplotlib.pyplot as plt

x = [1, 2, 3, 4, 5]
y = [10, 20, 30, 40, 50]

plt.plot(x, y)

plt.gca().set_aspect('equal')  # Set aspect ratio to be equal

plt.xlabel("X-axis")
plt.ylabel("Y-axis")
plt.grid(True)
plt.savefig('test.png')
