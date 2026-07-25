# pyrefly: ignore [missing-import]
import rembg
from PIL import Image

def main():
    input_path = r"C:\Users\Goo\.gemini\antigravity-ide\brain\0fd68141-692d-4ef1-9d42-28d702e8348e\premium_m_logo_1784981506335.png"
    output_path = r"e:\learning\eraa soft\flutter\mubasher fund support\mubasher_fund_supporter\assets\images\app_icon.png"

    with open(input_path, "rb") as i:
        input_data = i.read()

    output_data = rembg.remove(input_data)
    
    # Save transparent logo to replace app_icon.png
    with open(output_path, "wb") as o:
        o.write(output_data)
        
    print("Background removed and saved to app_icon.png")

if __name__ == "__main__":
    main()
