# AI Nutrition Data Pipeline

AI-powered nutrition logging and analytics pipeline that allows users to log meals through WhatsApp by sending food images. The system uses Google Gemini to extract structured nutrition data from meal images, stores raw predictions in SQL Server staging tables, applies a human-in-the-loop confirmation workflow, loads confirmed records into clean production tables, and visualizes insights through Power BI dashboards.

---

## Project Overview

This project is an automated AI-powered nutrition data pipeline that converts unstructured meal images into structured, validated, analytics-ready nutrition records.

The user interacts with the system through WhatsApp. Instead of manually entering meal details, the user sends a meal image to the WhatsApp chatbot. Twilio receives the message and automatically forwards it to a FastAPI webhook. The backend downloads the image from Twilio, sends it to Google Gemini for food and nutrition extraction, and receives a structured JSON response containing detected food items, estimated quantities, calories, protein, carbohydrates, fats, and AI confidence scores.

The pipeline is automated through multiple stages. Once an image is received, the backend automatically saves the image, calls Gemini, inserts the raw AI prediction into SQL Server staging tables, and sends the extracted nutrition estimate back to the user through WhatsApp. The user then replies with `CONFIRM` or `CANCEL`.

If the user replies `CONFIRM`, the system automatically updates the prediction status, runs the SQL Server ETL stored procedure, validates and loads the confirmed meal into clean production tables, and updates the analytical mart views used by Power BI. If the user replies `CANCEL`, the prediction is marked as cancelled and is not loaded into the production tables.

Power BI connects to the SQL Server mart views using DirectQuery. This allows the dashboard to reflect newly confirmed meals without manually reimporting data. With automatic page refresh enabled, the Power BI report can update while the pipeline continues receiving new meal logs from WhatsApp.

The project demonstrates a complete data engineering workflow: webhook-based ingestion, AI extraction, staging, human-in-the-loop validation, ETL processing, clean data storage, analytical SQL views, and dashboard reporting.

---

## Setup Instructions

This section explains how to run the project locally.

### Prerequisites

Before running the project, install the following tools:

- Python 3.10 or later
- SQL Server
- SQL Server Management Studio
- Power BI Desktop
- ngrok
- Git
- Twilio account with WhatsApp Sandbox enabled
- Google AI Studio API key for Gemini

---

### 1. Clone the Repository

````bash
git clone https://github.com/hagargamaz-del/ai-nutrition-data-pipeline.git
cd ai-nutrition-data-pipeline

````

## Demo Screenshots

### WhatsApp Chatbot Demo

The user sends a meal image through WhatsApp, receives an AI-generated nutrition estimate, and confirms whether the meal should be logged.
<img width="1394" height="855" alt="chatbot analysis" src="https://github.com/user-attachments/assets/454ef2bf-fa6e-4a25-87a3-f56a19f18535" />
<img width="1420" height="437" alt="confirmed_request" src="https://github.com/user-attachments/assets/8626d90c-1a9b-448d-baee-a31a2ad2f39a" />
<img width="1388" height="722" alt="cancelled_request" src="https://github.com/user-attachments/assets/85f65fc0-1d10-4852-b627-730072d61d32" />


---

### Nutrition Overview Dashboard

Shows total calories, protein, carbs, fat, meals logged, and daily nutrition trends.

<img width="1156" height="746" alt="Nutrition Overview dashboard" src="https://github.com/user-attachments/assets/d389b7b8-2d3f-4b20-9fd6-91edfe25edd5" />

---

### Target vs Actual Dashboard

Compares actual calorie and macronutrient intake against user targets.

<img width="1158" height="668" alt="Target vs Actual Plan dashboard" src="https://github.com/user-attachments/assets/ee1b39c8-d1db-44d0-ab5e-71cc348da4fe" />

---

### Food Analysis Dashboard

Shows most consumed foods, highest-calorie foods, and meal item details.

<img width="1163" height="710" alt="Food Analysis dashboard" src="https://github.com/user-attachments/assets/eed8ed7e-30e0-4e2c-a51a-2c63cd5e17b1" />

---

### AI Pipeline Monitoring Dashboard

Tracks AI prediction status, average confidence, failed/rejected records, and ETL pipeline performance.

<img width="1170" height="673" alt="AI Pipeline Monitoring dashboard" src="https://github.com/user-attachments/assets/dbc84783-2375-40a8-9b51-aae4547e57a1" />

---

## Key Features

- WhatsApp-based meal image logging using Twilio Sandbox.
- AI-powered food and nutrition extraction using Google Gemini.
- FastAPI backend for webhook handling and pipeline orchestration.
- SQL Server database with staging, production, audit, ETL, and mart layers.
- Human-in-the-loop confirmation workflow before loading meal records.
- SQL stored procedure for ETL processing.
- Status tracking for loaded, pending, cancelled, failed, rejected, and needs-review predictions.
- Power BI dashboard connected to SQL Server mart views.
- DirectQuery-based dashboard connection for near-real-time reporting.
- Pipeline monitoring dashboard for operational visibility and data quality tracking.

---

## Tech Stack

| Layer                 | Tools                                    |
| --------------------- | ---------------------------------------- |
| Chatbot Interface     | WhatsApp, Twilio Sandbox                 |
| Backend API           | Python, FastAPI                          |
| AI/LLM                | Google Gemini API                        |
| Database              | SQL Server, SQL Server Management Studio |
| ETL                   | SQL Stored Procedures, Python            |
| Analytics Layer       | SQL Server Views                         |
| Dashboard             | Power BI Desktop                         |
| Local Webhook Testing | ngrok                                    |
| Version Control       | Git, GitHub                              |

---

## System Architecture

```text
WhatsApp User
    ↓
Twilio WhatsApp Sandbox
    ↓
FastAPI Webhook
    ↓
Image Download from Twilio Media URL
    ↓
Google Gemini Vision Analysis
    ↓
Structured Nutrition JSON
    ↓
SQL Server Staging Tables
    ↓
WhatsApp Confirmation Request
    ↓
User Replies CONFIRM or CANCEL
    ↓
ETL Stored Procedure
    ↓
SQL Server Production Tables
    ↓
SQL Server Mart Views
    ↓
Power BI Dashboard

