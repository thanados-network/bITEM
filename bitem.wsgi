import os
import sys
site.addsitedir('/var/www/frontend/bitem/.venv/lib/python3.13/site-packages')

from bitem import app as application
