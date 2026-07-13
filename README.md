# MeetingMind AI 🚀

> An AI-powered intelligent meeting assistant for recording, transcribing, summarizing, analyzing, and transforming conversations into actionable insights.

MeetingMind AI is a Flutter-based intelligent meeting productivity application that helps users capture conversations, generate structured meeting notes, analyze speaker emotions, extract action items, track decisions, and interact with meeting content using Artificial Intelligence.

The application combines speech recognition, large language models, emotion analysis, and meeting analytics to make meetings more organized, searchable, and productive.

---

## 🌐 Live Services

### Emotion Analysis Backend

The MeetingMind Emotion API is deployed on Render:

https://meetingmind-ai-lgka.onrender.com

Health-check endpoint:

https://meetingmind-ai-lgka.onrender.com/health

Basic emotion endpoint:

https://meetingmind-ai-lgka.onrender.com/emotion

> The Render free service may take approximately 30–90 seconds to wake after a period of inactivity.

---

## ✨ Key Features

### 🎙️ Audio Recording

- Record meetings directly from the mobile application.
- Capture high-quality meeting audio.
- Support real-time meeting recording.
- Manage active recording sessions.

### 📝 Speech-to-Text Transcription

- Automatically convert meeting conversations into text.
- Generate searchable meeting transcripts.
- Support real-time speech recognition.
- Powered by Deepgram speech-processing technology.

### 👥 Speaker Identification

- Detect and separate multiple speakers.
- Label participants as Speaker 1, Speaker 2, and more.
- Organize conversations by speaker.
- Improve meeting readability and analysis.

### 🤖 AI Meeting Summarization

- Generate concise and structured meeting summaries.
- Highlight important discussion points.
- Reduce the time required to review long meetings.
- Generate useful insights from meeting conversations.

### ✅ Action-Item Extraction

- Automatically identify assigned tasks.
- Extract responsibilities and deadlines.
- Generate structured follow-up actions.
- Help teams track pending work.

### 📌 Decision Tracking

- Identify important decisions made during meetings.
- Store decisions for future reference.
- Maintain a clear record of meeting outcomes.

### 😊 Emotion and Voice-Tonality Analysis

MeetingMind AI analyzes vocal characteristics to estimate emotional tone.

Supported emotion insights include:

- 😀 Happy
- 😐 Neutral
- 😟 Concerned
- 😠 Frustrated
- 🎯 Confident

The emotion-analysis backend processes audio features such as:

- Pitch
- Energy
- Spectral characteristics
- Zero-crossing rate
- Voice activity
- Tonal variation

### 💬 AI Meeting Assistant

- Ask questions about recorded meetings.
- Retrieve information from meeting content.
- Generate additional insights.
- Understand summaries, decisions, and action items.

### 📊 Meeting Analytics

- Track meeting activity.
- Analyze participation and engagement.
- View meeting-performance metrics.
- Explore speaker and conversation insights.

### 🗂️ Meeting History

- Store and manage previous meetings.
- Access summaries and transcripts anytime.
- Review decisions and action items.
- Maintain organized meeting records.

### 🔍 Intelligent Search

- Search meeting transcripts.
- Find summaries and important discussions.
- Locate previous meeting records quickly.

---

## 🏗️ Technology Stack

### Mobile Application

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Application programming language |
| Riverpod | State management |
| Isar Database | Local data storage |
| Dio | HTTP networking |
| WebSocket | Real-time communication |

### Backend

| Technology | Purpose |
|---|---|
| Python | Backend programming language |
| Flask | REST API framework |
| Gunicorn | Production WSGI server |
| Render | Cloud backend deployment |
| NumPy | Numerical audio processing |
| SciPy | Signal and audio analysis |
| Static FFmpeg | Audio conversion and processing |

### Artificial Intelligence

| Technology | Purpose |
|---|---|
| Ollama | Local AI model execution |
| Qwen 2.5 7B | Meeting understanding and generation |
| OpenAI Integration | AI-powered meeting intelligence |
| Custom Emotion Analysis | Voice-tone and emotion estimation |

### Speech Processing

| Technology | Purpose |
|---|---|
| Deepgram API | Speech-to-text transcription |
| FFmpeg | Audio conversion |
| WebSocket | Real-time transcription |

### Authentication

| Technology | Purpose |
|---|---|
| Firebase Authentication | User authentication and account management |

---

## 🧠 AI Capabilities

MeetingMind AI uses artificial intelligence to:

- Generate structured meeting summaries.
- Extract action items and responsibilities.
- Identify important meeting decisions.
- Analyze meeting conversations.
- Generate speaker-related insights.
- Estimate emotional tone from voice.
- Answer meeting-related questions.
- Organize unstructured conversations.
- Improve meeting productivity.

---

## 🔄 Application Workflow

```text
Meeting Audio
      ↓
Audio Recording
      ↓
Speech-to-Text Transcription
      ↓
Speaker Identification
      ↓
AI Conversation Analysis
      ↓
Meeting Summary
      ↓
Action Items and Decisions
      ↓
Emotion and Voice-Tone Analysis
      ↓
Meeting Analytics and AI Insights

## 🎯 Project Objective

The primary objective of MeetingMind AI is to reduce the manual effort required to document, review, and manage meetings.

Traditional meetings often create several challenges:

- Important discussion points may be forgotten.
- Manual note-taking can distract participants.
- Action items may not be properly recorded.
- Responsibilities and deadlines can become unclear.
- Reviewing long recordings takes significant time.
- Important decisions may become difficult to track.
- Speaker engagement and emotional tone are usually not analyzed.

MeetingMind AI addresses these challenges by combining speech recognition, artificial intelligence, natural language processing, local large language models, and voice-emotion analysis in one intelligent meeting-management platform.

The application transforms unstructured conversations into organized and actionable information.

---

## 💡 Problem Statement

Organizations, teams, students, researchers, and professionals conduct meetings regularly. However, manually recording every discussion, identifying important decisions, assigning responsibilities, and preparing summaries can be time-consuming and inefficient.

MeetingMind AI provides an intelligent solution that can:

1. Record meeting conversations.
2. Convert speech into structured text.
3. Identify and organize speaker conversations.
4. Generate concise AI-powered summaries.
5. Extract tasks and action items.
6. Identify important decisions.
7. Analyze emotional tone from voice characteristics.
8. Store meeting records for future access.
9. Allow users to ask questions about meeting content.
10. Generate meaningful meeting analytics and insights.

---

## 🌟 Why MeetingMind AI?

MeetingMind AI is designed as more than a basic audio recorder or transcription application.

It combines multiple intelligent capabilities into one platform:

| Traditional Meeting Tools | MeetingMind AI |
|---|---|
| Store only audio recordings | Generates structured meeting intelligence |
| Require manual note-taking | Automatically creates meeting notes |
| Provide plain transcripts | Produces summaries and key insights |
| Require manual task tracking | Extracts action items automatically |
| Do not track decisions | Identifies and stores decisions |
| Limited speaker insights | Supports speaker identification |
| No emotional understanding | Estimates emotion and voice tonality |
| Difficult to review long meetings | Provides concise AI-generated summaries |
| Limited interaction with records | Supports AI-powered meeting questions |

---

## 🔄 Complete Meeting Processing Pipeline

MeetingMind AI follows an intelligent multi-stage workflow:

```text
┌─────────────────────────────┐
│      Start New Meeting      │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│      Record Meeting Audio   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Speech-to-Text Transcription│
│        Using Deepgram       │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Speaker Detection and       │
│ Conversation Organization   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ AI Processing with          │
│ Ollama and Qwen 2.5 7B      │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Summary • Tasks • Decisions │
│ Topics • Meeting Insights   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Voice Emotion and Tonality  │
│ Analysis using Flask API    │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ Meeting History, Analytics, │
│ Search and AI Chat          │
└─────────────────────────────┘
