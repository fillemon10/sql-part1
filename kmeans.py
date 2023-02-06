import pandas
import numpy as np
from sklearn.linear_model import LinearRegression
import matplotlib.pyplot as plt

def scatter():
    # reading the csv file
    d3 = pandas.read_csv("data_assignment3.csv")

    yValues = d3['phi']
    xValues = d3['psi']

    #plot the data
    plt.scatter(x=xValues, y=yValues, s=1)
    plt.title("phi vs. psi")
    plt.xlabel("phi (degrees)")
    plt.ylabel("psi (degrees)")
    plt.show()
    plt.title("phi vs. psi")
    plt.xlabel("phi (degrees)")
    plt.ylabel("psi (degrees)")
    plt.hist2d(x=xValues, y=yValues, bins=300)
    plt.show()



# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    scatter()

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
