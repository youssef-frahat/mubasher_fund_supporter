from PIL import Image

def main():
    input_path = r"C:\Users\Goo\.gemini\antigravity-ide\brain\0fd68141-692d-4ef1-9d42-28d702e8348e\premium_m_logo_1784981506335.png"
    output_path = r"e:\learning\eraa soft\flutter\mubasher fund support\mubasher_fund_supporter\assets\images\app_icon.png"

    img = Image.open(input_path).convert("RGBA")
    datas = img.getdata()

    new_data = []
    # Target background color is roughly #180a32 (R=24, G=10, B=50)
    # We will make anything close to this color transparent based on a threshold
    target_r, target_g, target_b = 24, 10, 50
    threshold = 30

    for item in datas:
        # Calculate distance
        r, g, b, a = item
        dist = abs(r - target_r) + abs(g - target_g) + abs(b - target_b)
        
        if dist < threshold:
            # Change close-to-background pixels to transparent
            # Also keep the color but reduce alpha based on distance to blend glow
            alpha = int((dist / threshold) * 255)
            new_data.append((r, g, b, alpha))
        else:
            new_data.append(item)

    img.putdata(new_data)
    img.save(output_path, "PNG")
    print("Background removed using fast method and saved to app_icon.png")

if __name__ == "__main__":
    main()
