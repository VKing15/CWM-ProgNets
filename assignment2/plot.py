# !/usr/bin/python3
import numpy as np
import matplotlib.pyplot as plt

# parameters to modify
filename="iperf3_1.log"
label1='Bandwidth of iperf3'
#label2='Bandwidth of Raspberry Pi to Lab Machine (t=10, i=1)'
xlabel = 'Time/s'
ylabel = 'Bandwidth/(kB/s)'
title='Bandwidth of iperf3'
fig_name='iperf3_1.png'
bins=10000 #adjust the number of bins to your plot


t = np.loadtxt(filename, delimiter=" ", dtype="float")

#plt.plot(t[:,0], t[:,1], label=label1)  # Plot some data on the (implicit) axes.
#plt.plot(t[:,0], t[:,2], label=label2)  # Plot some data on the (implicit) axes.
#Comment the line above and uncomment the line below to plot a CDF
plt.hist(t[:,1], bins, density=True, histtype='step', cumulative=True, label=label1)
plt.xlabel(xlabel)
plt.ylabel(ylabel)
plt.title(title)
plt.legend()
plt.savefig(fig_name)
plt.show()
