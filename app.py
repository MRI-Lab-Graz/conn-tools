import os
import subprocess
import sys
import json
import webbrowser
from threading import Timer
from flask import Flask, render_template, request, Response, jsonify
from waitress import serve

# Import local modules
from scripts_py.reorganize_data import reorganize_data
from scripts_py.export_light import export_light

app = Flask(__name__)

# --- API Endpoints ---

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

def run_command(cmd_args):
    """Executes a command and yields output line by line."""
    process = subprocess.Popen(
        [sys.executable] + cmd_args,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        universal_newlines=True
    )
    for line in iter(process.stdout.readline, ""):
        yield f"data: {line.strip()}\n\n"
    process.stdout.close()
    process.wait()
    yield "data: [DONE]\n\n"

@app.route('/run/reorganize')
def run_reorganize():
    path = request.args.get('path')
    return Response(run_command(["scripts_py/reorganize_data.py", path]), mimetype='text/event-stream')

@app.route('/run/map-ids')
def run_map_ids():
    conn = request.args.get('conn')
    bids = request.args.get('bids')
    return Response(run_command(["map_conn_ids.py", "-conn", conn, "-bids", bids]), mimetype='text/event-stream')

@app.route('/run/export')
def run_export():
    source = request.args.get('source')
    dest = request.args.get('dest')
    return Response(run_command(["scripts_py/export_light.py", source, dest]), mimetype='text/event-stream')

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
