#!/bin/bash

TESTSTATION_NUM=5

# verify voltage
all_inputs() {
ssh root@172.16.73.1${1}1 "/tmp/LX_TestClient/bin/io_master -v 12 -d 8 --verify 4" &
ssh root@172.16.73.1${1}3 "/tmp/LX_TestClient/bin/lxm_iio -i 16"
}
# input test
input_test() {
ssh root@172.16.73.1${1}1 "/tmp/LX_TestClient/bin/io_master -v 12 -d 2 -i 5" &
ssh root@172.16.73.1${1}3 "/tmp/LX_TestClient/bin/lxm_iio -i 16"
}
# output test
output_test() {
ssh root@172.16.73.1${1}3 "/tmp/LX_TestClient/bin/lxm_iio -o 3 ${2}" &
ssh root@172.16.73.1${1}1 "/tmp/LX_TestClient/bin/io_master -v 12 -d 3 -o 3"
}

clear
echo "Low Voltage Testing"
echo "Press <ENTER> to start IO Tests" ; read

echo "Turn on all inputs:"
all_inputs ${TESTSTATION_NUM}
echo "Press <ENTER> for next test" ; read

clear
echo "Test inputs:"
input_test ${TESTSTATION_NUM}
echo "Press <ENTER> for next test" ; read

clear
echo "test outputs (First Card):"
output_test ${TESTSTATION_NUM} 0
echo "Press <ENTER> for next test" ; read

# Only if there are two cards
#clear
#echo "Turn on all inputs (Second Card):"
#output_test ${TESTSTATION_NUM} 1
