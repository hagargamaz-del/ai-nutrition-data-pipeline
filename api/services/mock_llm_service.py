def analyze_meal_image_mock(image_path: str) -> dict:
    """
    Temporary mock function.
    Later, this will be replaced with real LLM image analysis.
    """

    return {
        "meal_items": [
            {
                "food_name": "grilled chicken breast",
                "estimated_quantity": 150,
                "unit": "g",
                "calories": 248,
                "protein_g": 46,
                "carbs_g": 0,
                "fat_g": 5,
                "confidence_score": 0.86
            },
            {
                "food_name": "white rice",
                "estimated_quantity": 180,
                "unit": "g",
                "calories": 234,
                "protein_g": 4,
                "carbs_g": 51,
                "fat_g": 0.5,
                "confidence_score": 0.80
            }
        ],
        "total_calories": 482,
        "total_protein_g": 50,
        "total_carbs_g": 51,
        "total_fat_g": 5.5,
        "confidence_score": 0.83
    }