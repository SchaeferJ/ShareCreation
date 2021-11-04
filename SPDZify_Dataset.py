"!/bin/python"

# Converts CSV-Files into the file format expected by MP-SPDZ.
# Note: The result of this code is still cleartext. To create shares
# you have to run the client code, which will take the output of this
# program as input.

import csv
import argparse
import os.path
from pathlib import Path

parser = argparse.ArgumentParser(description='Convert CSV data in a MP-SPDZ compatible format')

parser.add_argument('--infile', '-i', type=str,
                    help='Path to the input file', required=True)
parser.add_argument('--outfile', '-o', type=str,
                    help='Path to the output file', required=False, default="./MP-SPDZ/Player-Data/")
parser.add_argument('--delim', '-d', type=str,
                    help='Delimiter used in the CSV', required=False, default=",")
parser.add_argument('--label', '-l', type=int,
                    help='Position of label column (-1=last column)', required=False, default=-1)
parser.add_argument('--player', '-p', type=str,
                    help='Player number', required=False, default="0")     
parser.add_argument('--input', '-n', type=str,
                    help='Input number', required=False, default="0")                        
parser.add_argument('--skipheader', action='store_true', default=False,
                    help='Skip first row in CSV')

args = vars(parser.parse_args())

INFILE = os.path.normpath(args["infile"])
FILENAME = "Input-P"+args["player"]+"-"+args["input"]
OUTPATH = os.path.normpath(args["outfile"])
OUTFILE = os.path.join(OUTPATH, FILENAME)
LABELPOS = args["label"]
DELIM = args["delim"]

# Open CSV file and convert it to a list of lists (one list of values per row in CSV)
with open(INFILE, newline='') as csvfile:
    data = list(csv.reader(csvfile, delimiter=DELIM))

# Skip headers if requested
if args["skipheader"]:
    data = data[1:]

# Determine number of columns present in data (= number of attributes)
# This will be used lateron to separate attributes from labels.
varcount = len(data[0])
if LABELPOS == -1:
    LABELPOS = varcount-1

# Separating attributes and labels, also typecasting
traindata, label = [], []
for d in data:
    for e in range(len(d)):
        # Store labels in separate dataset
        if e==LABELPOS:
            label.append(int(d[e]))
        else:
            traindata.append(float(d[e]))

if not os.path.exists(OUTPATH):
    print("Info: Output Directory does not exist, is being created.")
    Path(OUTPATH).mkdir(parents=True, exist_ok=True)

with open(OUTFILE, "w") as f:
    for t in range(len(traindata)):
        f.write(str(traindata[t])+" ")
        if (t+1)%(varcount-1)==0 and t>0:
            # TODO: Clean up this index mess
            f.write(str(float(label[int(((t/(varcount-1))))]))+" ")
