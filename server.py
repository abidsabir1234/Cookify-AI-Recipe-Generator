import cv2
import numpy as np
import uvicorn
import io
import os
from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

try:
    import onnxruntime as ort
    HAS_ONNX = True
except ImportError:
    HAS_ONNX = False

app = FastAPI(title="Cookify ONNX Detector")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MODEL_PATH = "best.onnx"
IMG_SIZE = 640
CONF_THRESHOLD = 0.30
IOU_THRESHOLD = 0.45

CLASS_NAMES = [
    'Potato', 'Eggplant', 'Onion', 'Carrot', 'Apple', 'Cabbage', 'Carrot', 'Coriander', 'Cucumber', 'Egg', 
    'Garlic', 'Green Chilli', 'Green Lemon', 'Italian Parsley', 'Lemon', 'Lime', 'Mushroom', 'Noodle', 
    'Onion', 'Orange', 'Red Chilli', 'Rice', 'Salmon', 'Spring Onion', 'Tomato', 'Apple', 'Background', 
    'Basmati Rice', 'Beef', 'Brown Rice', 'Button Mushroom', 'Cabbage', 'Carrot', 'Carrot', 'Chicken', 
    'Chicken Broth', 'Chicken Stock Seasoning', 'Chili', 'Chilli', 'Cilantro', 'Coriander', 'Cucumber', 
    'Dried Mushroom', 'Egg', 'Egg', 'Fish', 'Flat Noodle', 'Garlic', 'Ginger', 'Green Chilie', 
    'Green Chilli', 'Green Chilli', 'Honey', 'Hor Fun', 'Ikan Bilis Seasoning', 'Kway Teow', 'Lemon', 
    'Lime', 'Milk', 'Mushroom', 'Olive', 'Onion', 'Orange', 'Orange', 'Parsley', 'Peanut', 'Pork', 
    'Potato', 'Prawn', 'Red Chilli', 'Red Chilli', 'Rice', 'Shrimp', 'Spring Onion', 'Stock', 'Tomato', 
    'Tomato', 'Udon Noodle', 'White Rice', 'Yoghurt'
]

if HAS_ONNX and os.path.exists(MODEL_PATH):
    try:
        session = ort.InferenceSession(MODEL_PATH, providers=['CPUExecutionProvider'])
        input_name = session.get_inputs()[0].name
        print(f"✅ Loaded ONNX model: {MODEL_PATH}")
    except Exception as e:
        print(f"❌ Failed to load ONNX model: {e}")
        session = None
else:
    session = None
    if os.path.exists(MODEL_PATH) and not HAS_ONNX:
        print("⚠️ ONNX model found but onnxruntime failed to load (DLL error).")

def letterbox(img, new_shape=(640, 640), color=(114, 114, 114)):
    shape = img.shape[:2]
    r = min(new_shape[0] / shape[0], new_shape[1] / shape[1])
    new_unpad = int(round(shape[1] * r)), int(round(shape[0] * r))
    dw, dh = new_shape[1] - new_unpad[0], new_shape[0] - new_unpad[1]
    dw, dh = dw / 2, dh / 2
    if shape[::-1] != new_unpad:
        img = cv2.resize(img, new_unpad, interpolation=cv2.INTER_LINEAR)
    top, bottom = int(round(dh - 0.1)), int(round(dh + 0.1))
    left, right = int(round(dw - 0.1)), int(round(dw + 0.1))
    img = cv2.copyMakeBorder(img, top, bottom, left, right, cv2.BORDER_CONSTANT, value=color)
    return img, r, (dw, dh)

@app.post("/detect")
async def detect(file: UploadFile = File(...)):
    if session is None:
        return JSONResponse({"error": "ONNX model not loaded"}, status_code=500)

    file_bytes = await file.read()
    nparr = np.frombuffer(file_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        return JSONResponse({"error": "Invalid image"}, status_code=400)

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_res, ratio, (dw, dh) = letterbox(img_rgb)
    input_img = img_res.astype(np.float32) / 255.0
    input_img = input_img.transpose(2, 0, 1)
    input_img = np.expand_dims(input_img, axis=0)

    outputs = session.run(None, {input_name: input_img})
    output = outputs[0]
    output = np.squeeze(output)
    output = output.transpose()

    boxes = []
    scores = []
    class_ids = []

    for row in output:
        classes_scores = row[4:]
        class_id = np.argmax(classes_scores)
        score = classes_scores[class_id]
        if score > CONF_THRESHOLD:
            cx, cy, w, h = row[:4]
            x = (cx - dw) / ratio
            y = (cy - dh) / ratio
            w /= ratio
            h /= ratio
            boxes.append([int(x - w/2), int(y - h/2), int(w), int(h)])
            scores.append(float(score))
            class_ids.append(int(class_id))

    indices = cv2.dnn.NMSBoxes(boxes, scores, CONF_THRESHOLD, IOU_THRESHOLD)

    predictions = []
    seen = set()
    if len(indices) > 0:
        for i in indices.flatten():
            label = CLASS_NAMES[class_ids[i]] if class_ids[i] < len(CLASS_NAMES) else f"class_{class_ids[i]}"
            if label not in seen:
                predictions.append({
                    "class": label,
                    "confidence": round(scores[i], 3),
                    "bbox": boxes[i]
                })
                seen.add(label)

    return {"predictions": predictions, "count": len(predictions)}

@app.get("/health")
def health():
    return {"status": "ok", "engine": "onnxruntime"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
