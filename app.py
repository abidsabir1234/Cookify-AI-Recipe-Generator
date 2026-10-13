import cv2
import numpy as np
import uvicorn
import io
import os
from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

try:
    from ultralytics import YOLO
    HAS_ULTRALYTICS = True
except ImportError:
    HAS_ULTRALYTICS = False

app = FastAPI(title="Cookify API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

PT_MODEL_PATH = "best.pt"
CONF_THRESHOLD = 0.15
IOU_THRESHOLD = 0.45

pt_model = None
class_names = {}

if HAS_ULTRALYTICS and os.path.exists(PT_MODEL_PATH):
    try:
        pt_model = YOLO(PT_MODEL_PATH)
        raw_names = pt_model.names
        
        FIX_MAP = {
            "0": "Potato",
            "1": "Onion",
            "2": "Carrot",
            "3": "Eggplant"
        }
        
        class_names = {}
        for idx, name in raw_names.items():
            clean_name = FIX_MAP.get(name, name)
            clean_name = clean_name.replace('_', ' ').replace('-', ' ').strip()
            
            if clean_name.lower() in ["green_chill", "green chill"]: clean_name = "Green Chilli"
            if clean_name.lower() in ["red chili", "red_chilli"]: clean_name = "Red Chilli"
            
            clean_name = " ".join([w.capitalize() for w in clean_name.split()])
            
            if clean_name.lower().endswith('oes'): 
                clean_name = clean_name[:-2]
            elif clean_name.lower().endswith('s') and not clean_name.lower().endswith('ss'):
                clean_name = clean_name[:-1]
                
            class_names[idx] = clean_name
            
        print(f"✅ Cookify Engine Ready: {len(class_names)} classes.")
    except Exception as e:
        print(f"❌ Initialization Error: {e}")
else:
    class_names = {}

@app.post("/detect")
async def detect(file: UploadFile = File(...)):
    if pt_model is None:
        return JSONResponse({"error": "Model not loaded"}, status_code=500)

    try:
        file_bytes = await file.read()
        nparr = np.frombuffer(file_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            return JSONResponse({"error": "Invalid image"}, status_code=400)
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=400)

    try:
        results = pt_model(img, conf=CONF_THRESHOLD, iou=IOU_THRESHOLD, verbose=False)[0]
        predictions = []
        seen = set()
        
        for box in results.boxes:
            class_id = int(box.cls[0])
            label = class_names.get(class_id, f"Item_{class_id}")
            
            if label not in seen:
                x1, y1, x2, y2 = box.xyxy[0].tolist()
                predictions.append({
                    "class": label,
                    "confidence": round(float(box.conf[0]), 3),
                    "bbox": [int(x1), int(y1), int(x2-x1), int(y2-y1)]
                })
                seen.add(label)
        
        return {
            "predictions": predictions, 
            "count": len(predictions),
            "status": "success"
        }
    except Exception as e:
        return JSONResponse({"error": str(e)}, status_code=500)

@app.get("/")
def home():
    return {"app": "Cookify API", "status": "active"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
