import csv
import json
import sys

def csv_to_json(csv_filepath, json_filepath):
    """
    Converts a CSV file to JSON.
    
    :param csv_filepath: Path to the input CSV file.
    :param json_filepath: Path to the output JSON file.
    """
    
    # Opens the CSV file
    with open(csv_filepath, mode='r', encoding='utf-8') as csv_file:
        # csv.DictReader maps each row to a dictionary {column: value}
        reader = csv.DictReader(csv_file)
        
        # Converts all rows into a list of dictionaries
        rows = list(reader)
        
    # Saves the list of dictionaries to a JSON file
    with open(json_filepath, mode='w', encoding='utf-8') as json_file:
        json.dump(rows, json_file, ensure_ascii=False, indent=4)
    
    print(f"JSON file successfully created at: {json_filepath}")


if __name__ == "__main__":
    # Example usage:
    #
    # python csv_to_json.py path_to_csv.csv path_to_json.json
    #
    # Alternatively, you can set fixed paths directly in the script.
    
    if len(sys.argv) != 3:
        print(f"Usage: python {sys.argv[0]} <csv_path> <json_path>")
        sys.exit(1)
    
    csv_path = sys.argv[1]
    json_path = sys.argv[2]
    
    csv_to_json(csv_path, json_path)