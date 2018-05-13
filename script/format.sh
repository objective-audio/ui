#!/bin/sh

clang-format -i -style=file `find ../ui ../ui_tests ../ui_sample_common ../ui_mac_sample ../ui_ios_sample ../ui_mac_tests -type f \( -name *.h -o -name *.cpp -o -name *.hpp -o -name *.m -o -name *.mm \)`
