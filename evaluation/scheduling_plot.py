import json
import sys
from pathlib import Path
from collections import defaultdict

import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import StrMethodFormatter
import seaborn as sns
import scienceplots

RESULTS_DIR = "../results"
WFCOMMONS_DIR = "../../wfcommons/generated_workflows"

SAVE = True

WF = "Workflow"
SA = "Scheduling Approach"
RN = "Run Number"
RMRR = "RankMin-RR"

TRIPS = [
    # ("Synthetic_Genome", "rankminrr/3", "benchmark_tarema/2"),
    ("Synthetic_Montage", "rankminrr/3", "benchmark_tarema/2"),
]


def sa(path: str) -> str:
    if path.startswith("rankminrr"):
        return RMRR
    elif path.startswith("benchmark_tarema"):
        return "Benchmark Tarema"
    elif path.startswith("online_tarema"):
        return "Online Tarema"
    else:
        return None


ND = "Node"
TSK = "Abstract Task"
CPU = "CPU Work per Core"


def main() -> None:
    global SAVE
    SAVE = input("Save plots? (y/n) ") == "y"
    plt.style.use("science")
    plt.rcParams["font.size"] = 12

    for wf, first, second in TRIPS:
        cpu_work_df = pd.read_csv(f"{WFCOMMONS_DIR}/{wf}/data.csv")
        intervals = {
            task: (
                cpu_work_df[cpu_work_df[TSK] == task][CPU].min(),
                cpu_work_df[cpu_work_df[TSK] == task][CPU].mean(),
                cpu_work_df[cpu_work_df[TSK] == task][CPU].max()
            )
            for task in cpu_work_df[TSK].unique()
        }

        complete_df = pd.DataFrame(columns=[WF, SA, ND, TSK, "mn", "mx", "avg"])

        first_df = pd.read_csv(f"{RESULTS_DIR}/{wf}/{first}/trace.csv")
        for i, row in first_df.iterrows():
            task = row["process"].replace("task_", "", 1)
            complete_df.loc[len(complete_df)] = [wf, sa(first), row["hostname"].replace("hu-worker-", ""),
                                                 task, *intervals[task]]
        second_df = pd.read_csv(f"{RESULTS_DIR}/{wf}/{second}/trace.csv")
        for i, row in second_df.iterrows():
            task = row["process"].replace("task_", "", 1)
            complete_df.loc[len(complete_df)] = [wf, sa(second), row["hostname"].replace("hu-worker-", ""),
                                                 task, *intervals[task]]

        print(complete_df.head())

        fig, ax = plt.subplots(2, 1, figsize=(10, 10))
        first_subdf = complete_df[complete_df[SA] == sa(first)]
        print(first_subdf.head())
        sns.histplot(data=first_subdf, x="avg", multiple="fill", hue=ND, hue_order=["c29", "c40", "c23", "c43"], ax=ax[0])
        second_subdf = complete_df[complete_df[SA] == sa(second)]
        print(second_subdf.head())
        sns.histplot(data=second_subdf, x="avg", multiple="fill", hue=ND, hue_order=["c29", "c40", "c23", "c43"], ax=ax[1])
        plt.show()


if __name__ == "__main__":
    main()
