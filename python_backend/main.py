import os
import random
import qiskit
from qiskit import QuantumCircuit, QuantumRegister
from qiskit_ibm_runtime import QiskitRuntimeService, Sampler
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# Initialize IBM Quantum service. Ensure your QISKIT_IBM_TOKEN is set.
IBM_TOKEN = os.getenv("QISKIT_IBM_TOKEN")
if not IBM_TOKEN:
    raise Exception("IBM Quantum token not set. Please set QISKIT_IBM_TOKEN in your environment.")

service = QiskitRuntimeService(channel="ibm_quantum", token=IBM_TOKEN)

@app.get("/backends")
def list_backends():
    try:
        return [b.name for b in service.backends()]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class RandomRequest(BaseModel):
    bits: Optional[int] = 1  # Number of qubits (and bits) to use (legacy)
    digits: Optional[int] = None  # Number of decimal digits required (e.g. 6 for lottery)
    backend: Optional[str] = None  # Optional backend name

@app.get("/")
def health_check():
    return {"status": "ok"}

@app.post("/random")
def get_quantum_random(req: RandomRequest):
    import traceback
    import math
    try:
        print("Received request:", req)
        # Determine if user requested 'digits' (number of decimal digits)
        if req.digits is not None:
            n_digits = max(1, min(req.digits, 12))  # Limit to 12 digits (0-999999999999)
            max_value = 10 ** n_digits
            n_bits = math.ceil(math.log2(max_value))
            print(f"User requested {n_digits} digits, so need {n_bits} bits (max_value: {max_value})")
        else:
            n_bits = max(1, min(req.bits, 32))
            n_digits = None
            max_value = 2 ** n_bits
            print(f"User requested {n_bits} bits (legacy mode)")
        
        # Create a circuit with a quantum register only (no measurement).
        qr = QuantumRegister(n_bits)
        qc = QuantumCircuit(qr)
        qc.h(qr)  # Apply Hadamard gate to create an equal superposition
        print("Quantum circuit created:", qc)
        
        # Determine backend: use provided one or default to "ibm_brisbane"
        backend_name = req.backend or "ibm_brisbane"
        print(f"Requested backend: {backend_name}")
        available_backends = [b.name for b in service.backends()]
        print("Available backends:", available_backends)
        if backend_name not in available_backends:
            print(f"Backend '{backend_name}' not available. Returning 400.")
            raise HTTPException(
                status_code=400,
                detail=f"Backend '{backend_name}' not available. Available: {available_backends}"
            )
        backend = service.backend(backend_name)
        print(f"Using backend: {backend}")
        
        # Add measurement to circuit for bitstring output
        from qiskit import ClassicalRegister, transpile
        cr = ClassicalRegister(n_bits)
        qc.add_register(cr)
        qc.measure(qr, cr)
        print("Quantum circuit with measurement:", qc)

        # Remove measurement and classical register for Sampler primitive
        from qiskit import transpile
        qc = transpile(qc, backend)
        print("Transpiled circuit (no measurement):", qc)

        # Run the circuit using the Sampler primitive
        print("Submitting job to Sampler...")
        sampler = Sampler(backend)
        job = sampler.run([qc])
        print("Job submitted. Waiting for result...")
        result = job.result()
        print("Job result received.")

        # Extract quantum probability distribution from Sampler result
        pub_result = result[0]
        databin = pub_result.data
        print("DataBin:", databin)
        print("DataBin attributes:", dir(databin))

        # Dynamically get the first BitArray attribute (c0, c1, ...)
        bitarray = None
        for attr in dir(databin):
            if attr.startswith('c'):
                maybe = getattr(databin, attr)
                # Check for BitArray by presence of get_counts()
                if hasattr(maybe, 'get_counts'):
                    bitarray = maybe
                    print(f"Found BitArray in DataBin attribute: {attr}")
                    break
        if bitarray is None:
            print("No BitArray found in DataBin!")
            return {"error": "No BitArray found in DataBin."}

        try:
            counts = bitarray.get_counts()
            print("BitArray counts:", counts)
            outcomes = list(counts.keys())
            probabilities = list(counts.values())
            print("Outcomes:", outcomes)
            print("Probabilities:", probabilities)
            bitstring = random.choices(outcomes, weights=probabilities, k=1)[0]
            bitstring = bitstring.zfill(n_bits)
            print("Selected bitstring (padded):", bitstring)
            rnd_number = int(bitstring, 2)
            print(f"Raw quantum integer: {rnd_number}")

            if n_digits is not None:
                # Map to decimal number with n_digits (0 to max_value-1), pad with zeros
                lottery_number = rnd_number % max_value
                lottery_number_str = str(lottery_number).zfill(n_digits)
                print(f"Quantum lottery number: {lottery_number_str}")
                return {
                    "random_number": lottery_number_str,
                    "digits": n_digits,
                    "bitstring": bitstring,
                    "raw_integer": rnd_number,
                    "max_value": max_value - 1
                }
            else:
                return {
                    "random_number": rnd_number,
                    "bits": n_bits,
                    "bitstring": bitstring,
                    "max_value": 2 ** n_bits - 1
                }
        except Exception as e:
            print("Exception extracting from BitArray using get_counts():", e)
            return {"error": "Failed to extract bitstrings from BitArray using get_counts(). See logs."}

    except Exception as e:
        print("Exception occurred in /random endpoint:")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"{str(e)}\n{traceback.format_exc()}")
