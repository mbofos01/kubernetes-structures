# Simple API

A simple FastAPI application for Kubernetes experiments. The API provides host and pod information via the `/info` endpoint.

## Prerequisites

- Python 3.11 or later
- pip (Python package manager)

## Local Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Run the API

```bash
uvicorn simple-api.main:app --reload --host 0.0.0.0 --port 8000
```

The server will start on `http://localhost:8000`

### 3. Access the API

- **Interactive API docs:** http://localhost:8000/docs
- **API endpoint:** http://localhost:8000/info

Example response from `/info`:

```json
{
  "hostname": "DESKTOP-ABC123",
  "ip_address": "192.168.1.100",
  "platform": "Windows-10-10.0.19045-SP1",
  "python_version": "3.11.5",
  "pid": 1234,
  "pod_name": null,
  "namespace": null,
  "timestamp": "2026-10-25T00:18:48.684000+00:00"
}
```

## Development

The server runs in watch mode and will automatically reload when you modify `simple-api/main.py`.

## Kubernetes Deployment (Future)

To deploy to a local Kubernetes cluster using `kind`, see deployment instructions (coming soon).

## Project Structure

```
.
├── simple-api/
│   └── main.py           # FastAPI application
├── requirements.txt      # Python dependencies
└── README.md            # This file
```
