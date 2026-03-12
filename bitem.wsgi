import sys
import os

path = '/var/www/frontend/bitem'
if path not in sys.path:
    sys.path.insert(0, path)

from bitem import app as application
