# This script downloads TRMM monthly data 3B43 from 2001 to 2014. They are as NetCDF4 files for 
# the whole globe (~6mb each).

# Before running, you must make sure that the NASA GESDISC DATA ARCHIVE Data Access is loaded for
# this to work properly. Check out this website for more help: 
# https://disc.sci.gsfc.nasa.gov/recipes/?q=recipes/How-to-Download-Data-Files-from-HTTP-Service-with-wget

# First create a mydata.dat file that contains the links you wish to download from. Our is already done.

wget --content-disposition --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --auth-no-challenge=on --keep-session-cookies -i myfileOriginal.dat


