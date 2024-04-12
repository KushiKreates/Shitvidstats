from flask import Flask, send_file, request
import requests
import cv2
import numpy as np
import imageio
import psutil

app = Flask(__name__)

################################################################################################
##Video....

def fetch_overlay_image_video(usern, interval, mode):
    try:
        image_url = f"http://api.astralaxis.info:35819/vod/{usern}/{interval}/{mode}"
        response = requests.get(image_url)
        response.raise_for_status()  # Raise an exception for bad status codes
        image_data = response.content
        image_array = np.frombuffer(image_data, dtype=np.uint8)
        image = cv2.imdecode(image_array, cv2.IMREAD_UNCHANGED)
        return image
    except requests.exceptions.RequestException as e:
        print(f"Error fetching overlay image: {e}")
        return None

def overlay_image_video(video_path, overlay_image):
    try:
        # Open video capture
        cap = cv2.VideoCapture(video_path)

        # Get video properties
        frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        fps = int(cap.get(cv2.CAP_PROP_FPS))

        # Create output video writer
        output_video_path = "output.mp4"
        out = cv2.VideoWriter(output_video_path, cv2.VideoWriter_fourcc(*'mp4v'), fps, (frame_width, frame_height))

        # Iterate through each frame of the video
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            # Resize overlay image to match frame dimensions
            overlay_resized = cv2.resize(overlay_image, (frame_width, frame_height))

            # Overlay image on frame
            for c in range(0, 3):
                frame[:, :, c] = overlay_resized[:, :, c] * (overlay_resized[:, :, 3] / 255.0) + frame[:, :, c] * (1.0 - overlay_resized[:, :, 3] / 255.0)

            # Write frame to video
            out.write(frame)

        # Release resources
        cap.release()
        out.release()

        return output_video_path

    except Exception as e:
        print(f"Error overlaying image on video: {e}")
        return None

@app.route('/overlay/video/<usern>/<interval>/<mode>')
def generate_video(usern, interval, mode):
    try:
        # Load the video file
        bg = request.args.get('bg')
        if bg == '1':
            video_path = "well1.mp4"
        elif bg == '2':
            video_path = "well3.mp4"
        elif bg == '4':
            video_path = "well4.mp4"
        else:
            video_path = "well2.mp4"

        # Fetch the overlay image from the API
        overlay_image_data = fetch_overlay_image_video(usern, interval, mode)
        if overlay_image_data is None:
            return "Error fetching overlay image", 500

        # Overlay image on video and create output video
        output_video_path = overlay_image_video(video_path, overlay_image_data)
        if output_video_path is None:
            return "Error creating video", 500

        # Return the generated video file
        return send_file(output_video_path)

    except Exception as e:
        return str(e)

################################################################################################
#Gif

def fetch_overlay_image_gif(usern, interval, mode):
    try:
        image_url = f"http://api.astralaxis.info:35819/vod/{usern}/{interval}/{mode}"
        response = requests.get(image_url)
        response.raise_for_status()  # Raise an exception for bad status codes
        image_data = response.content
        image_array = np.frombuffer(image_data, dtype=np.uint8)
        image = cv2.imdecode(image_array, cv2.IMREAD_UNCHANGED)
        return image
    except requests.exceptions.RequestException as e:
        print(f"Error fetching overlay image: {e}")
        return None

def overlay_image_gif(video_path, overlay_image):
    try:
        # Open video capture
        cap = cv2.VideoCapture(video_path)

        # Get video properties
        frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        fps = int(cap.get(cv2.CAP_PROP_FPS))
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

        # Trim the video to make it faster
        target_duration = 1.4  # seconds
        target_frame_count = int(target_duration * fps)
        frame_skip = int(frame_count / target_frame_count)

        # Initialize frames list
        frames = []

        # Iterate through each frame of the video
        for i in range(target_frame_count):
            cap.set(cv2.CAP_PROP_POS_FRAMES, i * frame_skip)
            ret, frame = cap.read()
            if not ret:
                break

            # Resize overlay image to match frame dimensions
            overlay_resized = cv2.resize(overlay_image, (frame_width, frame_height))

            # Overlay image on frame
            for c in range(0, 3):
                frame[:, :, c] = overlay_resized[:, :, c] * (overlay_resized[:, :, 3] / 255.0) + frame[:, :, c] * (1.0 - overlay_resized[:, :, 3] / 255.0)

            # Convert frame to RGB (imageio expects RGB)
            frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            # Append frame to the list
            frames.append(frame)

        # Release resources
        cap.release()

        # Create output GIF
        output_gif_path = "output.gif"
        imageio.mimsave(output_gif_path, frames, fps=fps)

        return output_gif_path

    except Exception as e:
        print(f"Error overlaying image on video: {e}")
        return None

@app.route('/overlay/gif/<usern>/<interval>/<mode>')
def generate_gif(usern, interval, mode):
    try:
        # Load the video file
        bg = request.args.get('bg')
        if bg == '1':
            video_path = "well1.mp4"
        elif bg == '2':
            video_path = "well3.mp4"
        elif bg == '4':
            video_path = "well4.mp4"
        else:
            video_path = "well2.mp4"

        # Fetch the overlay image from the API
        overlay_image_data = fetch_overlay_image_gif(usern, interval, mode)
        if overlay_image_data is None:
            return "Error fetching overlay image", 500

        # Overlay image on video and create GIF
        output_gif_path = overlay_image_gif(video_path, overlay_image_data)
        if output_gif_path is None:
            return "Error creating GIF", 500

        # Return the generated GIF file
        return send_file(output_gif_path)

    except Exception as e:
        return str(e)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=25684, debug=False)
