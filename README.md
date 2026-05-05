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



## Demo Screenshots

### WhatsApp Chatbot Demo

The user sends a meal image through WhatsApp, receives an AI-generated nutrition estimate, and confirms whether the meal should be logged.

![WhatsApp Chatbot Demo](docs/images/whatsapp_chatbot_demo.png)

---

### Nutrition Overview Dashboard

Shows total calories, protein, carbs, fat, meals logged, and daily nutrition trends.

![Nutrition Overview Dashboard](docs/images/nutrition_overview_dashboard.png)

---

### Target vs Actual Dashboard

Compares actual calorie and macronutrient intake against user targets.

![Target vs Actual Dashboard](docs/images/target_vs_actual_dashboard.png)

---

### Food Analysis Dashboard

Shows most consumed foods, highest-calorie foods, and meal item details.

![Food Analysis Dashboard](docs/images/food_analysis_dashboard.png)

---

### AI Pipeline Monitoring Dashboard

Tracks AI prediction status, average confidence, failed/rejected records, and ETL pipeline performance.

![AI Pipeline Monitoring Dashboard](docs/images/pipeline_monitoring_dashboard.png)

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
````
