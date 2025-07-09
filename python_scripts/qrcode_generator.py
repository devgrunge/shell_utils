import sys
import qrcode

def generate_qr(link, filename="qr_code.png"):
    qr = qrcode.QRCode(
        version=1,
        box_size=10,
        border=4
    )
    qr.add_data(link)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    img.save(filename)
    print(f"QR Code saved as: {filename}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python qrcode_generator.py <link> [filename.png]")
        sys.exit(1)

    link = sys.argv[1]
    filename = sys.argv[2] if len(sys.argv) > 2 else "qr_code.png"

    print(f"🔗 Generating QR Code for: {link}")
    generate_qr(link, filename)
    print(f"✅ QR Code saved as: {filename}")

