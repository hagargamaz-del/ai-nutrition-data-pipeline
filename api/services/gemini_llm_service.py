import os
from typing import List

from dotenv import load_dotenv
from google import genai
from PIL import Image
from pydantic import BaseModel, Field

load_dotenv()


class MealItem(BaseModel):
    food_name: str = Field(description="Detected food item name.")
    estimated_quantity: float = Field(description="Estimated quantity of the food item.")
    unit: str = Field(description="Measurement unit. Prefer grams as g.")
    calories: float = Field(description="Estimated calories for this food item.")
    protein_g: float = Field(description="Estimated protein in grams.")
    carbs_g: float = Field(description="Estimated carbohydrates in grams.")
    fat_g: float = Field(description="Estimated fat in grams.")
    confidence_score: float = Field(description="Confidence score between 0 and 1.")


class MealAnalysis(BaseModel):
    meal_items: List[MealItem]
    total_calories: float
    total_protein_g: float
    total_carbs_g: float
    total_fat_g: float
    confidence_score: float


def analyze_meal_image_with_gemini(image_path: str) -> dict:
    """
    Sends a meal image to Gemini and returns structured nutrition JSON.
    """

    api_key = os.getenv("GEMINI_API_KEY")
    model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is missing from .env file.")

    client = genai.Client(api_key=api_key)

    image = Image.open(image_path)

    prompt = """
You are a nutrition image analysis assistant.

Analyze the visible meal image and estimate the food items and nutrition values.

Rules:
1. Return only visible food items.
2. Estimate quantity in grams when possible.
3. If exact quantity is uncertain, provide a reasonable estimate.
4. Calories, protein, carbs, and fat must be numeric.
5. Do not return negative values.
6. confidence_score must be between 0 and 1.
7. If the image is unclear, use a lower confidence_score.
8. The totals must approximately equal the sum of the meal item values.
"""

    response = client.models.generate_content(
        model=model_name,
        contents=[image, prompt],
        config={
            "response_mime_type": "application/json",
            "response_json_schema": MealAnalysis.model_json_schema(),
        },
    )

    meal_analysis = MealAnalysis.model_validate_json(response.text)

    return meal_analysis.model_dump()