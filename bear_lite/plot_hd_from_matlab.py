"""
plot_hd_from_matlab.py
======================
Load the HD results exported by run_hd.m and produce the stacked-bar
contribution plot using the existing plot_hd() function from bvar_hd_plot.py.

Usage (from the bear_lite directory):
    python plot_hd_from_matlab.py
"""

import pandas as pd
import matplotlib.pyplot as plt
from bvar_hd_plot import plot_hd

# ── configuration ──────────────────────────────────────────────────────────
HD_CSV     = "hd_results.csv"       # exported by run_hd.m (same directory)
TARGET_VAR = "ch_food_cpi"          # must match target_var in run_hd.m
OUTPUT_PNG = "hd_from_matlab.png"
TITLE      = f"Historical decomposition – {TARGET_VAR}"
# Optional: restrict the date range shown in the plot (set to None = all dates)
START_DATE = None   # e.g. "2015-01-01"
END_DATE   = None

# ── load ───────────────────────────────────────────────────────────────────
hd = pd.read_csv(HD_CSV, index_col=0, parse_dates=True)

# ── reshape to match plot_hd() convention ──────────────────────────────────
# The own-shock column (TARGET_VAR's self-contribution) is merged into
# "Unexplained", matching the convention in estimate_bvar() / plot_hd().
# The remaining n-1 columns are named exogenous shock contributions.
hd["Unexplained"] = hd[TARGET_VAR]
hd = hd.drop(columns=[TARGET_VAR])

# ── plot ───────────────────────────────────────────────────────────────────
fig = plot_hd(
    hd=hd,
    output_path=OUTPUT_PNG,
    start_date=START_DATE,
    end_date=END_DATE,
    title=TITLE,
)
plt.show()
