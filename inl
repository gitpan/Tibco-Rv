#!/bin/sh
perl -Mblib -MInline=NOISY,_INSTALL_ -M$1 -e1 1.12 blib/arch
