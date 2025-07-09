import sys
import qrcode

def gerar_qr(link, nome_arquivo="qr_code.png"):
    qr = qrcode.QRCode(
        version=1,
        box_size=10,
        border=4
    )
    qr.add_data(link)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    img.save(nome_arquivo)
    print(f"QR Code salvo como: {nome_arquivo}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python gerar_qr.py <link> [nome_arquivo.png]")
        sys.exit(1)

    link = sys.argv[1]
    nome_arquivo = sys.argv[2] if len(sys.argv) > 2 else "qr_code.png"

    gerar_qr(link, nome_arquivo)

    if __name__ == "__main__":
        if len(sys.argv) < 2:
            print("Uso: python gerar_qr.py <link> [nome_arquivo.png]")
            sys.exit(1)

        link = sys.argv[1]
        nome_arquivo = sys.argv[2] if len(sys.argv) > 2 else "qr_code.png"

        print(f"🔗 Gerando QR Code para: {link}")
        gerar_qr(link, nome_arquivo)
        print(f"✅ QR Code salvo em: {nome_arquivo}")