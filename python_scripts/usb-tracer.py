import serial
import datetime

PORT = "/dev/ttyUSBX"
BAUDRATE = 115200
MIN_PACKET_LENGTH = 8

def format_line(direction: str, data: bytes) -> str:
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')
    hex_data = data.hex()
    return f"[{timestamp}] {direction}: {hex_data}"

def identify_direction(data: bytes) -> str:
    if len(data) < MIN_PACKET_LENGTH or data[0] != 0x02 or data[-1] != 0x03:
        return "UNKNOWN"

    addr = data[2]
    comd = data[4]

    if 0x41 <= comd <= 0x5A:  # ASCII A-Z
        return "MASTER→SLAVE"
    else:
        return "SLAVE→MASTER"

def main():
    print(f"[+] Tracing {PORT} at {BAUDRATE} baud...\n")
    try:
        with serial.Serial(PORT, BAUDRATE, timeout=0.1) as ser:
            buffer = b""
            while True:
                byte = ser.read(1)
                if byte:
                    buffer += byte
                    if len(buffer) > 32:
                        direction = identify_direction(buffer)
                        if direction != "UNKNOWN" or len(buffer) > 3:
                            print(format_line(direction, buffer))
                        buffer = b""
    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    main()