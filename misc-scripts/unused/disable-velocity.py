#!/usr/bin/python

import sys
import yaml

with open(sys.argv[1]) as f:
    y = yaml.safe_load(f)
    y['settings']['velocity-support']['enabled'] = 'false'

with open(sys.argv[1], "w") as f:
    print(yaml.dump(y, f, default_style=None, default_flow_style=False))
