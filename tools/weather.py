import argparse
import datetime
import requests


API_BASE_FORECAST = "https://api.open-meteo.com/v1/forecast"
API_BASE_ARCHIVE = "https://archive-api.open-meteo.com/v1/archive"


def fetch_past_weather(lat: float, lon: float, days: int = 20):
    """Fetch past weather data for the given latitude and longitude."""
    end_date = datetime.date.today()
    start_date = end_date - datetime.timedelta(days=days)

    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat(),
        "daily": [
            "temperature_2m_max",
            "temperature_2m_min",
            "precipitation_sum",
        ],
        "timezone": "auto",
    }

    response = requests.get(API_BASE_ARCHIVE, params=params, timeout=10)
    response.raise_for_status()
    return response.json().get("daily", {})


def fetch_future_weather(lat: float, lon: float, days: int = 7):
    """Fetch weather forecast for the next given number of days."""
    params = {
        "latitude": lat,
        "longitude": lon,
        "daily": [
            "temperature_2m_max",
            "temperature_2m_min",
            "precipitation_sum",
        ],
        "forecast_days": days,
        "timezone": "auto",
    }

    response = requests.get(API_BASE_FORECAST, params=params, timeout=10)
    response.raise_for_status()
    return response.json().get("daily", {})


def main():
    parser = argparse.ArgumentParser(description="Weather prediction tool using Open-Meteo")
    parser.add_argument("lat", type=float, help="Latitude")
    parser.add_argument("lon", type=float, help="Longitude")
    args = parser.parse_args()

    print("Fetching past 20 days of weather data...")
    past = fetch_past_weather(args.lat, args.lon)
    print(past)

    print("\nFetching 7 day forecast...")
    future = fetch_future_weather(args.lat, args.lon)
    print(future)


if __name__ == "__main__":
    main()
