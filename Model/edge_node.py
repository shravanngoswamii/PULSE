import cv2
import time
import requests
from datetime import datetime
from ultralytics import YOLO

# 1. Configuration
NODE_ID = "Intersection_1" # Change this for different Raspberry Pis
BACKEND_URL = "http://127.0.0.1:8000/api/edge/density"
UPDATE_INTERVAL = 2.0 # Send data to server every 2 seconds

# 2. Load the lightweight edge model (downloads automatically the first time)
print("Loading YOLOv8 Nano model...")
model = YOLO("yolov8n.pt") 

# COCO Class IDs for vehicles
VEHICLE_CLASSES = {
    2: ("car", 2),       # Class ID: (Name, Congestion Weight)
    3: ("motorcycle", 1),
    5: ("bus", 4),
    7: ("truck", 4)
}

def calculate_density(results):
    total_weight = 0
    vehicle_counts = {"car": 0, "motorcycle": 0, "bus": 0, "truck": 0}
    
    # Parse the YOLO boxes
    for box in results[0].boxes:
        class_id = int(box.cls[0])
        if class_id in VEHICLE_CLASSES:
            name, weight = VEHICLE_CLASSES[class_id]
            vehicle_counts[name] += 1
            total_weight += weight
            
    return total_weight, vehicle_counts

def main():
    # 1. CHANGE THIS LINE: Put your video file name here instead of '0'
    cap = cv2.VideoCapture("traffic.mp4") 
    last_update_time = time.time()

    print(f"Starting Edge AI Node: {NODE_ID}")

    while cap.isOpened():
        success, frame = cap.read()
        
        # 2. HACKATHON PRO-TIP: Loop the video if it ends!
        if not success:
            print("Video ended. Looping back to the start...")
            cap.set(cv2.CAP_PROP_POS_FRAMES, 0) # Reset video to frame 0
            continue

        # Run YOLO inference
        results = model(frame, classes=list(VEHICLE_CLASSES.keys()), verbose=False)
        
        # Calculate the congestion weight
        density_weight, counts = calculate_density(results)

        # Draw the bounding boxes on the frame
        annotated_frame = results[0].plot()
        
        # Add UI overlay
        cv2.putText(annotated_frame, f"PULSE Edge Node: {NODE_ID}", (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 255), 2)
        cv2.putText(annotated_frame, f"Density Score: {density_weight}", (20, 80), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255), 2)
        cv2.imshow("PULSE V2I - Edge Vision", annotated_frame)

        # Send data to the FastAPI Backend every X seconds
        current_time = time.time()
        if current_time - last_update_time >= UPDATE_INTERVAL:
            payload = {
                "node_id": NODE_ID,
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "densities": {"total_weight": density_weight, "raw_counts": counts},
                "status": "active"
            }
            try:
                response = requests.post(BACKEND_URL, json=payload)
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Sent Density: {density_weight} -> Server Response: {response.status_code}")
            except Exception as e:
                pass # Silently fail if backend isn't running yet
                
            last_update_time = current_time

        # Press 'q' to quit
        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

    cap.release()
    cv2.destroyAllWindows()
    # Open the webcam (Use '0' for webcam, or put a video file path like 'traffic.mp4')
    cap = cv2.VideoCapture(0) 
    last_update_time = time.time()

    print(f"Starting Edge AI Node: {NODE_ID}")

    while cap.isOpened():
        success, frame = cap.read()
        if not success:
            break

        # Run YOLO inference (filtering only for our vehicle classes to save processing power)
        results = model(frame, classes=list(VEHICLE_CLASSES.keys()), verbose=False)
        
        # Calculate the congestion weight
        density_weight, counts = calculate_density(results)

        # Draw the bounding boxes on the frame for our visual demo
        annotated_frame = results[0].plot()
        
        # Add a sleek UI overlay for the hackathon demo video
        cv2.putText(annotated_frame, f"PULSE Edge Node: {NODE_ID}", (20, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 255), 2)
        cv2.putText(annotated_frame, f"Density Score: {density_weight}", (20, 80), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255), 2)
        cv2.imshow("PULSE V2I - Edge Vision", annotated_frame)

        # Send data to the FastAPI Backend every X seconds
        current_time = time.time()
        if current_time - last_update_time >= UPDATE_INTERVAL:
            payload = {
                "node_id": NODE_ID,
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "densities": {
                    "total_weight": density_weight,
                    "raw_counts": counts
                },
                "status": "active"
            }
            
            try:
                # Post to your FastAPI server!
                response = requests.post(BACKEND_URL, json=payload)
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Sent Density: {density_weight} -> Server Response: {response.status_code}")
            except Exception as e:
                print(f"Backend offline or unreachable. Error: {e}")
                
            last_update_time = current_time

        # Press 'q' to quit
        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()