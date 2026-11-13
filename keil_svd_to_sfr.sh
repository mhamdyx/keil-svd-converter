#!/usr/bin/env bash

##################################################################################
# Script Name: keil_svd_to_sfr.sh
# Description: Locates all SVD files and generates the corresponding SFR files
# Author: Mahmoud Hamdy
# Created: Apr 2, 2026
# Last Modified: Jun 25, 2026
# Version: 1.2
# Usage: ./keil_svd_to_sfr.sh (or bash keil_svd_to_sfr.sh)
#################################################################################

# ==== CONFIG ====
# Adjust this manually according to your installation location
PACKS_DIR="/c/Users/mhamdyx/AppData/Local/Arm/Packs"
SVDCONV="/c/Keil_v5/UV4/SVDConv.exe"

# SVDConv.exe return codes. For context, refer to:
# https://open-cmsis-pack.github.io/svd-spec/main/svd_SVDConv_pg.html
SVDCONV_CODE_OK=0
SVDCONV_CODE_WARNINGS=1
SVDCONV_CODE_ERRORS=2
SVDCONV_CODE_CMD_ERROR=3
SVDCONV_CODE_UNEXPECTED=99


# ==== SAFETY CHECKS ====
if [ ! -f "$SVDCONV" ]; then
    echo "ERROR: SVDConv.exe not found at $SVDCONV"
    exit 1
fi

echo "========================================"
echo " Generating SFR files from all SVD files"
echo "========================================"

# ==== FIND & PROCESS ====
find "$PACKS_DIR" -type f -name "*.svd" | while read -r svd_file
do
    svd_dir=$(dirname "$svd_file")
    svd_filename=$(basename "$svd_file")

    echo ""
    echo "[+] Processing: $svd_filename"
    echo "    Location: $svd_dir"

    # Change to SVD directory (silently)
	pushd "$svd_dir" > /dev/null || {
		echo "[FAIL] Failed to enter directory: $svd_dir";
		exit -1;
	}
	
	sfr_filename="${svd_filename%.svd}.sfr"
	
	# Avoid regenerating SFR files
	if [ -f "$sfr_filename" ]; then
		echo "    [SKIP] $sfr_filename already exists"
		popd > /dev/null
		continue
	fi
	
	# Run SVDConv
	log_filename="${svd_filename%.svd}.log"
	"$SVDCONV" "xx$svd_filename" --generate=sfr > "$log_filename" 2>&1
    svdconv_return_code=$?
	
	if [ "$svdconv_return_code" -eq "$SVDCONV_CODE_OK" ]; then
        echo "    [ OK ] SFR generated with no errors (Return Code: $svdconv_return_code)"
	elif [ "$svdconv_return_code" -eq "$SVDCONV_CODE_WARNINGS" ]; then
		echo "    [ OK ] SFR generated with warnings (Return Code: $svdconv_return_code)"
	elif [ "$svdconv_return_code" -eq "$SVDCONV_CODE_ERRORS" ]; then
		echo "    [FAIL] Failed to generate $sfr_filename due to errors in $svd_filename"
	elif [ "$svdconv_return_code" -eq "$SVDCONV_CODE_CMD_ERROR" ]; then
		echo "    [FAIL] SVDConv invocation error"
		popd > /dev/null
		exit "$SVDCONV_CODE_CMD_ERROR"
    else
        echo "    [FAIL] Unexpected SVDConv return code: $svdconv_return_code"
		echo "		 See $log_filename for details."
		popd > /dev/null
		exit "$SVDCONV_CODE_UNEXPECTED"
    fi
	
	# Return to current directory (silently)
	popd > /dev/null

done

echo ""
echo "========== DONE =========="
