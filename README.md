
# Shell Utils

**Shell Utils** is a collection of scripts designed to streamline and automate day-to-day development tasks. This project includes scripts written in **Shell**, **Python**, and **TypeScript** to improve productivity for developers.

## Table of Contents
- [Getting Started](#getting-started)
- [Available Scripts](#available-scripts)
  - [Shell Scripts](#shell-scripts)
  - [Python Scripts](#python-scripts)
  - [TypeScript Scripts](#typescript-scripts)
- [Contributing](#contributing)
- [License](#license)

---

## Getting Started

### Prerequisites
- Ensure you have the following installed:
  - **Shell**: Bash or equivalent terminal
  - **Python**: Version 3.x and pip
  - **Node.js**: Version 16.x or higher (for TypeScript scripts)

### Cloning the Repository
```bash
git clone https://github.com/devgrunge/shell_utils.git
cd shell_utils
```

---

## Available Scripts

### Shell Scripts
Shell scripts are located in the `bash_scripts` folder.

#### Example: Export Environment Variables
- **Script**: `bash_scripts/export_env_vars.sh`
- **Description**: Exports environment variables from a service and formats them as `key=value`.
- **Usage**:
  ```bash
  chmod +x bash_scripts/export_env_vars.sh
  ./bash_scripts/export_env_vars.sh
  ```

---

### Python Scripts
Python scripts are located in the `python_scripts` folder.

#### Example: CSV to JSON Converter
- **Script**: `python_scripts/csvtojson.py`
- **Description**: Converts a CSV file to a JSON file.
- **Usage**:
  ```bash
  python python_scripts/csvtojson.py input.csv output.json
  ```

---

### TypeScript Scripts
TypeScript scripts are located in the `node_scripts` folder.

#### Example: JSON to Postman Converter
- **Script**: `node_scripts/json-to-postman/index.ts`
- **Description**: Converts a JSON file into a format compatible with Postman collections.
- **Usage**:
  1. Install dependencies:
     ```bash
     cd node_scripts/json-to-postman
     npm install
     ```
  2. Run the script:
     ```bash
     npm start input.json output.postman.json
     ```

---

## Contributing

We welcome contributions! Follow these steps to contribute:
1. Fork the repository.
2. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add your message here"
   ```
4. Push to your branch:
   ```bash
   git push origin feature/your-feature-name
   ```
5. Open a pull request.

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
