#!/bin/bash

# Update stage3 (rebuilds, etc. needed to fix emerge complaints)
if [ -n "${clst_update_stage_command}" ]; then
	echo "Updating stage..."
	${clst_update_stage_command}
else
	echo "Skipping seed stage update..."
fi

