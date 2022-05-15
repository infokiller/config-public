# This file only defines names (including imports) that should be available
# interactively. The rest of the configuration should be in ext/config.py.
#
# pylint: disable=invalid-name
# pylint: disable=unused-import

# Interactive standard library imports
import collections
import copy
import csv
import datetime
import decimal
import functools
import glob
import importlib
import io
import itertools
import logging
import math
import operator
import os
import pathlib
import pickle
import pprint
import random
import re
import shutil
import subprocess
import sys
import time
import warnings
from typing import (Any, Callable, Dict, Iterable, List, Optional, Sequence,
                    Tuple, Union)

reload = importlib.reload
pprint = pprint.pprint
Path = pathlib.Path

OPTIONAL_IMPORTS = [
    'import matplotlib',
    'import matplotlib.pyplot as plt',
    'import numpy as np',
    'import pandas as pd',
    'import seaborn as sns',
    'import scipy.stats as sps',
    'import torch',
    'import torch.nn as nn',
    'import torch.nn.functional as F',
    'import torch.optim as optim',
    'import torch.utils.data',
    'import torchvision',
    'import torchvision.transforms as transforms',
    'import torchviz',
    'from dateutil import relativedelta',
]
for opt_import in OPTIONAL_IMPORTS:
    try:
        # pylint: disable=exec-used
        exec(opt_import)
    except ImportError:
        pass
del OPTIONAL_IMPORTS


# NOTE: Keep this function in sync with the one in ext/config.py.
def _load_local_extension(name):
    if '__file__' not in globals():
        warnings.warn('__file__ not set, cannot load IPython local extension')
        return None
    startup_dir = os.path.dirname(__file__)
    while startup_dir and startup_dir != '/':
        if os.path.basename(startup_dir) == 'startup':
            break
        startup_dir = os.path.dirname(startup_dir)
    if not startup_dir or startup_dir == '/':
        warnings.warn('could not detect IPython startup dir')
        return None
    module_path = os.path.join(startup_dir, 'ext', f'{name}.py')
    if not os.path.exists(module_path):
        warnings.warn(f'extension {module_path} not found')
        return None
    spec = importlib.util.spec_from_file_location(name, module_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


myconfig = _load_local_extension('config')
del _load_local_extension
xc = myconfig.copy_to_clipboard
del myconfig

# Clean up the globals namespace.
# NOTE: this is disabled because it's too complex and no longer needed because
# most of the config is now in a separate module. It's kept here just for
# reference.
# if '__file__' in globals() and __file__:
#     this_file = os.path.abspath(__file__)
#
#     def _should_delete_object(name: str, value):
#         if inspect.isbuiltin(value):
#             return False
#         if name.startswith('__') and name.endswith('__'):
#             return False
#         # NOTE: inspect.getabsfile raises a TypeError for module variables.
#         try:
#             return name.startswith('_') and inspect.getabsfile(
#                 value) == this_file
#         except TypeError:
#             return False
#
#     # NOTE: without copying the globals dict, I can get an error about
#     # iterating over a changing iterable.
#     names_to_delete = [
#         k for k, v in dict(globals()).items() if _should_delete_object(k, v)
#     ]
#     for name in names_to_delete:
#         # pylint: disable=exec-used
#         exec(f'del {name}')
#     del names_to_delete
#
#     # del _load_local_extension
#     # del _is_using_prompt_toolkit
#     # del _define_prompt_toolkit_keybindings
#     # del _define_aliases
#     # del _register_magic_aliases
