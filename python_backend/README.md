# Quantum Random Number Generator Python Backend

This backend uses FastAPI and Qiskit to provide quantum random numbers via an HTTP API.

## Setup Instructions

1. Create and activate a Python virtual environment:
   
   ```sh
   python -m venv venv
   # On Windows:
   venv\Scripts\activate
   # On macOS/Linux:
   source venv/bin/activate
   ```

2. Install dependencies:
   
   ```sh
   pip install -r requirements.txt
   ```

3. Set up your IBM Quantum account:
   
   - Register at https://quantum-computing.ibm.com/ if you don't have an account.
   - Get your API token from your IBM Quantum account settings.
   - You can initialize your account in code or set the environment variable `QISKIT_IBM_TOKEN=your_real_ibm_quantum_api_token`.

4. Run the FastAPI server:
   
   ```sh
   uvicorn main:app --reload
   ```

The API will be available at http://localhost:8000
