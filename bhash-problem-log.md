Subject: Comprehensive Technical Report – Bhashini Voice API & Pipeline: Code Flow, Issues, and Recommendations

---

Dear Team,

This email provides a detailed technical analysis of the Bhashini voice integration in our project, covering both the Flutter frontend and Python FastAPI backend. It explains how audio is recorded, processed, sent to the pipeline API, and how results are handled, with code snippets and explanations. The report also highlights the distinction between local/offline model success and API pipeline failures, and concludes with actionable recommendations.

---

## 1. Overview: Voice Pipeline Flow
- **Frontend:** Records user audio, encodes it, and POSTs to backend API.
- **Backend:** Accepts audio, runs ASR/translation/TTS via local models or Bhashini API, and returns results.
- **Fallbacks:** If Bhashini API is down, local models are used (and vice versa).

---

## 2. Flutter Frontend: `voice_screen.dart`

### a) Audio Recording & Control
- Uses browser's `MediaRecorder` API (web only) to capture audio in `webm` format.
- Handles microphone permission, chunk collection, and timer for recording duration.

**Key Code:**
```dart
Future<void> _initializeRecording() async {
  _stream = await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
  _mediaRecorder = html.MediaRecorder(_stream!, {'mimeType': 'audio/webm'});
  _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
    final dataEvent = event as html.BlobEvent;
    if (dataEvent.data != null && dataEvent.data!.size > 0) {
      _audioChunks.add(dataEvent.data!);
    }
  });
}

Future<void> _startRecording() async {
  await _initializeRecording();
  _audioChunks = [];
  _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    setState(() { _recordingDuration++; });
  });
  setState(() { _isRecording = true; ... });
}

void _stopRecording() {
  _recordingTimer?.cancel();
  if (_mediaRecorder != null && _mediaRecorder!.state == 'recording') {
    _mediaRecorder!.addEventListener('stop', (html.Event _) {
      _processRecording();
    });
    _mediaRecorder!.stop();
    setState(() => _isRecording = false);
  }
}
```

### b) Audio Processing & API Call
- Converts recorded audio chunks to a Blob, then to base64.
- Sends POST request to backend (`/api/voice-query`) with `audio_base64` and `language` fields.
- Handles JSON response: updates UI with transcription, translation, AI response, and TTS audio.

**Key Code:**
```dart
Future<void> _processRecording() async {
  setState(() => _isLoading = true);
  try {
    final blob = html.Blob(_audioChunks, 'audio/webm');
    final reader = html.FileReader();
    ...
    reader.readAsDataUrl(blob);
    final base64Audio = await readerCompleter.future;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:8000/api/voice-query'),
    );
    request.fields['audio_base64'] = base64Audio;
    request.fields['language'] = _useTeluguASR ? 'te' : 'en';
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _transcription = data['asr_text'] ?? '';
        _translatedText = data['translated_text'] ?? '';
        _assistantResponse = data['assistant_response'] ?? '';
        _audioUrl = data['audio_url'] ?? '';
      });
    } else {
      throw Exception('HTTP error ...');
    }
  } catch (e) {
    setState(() => _isLoading = false);
    ...
  }
}
```

### c) Error Handling & Fallback
- If Bhashini API is unavailable, falls back to offline NeMo ASR.
- Shows popup to the user and processes audio locally.

**Key Code:**
```dart
void _showFallbackPopup() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(children: [Icon(Icons.info_outline, color: Colors.orange), ...]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('The Bhashini API is currently unavailable. Your audio has been processed using the offline NeMo ASR model instead.'),
          ...
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
    ),
  );
}
```

---

## 3. Backend: FastAPI Pipeline (`main.py`)

### a) Endpoints & Model IDs
- `/nemo_transcribe` (POST): Main entry for voice queries.
- `/tts` (POST): Text-to-speech.
- `/api/voice-query` (POST): Used as a fallback.
- **Model IDs (hardcoded):**
  - ASR Telugu: `66e41f28e2f5842563c988d9`
  - Translation: `67b871747d193a1beb4b847e`
  - TTS English: `6576a17e00d64169e2f8f43d`

### b) Pipeline Logic
- Saves uploaded audio file.
- For Telugu, tries local ASR (`LocalTeluguASR`); if that fails, falls back to Bhashini API.
- For English, uses default STT system.
- Returns JSON: ASR result, translation, AI response, model IDs, and audio (base64 TTS).

**Key Code:**
```python
@app.post("/nemo_transcribe")
async def nemo_transcribe(audio: UploadFile = File(...), language: str = Form("telugu")):
    asr_model_id = "66e41f28e2f5842563c988d9"
    translation_model_id = "67b871747d193a1beb4b847e"
    tts_model_id = "6576a17e00d64169e2f8f43d"
    ...
    try:
        if is_telugu:
            # Use local ASR
            ...
        else:
            # Use English STT
            ...
    except Exception as e:
        # Fallback to Bhashini API
        ...
        async with session.post("http://localhost:8000/api/voice-query", data=form_data) as resp:
            ...
```

### c) Fallback Logic
- If local ASR fails, POSTs audio to `/api/voice-query` (Bhashini pipeline).
- If both fail, returns HTTP 500 with error details.

**Key Code:**
```python
except Exception as e:
    logger.error(f"Error in ASR transcription: {e}")
    if is_telugu:
        try:
            ...
            async with aiohttp.ClientSession() as session:
                async with session.post("http://localhost:8000/api/voice-query", data=form_data) as resp:
                    if resp.status == 200:
                        result = await resp.json()
                        return JSONResponse(content={ ... })
                    else:
                        error_msg = await resp.text()
                        logger.error(f"Bhashini API error: {error_msg}")
                        raise HTTPException(status_code=resp.status, detail=f"Bhashini API error: {error_msg}")
        except Exception as e:
            logger.error(f"Error using Bhashini API fallback: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Error using Bhashini API fallback: {str(e)}")
```

---

## 4. Model Behavior: Local vs API Pipeline
- **Offline/Local Model:** Works reliably when loaded into backend (CPU).
- **API Pipeline:** May fail or return errors even with same model and audio, due to request formatting, environment, or configuration issues.
- **Audio Format:** Backend expects WAV; mismatches can break pipeline.
- **Model IDs:** Must match; if changed or invalid, pipeline fails.

---

## 5. Recommendations
- Make model IDs configurable (not hardcoded).
- Improve backend error reporting (specify which step failed).
- Add robust checks/logs for API failures.
- Ensure audio format compatibility.
- Investigate why models work offline but not via API (permissions, payload, environment).

---

Best regards,
[Your Name / Team]

- **Recording**: Uses browser MediaRecorder API (web only), collects chunks.
- **Encoding**: Converts audio blob to base64 string.
- **Sending**: POSTs to `http://localhost:8000/api/voice-query` with fields: `audio_base64`, `language`.
- **Response**: Expects fields:
  - `asr_text` (ASR output, e.g., Telugu)
  - `translated_text` (if applicable)
  - `ai_response_te`/`ai_response_en` (assistant answer)
  - `audio` (base64 WAV, TTS output)
- **Playback**: If TTS audio is present, decodes and plays in browser.

## 2. **How Voice is Converted and Sent to Service**
- User presses and holds mic (UI event).
- Audio is captured via browser (webm format, see `_startRecording`, `_stopRecording`).
- On stop, `_processRecording()` is called.
- Audio is encoded as base64 and POSTed to backend.
- Backend is expected to run a pipeline:
  - ASR (Automatic Speech Recognition, e.g., Bhashini model)
  - Optional: Translation (Telugu→English)
  - AI response (LLM, etc.)
  - TTS (Text-to-Speech, e.g., Bhashini model)
- Backend returns JSON with all results and TTS audio (base64 WAV).
- App displays transcription, AI answer, and plays TTS audio if present.

## 3. **Known Issues with Bhashini Servers / Pipeline**
- **Browser/Flutter Web Issues:**
  - MediaRecorder API is not supported on all browsers (esp. Safari/iOS).
  - Flutter web cannot access native mobile audio APIs; only browser APIs work.
  - Blob/BlobEvent API mismatch (see error logs in notice_page.dart).
- **Bhashini API Issues:**
  - Bhashini pipeline API is sometimes slow, returns 5xx or times out.
  - Model IDs for ASR/TTS/Translation are hardcoded; if changed on server, client breaks.
  - Sometimes backend falls back to offline ASR (NeMo) if Bhashini is down (see `_showFallbackPopup`).
  - Audio format incompatibility (webm→wav) may cause backend errors.
  - TTS sometimes returns empty or malformed audio (base64 decode errors on client).
- **Error Handling:**
  - User is shown fallback popup if Bhashini is unavailable.
  - Errors are shown in SnackBar but not always actionable for user.
- **Pipeline Fragility:**
  - If any step (ASR/Translation/TTS) fails, user gets partial or no response.
  - No granular error reporting from backend to client (just fallback or generic error).

## 4. **References in Codebase**
- No dedicated `bhashini_api.dart` file; all logic is in `voice_screen.dart`.
- Backend endpoint is `/api/voice-query` (see POST in `_processRecording`).
- Model IDs for Bhashini are hardcoded in `voice_screen.dart`:
  - ASR Telugu: `66e41f28e2f5842563c988d9`
  - Translation: `67b871747d193a1beb4b847e`
  - TTS English: `6576a17e00d64169e2f8f43d`

## 5. **Summary Table**
| Step                | Client (Flutter Web)            | Backend (FastAPI)           | Issue/Fragility          |
|---------------------|---------------------------------|-----------------------------|--------------------------|
| Record Audio        | MediaRecorder (webm)            | Receives base64             | Browser API fragile      |
| POST to API        | /api/voice-query                | Receives audio_base64, lang | Backend may timeout      |
| ASR                | -                               | Bhashini/Offline ASR        | Bhashini slow/unreliable |
| Translation        | -                               | Bhashini Translation        | Model ID mismatch        |
| AI Response        | -                               | LLM                         | LLM/infra errors         |
| TTS                | -                               | Bhashini/Offline TTS        | TTS output unreliable    |
| Return to Client   | Receives JSON + base64 audio    | Sends JSON                  | Audio decode issues      |

## 6. **Example Error**
```
Error: The getter 'blob' isn't defined for the class 'BlobEvent'.
- 'BlobEvent' is from 'dart:html'.
    _audioChunks.add(data.blob!);
```

## 7. **Recommendations**
- Add retry and better error messages for Bhashini failures.
- Consider supporting more audio formats (webm/wav/mp3) on backend.
- Make model IDs configurable (not hardcoded in frontend).
- Improve backend error reporting (which pipeline step failed).
- For production, consider fallback to browser TTS or local ASR if Bhashini is down.

---

## 8. **Backend Implementation of Bhashini Voice Pipeline**

---

**Subject:** Analysis of Bhashini Voice API Backend Pipeline – Implementation, API Usage, Model Details, and Observed Issues

---

Dear Team,

Please find below a comprehensive report on the backend implementation of the Bhashini voice pipeline, including API details, Postman usage, code snippets, and a summary of the models used (with IDs and roles). This report also highlights the distinction between local/offline model success and API pipeline failures.

---

### 1. Backend Bhashini Voice Pipeline: Implementation Overview

**API Endpoints:**
- `/nemo_transcribe` (POST): Main endpoint for voice transcription. Accepts `audio` (file) and `language` (`telugu`/`english`).
- `/tts` (POST): Text-to-speech endpoint (not always using Bhashini).
- `/api/voice-query` (POST): Used internally for fallback to Bhashini pipeline.

**Processing Flow:**
1. **Audio Upload:** User uploads audio via frontend or Postman (as `multipart/form-data`).
2. **Model Selection:** Backend uses hardcoded model IDs:
   - **ASR Telugu**: `66e41f28e2f5842563c988d9` (Speech-to-Text for Telugu)
   - **Translation**: `67b871747d193a1beb4b847e` (Telugu-to-English Translation)
   - **TTS English**: `6576a17e00d64169e2f8f43d` (Text-to-Speech for English)
3. **ASR Processing:**
   - For Telugu: Attempts local model (`LocalTeluguASR`). If it fails, falls back to Bhashini API (`/api/voice-query`).
   - For English: Uses default STT system.
4. **Response:** Returns JSON with fields: `text`, `translated_text`, `filename`, `language`, `model_ids`.

**Fallback Mechanism:**
- If the local model fails, backend logs the error and POSTs the audio to the Bhashini pipeline.
- If both local and Bhashini fail, a 500 error is returned.

---

### 2. API Testing with Postman

**How to Test:**
- Use Postman to send a `POST` request to `http://localhost:8000/nemo_transcribe`.
- Set `audio` as a file (choose a WAV file).
- Set `language` as `telugu` or `english`.
- Inspect JSON response for ASR output and model IDs.
- For fallback testing, temporarily disable the local model to force Bhashini API usage.

**Example Postman Request:**
- **URL:** `http://localhost:8000/nemo_transcribe`
- **Method:** POST
- **Body:** `form-data`
  - `audio`: (File, WAV format)
  - `language`: `telugu` or `english`

**Expected Response:**
```json
{
  "text": "<ASR output>",
  "translated_text": "<Translation output>",
  "filename": "<saved audio filename>",
  "language": "telugu",
  "model_ids": {
    "asr": "66e41f28e2f5842563c988d9",
    "translation": "67b871747d193a1beb4b847e",
    "tts": "6576a17e00d64169e2f8f43d"
  }
}
```

---

### 3. Key Code Snippets

**Endpoint Implementation (`main.py`):**
```python
@app.post("/nemo_transcribe")
async def nemo_transcribe(audio: UploadFile = File(...), language: str = Form("telugu")):
    asr_model_id = "66e41f28e2f5842563c988d9"  # Telugu ASR
    translation_model_id = "67b871747d193a1beb4b847e"  # Telugu-to-English
    tts_model_id = "6576a17e00d64169e2f8f43d"  # English TTS
    ...
    try:
        if is_telugu:
            # Use local ASR
            ...
        else:
            # Use English STT
            ...
    except Exception as e:
        # Fallback to Bhashini API
        ...
        async with session.post("http://localhost:8000/api/voice-query", data=form_data) as resp:
            ...
```

**Fallback Logic:**
```python
except Exception as e:
    logger.error(f"Error in ASR transcription: {e}")
    # If local model fails, attempt to use Bhashini API for Telugu
    if is_telugu:
        try:
            ...
            async with aiohttp.ClientSession() as session:
                async with session.post("http://localhost:8000/api/voice-query", data=form_data) as resp:
                    if resp.status == 200:
                        result = await resp.json()
                        return JSONResponse(content={
                            "text": result.get("asr_text", ""),
                            "translated_text": result.get("translated_text", ""),
                            "filename": unique_filename,
                            "language": "telugu",
                            "model_ids": {
                                "asr": asr_model_id,
                                "translation": translation_model_id,
                                "tts": tts_model_id
                            }
                        })
                    else:
                        error_msg = await resp.text()
                        logger.error(f"Bhashini API error: {error_msg}")
                        raise HTTPException(status_code=resp.status, detail=f"Bhashini API error: {error_msg}")
        except Exception as e:
            logger.error(f"Error using Bhashini API fallback: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Error using Bhashini API fallback: {str(e)}")
```

**Model IDs and Usage:**
- **ASR Telugu**: `66e41f28e2f5842563c988d9` (used for speech-to-text in Telugu)
- **Translation**: `67b871747d193a1beb4b847e` (used for Telugu-to-English translation)
- **TTS English**: `6576a17e00d64169e2f8f43d` (used for text-to-speech in English)
- These IDs are hardcoded in both frontend and backend.

---

### 4. Model Behavior: Local vs API Pipeline

- **Offline/Local Model:**
  - When the model is downloaded and loaded into the backend (CPU), local inference for ASR, translation, and TTS works reliably.
  - Example: `LocalTeluguASR` transcribes audio correctly when invoked directly.
- **API Pipeline:**
  - When using the same model via the `/api/voice-query` API pipeline, the API may fail or return errors, even if the model works offline.
  - Possible causes: request formatting, environment differences, model loading issues in the API context, or permission/configuration mismatches.
- **Frontend/Backend Expectation:**
  - Audio must be in WAV format for backend compatibility.
  - Model IDs must match exactly; if changed or invalid, the pipeline breaks.

---

### 5. Recommendations and Next Steps

- Make model IDs configurable, not hardcoded in code.
- Improve backend error reporting to specify which step failed (ASR, translation, TTS).
- Add more robust checks and logs for API pipeline failures.
- Ensure audio format compatibility between frontend and backend.
- Investigate why models work offline but not via the API pipeline (permissions, environment, payload, etc).

---

Best regards,
[Your Name / Team]

### **API Endpoint**
- The main backend endpoint for voice pipeline is `/nemo_transcribe` (POST).
- Accepts an uploaded audio file (`audio`) and a language (`telugu` or `english`).

### **Processing Flow**
1. **Save Audio:**
   - Uploaded audio is saved to a unique file in the backend's audio directory.
2. **Model IDs:**
   - Hardcoded model IDs are used for Bhashini:
     - ASR Telugu: `66e41f28e2f5842563c988d9`
     - Translation: `67b871747d193a1beb4b847e`
     - TTS English: `6576a17e00d64169e2f8f43d`
3. **ASR Processing:**
   - For Telugu:
     - Attempts to use a local ASR model (`LocalTeluguASR`).
     - If local model fails, falls back to Bhashini API by POSTing the audio to `/api/voice-query`.
     - Returns both the ASR result and the model IDs used.
   - For English:
     - Uses the default STT system.
4. **Response:**
   - Returns a JSON with fields:
     - `text`: ASR result
     - `translated_text`: If available (from Bhashini)
     - `filename`: Saved filename
     - `language`: Telugu or English
     - `model_ids`: Dict with ASR, translation, and TTS model IDs

### **Fallback Mechanism**
- If the local ASR model fails for Telugu, the backend logs the error and tries to use the Bhashini pipeline by sending the audio to `/api/voice-query`.
- If both local and Bhashini fail, a 500 error is returned.

### **Other Related Endpoints**
- `/tts`: Text-to-speech (uses backend TTS system, not directly Bhashini)
- `/upload_audio`: For uploading and saving audio files

### **Summary Table**
| Step                 | Endpoint              | Model/Service Used     | Fallback/Notes                |
|----------------------|----------------------|-----------------------|-------------------------------|
| Upload & Transcribe  | /nemo_transcribe     | Local ASR/Bhashini    | Fallback to Bhashini if local fails |
| TTS                  | /tts                 | TTS backend           | Not always Bhashini           |
| Voice Query (ASR+TTS)| /api/voice-query     | Bhashini pipeline     | Used as fallback              |

### **Key Code Snippet**
```python
@app.post("/nemo_transcribe")
async def nemo_transcribe(audio: UploadFile = File(...), language: str = Form("telugu")):
    ...
    asr_model_id = "66e41f28e2f5842563c988d9"  # Telugu ASR
    translation_model_id = "67b871747d193a1beb4b847e"  # Telugu-to-English
    tts_model_id = "6576a17e00d64169e2f8f43d"  # English TTS
    ...
    try:
        if is_telugu:
            # Use local ASR
            ...
        else:
            # Use English STT
            ...
    except Exception as e:
        # Fallback to Bhashini API
        ...
        async with session.post("http://localhost:8000/api/voice-query", data=form_data) as resp:
            ...
```

### **Observations**
- Model IDs are hardcoded in the backend, just like frontend.
- Fallback to Bhashini is robust, but error reporting is generic.
- TTS is handled separately; not always using Bhashini.
- The backend expects audio in `wav` format for Bhashini pipeline.
- The pipeline is modular, but fragile if any step fails or if model IDs change.
