#!/bin/bash
# ==========================================================================
# Copyright (C) 2023 Intel Corporation
#
# SPDX-License-Identifier: MIT
# ==========================================================================
PERF=/usr/lib/linux-tools/6.5.0-18-generic/perf
export DTO_USESTDC_CALLS=0
export DTO_COLLECT_STATS=1
export DTO_WAIT_METHOD=busypoll
export DTO_MIN_BYTES=8192
export DTO_CPU_SIZE_FRACTION=0.33
export DTO_AUTO_ADJUST_KNOBS=1

EVENTSET="-e dsa0/event=0x1,event_category=0x0/,dsa0/event=0x1,event_category=0x1/,dsa0/event=0x2,event_category=0x1/"
EVENTSET+="-e context-switches"

And after some time, it will summarize the throughput results for the software operations, hardware operations separately initiated by the host on QAT and DSA, and hardware-managed chained operations performed on the QAT accelerator alone
The goal of this framework is to show the performance of the different accelerable functions when we try to use them together and under diferent system configurations

For instance, we can get an understanding of what occurs when we poll multiple accelerators on the same CPU

# Run dto-test without DTO library
#/usr/bin/time ./dto-test-wodto

# Run dto-test with DTO library using LD_PRELOAD method
#export LD_PRELOAD=./libdto.so.1.0
#/usr/bin/time ./dto-test-wodto

# Run dto-test with DTO library using "re-compile with DTO" method
# (i.e., without LD_PRELOAD)
time ./dto-test | tee dto-test-busy-poll.log
# Run dto-test with DTO and get DSA perfmon counters
# $PERF stat -e $EVENTSET time ./dto-test |  tee dto-test-busypoll-perf.log

export DTO_WAIT_METHOD=yield
time ./dto-test | tee dto-test-busy-poll.log
# Run dto-test with DTO and get DSA perfmon counters
$PERF stat -e dsa0/event=0x1,event_category=0x0/,dsa0/event=0x1,event_category=0x1/,dsa0/event=0x2,event_category=0x1/ -e context-switches time ./dto-test | tee dto-test-yield-perf.log
