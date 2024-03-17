from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# DIR = "../results_copied_down/bachelor_results_0/"
DIR = "../results_copied_down/bachelor_results_1/"


def main() -> None:
    df: pd.DataFrame = pd.DataFrame(columns=["workflow", "scheduling_approach", "run_number", "start", "end", "duration"])

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
            run_df: pd.DataFrame = pd.read_csv(file)
            start: int = run_df["start"].min()
            end: int = run_df["complete"].max()
            data = {
                "workflow": workflow,
                "scheduling_approach": scheduling_approach,
                "run_number": int(run_name),
                "start": start,
                "end": end,
                "duration": end - start,
            }
            df.loc[len(df)] = data

    df["workflow_mean"] = df["workflow"].map(lambda wf: df[df["workflow"] == wf]["duration"].mean())
    df["relative_duration"] = df["duration"] / df["workflow_mean"]
    df["percentage_improvement"] = df["relative_duration"].map(lambda x: (x - 1) * 100)

    # sns.boxplot(data=df, x="workflow", y="duration", hue="scheduling_approach")
    sns.boxplot(data=df, x="workflow", y="relative_duration", hue="scheduling_approach")
    # sns.boxplot(data=df, x="workflow", y="percentage_improvement", hue="scheduling_approach")
    plt.show()


if __name__ == "__main__":
    main()
