# StudyOralCoach Backend

Small Docker backend for StudyOralCoach. It handles PDF text extraction with
`pdfjs-dist` and proxies microphone audio to Deepgram for speech-to-text.

## Run

```bash
cd backend
docker compose up --build
```

The app calls:

```text
POST http://<host>:18081/api/pdf/extract
POST http://<host>:18081/api/answer/evaluate
WS   ws://<host>:18081/listen
```

For an emulator running on the same computer, `127.0.0.1` can work. For a physical device, set the app backend URL to the computer's LAN IP.

## Speech-to-Text

Set `DEEPGRAM_API_KEY` in `backend/.env` before starting Docker. The app streams
16 kHz mono `linear16` microphone audio to `/listen`; this backend forwards it to
Deepgram and returns interim/final transcript messages.
