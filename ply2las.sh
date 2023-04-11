files="../2019_FrenchGuiana/TLS_segmentation/tls2trees/clouds/2023-03-30_full_plot/*/leafoff/ply/*.ply"

for f in $files; do
    # echo "full file: $f";
    d=$(dirname $f)
    d=${d%%\/ply};
    f=$(basename $f)
    f=${f%%.ply};
    # echo $d
    # if [ ! -d "$d/ply" ]; then
    #     mkdir $d/ply
    #     mv $d/*.ply $d/ply
    #     mkdir $d/las
    # fi
    echo $f
    pdal translate -i "$d/ply/$f.ply" -o "$d/las/$f.las";
done
