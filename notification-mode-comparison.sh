#!/bin/bash

DSA_SETUP=../setup_dsa.sh

sudo $DSA_SETUP -d dsa0 -w1 -ms -e4

make libdto

make dto-test

time DTO_LOG_LEVEL=2 DTO_WAIT_METHOD=busypoll taskset -c 1 ./dto-test 2

time DTO_LOG_LEVEL=2 DTO_WAIT_METHOD=yield taskset -c 1 ./dto-test 2
