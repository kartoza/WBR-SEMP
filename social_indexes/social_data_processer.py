import os
import pandas as pd
from optparse import OptionParser

parser = OptionParser()
parser.add_option(
    "-r", "--directory", dest="directory", help="directory with shapefiles",
    metavar="DIRECTORY")
(options, args) = parser.parse_args()

root_directory = options.directory
target = r'%s' % root_directory
# Download stata data from https://www.datafirst.uct.ac.za/dataportal/index.php
for stata_data in os.listdir(target):
    if stata_data.endswith('.dta'):
        csv_output = stata_data + '.csv'
        stata_lyr = stata_data + '.dta'

        data = pd.io.stata.read_stata('%s') % stata_lyr
        data.to_csv('%s') % csv_output
