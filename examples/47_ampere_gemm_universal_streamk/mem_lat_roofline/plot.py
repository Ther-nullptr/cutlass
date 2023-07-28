import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('mem_lat_roofline.csv') 

x = df['OutstandingRequests(B)']
y = df['Bandwidth(GB/s)']

plt.xscale('log') 
plt.yscale('log')
plt.scatter(x, y, color='blue', marker='o')
plt.hlines(y=1400, xmin=min(x), xmax=max(x), colors='red', linestyles='-')
plt.text(x=1024, y=1500, s='Peak Bandwidth')
plt.plot(x, x/700, 'r-', linewidth=2, label='Latency Bound')
plt.legend()

for i, txt in enumerate(x):
    plt.annotate(txt, (x[i], y[i]))

plt.xlabel('Outstanding Requests (B)')
plt.ylabel('Bandwidth (GB/s)')
plt.title('Roofline Diagram')

plt.savefig('mem_lat_roofline.png')