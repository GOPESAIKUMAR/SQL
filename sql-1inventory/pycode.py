import pandas as pd
from sqlalchemy import create_engine

# Connection details
username = 'root'
password = 'your_password'
host = 'localhost'
port = 3306
database = 'your_database_name'

# Create SQLAlchemy engine
engine = create_engine(f"mysql+pymysql://{username}:{password}@{host}:{port}/{database}")

# CSV file paths (update with your real paths)
csv_files = {
    'begin_inventory': r'D:\resume projects\Vendor Analysis BI\data\begin_inventory.csv',
    'end_inventory': r'D:\resume projects\Vendor Analysis BI\data\end_inventory.csv',
    'purchase_prices': r'D:\resume projects\Vendor Analysis BI\data\purchase_prices.csv',
    'purchases': r'D:\resume projects\Vendor Analysis BI\data\purchases.csv',
    'vendor_invoice': r'D:\resume projects\Vendor Analysis BI\data\vendor_invoice.csv',
    'sales': r'D:\resume projects\Vendor Analysis BI\data\sales.csv'
}

# Load each CSV into its corresponding table
for table_name, file_path in csv_files.items():
    print(f"Loading {file_path} into table `{table_name}`...")
    df = pd.read_csv(file_path)
    df.to_sql(name=table_name, con=engine, if_exists='replace', index=False) #chunksize=5000000 for large files
    print(f"✅ Loaded: {table_name}")

print("🎉 All CSV files have been loaded into MySQL successfully!") 