from sqlalchemy import create_engine, MetaData, Table
import json

db_url = "mysql://adminmHsxPQq:U_2Vyn6bbM37@127.11.141.2:3306/genesforgood"
table_name = 'categoryswitch'
data_column_name = 'datastring'

# boilerplace sqlalchemy setup
engine = create_engine(db_url)
metadata = MetaData()
metadata.bind = engine
table = Table(table_name, metadata, autoload=True)
# make a query and loop through
s = table.select()
rows = s.execute()

data = []
#status codes of subjects who completed experiment
statuses = [3,4,5,7]
# if you have workers you wish to exclude, add them here
exclude = []
for row in rows:
    # only use subjects who completed experiment and aren't excluded
    if row['status'] in statuses and row['uniqueid'] not in exclude:
        data.append(row[data_column_name])	

# Now we have all participant datastrings in a list.
# Let's make it a bit easier to work with:

# parse each participant's datastring as json object
# and take the 'data' sub-object

for part in data:
	print part

# Put all subjects' trial data into a dataframe object from the
# 'pandas' python library: one option among many for analysis
