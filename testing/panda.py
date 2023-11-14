import pandas as pd
from scipy import stats

# Read the CSV file
df = pd.read_csv('../main-project/Events.csv')

# Define the threshold as a global variable so it's accessible throughout the script
THRESHOLD = 3

# Function to detect anomalies using Z-score and provide explanations
def find_anomalies(data):
    # Calculate Z-scores
    z_scores = stats.zscore(data)
    # Identify indices and values where the absolute Z-score is greater than the threshold
    return [(i, data.iloc[i], z) for i, z in enumerate(z_scores) if abs(z) > THRESHOLD]

# Applying the function to each numeric column and storing results
results = []
for column in df.select_dtypes(include=['number']).columns:
    data = df[column].dropna()  # Remove NaN values for numerical processing
    anomalies = find_anomalies(data)
    for idx, val, z_score in anomalies:
        # Use the global THRESHOLD variable in the f-string
        explanation = f"Z-score of {z_score:.2f} exceeds threshold of {THRESHOLD}"
        results.append({
            'Time Created': df.at[idx, 'TimeCreated'],
        })

# Convert results to a DataFrame
results_df = pd.DataFrame(results)

# Save the results to a new CSV file
results_df.to_csv('./results.csv', index=False)
