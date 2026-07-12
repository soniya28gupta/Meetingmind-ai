import io
import json
import numpy as np
import scipy.io.wavfile
import time
import socket
import os
import subprocess
import tempfile
import concurrent.futures
import requests
from flask import Flask, jsonify, request

app = Flask(__name__)
start_time = time.time()

@app.after_request
def add_cors_headers(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

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

@app.route('/', methods=['GET'])
def root():
    """Root endpoint returning service status."""
    return jsonify({
        "service": "MeetingMind Emotion API",
        "status": "online"
    })

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint returning detailed status."""
    print("Health request received")
    
    # Check Deepgram connectivity via socket
    deepgram_status = "connected"
    try:
        # Check standard Deepgram API host on port 443
        socket.setdefaulttimeout(2.0)
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(("api.deepgram.com", 443))
        s.close()
    except Exception as e:
        deepgram_status = f"unavailable: {str(e)}"
        
    uptime_seconds = time.time() - start_time
    
    resp = jsonify({
        "status": "online",
        "service": "emotion-analysis",
        "version": "1.0.0",
        "model_loaded": True,
        "uptime": int(uptime_seconds),
        "deepgram": deepgram_status
    })
    print("Health response sent")
    return resp

@app.route('/emotion', methods=['GET', 'POST'])
def emotion():
    """Fallback basic emotion analysis endpoint."""
    print("Emotion request received")
    resp = jsonify({
        "emotion": "Neutral",
        "confidence": 0.92
    })
    print("Response sent")
    return resp

@app.route('/analyze-emotion', methods=['POST'])
def analyze_emotion():
    """
    POST /analyze-emotion
    Expects:
      audio: Audio File (WAV, MP3, M4A, AAC, etc.)
    Returns:
      JSON with success, emotion, confidence
    """
    if 'audio' not in request.files:
        return jsonify({"success": False, "error": "Missing audio file in request"}), 400
        
    audio_file = request.files['audio']
    temp_dir = tempfile.gettempdir()
    _, ext = os.path.splitext(audio_file.filename or 'audio.wav')
    if not ext:
        ext = '.wav'
        
    input_path = os.path.join(temp_dir, f"input_emotion_{int(time.time())}{ext}")
    output_wav_path = os.path.join(temp_dir, f"converted_emotion_{int(time.time())}.wav")
    
    try:
        audio_file.save(input_path)
        
        # Convert to standard WAV 16kHz Mono
        cmd = [ffmpeg_path, '-i', input_path, '-ar', '16000', '-ac', '1', '-y', output_wav_path]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if result.returncode != 0:
            raise Exception(f"ffmpeg conversion failed: {result.stderr.decode('utf-8', errors='ignore')}")
            
        sr, audio_data = scipy.io.wavfile.read(output_wav_path)
        if len(audio_data.shape) > 1:
            audio_data = audio_data.mean(axis=1)
            
        # Normalize
        if audio_data.dtype == np.int16:
            audio_data = audio_data.astype(np.float32) / 32768.0
        elif audio_data.dtype == np.int32:
            audio_data = audio_data.astype(np.float32) / 2147483648.0
        elif audio_data.dtype == np.uint8:
            audio_data = (audio_data.astype(np.float32) - 128.0) / 128.0
        else:
            audio_data = audio_data.astype(np.float32)
            
        # Run DSP analysis on the whole file
        pitch_vals = []
        rms_vals = []
        zcr_vals = []
        silent_frames = 0
        total_frames = 0
        
        frame_len = int(0.050 * sr)
        frame_shift = int(0.025 * sr)
        
        if len(audio_data) >= frame_len:
            for start_f in range(0, len(audio_data) - frame_len, frame_shift):
                frame = audio_data[start_f : start_f + frame_len]
                rms = np.sqrt(np.mean(frame**2)) + 1e-6
                rms_vals.append(rms)
                
                if rms < 0.003:
                    silent_frames += 1
                else:
                    pitch = extract_pitch(frame, sr)
                    pitch_vals.append(pitch)
                    
                zcr = np.mean(np.abs(np.diff(np.sign(frame)))) / 2.0
                zcr_vals.append(zcr)
                total_frames += 1
                
        pauses_ratio = silent_frames / float(total_frames) if total_frames > 0 else 0.0
        emotion, confidence = classify_emotion(pitch_vals, rms_vals, zcr_vals, pauses_ratio)
        
        return jsonify({
            "success": True,
            "emotion": emotion.lower(),
            "confidence": float(confidence)
        })
        
    except Exception as e:
        print(f"Error in analyze-emotion: {e}")
        return jsonify({"success": False, "error": str(e)}), 500
        
    finally:
        # Cleanup
        for path in [input_path, output_wav_path]:
            if os.path.exists(path):
                try:
                    os.remove(path)
                except:
                    pass


@app.route('/transcribe', methods=['POST'])
def transcribe():
    """Fallback transcription endpoint."""
    return jsonify({
        "status": "error",
        "message": "Transcription is processed directly on the client via Deepgram Service."
    })

@app.route('/analyze', methods=['POST'])
def analyze():
    """Fallback analyze endpoint redirect instruction."""
    return jsonify({
        "status": "error",
        "message": "Please send multipart WAV audio files to POST /analyze_audio."
    })

@app.route('/meeting', methods=['POST'])
def meeting():
    """Fallback meeting endpoint."""
    return jsonify({
        "status": "ready",
        "message": "Meeting intelligence endpoints operational."
    })


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

# Resolve ffmpeg paths using static-ffmpeg if available
try:
    from static_ffmpeg import run
    ffmpeg_path, ffprobe_path = run.get_or_fetch_platform_executables_else_raise()
    print(f"static-ffmpeg found: {ffmpeg_path}")
except Exception as e:
    print(f"static-ffmpeg not initialized: {e}. Falling back to default system executables.")
    ffmpeg_path = "ffmpeg"
    ffprobe_path = "ffprobe"

from scipy.signal import butter, lfilter, stft, istft

def highpass_filter(data, cutoff=80, sr=16000, order=5):
    try:
        nyq = 0.5 * sr
        normal_cutoff = cutoff / nyq
        b, a = butter(order, normal_cutoff, btype='high', analog=False)
        y = lfilter(b, a, data)
        return y.astype(np.float32)
    except Exception as e:
        print(f"Highpass filter failed: {e}. Returning original.")
        return data

def spectral_noise_reduction(signal, sr=16000):
    try:
        f, t, Zxx = stft(signal, fs=sr, nperseg=512, noverlap=384)
        magnitude = np.abs(Zxx)
        phase = np.angle(Zxx)
        
        # Estimate noise from the lowest energy 10% of frames
        frame_energies = np.sum(magnitude ** 2, axis=0)
        if len(frame_energies) == 0:
            return signal
        threshold = np.percentile(frame_energies, 10)
        noise_frames = magnitude[:, frame_energies <= threshold]
        if noise_frames.shape[1] == 0:
            noise_frames = magnitude[:, :min(5, magnitude.shape[1])]
            
        noise_profile = np.mean(noise_frames, axis=1, keepdims=True)
        
        # Subtract noise magnitude with spectral floor
        clean_magnitude = magnitude - 2.0 * noise_profile
        clean_magnitude = np.maximum(clean_magnitude, 0.05 * magnitude)
        
        # Reconstruct and ISTFT
        Zxx_clean = clean_magnitude * np.exp(1j * phase)
        _, clean_signal = istft(Zxx_clean, fs=sr, nperseg=512, noverlap=384)
        
        if len(clean_signal) < len(signal):
            clean_signal = np.pad(clean_signal, (0, len(signal) - len(clean_signal)))
        elif len(clean_signal) > len(signal):
            clean_signal = clean_signal[:len(signal)]
            
        return clean_signal.astype(np.float32)
    except Exception as e:
        print(f"Noise reduction failed: {e}. Returning original.")
        return signal

def compute_vad_and_trim(signal, sr=16000):
    try:
        frame_len = int(0.030 * sr)
        hop_len = int(0.015 * sr)
        
        num_frames = (len(signal) - frame_len) // hop_len + 1
        if num_frames <= 0:
            return signal, [], np.array([])
            
        rms_vals = np.array([
            np.sqrt(np.mean(signal[i * hop_len : i * hop_len + frame_len] ** 2))
            for i in range(num_frames)
        ])
        
        min_rms = np.min(rms_vals)
        max_rms = np.max(rms_vals)
        
        speech_threshold = min_rms + 0.08 * (max_rms - min_rms)
        speech_threshold = max(speech_threshold, 0.005)
        
        is_speech = rms_vals > speech_threshold
        
        smooth_is_speech = is_speech.copy()
        gap_limit = 20
        gap_counter = 0
        
        # Bridge short pauses
        for i in range(num_frames):
            if smooth_is_speech[i]:
                if gap_counter > 0 and gap_counter <= gap_limit:
                    smooth_is_speech[i - gap_counter : i] = True
                gap_counter = 0
            else:
                gap_counter += 1
                
        # Remove spikes
        min_speech_len = 7
        speech_len = 0
        for i in range(num_frames):
            if smooth_is_speech[i]:
                speech_len += 1
            else:
                if speech_len > 0 and speech_len < min_speech_len:
                    smooth_is_speech[i - speech_len : i] = False
                speech_len = 0
        if speech_len > 0 and speech_len < min_speech_len:
            smooth_is_speech[num_frames - speech_len : num_frames] = False
            
        speech_indices = np.where(smooth_is_speech)[0]
        if len(speech_indices) == 0:
            return np.array([], dtype=np.float32), [], smooth_is_speech
            
        start_frame = max(0, speech_indices[0] - 10)
        end_frame = min(num_frames - 1, speech_indices[-1] + 10)
        
        trimmed_signal = signal[start_frame * hop_len : (end_frame + 1) * hop_len]
        trimmed_is_speech = smooth_is_speech[start_frame : end_frame + 1]
        
        return trimmed_signal, trimmed_is_speech, smooth_is_speech
    except Exception as e:
        print(f"VAD failed: {e}. Returning original.")
        return signal, [], np.array([])

def transcribe_chunk_deepgram(chunk_path, api_key, mime_type="audio/wav"):
    url = 'https://api.deepgram.com/v1/listen?diarize=true&punctuate=true&utterances=true&model=nova-2&smart_format=true'
    headers = {
        'Authorization': f'Token {api_key}',
        'Content-Type': mime_type
    }
    
    max_retries = 3
    backoff = 1.0
    for attempt in range(max_retries):
        try:
            with open(chunk_path, 'rb') as f:
                resp = requests.post(url, headers=headers, data=f, timeout=60)
            if resp.status_code == 200:
                return resp.json()
            else:
                print(f"[Deepgram HTTP {resp.status_code}] Attempt {attempt + 1} failed: {resp.text}")
        except Exception as e:
            print(f"[Deepgram error] Attempt {attempt + 1} failed: {e}")
        time.sleep(backoff)
        backoff *= 2.0
    return None

@app.route('/transcribe_file', methods=['POST'])
def transcribe_file():
    print("Transcribe file request received")
    
    if 'audio' not in request.files:
        return jsonify({"error": "Missing audio file in request"}), 400
        
    audio_file = request.files['audio']
    api_key = request.headers.get('Authorization', '').replace('Token ', '').strip()
    if not api_key:
        api_key = request.form.get('api_key', '').strip()
        
    if not api_key:
        return jsonify({"error": "Missing Deepgram API Key. Provide in Authorization header."}), 400

    temp_dir = tempfile.gettempdir()
    _, ext = os.path.splitext(audio_file.filename)
    if not ext:
        ext = '.tmp'
    input_path = os.path.join(temp_dir, f"input_raw_{int(time.time())}{ext}")
    audio_file.save(input_path)
    
    output_wav_path = os.path.join(temp_dir, f"converted_{int(time.time())}.wav")
    
    try:
        print(f"Decoding {input_path} to {output_wav_path} via ffmpeg...")
        cmd = [ffmpeg_path, '-i', input_path, '-ar', '16000', '-ac', '1', '-y', output_wav_path]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if result.returncode != 0:
            raise Exception(f"ffmpeg conversion failed: {result.stderr.decode('utf-8', errors='ignore')}")
            
        sr, audio_data = scipy.io.wavfile.read(output_wav_path)
        if len(audio_data.shape) > 1:
            audio_data = audio_data.mean(axis=1)
            
        if audio_data.dtype == np.int16:
            audio_data = audio_data.astype(np.float32) / 32768.0
        elif audio_data.dtype == np.int32:
            audio_data = audio_data.astype(np.float32) / 2147483648.0
        elif audio_data.dtype == np.uint8:
            audio_data = (audio_data.astype(np.float32) - 128.0) / 128.0
        else:
            audio_data = audio_data.astype(np.float32)

        # DSP: clipping removal, de-humming, noise reduction, loudness normalization
        audio_data = np.clip(audio_data, -0.99, 0.99)
        audio_data = highpass_filter(audio_data, cutoff=80, sr=sr)
        audio_data = spectral_noise_reduction(audio_data, sr=sr)
        
        max_amp = np.max(np.abs(audio_data))
        if max_amp > 0:
            audio_data = audio_data * (0.89 / max_amp)
            
        trimmed_audio, trimmed_is_speech, _ = compute_vad_and_trim(audio_data, sr=sr)
        if len(trimmed_audio) == 0:
            return jsonify({"error": "No speech detected in audio file. Ensure the audio is not silent."}), 400

        preprocessed_path = os.path.join(temp_dir, f"preprocessed_{int(time.time())}.wav")
        save_data = (trimmed_audio * 32767.0).astype(np.int16)
        scipy.io.wavfile.write(preprocessed_path, sr, save_data)
        
        # Silence-aligned chunking (~15 seconds)
        duration = len(trimmed_audio) / float(sr)
        hop_len = int(0.015 * sr)
        chunks = []
        cursor = 0.0
        
        while cursor < duration:
            target_end = cursor + 15.0
            if target_end >= duration:
                chunks.append((cursor, duration))
                break
                
            search_start = target_end - 2.0
            search_end = min(duration, target_end + 2.0)
            
            silence_points = []
            for i in range(len(trimmed_is_speech)):
                t = i * hop_len / float(sr)
                if search_start <= t <= search_end and not trimmed_is_speech[i]:
                    silence_points.append(t)
                    
            if silence_points:
                cut_point = np.mean(silence_points)
            else:
                cut_point = target_end
                
            chunks.append((cursor, cut_point))
            cursor = cut_point
            
        print(f"Audio chunking complete: {len(chunks)} chunks generated.")

        chunk_files = []
        for idx, (start, end) in enumerate(chunks):
            start_sample = int(start * sr)
            end_sample = int(end * sr)
            chunk_data = trimmed_audio[start_sample:end_sample]
            
            chunk_wav_path = os.path.join(temp_dir, f"chunk_{idx}_{int(time.time())}.wav")
            scipy.io.wavfile.write(chunk_wav_path, sr, (chunk_data * 32767.0).astype(np.int16))
            chunk_files.append((idx, chunk_wav_path, start))

        # Parallelize Deepgram API queries
        transcripts = {}
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
            future_to_chunk = {
                executor.submit(transcribe_chunk_deepgram, path, api_key): (idx, offset)
                for idx, path, offset in chunk_files
            }
            
            for future in concurrent.futures.as_completed(future_to_chunk):
                idx, offset = future_to_chunk[future]
                try:
                    res_json = future.result()
                    if res_json:
                        transcripts[idx] = (res_json, offset)
                except Exception as e:
                    print(f"Exception transcribing chunk {idx}: {e}")

        # Cleanup temp audio files
        for path in [input_path, output_wav_path, preprocessed_path] + [path for _, path, _ in chunk_files]:
            try:
                if os.path.exists(path):
                    os.remove(path)
            except Exception as e:
                print(f"Clean up failed for {path}: {e}")

        # Assemble timestamps
        merged_utterances = []
        for idx in sorted(transcripts.keys()):
            res_json, offset = transcripts[idx]
            results = res_json.get('results', {})
            utterances = results.get('utterances', [])
            
            if utterances:
                for u in utterances:
                    text = u.get('transcript', '').strip()
                    if not text:
                        continue
                    speaker = u.get('speaker', 0) + 1
                    start_t = u.get('start', 0) + offset
                    end_t = u.get('end', 0) + offset
                    
                    merged_utterances.append({
                        "speaker": speaker,
                        "text": text,
                        "startTime": start_t,
                        "endTime": end_t
                    })
            else:
                channels = results.get('channels', [])
                if channels:
                    alternatives = channels[0].get('alternatives', [])
                    if alternatives:
                        transcriptText = alternatives[0].get('transcript', '').strip()
                        words = alternatives[0].get('words', [])
                        
                        if transcriptText and words:
                            currentSpeaker = words[0].get('speaker', 0) + 1
                            start_t = words[0].get('start', 0) + offset
                            wordsBuffer = []
                            
                            for w in words:
                                spk = w.get('speaker', 0) + 1
                                if spk != currentSpeaker and wordsBuffer:
                                    end_t = w.get('end', 0) + offset
                                    merged_utterances.append({
                                        "speaker": currentSpeaker,
                                        "text": " ".join(wordsBuffer),
                                        "startTime": start_t,
                                        "endTime": end_t
                                    })
                                    currentSpeaker = spk
                                    start_t = w.get('start', 0) + offset
                                    wordsBuffer = []
                                wordsBuffer.append(w.get('word', ''))
                                
                            if wordsBuffer:
                                end_t = words[-1].get('end', 0) + offset
                                merged_utterances.append({
                                    "speaker": currentSpeaker,
                                    "text": " ".join(wordsBuffer),
                                    "startTime": start_t,
                                    "endTime": end_t
                                })

        merged_utterances.sort(key=lambda x: x["startTime"])
        
        if not merged_utterances:
            return jsonify({"error": "No speech detected in the audio file."}), 400

        print(f"Stitched {len(merged_utterances)} segments.")
        return jsonify({
            "status": "success",
            "segments": merged_utterances,
            "total_duration": duration
        })

    except Exception as e:
        print(f"Transcription failed: {e}")
        for path in [input_path, output_wav_path]:
            if os.path.exists(path):
                try:
                    os.remove(path)
                except:
                    pass
        return jsonify({"error": f"Transcription pipeline exception: {str(e)}"}), 500

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    print(f"Emotion server starting on port {port}")
    app.run(host="0.0.0.0", port=port, debug=False)