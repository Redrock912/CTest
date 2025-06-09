# CTest

This repository demonstrates basic Python environment setup.

## Setup

1. Install Python 3.12 or later.
2. Create a virtual environment:
   ```bash
   python3 -m venv .venv
   ```
3. Activate the virtual environment:
   ```bash
   source .venv/bin/activate
   ```
4. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Running the sample script

After activating the environment, run:

```bash
python hello.py
```

The script prints a greeting message.

## Tools

### Weather prediction tool

Fetch past 20 days of weather information and a 7 day forecast using the [Open-Meteo](https://open-meteo.com/) API.

Example:

```bash
python tools/weather.py 52.52 13.41
```

### Template tool

Placeholder script for future functionality:

```bash
python tools/template_tool.py
```
