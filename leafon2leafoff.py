#!/usr/bin/env python
import glob
import json
import os

import pdal

src_dir = "../2019_FrenchGuiana/TLS_segmentation/tls2trees/clouds/2023-03-30_full_plot/0.0/"
files = glob.glob(os.path.join(src_dir, "leafon/*.leafon.ply"))
out_dir = os.path.join(src_dir, "leafoff/csv")

if not os.path.exists(out_dir):
    os.mkdir(out_dir)

for f in files:
    base = os.path.splitext(os.path.basename(f))[0].replace("leafon", "leafoff", 1)
    reader = {"type": "readers.ply", "filename": f}
    get_wood = {
        "type": "filters.range",
        "limits": "label[3:3]"
    }
    writer = {
        "type": "writers.text",
        "filename": os.path.join(out_dir, f"{base}.csv")
    }
    JSON = json.dumps([reader, get_wood, writer])
    try:
        pipeline = pdal.Pipeline(JSON)
        pipeline.execute()
    except Exception as e:
        print(e)