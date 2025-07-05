"""
BDM for binary sequences
"""

import numpy as np
from pybdm import BDM

# Create a dataset (must be of integer type)
X = np.array([
    [0, 1, 0, 1, 0, 1],
    [1, 0, 1, 0, 1, 0],
    [0, 1, 0, 1, 0, 1],
    [1, 0, 1, 0, 1, 0],
    [0, 1, 0, 1, 0, 1],
    [1, 0, 1, 0, 1, 0]
], dtype=int)
print(X)

# Initialize BDM object
# ndim argument specifies dimensionality of BDM
bdm = BDM(ndim=2)

# Compute BDM
print("BDM:", bdm.bdm(X))
print("Normalized BDM:", bdm.nbdm(X))
