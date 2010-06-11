#!/bin/sh

#Synthesize the Wrapper Files
echo 'Synthesizing wrapper files with XST';
xst -ifn source_xst.scr
