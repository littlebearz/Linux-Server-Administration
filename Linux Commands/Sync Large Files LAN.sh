#!/bin/bash

# SETUP OPTIONS

display_help() {
    echo "Usage: $0 SRCDIR DESDIR [THREADS]" >&2
    echo
    echo "   $1 is source directory"
    echo "   $2 is destination directory"
    echo
    # echo some stuff here for the -a or --add-options
    exit 1
}

export SRCDIR="$1"
export DESTDIR="$2"
export THREADS="8"

# echo "Source: $SRCDIR\n Destination: $DESDIR\n Threads: $THREADS"
# RSYNC DIRECTORY STRUCTURE

rsync -zr --progress -f"+ */" -f"- *" $SRCDIR/ $DESTDIR/

# FOLLOWING MAYBE FASTER BUT NOT AS FLEXIBLE
# cd $SRCDIR; find . -type d -print0 | cpio -0pdm $DESTDIR/
# FIND ALL FILES AND PASS THEM TO MULTIPLE RSYNC PROCESSES

cd $SRCDIR; find . ! -type d -print0 | xargs -0 -n1 -P$THREADS -I% rsync -az --progress % $DESTDIR/%


# IF YOU WANT TO LIMIT THE IO PRIORITY,
# PREPEND THE FOLLOWING TO THE rsync & cd/find COMMANDS ABOVE:
#   ionice -c2
