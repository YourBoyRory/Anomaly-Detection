import pandas as pd

def clean_data(csv_file_path):
    # Load CSV data into a DataFrame, skipping the first row (header)
    df = pd.read_csv(csv_file_path, delimiter=',', encoding='utf-8', skiprows=[0], error_bad_lines=False, low_memory=False)

    # Rename the columns based on the provided header
    column_names = ['TimeCreated', 'Kernel', 'Type', 'NIC IN', 'NIC OUT', 'MAC', 'SRC', 'DST', 'LEN', 'TOS', 'PREC', 'TTL', 'ID']
    df.columns = column_names

    # Perform data cleaning and preprocessing as needed
    # For example, convert 'TimeCreated' column to datetime format
    df['TimeCreated'] = pd.to_datetime(df['TimeCreated'])
    return df

def save_cleaned_data(cleaned_data, output_csv_path):
    # Save the cleaned DataFrame to a new CSV file
    cleaned_data.to_csv(output_csv_path, index=False)

if __name__ == "__main__":
    input_csv_path = r"./Events.csv"
    output_csv_path = r"./cleaned_Events.csv"

    cleaned_data = clean_data(input_csv_path)
    print("Cleaned Data:")
    print(cleaned_data.head())  # Display the cleaned DataFrame

    save_cleaned_data(cleaned_data, output_csv_path)
    print(f"Cleaned data saved to {output_csv_path}")
