import http from 'node:http';
import express from 'express';
import { WebSocket, WebSocketServer } from 'ws';

const PORT = Number.parseInt(process.env.PORT ?? '18081', 10);
const MAX_JSON_SIZE = process.env.MAX_JSON_SIZE ?? '35mb';
const MIN_TEXT_LENGTH = Number.parseInt(process.env.PDF_TEXT_MIN_LENGTH ?? '1', 10);
const ENABLE_LOCAL_AI_QA = (process.env.ENABLE_LOCAL_AI_QA ?? 'true') === 'true';
const OLLAMA_URL = process.env.OLLAMA_URL ?? 'http://host.docker.internal:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL ?? 'llama3.2:3b';
const DEEPGRAM_API_KEY = (process.env.DEEPGRAM_API_KEY ?? '').trim();
const DEEPGRAM_URL = 'wss://api.deepgram.com/v1/listen' +
  '?encoding=linear16&sample_rate=16000&channels=1&language=en&filler_words=true&interim_results=true&model=nova-2';

const app = express();
app.use(express.json({ limit: MAX_JSON_SIZE }));
const server = http.createServer(app);
const asrServer = new WebSocketServer({ server, path: '/listen' });

app.get('/health', (_request, response) => {
  response.json({
    ok: true,
    service: 'study-oral-coach-pdf-backend'
  });
});

app.post('/api/pdf/extract', async (request, response, next) => {
  try {
    const body = request.body ?? {};
    const fileName = typeof body.fileName === 'string' ? body.fileName : 'document.pdf';
    const fileBase64 = typeof body.fileBase64 === 'string' ? body.fileBase64 : '';
    if (fileBase64.length === 0) {
      response.status(400).json({ error: 'fileBase64 is required' });
      return;
    }

    const pdfBuffer = Buffer.from(fileBase64, 'base64');
    if (!isPdfBuffer(pdfBuffer)) {
      response.status(400).json({ error: 'Uploaded file is not a PDF' });
      return;
    }

    const extracted = await extractPdfText(pdfBuffer);
    const ruleQaPairs = extractAdjacentQaPairs(extracted.text);
    const aiQaPairs = ENABLE_LOCAL_AI_QA ? await refineQaPairsWithLocalAi(ruleQaPairs) : [];
    const qaPairs = aiQaPairs.length >= Math.min(3, ruleQaPairs.length) ? aiQaPairs : ruleQaPairs;
    response.json({
      fileName,
      method: extracted.method,
      pageCount: extracted.pages.length,
      textLength: extracted.text.length,
      status: extracted.text.length >= MIN_TEXT_LENGTH ? 'ready' : 'text_too_short',
      text: extracted.text,
      pages: extracted.pages,
      qaPairs
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/answer/evaluate', async (request, response, next) => {
  try {
    const body = request.body ?? {};
    const question = typeof body.question === 'string' ? body.question.trim() : '';
    const referenceAnswer = typeof body.referenceAnswer === 'string' ? body.referenceAnswer.trim() : '';
    const userAnswer = typeof body.userAnswer === 'string' ? body.userAnswer.trim() : '';
    if (referenceAnswer.length === 0 || userAnswer.length === 0) {
      response.status(400).json({ error: 'referenceAnswer and userAnswer are required' });
      return;
    }

    const aiResult = ENABLE_LOCAL_AI_QA ?
      await evaluateAnswerWithLocalAi(question, referenceAnswer, userAnswer) : null;
    response.json(aiResult ?? {
      available: false,
      verdict: 'unknown',
      adjustment: 0,
      feedback: ''
    });
  } catch (error) {
    next(error);
  }
});

app.use((error, _request, response, _next) => {
  console.error('[StudyOralPdfBackend] request failed', error);
  response.status(500).json({
    error: error instanceof Error ? error.message : 'PDF extraction failed'
  });
});

asrServer.on('connection', (clientSocket) => {
  if (DEEPGRAM_API_KEY.length === 0) {
    clientSocket.close(1011, 'Missing DEEPGRAM_API_KEY');
    return;
  }

  const deepgramSocket = new WebSocket(DEEPGRAM_URL, {
    headers: {
      Authorization: `Token ${DEEPGRAM_API_KEY}`
    }
  });

  let deepgramReady = false;
  const pendingAudio = [];

  deepgramSocket.on('open', () => {
    deepgramReady = true;
    while (pendingAudio.length > 0 && deepgramSocket.readyState === WebSocket.OPEN) {
      deepgramSocket.send(pendingAudio.shift());
    }
  });

  clientSocket.on('message', (message, isBinary) => {
    if (!isBinary) {
      if (deepgramSocket.readyState === WebSocket.OPEN) {
        deepgramSocket.send(message.toString());
      }
      return;
    }
    if (deepgramReady && deepgramSocket.readyState === WebSocket.OPEN) {
      deepgramSocket.send(message);
    } else {
      pendingAudio.push(message);
    }
  });

  deepgramSocket.on('message', (message) => {
    if (clientSocket.readyState === WebSocket.OPEN) {
      clientSocket.send(message.toString());
    }
  });

  const closeBoth = () => {
    if (clientSocket.readyState === WebSocket.OPEN) {
      clientSocket.close();
    }
    if (deepgramSocket.readyState === WebSocket.OPEN || deepgramSocket.readyState === WebSocket.CONNECTING) {
      deepgramSocket.close();
    }
  };

  clientSocket.on('close', closeBoth);
  clientSocket.on('error', closeBoth);
  deepgramSocket.on('close', closeBoth);
  deepgramSocket.on('error', (error) => {
    console.warn('[StudyOralASR] Deepgram websocket failed', error);
    closeBoth();
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[StudyOralPdfBackend] listening on ${PORT}`);
  console.log(`[StudyOralASR] websocket ready on ws://0.0.0.0:${PORT}/listen`);
});

function isPdfBuffer(buffer) {
  if (buffer.length < 5) {
    return false;
  }
  return buffer.subarray(0, 5).toString('ascii') === '%PDF-';
}

function extractAdjacentQaPairs(text) {
  const lines = text.split(/\n+/).map((line) => line.trim()).filter((line) => line.length > 0);
  const pairs = [];
  let current = null;

  for (const line of lines) {
    if (isQuestionLine(line, current !== null && current.answerParts.length > 0)) {
      if (current && current.answerParts.length > 0) {
        pairs.push(toPair(current));
      }
      current = {
        question: cleanQuestion(line),
        answerParts: [],
        sourceParts: [line]
      };
      continue;
    }

    if (current) {
      const answerLine = cleanAnswer(line);
      if (answerLine.length > 0) {
        current.answerParts.push(answerLine);
        current.sourceParts.push(line);
      }
    }
  }

  if (current && current.answerParts.length > 0) {
    pairs.push(toPair(current));
  }

  const seen = new Set();
  return pairs
    .filter((pair) => {
      const key = pair.question.toLowerCase().replace(/\s+/g, ' ');
      if (!isValidQuestionTitle(pair.question) || pair.answer.length === 0 || seen.has(key)) {
        return false;
      }
      seen.add(key);
      return true;
    })
    .slice(0, 200);
}

function toPair(block) {
  return {
    question: cleanQuestion(block.question),
    answer: cleanAnswer(block.answerParts.join('\n')),
    sourceText: block.sourceParts.join('\n').trim()
  };
}

async function refineQaPairsWithLocalAi(rulePairs) {
  if (rulePairs.length === 0) {
    return [];
  }

  const compactPairs = rulePairs.slice(0, 120).map((pair, index) => ({
    index,
    question: pair.question.substring(0, 220),
    answer: pair.answer.substring(0, 700)
  }));
  const prompt = [
    'You clean study question-answer pairs that were extracted from a document.',
    'Keep only real study questions and their adjacent answers.',
    'Do not invent new questions or answers.',
    'You may shorten messy questions, but keep answers faithful.',
    'Return ONLY valid JSON in this exact shape:',
    '{"pairs":[{"question":"...","answer":"..."}]}',
    'If no reliable pairs exist, return {"pairs":[]}.',
    '',
    'CANDIDATE_PAIRS:',
    JSON.stringify(compactPairs)
  ].join('\n');

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000);
  try {
    const response = await fetch(`${OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      signal: controller.signal,
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        prompt,
        stream: false,
        format: 'json',
        options: {
          temperature: 0
        }
      })
    });

    if (!response.ok) {
      console.warn(`[StudyOralPdfBackend] local AI QA failed status=${response.status}`);
      return [];
    }

    const body = await response.json();
    const parsed = JSON.parse(typeof body.response === 'string' ? body.response : '{"pairs":[]}');
    if (!Array.isArray(parsed.pairs)) {
      return [];
    }

    return parsed.pairs
      .map((pair) => ({
        question: typeof pair.question === 'string' ? pair.question.trim() : '',
        answer: typeof pair.answer === 'string' ? pair.answer.trim() : ''
      }))
      .filter((pair) => pair.question.length >= 3 && pair.answer.length > 0)
      .filter((pair) => isValidQuestionTitle(pair.question))
      .slice(0, 200);
  } catch (error) {
    console.warn('[StudyOralPdfBackend] local AI QA unavailable', error);
    return [];
  } finally {
    clearTimeout(timeout);
  }
}

async function evaluateAnswerWithLocalAi(question, referenceAnswer, userAnswer) {
  const prompt = [
    'You evaluate a study answer against the saved reference answer.',
    'Do not use generic exam templates.',
    'Only judge whether the user answer means the same thing as the reference answer.',
    'If the reference answer is a short exact fact, a different fact is incorrect.',
    'Return ONLY valid JSON in this exact shape:',
    '{"verdict":"correct|partial|incorrect","adjustment":0,"feedback":"short reason"}',
    'adjustment must be an integer from -10 to 10. Use 0 unless meaning clearly changes the overlap score.',
    '',
    'QUESTION:',
    question.substring(0, 700),
    '',
    'REFERENCE_ANSWER:',
    referenceAnswer.substring(0, 1200),
    '',
    'USER_ANSWER:',
    userAnswer.substring(0, 1200)
  ].join('\n');

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetch(`${OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      signal: controller.signal,
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        prompt,
        stream: false,
        format: 'json',
        options: {
          temperature: 0
        }
      })
    });

    if (!response.ok) {
      console.warn(`[StudyOralPdfBackend] local AI answer evaluation failed status=${response.status}`);
      return null;
    }

    const body = await response.json();
    const parsed = JSON.parse(typeof body.response === 'string' ? body.response : '{}');
    const verdict = ['correct', 'partial', 'incorrect'].includes(parsed.verdict) ? parsed.verdict : 'unknown';
    const rawAdjustment = Number.isFinite(parsed.adjustment) ? parsed.adjustment : 0;
    return {
      available: true,
      verdict,
      adjustment: Math.max(-10, Math.min(10, Math.round(rawAdjustment))),
      feedback: typeof parsed.feedback === 'string' ? parsed.feedback.trim().substring(0, 300) : ''
    };
  } catch (error) {
    console.warn('[StudyOralPdfBackend] local AI answer evaluation unavailable', error);
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

function isQuestionLine(line, hasCurrentAnswer) {
  const clean = line.trim();
  const lower = clean.toLowerCase();
  if (lower.startsWith('q:') || lower.startsWith('question:') || /^q[0-9]+[\.:)]\s+/.test(lower)) {
    return true;
  }
  if (/^[0-9]+[\.)、]\s*\S+/.test(clean) && clean.length <= 220) {
    return isLikelyNumberedQuestion(clean, hasCurrentAnswer);
  }
  if (clean.includes('?') || clean.includes('？')) {
    return isLikelyQuestionSentence(clean);
  }
  return false;
}

function isLikelyNumberedQuestion(line, hasCurrentAnswer) {
  const body = line.replace(/^[0-9]+[\.)、]\s*/, '').trim();
  const lower = body.toLowerCase();
  if (body.includes(' / ')) {
    return true;
  }
  if (body.includes('?') || body.includes('？')) {
    return isLikelyQuestionSentence(body);
  }
  if (/^(what|why|how|when|where|which|who|define|explain|describe|compare|list|types|advantages|disadvantages)\b/.test(lower)) {
    return true;
  }
  return !hasCurrentAnswer && body.length <= 80;
}

function isLikelyQuestionSentence(line) {
  const clean = line.trim();
  const lower = clean.toLowerCase();
  if (clean.length > 220) {
    return false;
  }

  const questionIndex = Math.max(clean.indexOf('?'), clean.indexOf('？'));
  const colonIndex = Math.max(clean.indexOf(':'), clean.indexOf('：'));
  if (colonIndex >= 0 && questionIndex > colonIndex) {
    return false;
  }

  if (/^(what|why|how|when|where|which|who|define|explain|describe|compare|list|types|advantages|disadvantages)\b/.test(lower)) {
    return true;
  }
  return clean.endsWith('?') || clean.endsWith('？');
}

function isValidQuestionTitle(question) {
  const clean = question.trim();
  const lower = clean.toLowerCase();
  if (clean.length < 3 || clean.length > 220) {
    return false;
  }
  if (clean.includes('|')) {
    return false;
  }
  if (/^(post|get|put|delete|patch)$/i.test(clean)) {
    return false;
  }
  if (!/[A-Za-z]/.test(clean)) {
    return false;
  }
  if (/^(on expiry|mechanisms)\b/i.test(clean)) {
    return false;
  }
  if (/^(authentication|authorization|accountability)\b/i.test(clean) && clean.includes(':')) {
    return false;
  }
  if (isLikelyQuestionSentence(clean)) {
    return true;
  }
  if (/^(what|why|how|when|where|which|who|define|explain|describe|compare|list|types|advantages|disadvantages)\b/.test(lower)) {
    return true;
  }
  if (clean.includes(' / ')) {
    return true;
  }

  const words = clean.split(/\s+/).filter((word) => /[A-Za-z0-9]/.test(word));
  return words.length >= 2;
}

function cleanQuestion(question) {
  let clean = question
    .trim()
    .replace(/^Q[0-9]*[\.:)]\s*/i, '')
    .replace(/^Question[\.:]\s*/i, '')
    .replace(/^[0-9]+[\.)、]\s*/, '')
    .trim();
  const slashIndex = clean.indexOf(' / ');
  if (slashIndex > 0 && /[A-Za-z]/.test(clean.substring(0, slashIndex))) {
    clean = clean.substring(0, slashIndex).trim();
  }
  return clean.replace(/\s*\/\s*$/, '').trim();
}

function cleanAnswer(answer) {
  let clean = answer
    .trim()
    .replace(/^A[\.:)]\s*/i, '')
    .replace(/^Answer[\.:]\s*/i, '')
    .replace(/^Ans[\.:]\s*/i, '')
    .trim();
  const chineseIndex = clean.search(/\n?\s*(中文|Chinese|CN|ZH)\s*[:：]/i);
  if (chineseIndex > 0) {
    clean = clean.substring(0, chineseIndex).trim();
  }
  return clean
    .replace(/file:\/\/\/\S+\s+\d+\/\d+/g, ' ')
    .replace(/\d{4}\/\d{1,2}\/\d{1,2}\s+\d{1,2}:\d{2}/g, ' ')
    .replace(/[ \t]+/g, ' ')
    .trim();
}

async function extractPdfText(buffer) {
  const pdfjs = await import('pdfjs-dist/legacy/build/pdf.mjs');
  const loadingTask = pdfjs.getDocument({
    data: new Uint8Array(buffer),
    disableFontFace: true,
    isEvalSupported: false,
    useSystemFonts: true
  });

  const pdf = await loadingTask.promise;
  const pages = [];
  try {
    for (let pageNumber = 1; pageNumber <= pdf.numPages; pageNumber += 1) {
      const page = await pdf.getPage(pageNumber);
      const textContent = await page.getTextContent();
      const text = textItemsToLines(textContent.items);
      pages.push({ pageNumber, text });
    }
  } finally {
    await pdf.destroy();
  }

  return {
    method: 'pdfjs-dist',
    pages,
    text: pages.map((page) => page.text).join('\n\n').trim()
  };
}

function textItemsToLines(items) {
  const lines = [];
  const tolerance = 2.5;

  for (const item of items) {
    if (typeof item.str !== 'string' || item.str.trim().length === 0 || !Array.isArray(item.transform)) {
      continue;
    }

    const x = Number(item.transform[4] ?? 0);
    const y = Number(item.transform[5] ?? 0);
    let line = lines.find((candidate) => Math.abs(candidate.y - y) <= tolerance);
    if (!line) {
      line = { y, items: [] };
      lines.push(line);
    }
    line.items.push({ x, text: item.str.trim() });
  }

  return lines
    .sort((left, right) => right.y - left.y)
    .map((line) => line.items
      .sort((left, right) => left.x - right.x)
      .map((item) => item.text)
      .join(' ')
      .replace(/\s+/g, ' ')
      .trim())
    .filter((line) => line.length > 0)
    .join('\n')
    .trim();
}
