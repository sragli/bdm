# BDM

Elixir module that implements the Block Decomposition Method (BDM).

For more details:
* Hector Zenil, Santiago Hernández-Orozco, Narsis A. Kiani, Fernando Soler-Toscano, Antonio Rueda-Toicen 2018 A Decomposition Method for Global Evaluation of Shannon Entropy and Local Estimations of Algorithmic Complexity. arXiv:1609.00110
* Hector Zenil, Narsis A. Kiani, Jesper Tegnr: Algorithmic Information Dynamics: A Computational Approach to Causality with Applications to Living Systems

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed by adding `bdm` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bdm, "~> 0.1.0"}
  ]
end
```

## Key Features

### Core BDM Implementation

* Supports both 1D (binary strings) and 2D (binary matrices) data
* Three boundary conditions: :ignore, :recursive, and :correlated
* Proper BDM formula implementation: CTM(block) + log₂(count)

### CTM Lookup Tables

* Precomputed CTM values for small binary strings and matrices
* Fallback mechanism for missing values (max CTM + 1 bit)

### Partitioning Strategies

* Ignore: Discards incomplete blocks
* Recursive: Recursively partitions remainder into smaller blocks
* Correlated: Uses sliding window approach

### Additional Features

* Block Entropy: For comparison with BDM complexity
* Perturbation Analysis: Identifies complexity-driving elements
* Normalization: Scales BDM values between 0 and 1

### Realistic Complexity Values

The CTM values follow the principle that:

* More structured/regular patterns have lower complexity
* More random/irregular patterns have higher complexity
* Larger patterns generally have higher base complexity

## Usage

```
# Create BDM instance - automatically includes all 2D CTM tables
bdm = BDM.new(2, 2)

# Test with different block sizes
large_matrix = [
  [0, 1, 0, 1, 0, 1],
  [1, 0, 1, 0, 1, 0],
  [0, 1, 0, 1, 0, 1],
  [1, 0, 1, 0, 1, 0],
  [0, 1, 0, 1, 0, 1],
  [1, 0, 1, 0, 1, 0]
]

# Now supports 2x2, 3x3, and 4x4 block decomposition
complexity_2x2 = BDM.compute(bdm, large_matrix, 2, :ignore)
complexity_3x3 = BDM.compute(bdm, large_matrix, 3, :ignore)
complexity_4x4 = BDM.compute(bdm, large_matrix, 4, :ignore)
```

## How BDM Works

The Block Decomposition Method operates in three main stages: decomposition, lookup, and aggregation.

### Foundation: Coding Theorem Method (CTM)

BDM builds upon the Coding Theorem Method (CTM), which approximates algorithmic complexity using this formula:

K(s) ≈ -log₂(P(s))

where P(s) is the algorithmic probability of string s. CTM approximates algorithmic probability by exploring spaces of Turing machines with n symbols and m states, counting how many produce a given output, and dividing by the total number of machines that halt.

### The BDM Process

Step 1: Precomputation
First precompute CTM values for all possible small objects of a given type (e.g. all binary strings of up to 12 digits or all possible square binary matrices up to 4x4) and store them in an efficient lookup table.

Step 2: Decomposition
Any arbitrarily large object can be decomposed into smaller slices of appropriate sizes for which CTM values can be looked up very fast. The method partitions the input data into blocks of predetermined sizes.

Step 3: Lookup
For each unique slice created during decomposition, the method looks up the precomputed CTM value from the lookup table.

Step 4: Aggregation
The CTM values for slices can be aggregated back to a global estimate of Kolmogorov complexity for the entire object using the BDM formula:

BDM(X) = Σᵢ CTM(sᵢ) + log₂(nᵢ)

where:

* i indexes the set of all unique slices
* CTM(sᵢ) is the complexity of slice i
* nᵢ is the number of occurrences of slice i

### Boundary Conditions

When data cannot be perfectly divided into equal-sized blocks, BDM handles three boundary conditions:

* Ignore: Malformed parts are ignored
* Recursive: Slice malformed parts into smaller pieces (down to some minimum size) and lookup CTM values for those smaller pieces
* Correlated: Use sliding window instead of slicing. This way all slices will be of the proper shape

### Key Advantages

* Computational Efficiency: Instead of computing CTM for each large dataset (which is extremely expensive), BDM uses precomputed values for small blocks
* Scalability: Can handle arbitrarily large datasets by decomposing them into manageable pieces
* Practical Approximation: Provides a computable approximation to the theoretically uncomputable Kolmogorov complexity

The method essentially transforms an intractable global computation into a series of fast local lookups, making algorithmic complexity estimation practical for real-world datasets.

