files="../2019_FrenchGuiana/TLS_segmentation/tls2trees/clouds/2023-03-30_full_plot/*/leafoff/ply/*.ply"

for f in $files; do
    d=$(dirname $f)
    d=${d%%\/ply};
    f=$(basename $f)
    f=${f%%.ply};
    # echo $d
    if [ ! -d "$d/csv" ]; then
        mkdir $d/csv
        # echo $d/csv
    fi
    # echo $f
    pdal translate -i "$d/ply/$f.ply" -o "$d/csv/$f.csv";
done
