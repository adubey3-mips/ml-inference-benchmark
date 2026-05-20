#!/usr/bin/env python3
"""Inspect a TFLite model's input/output specs."""
import sys

try:
    import tflite_runtime.interpreter as tflite
    Interpreter = tflite.Interpreter
except ImportError:
    from tensorflow.lite.python.interpreter import Interpreter

def inspect(path):
    interp = Interpreter(model_path=path)
    interp.allocate_tensors()
    print(f"Model: {path}")
    print("Input details:")
    for d in interp.get_input_details():
        print(f"  name={d['name']}")
        print(f"  shape={d['shape']}")
        print(f"  dtype={d['dtype']}")
        print(f"  quant_params={d['quantization_parameters']}")
    print("Output details:")
    for d in interp.get_output_details():
        print(f"  name={d['name']}")
        print(f"  shape={d['shape']}")
        print(f"  dtype={d['dtype']}")
        print(f"  quant_params={d['quantization_parameters']}")

if __name__ == "__main__":
    inspect(sys.argv[1])
