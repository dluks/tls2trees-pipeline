#!/bin/bash

# Instance segmentation function for use later (Step 5)
instance_seg_tile() {
        local f="$1"
        local tile_index="$2"
        local odir="$3"
        local n_tiles="$4"
        local overlap="$5"
        local slice_thickness="$6"
        local find_stems_height="$7"
        local find_stems_thickness="$8"
        local find_stems_min_rad="$9"
        local find_stems_min_pts="${10}"
        local graph_edge_length="${11}"
        local min_pts_per_tree="${12}"
        local add_leaves_voxel_length="${13}"
        local add_leaves_edge_length="${14}"

        echo "Running instance segmentation on file $f"
        python3 TLS2trees/tls2trees/instance.py -t "$f" \
                --tindex "$tile_index" \
                -o "$odir" \
                --n-tiles "$n_tiles" \
                --overlap "$overlap" \
                --slice-thickness "$slice_thickness" \
                --find-stems-height "$find_stems_height" \
                --find-stems-thickness "$find_stems_thickness" \
                --find-stems-min-radius "$find_stems_min_rad" \
                --find-stems-min-points "$find_stems_min_pts" \
                --graph-edge-length "$graph_edge_length" \
                --min-points-per-tree "$min_pts_per_tree" \
                --add-leaves \
                --add-leaves-voxel-length "$add_leaves_voxel_length" \
                --add-leaves-edge-length "$add_leaves_edge_length" \
                --save-diameter-class \
                --ignore-missing-tiles \
                --pandarallel \
}

export -f instance_seg_tile

# 0. SETUP ---------------------------------------
PROJ_DIR="/misc/scn1/2019_FrenchGuiana/TLS_segmentation"
LAS_DIR="$PROJ_DIR/0_original_laz"
T2T_DIR="$PROJ_DIR/tls2trees"
EXT="$T2T_DIR/extraction"
LAS2PLY_DIR="$EXT/las2ply"
DOWNSMP_DIR="$EXT/downsample"
TILE_INDEX="$EXT/tile_index.dat"
FSCT_DIR="$EXT/fsct"
CLOUD_DIR="$T2T_DIR/clouds"
NUM_PROCS=16

# Use multiprocessing to run the instance segmentation (Step 5) for each tile in
# parallel
USE_MULTIPROCESSING=true

# 1. LAS2PLY ---------------------------------------
ODIR=$LAS2PLY_DIR
TS=15 # Tile size in meters

echo "LAS -> PLY..."
python3 rxp-pipeline/las2ply.py -p $LAS_DIR -o $ODIR --keep-ids --num-prcs $NUM_PROCS -v

# 2. DOWNSAMPLE ---------------------------------------
FILES=$LAS2PLY_DIR
ODIR=$DOWNSMP_DIR
LENGTH=0.02

echo "Downsampling..."
python3 rxp-pipeline/downsample.py -i $FILES -o $ODIR -l $LENGTH --num-prcs $NUM_PROCS --verbose

# 3. TILE INDEX ---------------------------------------
IDIR=$DOWNSMP_DIR

echo "Creating tile index..."
python rxp-pipeline/tile_index.py -i $IDIR -t $TILE_INDEX

# 4. FSCT CLASSIFICATION (Semantic segmentation)  ---------------------------------------
FILES=$(find "$DOWNSMP_DIR" -name "*.ply")
ODIR=$FSCT_DIR
BUFFER=5
BATCH_SIZE=6

for f in $FILES; do
	echo "Processing $f..."
        # Update CUDA_VISIBLE_DEVICES to the GPU you want to use (you can use nvidia-smi
        # to see which GPUs are available). This is probably only necessary if you are
        # sharing a machine with other users who may be using GPUs.
	CUDA_VISIBLE_DEVICES=2 python3 TLS2trees/tls2trees/semantic.py \
                -p $f \
                --odir $ODIR \
                --tile-index $TILE_INDEX \
                --buffer $BUFFER \
                --num_procs $NUM_PROCS \
                --batch_size $BATCH_SIZE \
                --verbose
done

# 5. INSTANCE SEGMENTATION ---------------------------------------
# Set FILES to all files that end in .ply in the FSCT_DIR
FILES=$(find "$FSCT_DIR" -name "*.ply")
ODIR="$CLOUD_DIR/2023-10-04_multiproc_test_lusk"
N_TILES=5                            # Default: 3
OVERLAP=3                            # Default: 0
SLICE_THICKNESS=0.2                  # Default: 0.2
FIND_STEMS_HEIGHT=1.5                # Default: 1.5
FIND_STEMS_THICKNESS=0.5             # Default: 0.5
FIND_STEMS_MIN_RAD=0.025             # Default: 0.025
FIND_STEMS_MIN_PTS=200               # Default: 200
GRAPH_EDGE_LENGTH=0.1                # Default: 1
GRAPH_MAX_CUM_GAP=10                 # Default is np.inf
MIN_PTS_PER_TREE=0                   # Default: 0
ADD_LEAVES_VOXEL_LENGTH=0.2          # Default: 0.5
ADD_LEAVES_EDGE_LENGTH=2             # Default: 1



if [ "$USE_MULTIPROCESSING" = true ]; then
	echo "Running instance segmentation on all files... (multiprocessing)"
	echo "$FILES" | xargs -I{} -P "$(nproc)" bash -c \
        'instance_seg_tile "$@"' _ {} \
        "$TILE_INDEX" \
        "$ODIR" \
        "$N_TILES" \
        "$OVERLAP" \
        "$SLICE_THICKNESS" \
        "$FIND_STEMS_HEIGHT" \
        "$FIND_STEMS_THICKNESS" \
        "$FIND_STEMS_MIN_RAD" \
        "$FIND_STEMS_MIN_PTS" \
        "$GRAPH_EDGE_LENGTH" \
        "$MIN_PTS_PER_TREE" \
        "$ADD_LEAVES_VOXEL_LENGTH" \
        "$ADD_LEAVES_EDGE_LENGTH"
else
        echo "Running instance segmentation on all files..."
	for f in $FILES; do
                instance_seg_tile "$f" \
                "$TILE_INDEX" \
                "$ODIR" \
                "$N_TILES" \
                "$OVERLAP" \
                "$SLICE_THICKNESS" \
                "$FIND_STEMS_HEIGHT" \
                "$FIND_STEMS_THICKNESS" \
                "$FIND_STEMS_MIN_RAD" \
                "$FIND_STEMS_MIN_PTS" \
                "$GRAPH_EDGE_LENGTH" \
                "$MIN_PTS_PER_TREE" \
                "$ADD_LEAVES_VOXEL_LENGTH" \
                "$ADD_LEAVES_EDGE_LENGTH"
        done
fi