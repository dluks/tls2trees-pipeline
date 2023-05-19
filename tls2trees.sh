# 0. SETUP ---------------------------------------
PROJ_DIR="/misc/scn1/2019_FrenchGuiana/TLS_segmentation"
LAS_DIR="$PROJ_DIR/0_original_laz"
DATA_DIR="$PROJ_DIR/tls2trees"
EXT="$DATA_DIR/extraction"
LAS2PLY_DIR="$EXT/las2ply"
DOWNSMP_DIR="$EXT/downsample"
FSCT_DIR="$EXT/fsct"
CLOUD_DIR="$DATA_DIR/clouds"
NUM_PROCS=16


# 1. LAS2PLY ---------------------------------------
FILES=$LAS_DIR
ODIR=$LAS2PLY_DIR
TS=15

# echo "LAS -> PLY..."
# python3 rxp-pipeline/las2ply.py -p $FILES -o $ODIR --keep-ids --num-prcs $NUM_PROCS -v


# 2. DOWNSAMPLE ---------------------------------------
FILES=$LAS2PLY_DIR
ODIR=$DOWNSMP_DIR
LENGTH=0.02

# echo "Downsampling..."
# python3 rxp-pipeline/downsample.py -i $FILES -o $ODIR -l $LENGTH --num-prcs $NUM_PROCS --verbose


# 3. TILE INDEX ---------------------------------------
IDIR=$DOWNSMP_DIR
TILE_INDEX="$EXT/tile_index.dat"

# echo "Creating tile index..."
# python rxp-pipeline/tile_index.py -i $IDIR -t $TILE_INDEX


# 4. FSCT CLASSIFY (Semantic segmentation)  ---------------------------------------
FILES=( "$DOWNSMP_DIR/15_17.downsample.ply" "$DOWNSMP_DIR/18_9.downsample.ply" )
ODIR=$FSCT_DIR
TILE_INDEX="$EXT/tile_index.dat"
BUFFER=5
BATCH_SIZE=6

# for f in "${FILES[@]}"
# do
# 	echo "Processing $f..."
# 	CUDA_VISIBLE_DEVICES=2 python3 fsct/fsct/run.py -p $f --odir $ODIR --tile-index $TILE_INDEX --buffer $BUFFER --num_procs $NUM_PROCS --batch_size $BATCH_SIZE --verbose
# done


# 5. INSTANCE SEGMENTATION ---------------------------------------
FILES="$FSCT_DIR/11_12.downsample.segmented.ply"
ODIR="$CLOUD_DIR/2023-05-19_inst_seg_check_lusk"
N_TILES=5  # Default: 3
OVERLAP=3  # Default: 0
SLICE_THICKNESS=0.2  # Default: 0.2
FIND_STEMS_HEIGHT=1.5  # Default: 1.5
FIND_STEMS_THICKNESS=0.5  # Default: 0.5
FIND_STEMS_MIN_RAD=0.025  # Default: 0.025
FIND_STEMS_MIN_PTS=200  # Default: 200
GRAPH_EDGE_LENGTH=0.1  # Default: 1
GRAPH_MAX_CUM_GAP=(2.0 2.5 3.0 3.5)  # Default is np.inf
MIN_PTS_PER_TREE=0  # Default: 0
ADD_LEAVES_VOXEL_LENGTH=0.2  # Default: 0.5
ADD_LEAVES_EDGE_LENGTH=2  # Default: 1

for p in ${GRAPH_MAX_CUM_GAP[*]}
do
	echo "Running instance segmentation on $FILES with GRAPH_MAX_CUM_GAP of $p..."
	python3 fsct/fsct/points2trees.py -t $FILES --tindex $TILE_INDEX -o "$ODIR/$p" --n-tiles $N_TILES --overlap $OVERLAP --slice-thickness $SLICE_THICKNESS --find-stems-height $FIND_STEMS_HEIGHT --find-stems-thickness $FIND_STEMS_THICKNESS --find-stems-min-radius $FIND_STEMS_MIN_RAD --find-stems-min-points $FIND_STEMS_MIN_PTS --graph-edge-length $GRAPH_EDGE_LENGTH --graph-maximum-cumulative-gap $p --min-points-per-tree $MIN_PTS_PER_TREE --add-leaves --add-leaves-voxel-length $ADD_LEAVES_VOXEL_LENGTH --add-leaves-edge-length $ADD_LEAVES_EDGE_LENGTH  --save-diameter-class --ignore-missing-tiles --pandarallel --verbose
done

# ADD_LEAVES_VOXEL_LENGTH=0.3
# ODIR_TEST="$ODIR/ALVL=$ADD_LEAVES_VOXEL_LENGTH"
# for f in $FILES
# do
#     echo "Running instance segmentation on $f with ALVL of $ADD_LEAVES_VOXEL_LENGTH..."
#     python3 fsct/fsct/points2trees.py -t $f --tindex $TILE_INDEX -o $ODIR_TEST --n-tiles $N_TILES --overlap $OVERLAP --slice-thickness $SLICE_THICKNESS --find-stems-height $FIND_STEMS_HEIGHT --find-stems-thickness $FIND_STEMS_THICKNESS --find-stems-min-radius $FIND_STEMS_MIN_RAD --find-stems-min-points $FIND_STEMS_MIN_PTS --graph-edge-length $GRAPH_EDGE_LENGTH --min-points-per-tree $MIN_PTS_PER_TREE --add-leaves --add-leaves-voxel-length $ADD_LEAVES_VOXEL_LENGTH --add-leaves-edge-length $ADD_LEAVES_EDGE_LENGTH  --save-diameter-class --ignore-missing-tiles --pandarallel --verbose
# done
# 
# ADD_LEAVES_VOXEL_LENGTH=0.8
# ODIR_TEST="$ODIR/ALVL=$ADD_LEAVES_VOXEL_LENGTH"
# for f in $FILES
# do
#     echo "Running instance segmentation on $f with ALVL of $ADD_LEAVES_VOXEL_LENGTH..."
#     python3 fsct/fsct/points2trees.py -t $f --tindex $TILE_INDEX -o $ODIR_TEST --n-tiles $N_TILES --overlap $OVERLAP --slice-thickness $SLICE_THICKNESS --find-stems-height $FIND_STEMS_HEIGHT --find-stems-thickness $FIND_STEMS_THICKNESS --find-stems-min-radius $FIND_STEMS_MIN_RAD --find-stems-min-points $FIND_STEMS_MIN_PTS --graph-edge-length $GRAPH_EDGE_LENGTH --min-points-per-tree $MIN_PTS_PER_TREE --add-leaves --add-leaves-voxel-length $ADD_LEAVES_VOXEL_LENGTH --add-leaves-edge-length $ADD_LEAVES_EDGE_LENGTH  --save-diameter-class --ignore-missing-tiles --pandarallel --verbose
# done
