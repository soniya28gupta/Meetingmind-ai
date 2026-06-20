import io
import json
import numpy as np
import scipy.io.wavfile
import time
from flask import Flask, jsonify, request

app = Flask(__name__)

def extract_pitch(signal, sr):
    """Extract fundamental frequency (F0) using autocorrelation."""
    if len(signal) < 320:
        return 0.0
        
    # Autocorrelation
    r = np.correlate(signal, signal, mode='full')
    r = r[len(r)//2:]
    
    # Human pitch range: 50Hz to 400Hz
    # Lag ranges: sr / 400 to sr / 50
    min_lag = int(sr / 400)
    max_lag = int(sr / 50)
    
    if max_lag >= len(r):
        max_lag = len(r) - 1
    if min_lag >= max_lag:
        return 0.0
        
    search_range = r[min_lag:max_lag]
    if len(search_range) == 0:
        return 0.0
        
    peak_lag = np.argmax(search_range) + min_lag
    peak_val = r[peak_lag]
    
    # Check if there is periodic peak matching
    if r[0] > 0 and peak_val > 0.25 * r[0]:
        return float(sr / peak_lag)
    return 0.0

def extract_spectral_embedding(signal, sr):
    """Compute normalized 13-band log-filterbank style spectral energies (voice embedding)."""
    if len(signal) < 256:
        return [0.0] * 13
        
    fft_vals = np.abs(np.fft.rfft(signal))
    freqs = np.fft.rfftfreq(len(signal), 1.0 / sr)
    
    # Log-spaced band limits from 100Hz to 8000Hz (13 bands)
    limits = np.logspace(np.log10(100), np.log10(min(8000, sr // 2 - 100)), 14)
    embedding = []
    
    for i in range(13):
        lower = limits[i]
        upper = limits[i+1]
        mask = (freqs >= lower) & (freqs < upper)
        band_fft = fft_vals[mask]
        
        if len(band_fft) > 0:
            energy = np.sum(band_fft**2)
            embedding.append(float(np.log(energy + 1e-6)))
        else:
            embedding.append(-12.0)
            
    # L2 normalize the embedding
    emb_np = np.array(embedding)
    norm = np.linalg.norm(emb_np)
    if norm > 0:
        emb_np = emb_np / norm
    return emb_np.tolist()

def classify_emotion(pitch_vals, rms_vals, zcr_vals, pauses_ratio):
    """Heuristic rule-based classifier for voice tonality emotions."""
    voiced_pitch = [p for p in pitch_vals if p > 0]
    
    mean_pitch = np.mean(voiced_pitch) if voiced_pitch else 140.0
    var_pitch = np.var(voiced_pitch) if voiced_pitch else 0.0
    mean_rms = np.mean(rms_vals) if len(rms_vals) > 0 else 0.04
    mean_zcr = np.mean(zcr_vals) if len(zcr_vals) > 0 else 0.05
    
    # Rule classification based on acoustic features
    if mean_pitch > 170 and mean_rms > 0.06:
        if var_pitch > 180:
            res = ("Excited", 0.88)
        else:
            res = ("Happy", 0.84)
    elif mean_rms > 0.08:
        if mean_zcr > 0.12:
            res = ("Frustrated", 0.78)
        else:
            res = ("Confident", 0.83)
    elif mean_rms < 0.015:
        if pauses_ratio > 0.35:
            res = ("Bored", 0.72)
        else:
            res = ("Calm", 0.82)
    elif pauses_ratio > 0.4:
        res = ("Thinking", 0.75)
    elif var_pitch > 120:
        if mean_pitch > 150:
            res = ("Nervous", 0.74)
        else:
            res = ("Concerned", 0.78)
    else:
        res = ("Neutral", 0.90)
        
    return res

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    print("Emotion request received")
    resp = jsonify({"status": "online"})
    print("Response sent")
    return resp

@app.route('/emotion', methods=['GET'])
def emotion():
    """Fallback basic endpoint."""
    print("Emotion request received")
    resp = jsonify({
        "emotion": "Neutral",
        "confidence": 0.92
    })
    print("Response sent")
    return resp

@app.route('/analyze_audio', methods=['POST'])
def analyze_audio():
    """
    POST /analyze_audio
    Parameters:
      audio: WAV Audio File
      segments: JSON list of segments containing {startTime, endTime, speaker, text}
    """
    print("Emotion request received")
    if 'audio' not in request.files:
        print("Backend exception")
        return jsonify({"error": "Missing audio file in request"}), 400
        
    audio_file = request.files['audio']
    segments_json = request.form.get('segments', '[]')
    
    try:
        segments = json.loads(segments_json)
        print("Transcript received")
    except Exception as e:
        print("Backend exception")
        return jsonify({"error": f"Invalid segments JSON: {str(e)}"}), 400
        
    try:
        print("Model loaded")
        # Load WAV using scipy
        sr, audio_data = scipy.io.wavfile.read(io.BytesIO(audio_file.read()))
        
        # Convert to mono if stereo
        if len(audio_data.shape) > 1:
            audio_data = audio_data.mean(axis=1)
            
        # Normalize to float32 [-1.0, 1.0]
        if audio_data.dtype == np.int16:
            audio_data = audio_data.astype(np.float32) / 32768.0
        elif audio_data.dtype == np.int32:
            audio_data = audio_data.astype(np.float32) / 2147483648.0
        elif audio_data.dtype == np.uint8:
            audio_data = (audio_data.astype(np.float32) - 128.0) / 128.0
        else:
            audio_data = audio_data.astype(np.float32)
            
    except Exception as e:
        print("Backend exception")
        return jsonify({"error": f"Failed to decode audio WAV file: {str(e)}"}), 500

    total_duration = len(audio_data) / float(sr)
    
    # Gather voice embeddings, emotions, and durations per speaker index
    speakers_data = {}
    segment_emotions_timeline = []
    
    for idx, seg in enumerate(segments):
        start_t = float(seg.get('startTime', 0.0))
        end_t = float(seg.get('endTime', 0.0))
        speaker_idx = int(seg.get('speaker', 0))
        text = seg.get('text', '')
        
        if end_t <= start_t:
            continue
            
        # Slice audio for this segment
        start_sample = int(start_t * sr)
        end_sample = int(end_t * sr)
        
        # Guard limits
        start_sample = max(0, min(start_sample, len(audio_data)))
        end_sample = max(0, min(end_sample, len(audio_data)))
        
        chunk = audio_data[start_sample:end_sample]
        
        # Compute DSP properties
        pitch_vals = []
        rms_vals = []
        zcr_vals = []
        silent_frames = 0
        total_frames = 0
        
        # Frame-by-frame analysis inside the segment (50ms frames, 25ms shift)
        frame_len = int(0.050 * sr)
        frame_shift = int(0.025 * sr)
        
        if len(chunk) >= frame_len:
            for start_f in range(0, len(chunk) - frame_len, frame_shift):
                frame = chunk[start_f : start_f + frame_len]
                rms = np.sqrt(np.mean(frame**2)) + 1e-6
                rms_vals.append(rms)
                
                # Check for silence (below noise threshold)
                if rms < 0.003:
                    silent_frames += 1
                else:
                    pitch = extract_pitch(frame, sr)
                    pitch_vals.append(pitch)
                    
                zcr = np.mean(np.abs(np.diff(np.sign(frame)))) / 2.0
                zcr_vals.append(zcr)
                total_frames += 1
                
        pauses_ratio = silent_frames / float(total_frames) if total_frames > 0 else 0.0
        
        # Segment emotion classification
        seg_emotion, confidence = classify_emotion(pitch_vals, rms_vals, zcr_vals, pauses_ratio)
        print("Emotion prediction complete")
        
        segment_emotions_timeline.append({
            "startTime": start_t,
            "endTime": end_t,
            "speaker": speaker_idx,
            "emotion": seg_emotion,
            "confidence": confidence
        })
        
        # Get voice embedding for segment
        seg_embedding = extract_spectral_embedding(chunk, sr)
        
        # Word count calculation
        word_count = len(text.split())
        
        if speaker_idx not in speakers_data:
            speakers_data[speaker_idx] = {
                "speakerIndex": speaker_idx,
                "embeddingsList": [],
                "emotions": [],
                "speakingTime": 0.0,
                "wordCount": 0,
                "turns": 0
            }
            
        spk = speakers_data[speaker_idx]
        spk["embeddingsList"].append(seg_embedding)
        spk["emotions"].append(seg_emotion)
        spk["speakingTime"] += (end_t - start_t)
        spk["wordCount"] += word_count
        spk["turns"] += 1

    # Aggregate speakers voice embeddings and mood summaries
    speakers_list = []
    total_speaking_time = sum(spk["speakingTime"] for spk in speakers_data.values())
    
    for spk_idx, data in speakers_data.items():
        # Average embeddings
        mean_emb = np.mean(data["embeddingsList"], axis=0)
        norm = np.linalg.norm(mean_emb)
        if norm > 0:
            mean_emb = mean_emb / norm
            
        # Mood tally
        moods = data["emotions"]
        primary_mood = max(set(moods), key=moods.count) if moods else "Neutral"
        mood_count = moods.count(primary_mood)
        mood_conf = float(mood_count / len(moods)) if moods else 0.85
        
        # Observations
        observation = ""
        if primary_mood in ["Happy", "Excited"]:
            observation = "Positive tone, highly engaged, energetic participation."
        elif primary_mood in ["Frustrated"]:
            observation = "Tense voice tone, rapid speaking rate, possible friction."
        elif primary_mood in ["Calm", "Neutral"]:
            observation = "Steady, moderate pitch, highly stable and clear delivery."
        elif primary_mood in ["Thinking"]:
            observation = "Frequent pauses, introspective tone, deliberate speaking rate."
        elif primary_mood in ["Nervous", "Concerned"]:
            observation = "Shaky pitch fluctuations, tentative energy levels."
        else:
            observation = "Normal business tone, steady involvement."
            
        participation = data["speakingTime"] / total_speaking_time if total_speaking_time > 0 else 0.0
        
        # Interaction score (simple heuristic: turns * speakingTime ratio)
        interaction = float(min(100.0, data["turns"] * 5.0 + participation * 50.0))
        
        speakers_list.append({
            "speakerIndex": spk_idx,
            "voiceEmbedding": mean_emb.tolist(),
            "primaryMood": primary_mood,
            "moodConfidence": mood_conf,
            "observation": observation,
            "analytics": {
                "speakingTimeSeconds": float(data["speakingTime"]),
                "wordCount": int(data["wordCount"]),
                "participationPercentage": float(participation),
                "interactionScore": float(interaction)
            }
        })
        
    # Aggregate general meeting emotion timeline (e.g. grouped intervals of 30 seconds)
    meeting_timeline = []
    if len(segment_emotions_timeline) > 0:
        # Sort segments by start time
        segment_emotions_timeline.sort(key=lambda x: x["startTime"])
        interval = 30.0 # 30s chunks
        
        current_t = 0.0
        while current_t < total_duration:
            next_t = current_t + interval
            # Get emotions of segments overlapping this interval
            overlapping_emotions = []
            for seg in segment_emotions_timeline:
                if seg["startTime"] < next_t and seg["endTime"] > current_t:
                    overlapping_emotions.append(seg["emotion"])
                    
            if overlapping_emotions:
                most_freq = max(set(overlapping_emotions), key=overlapping_emotions.count)
            else:
                most_freq = "Neutral"
                
            meeting_timeline.append({
                "startTime": current_t,
                "endTime": min(next_t, total_duration),
                "emotion": most_freq
            })
            current_t = next_t
            
    print("Response sent")
    return jsonify({
        "speakers": speakers_list,
        "segmentEmotions": segment_emotions_timeline,
        "meetingTimeline": meeting_timeline,
        "totalDuration": total_duration
    })

if __name__ == '__main__':
    while True:
        try:
            print("Emotion server started")
            app.run(host="0.0.0.0", port=5000, debug=False)
        except Exception as e:
            print("Backend exception")
            time.sleep(2)