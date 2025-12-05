"""
Main workflow: Barcode scanning → UPC extraction → Ingredients lookup
Run this file to execute the complete workflow.
"""

from barcode_to_text import get_upc_from_image
from text_to_ingredients import get_ingredients_from_upc

def main():
    # Step 1: Extract UPC from barcode image
    print("=" * 60)
    print("STEP 1: Extracting UPC from barcode image...")
    print("=" * 60)
    upc = get_upc_from_image("image.png")
    
    if not upc:
        print("\n❌ Failed to extract UPC from image.")
        return
    
    # Step 2: Fetch ingredients from Open Food Facts API
    print("\n" + "=" * 60)
    print("STEP 2: Fetching ingredients from Open Food Facts API...")
    print("=" * 60)
    print(f"UPC: {upc}")
    
    ingredients = get_ingredients_from_upc(upc)
    
    # Step 3: Display results
    print("\n" + "=" * 60)
    print("RESULTS")
    print("=" * 60)
    print(f"Product UPC: {upc}")
    print(f"\nIngredients:\n{ingredients}")
    print("=" * 60)

if __name__ == "__main__":
    main()
