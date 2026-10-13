from ultralytics import YOLO
import os

model_path = "best.pt"
if os.path.exists(model_path):
    model = YOLO(model_path)
    print("MODEL_NAMES_START")
    print(model.names)
    print("MODEL_NAMES_END")
else:
    print("best.pt not found in current directory")
