# Wrapper: lets the numpy-based scripts run under `python3 -I` (which drops the
# user site-packages where numpy lives on this Mac). Usage: python3 -I run.py <script.py> args...
import sys, runpy, os
sys.path.append(os.path.expanduser('~/Library/Python/3.9/lib/python/site-packages'))
here = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, here)
script = sys.argv[1]; sys.argv = [os.path.join(here, script)] + sys.argv[2:]
runpy.run_path(sys.argv[0], run_name='__main__')
