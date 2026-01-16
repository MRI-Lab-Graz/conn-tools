import os
import subprocess
import sys
import json
import webbrowser
import threading
import queue
import io
import contextlib
from threading import Timer
from flask import Flask, render_template, request, Response, jsonify
from waitress import serve

# Helper to find resources in bundled apps (PyInstaller)
def resource_path(relative_path):
    """ Get absolute path to resource, works for dev and for PyInstaller """
    try:
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")
    return os.path.join(base_path, relative_path)

# Import local modules
from scripts_py.reorganize_data import reorganize_data
from scripts_py.export_light import export_light
import map_conn_ids

app = Flask(__name__, 
            template_folder=resource_path('templates'),
            static_folder=resource_path('static'))

# --- API Endpoints ---
# ... (rest of the file remains the same until the runner)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/ls')
def list_dir():
    path = request.args.get('path', os.getcwd())
    if not os.path.exists(path):
        # Try to find a valid parent
        path = os.path.expanduser("~")
    
    try:
        items = []
        # Sort so directories come first
        all_items = sorted(os.listdir(path), key=lambda x: (not os.path.isdir(os.path.join(path, x)), x.lower()))
        
        for item in all_items:
            full_path = os.path.join(path, item)
            items.append({
                "name": item,
                "path": full_path,
                "is_dir": os.path.isdir(full_path)
            })
        return jsonify({
            "current_path": os.path.abspath(path),
            "items": items
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/api/mkdir', methods=['POST'])
def make_dir():
    data = request.json
    path = data.get('path')
    name = data.get('name')
    new_path = os.path.join(path, name)
    try:
        os.makedirs(new_path, exist_ok=True)
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 400

# --- Runner Endpoints with Streaming ---

class StreamProcessor(io.StringIO):
    def __init__(self, q):
        super().__init__()
        self.q = q
    def write(self, s):
        if s.strip():
            self.q.put(s.strip())
        return super().write(s)

def run_in_thread(func, args, q):
    # Capture stdout and stderr
    with contextlib.redirect_stdout(StreamProcessor(q)):
        with contextlib.redirect_stderr(StreamProcessor(q)):
            try:
                func(*args)
            except Exception as e:
                print(f"Error: {str(e)}")
    q.put("[DONE]")

def stream_from_queue(q):
    while True:
        msg = q.get()
        if msg == "[DONE]":
            yield "data: [DONE]\n\n"
            break
        yield f"data: {msg}\n\n"

@app.route('/run/reorganize')
def run_reorganize():
    path = request.args.get('path')
    q = queue.Queue()
    threading.Thread(target=run_in_thread, args=(reorganize_data, [path], q)).start()
    return Response(stream_from_queue(q), mimetype='text/event-stream')

@app.route('/run/map-ids')
def run_map_ids():
    conn = request.args.get('conn')
    bids = request.args.get('bids')
    q = queue.Queue()
    threading.Thread(target=run_in_thread, args=(map_conn_ids.run_mapping, [conn, bids], q)).start()
    return Response(stream_from_queue(q), mimetype='text/event-stream')

@app.route('/run/export')
def run_export():
    source = request.args.get('source')
    dest = request.args.get('dest')
    q = queue.Queue()
    threading.Thread(target=run_in_thread, args=(export_light, [source, dest], q)).start()
    return Response(stream_from_queue(q), mimetype='text/event-stream')

if __name__ == '__main__':
    port = 5000
    max_retries = 10
    
    def open_browser(p):
        webbrowser.open(f"http://localhost:{p}")

    for i in range(max_retries):
        try:
            print(f"Starting CONN Tool Manager at http://localhost:{port}")
            # Start a timer to open the browser shortly after the server starts
            Timer(1.5, open_browser, args=[port]).start()
            serve(app, host='0.0.0.0', port=port)
            break
        except OSError as e:
            if e.errno == 48 or (os.name == 'nt' and e.errno == 10048):
                print(f"Port {port} is in use, trying {port + 1}...")
                port += 1
            else:
                raise e
        except Exception as e:
            # Handle other potential exceptions from serve
            if "already in use" in str(e).lower():
                print(f"Port {port} is in use, trying {port + 1}...")
                port += 1
            else:
                raise e
