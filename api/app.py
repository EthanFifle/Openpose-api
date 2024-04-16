from flask import Flask, request, jsonify
import cv2
import os
import tempfile
import pyopenpose as op
import numpy as np
import json  # Import JSON module

app = Flask(__name__)

# Initialize OpenPose with your configuration
params = {
    "model_folder": "../models",
    "write_json": tempfile.mkdtemp(),  # Temporary directory for JSON output
}
opWrapper = op.WrapperPython()
opWrapper.configure(params)
opWrapper.start()

@app.route('/process_image', methods=['POST'])
def process_image():
    # Check if an image was uploaded
    if 'image' not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    file = request.files['image']

    # Convert string data to numpy array
    npimg = np.fromstring(file.read(), np.uint8)
    # Read the image through OpenCV
    image = cv2.imdecode(npimg, cv2.IMREAD_UNCHANGED)
    # Process Image with OpenPose
    datum = op.Datum()
    datum.cvInputData = image
    opWrapper.emplaceAndPop(op.VectorDatum([datum]))

    # Assuming OpenPose was configured to write JSON to a temporary directory
    # Find the latest JSON file in the directory
    try:
        json_files = [os.path.join(params["write_json"], f) for f in os.listdir(params["write_json"]) if f.endswith('.json')]
        latest_file = max(json_files, key=os.path.getctime)
        with open(latest_file) as f:
            keypoints = json.load(f)  # Load the JSON content into a Python object
        # Clean up the temp directory
        os.remove(latest_file)
        return jsonify(keypoints), 200  # Return the Python object as JSON
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8081)
