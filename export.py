import argparse
import os
import subprocess
from pathlib import Path


def run(cmd: str):
    subprocess.Popen(cmd, shell=True)

parser = argparse.ArgumentParser()
parser.add_argument('-o', '--output', help="output directory", default="./out")
parser.add_argument('-d', '--diameter', help="bar diameter", default=25)

args = parser.parse_args()
print(args)

output_dir = args.output
diameter = args.diameter

os.makedirs(output_dir, exist_ok=True)

parts = {
    "Top": 1,
    "Bottom": 2,
    "Latch_Part_1": 3,
    "Latch_Part_2": 4
}

for part_name, part_selection in parts.items():
    dest = Path(output_dir).joinpath(f"{part_name}_{diameter}mm.stl")
    run(f"openscad -o {dest} -D Part_Selection='{part_selection}' -D Bar_Diameter='{diameter}' dumbell_clamp.scad")
