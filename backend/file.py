from PIL import Image
from pyzbar.pyzbar import decode

# Load your image
# Make sure "image.png" is the correct path to your barcode image
img = Image.open("image.png")

# Use pyzbar's decode function on the image
barcodes = decode(img)

# Loop through the detected barcodes (an image might have more than one)
if barcodes:
    print("--- Barcode Data Found ---")
    for barcode in barcodes:
        # The 'data' field is a byte string, so we decode it to a regular string
        data = barcode.data.decode('utf-8')
        
        # 'type' gives you the barcode format (e.g., 'UPC-A', 'QRCODE', 'EAN13')
        barcode_type = barcode.type
        
        print(f"Type: {barcode_type}")
        print(f"Data (Numbers): {data}")
        print("---")
else:
    print("No barcode was detected in the image.")

# img.show() # You can keep this line if you still want to display the image