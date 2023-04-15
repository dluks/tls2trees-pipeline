import glob
import json
import os

import pdal

src_dir = "./data/clouds/2023-01-16/qualitative-review-params/0.0"
files = glob.glob(os.path.join(src_dir, "*.leafon.ply"))
out_dir = os.path.join(src_dir, "csv")

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