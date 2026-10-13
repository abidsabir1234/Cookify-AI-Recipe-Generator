from ultralytics import YOLO
import os

model_path = "best.pt"
if os.path.exists(model_path):
    model = YOLO(model_path)
    raw_names = model.names
    
    FIX_MAP = {
        "0": "Potato",
        "2": "Carrot",
        "15": "Onion",
        "1": "Eggplant"
    }
    
    class_names = []
    for idx in range(len(raw_names)):
        name = raw_names[idx]
        clean_name = FIX_MAP.get(name, name)
        clean_name = clean_name.replace('_', ' ').replace('-', ' ').strip()
        
        if clean_name.lower() in ["green_chill", "green chill"]: clean_name = "Green Chilli"
        if clean_name.lower() in ["red chili", "red_chilli"]: clean_name = "Red Chilli"
        
        clean_name = " ".join([w.capitalize() for w in clean_name.split()])
        
        if clean_name.lower().endswith('oes'): 
            clean_name = clean_name[:-2]
        elif clean_name.lower().endswith('s') and not clean_name.lower().endswith('ss'):
            clean_name = clean_name[:-1]
            
        class_names.append(clean_name)
    
    print("CLEAN_NAMES_START")
    print(class_names)
    print("CLEAN_NAMES_END")
else:
    print("best.pt not found")
