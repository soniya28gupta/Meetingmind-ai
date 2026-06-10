from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/emotion')
def emotion():
    return jsonify({
        "emotion": "Neutral",
        "confidence": 0.92
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)