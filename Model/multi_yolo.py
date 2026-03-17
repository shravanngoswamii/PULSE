import cv2
import time
import requests
import multiprocessing
from datetime import datetime
from ultralytics import YOLO

BACKEND_URL = "http://127.0.0.1:8000/api/edge/density"
VEHICLE_CLASSES = {2: ("car", 2), 3: ("motorcycle", 1), 5: ("bus", 4), 7: ("truck", 4)}

def run_edge_node(node_id, video_source):
    print(f"Starting {node_id} on feed {video_source}...")
    model = YOLO("yolov8n.pt") # Each process loads its own model
    cap = cv2.VideoCapture(video_source)
    last_update = time.time()

    while cap.isOpened():
        success, frame = cap.read()
        if not success:
            cap.set(cv2.CAP_PROP_POS_FRAMES, 0) # Loop video
            continue

        # Resize frame to make it easier for 4 windows to fit on your Mac screen
        frame = cv2.resize(frame, (640, 360))
        results = model(frame, classes=list(VEHICLE_CLASSES.keys()), verbose=False)
        
        total_weight = sum([VEHICLE_CLASSES[int(box.cls[0])][1] for box in results[0].boxes if int(box.cls[0]) in VEHICLE_CLASSES])

        annotated_frame = results[0].plot()
        cv2.putText(annotated_frame, f"{node_id} | Density: {total_weight}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
        cv2.imshow(node_id, annotated_frame)

        if time.time() - last_update >= 2.0:
            payload = {"node_id": node_id, "timestamp": datetime.utcnow().isoformat() + "Z", "densities": {"total_weight": total_weight}, "status": "active"}
            try: requests.post(BACKEND_URL, json=payload)
            except: pass
            last_update = time.time()

        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == '__main__':
    # Map which video belongs to which intersection
    cameras = [
        ("Intersection_2", "vid1.mp4"),
        ("Intersection_4", "vid2.mp4"), # The traffic trap!
        ("Intersection_5", "vid3.mp4"),
        ("Intersection_6", "vid4.mp4")
    ]
    
    processes = []
    for node_id, video_file in cameras:
        p = multiprocessing.Process(target=run_edge_node, args=(node_id, video_file))
        p.start()
        processes.append(p)

    for p in processes:
        p.join()