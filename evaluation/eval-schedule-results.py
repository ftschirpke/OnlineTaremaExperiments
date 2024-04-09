from pathlib import Path
from collections import defaultdict

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import StrMethodFormatter
import seaborn as sns
import scienceplots

DIR = "../results_copied_down/bachelor_results_1/"


SAVE = True


def setBoxColors(bp, color):
    for element in ['boxes', 'whiskers', 'fliers', 'means', 'medians', 'caps']:
        for i in range(len(bp[element])):
            plt.setp(bp[element][i], color='black')
            if element == 'boxes':
                plt.setp(bp[element][i], facecolor=color)


WF = "Workflow"
SA = "Scheduling Approach"
RN = "Run Number"

RMRR = "RankMin-RR"


def reformat(name: str) -> str:
    if name == "rankminrr":
        return RMRR
    return " ".join([x.capitalize() for x in name.split("_")])


def main() -> None:
    global SAVE
    SAVE = input("Save plots? (y/n) ") == "y"
    plt.style.use("science")
    plt.rcParams["font.size"] = 12

    df: pd.DataFrame = pd.DataFrame(columns=[WF, SA, RN, "start", "end", "duration"])

    root_path: Path = Path(DIR)
    for dir in root_path.iterdir():
        if not dir.is_dir():
            continue
        for file in dir.rglob("trace.csv"):
            print(file)
            run_name = file.parents[0].name
            if "failed" in run_name:
                continue
            scheduling_approach = file.parents[1].name
            workflow = file.parents[2].name
            run_df: pd.DataFrame = pd.read_csv(file)
            start: int = run_df["start"].min()
            end: int = run_df["complete"].max()
            data = {
                WF: reformat(workflow),
                SA: reformat(scheduling_approach),
                RN: int(run_name),
                "start": start,
                "end": end,
                "duration": end - start,
            }
            df.loc[len(df)] = data

    MINS = "Duration in Minutes"

    df[MINS] = df["duration"] / (60 * 1000)
    df["workflow_mean"] = df[WF].map(lambda wf: df[df[WF] == wf]["duration"].mean())
    df["relative_duration"] = df["duration"] / df["workflow_mean"]
    df["percentage_improvement"] = df["relative_duration"].map(lambda x: (x - 1) * 100)

    df["rankminrr_mean"] = df[WF].map(
        lambda wf:
        df[(df[WF] == wf) & (df[SA] == RMRR)]["duration"].mean()
    )

    df["relative_to_rankminrr"] = df["duration"] / df["rankminrr_mean"]

    PERC_IMPR_RMRR = "Relative Makespan compared to RankMin-RR mean"
    df[PERC_IMPR_RMRR] = df["relative_to_rankminrr"].map(lambda x: (x - 1) * 100)

    plot_y = PERC_IMPR_RMRR

    print(df)

    # sns.boxplot(data=df, x=WF, y="minutes", hue=SA)
    # sns.boxplot(data=df, x=WF, y="relative_duration", hue=SA)
    # sns.boxplot(data=df, x=WF, y="percentage_improvement", hue=SA)
    bp = sns.boxplot(data=df, x=WF, y=plot_y, hue=SA)

    bp.yaxis.set_major_formatter(StrMethodFormatter("${x:+.0f}$\\%%"))

    print(f"Currently at Runtime plot ({plot_y})")
    if SAVE:
        yes = input("Save this? (y/n) ") == "y"
        if yes:
            fig = bp.get_figure()
            fig.set_size_inches(10, 5)
            fig.savefig("plots/runtimes.pdf", bbox_inches='tight')
    if not SAVE:
        plt.show()


def main2() -> None:
    data = defaultdict(dict)

    root_path: Path = Path(DIR)
    for dir in root_path.iterdir():
        if not dir.is_dir():
            continue
        for file in dir.rglob("trace.csv"):
            run_name = file.parents[0].name
            if "failed" in run_name:
                continue

            scheduling_approach = file.parents[1].name
            workflow = file.parents[2].name
            if workflow in data and scheduling_approach in data[workflow]:
                print("Duplicate workflow and scheduling approach found", workflow, scheduling_approach)
                continue

            run_df: pd.DataFrame = pd.read_csv(file)
            wf_start = run_df["start"].min()
            tasks = run_df["process"].unique()
            lengths = {}
            for task in tasks:
                task_df = run_df[run_df["process"] == task]
                start: int = task_df["start"].min() - wf_start
                end: int = task_df["complete"].max() - wf_start
                lengths[task] = (start, end - start, end)

            start: int = run_df["start"].min()
            end: int = run_df["complete"].max()
            data[workflow][scheduling_approach] = lengths

    for workflow, run_data in data.items():
        fig, axes = plt.subplots(len(run_data), 1, sharex=True, sharey=True, figsize=(20, 5))
        for ax, (scheduling_approach, task_data) in zip(axes, run_data.items()):
            ax.set_title(scheduling_approach)
            list_data = list(task_data.items())
            ax.barh(y=[x[0] for x in list_data], width=[x[1][1] for x in list_data], left=[x[1][0] for x in list_data])


if __name__ == "__main__":

    main()
    # main2()
