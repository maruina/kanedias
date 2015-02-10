#!/bin/sh
PATH=$PATH:{{ salt['pillar.get']('miniconda:path') }}/bin
