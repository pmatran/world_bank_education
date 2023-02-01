# -- Usage
"""
python send2sqlserver.py -s 'MSI\SQLEXPRESS' -db Education
"""

# -- Import python module
import os
import io
import requests
import pandas as pd
from zipfile import ZipFile
from tqdm import tqdm
import argparse
import sqlalchemy
from sqlalchemy.engine import URL

# ---- Set arguments helps
descr = 'Preprocess World Data Bank Education Statistic .csv files'
h_s = '[-s] or [--server] : SQL Server name.'
h_db = '[-db] or [--database] : SQL database name (required).'

# -- Create argument parser
parser = argparse.ArgumentParser(description=descr)
parser.add_argument('-s', '--server', type=str, required=True, help=h_s)
parser.add_argument('-db', '--database', type=str, required=True, help=h_db)

# -- Collect arguments values
args = parser.parse_args()
s, db = args.server, args.database

# -- Build connection asq string
#conn_str = 'DRIVER={SQL Server};SERVER=' + s + ';DATABASE=' + db + ';TRUSTED_CONNECTION=yes;'
conn_str = 'DRIVER={ODBC+Driver+17+for+SQL+Server};SERVER=' + s + \
		   ';DATABASE=' + db + ';TRUSTED_CONNECTION=yes;'

# -- Create URL connection instance
conn_url = URL.create("mssql+pyodbc", query={"odbc_connect": conn_str})

# -- Build sqlalchemy engine (works well with pandas)
engine = sqlalchemy.create_engine(conn_url, fast_executemany=True) # boost sql INSERT 

# -- Build connection
print(f'\n==> SENDING DATA TO DATABASE : {s}\\{db} ...')

# -- Set url to online World Bank Education Dataset
url = 'https://databank.worldbank.org/data/download/EdStats_CSV.zip'
r = requests.get(url, stream=True)

# -- Get zip file and extract all csv
zf = ZipFile(io.BytesIO(r.content))
zf.extractall()

# -- Manage all csv files
for path in tqdm(zf.namelist()):
	# -- Manage table name
	table_name = (
		os.path.split(path)[1]
		.replace('.csv', '')
		.replace('EdStats', '')
		.lower()
		.replace('-', '_')
		)
	# -- Read data / clean data
	df = (
		pd.read_csv(path)
		.dropna(axis=1, how='all') # Drop columns with NaN only
		.dropna(axis=0, how='all') # Drop rows with NaN only
		.rename(columns=lambda x: (
					str(x)
					.lower()
					.replace(' ', '_')
					.replace('-', '_')
					) 	# Normalize columns names
				)
		.rename(columns= lambda x: 'year_' + x if x.isnumeric() else x) # avoid numeric column name
		.rename(columns=dict(
					countrycode='country_code',
					seriescode='series_code'
					)
				)
		)

	# -- Export clean data to csv
	df.to_sql(name=table_name,
			  con=engine,
			  index=False,
			  chunksize=2100,
			  #method='multi', # Pass multiple rows in a single INSERT query
			  if_exists='replace')

# -- Cleanup downloaded csv
for csv in zf.namelist():
	os.remove(csv)

print('\n==> PRE-PROCESSING FINISHED !')
