from ultralytics import YOLO
import os

PT_MODEL_PATH = "best.pt"
if os.path.exists(PT_MODEL_PATH):
    pt_model = YOLO(PT_MODEL_PATH)
    raw_names = pt_model.names
    
    FIX_MAP = {
        "0": "Potato",
        "2": "Carrot",
        "15": "Onion",
        "1": "Eggplant"
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

    print("VERIFY_START")
    print(f"Class 0: {class_names[0]}")
    print(f"Class 1: {class_names[1]}")
    print(f"Class 2: {class_names[2]}")
    print(f"Class 3: {class_names[3]}")
    print(f"Class 11: {class_names[11]}")
    print(f"Class 51: {class_names[51]}")
    print(f"Class 76: {class_names[76]}")
    print("VERIFY_END")
else:
    print("best.pt not found")
