
import network
import ujson as json
import urequests as requests
from machine import Pin, UART, SPI
import time
from ili934xnew import ILI9341, color565
import m5stack
import tt24
import ntptime
import gc
from customqueue import CustomQueue


# Cấu hình WiFi
SSID = "Helloae"
PASSWORD = "88888888@#"

# Cấu hình Firebase
FIREBASE_HOST = "https://dacn2-41607-default-rtdb.firebaseio.com/"
FIREBASE_AUTH = "22LJKOhvDokLaCwY1d7smWvMjxRv4k78AFYXOFCl"
firebase_url = f"{FIREBASE_HOST}/data.json?auth={FIREBASE_AUTH}"

# Khởi tạo dữ liệu cảm biến
sensor_data = {key: 0.0 for key in ["Temperature", "pH", "Turbidity", "DO", "WaterLevel"]}
relay_state = {key: 0 for key in ["Mode", "AirPump", "LightingSys", "FilterSystem", "WaterPump", "Fan"]}
State = {key:0 for key in ["Apump","Fan","fil","Light","W","Mode"]}
previous_state = State.copy()  # Lưu trạng thái state  ban đầu

# Khai báo các ngưỡng với giá trị mặc định


threshold_DO = {
    "DO_max": 0.0,
    "DO_min": 0.0
}

threshold_Temp = {
    "Temp_max": 0.0,
    "Temp_min": 0.0
}

threshold_Tur = {
    "Tur_max": 0.0,
    "Tur_min": 0.0
}

threshold_W = {
    "W_max": 0.0,
    "W_min": 0.0
}

threshold_pH = {
    "pH_max": 0.0,
    "pH_min": 0.0
}

previous_thresholds_DO = threshold_DO.copy()  
previous_thresholds_pH = threshold_pH.copy()
previous_thresholds_Temp = threshold_Temp.copy()
previous_thresholds_Tur = threshold_Tur.copy()
previous_thresholds_W = threshold_W.copy()



# Cấu hình UART
TX_Arduino = 16
RX_Arduino = 17
uart = UART(2, baudrate=9600, tx=Pin(RX_Arduino), rx=Pin(TX_Arduino))

# Cấu hình SPI cho màn hình TFT
power = Pin(m5stack.TFT_LED_PIN, Pin.OUT)
power.value(1)

spi = SPI(
    1,
    baudrate=40000000,
    miso=Pin(m5stack.TFT_MISO_PIN),
    mosi=Pin(m5stack.TFT_MOSI_PIN),
    sck=Pin(m5stack.TFT_CLK_PIN),
)

lcd = ILI9341(
    spi,
    cs=Pin(m5stack.TFT_CS_PIN),
    dc=Pin(m5stack.TFT_DC_PIN),
    w=240,
    h=320,
    r=3,
)

def connect_wifi():
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    wlan.connect(SSID, PASSWORD)
    print("Đang kết nối Wi-Fi...")
    timeout = 15
    while not wlan.isconnected() and timeout > 0:
        time.sleep(0.5)
        timeout -= 0.5
        print(".", end="")
    if wlan.isconnected():
        print("\nĐã kết nối! Địa chỉ IP:", wlan.ifconfig()[0])
    else:
        print("\nLỗi kết nối Wi-Fi!")

# Đồng bộ thời gian NTP
def sync_time_ntp():
    try:
        ntptime.host = 'pool.ntp.org'
        ntptime.settime()
        current_time = time.localtime()
        print("Đồng bộ thời gian thành công: ", current_time)
        return current_time
    except Exception as e:
        print(f"Lỗi đồng bộ NTP: {e}")
        return None

# Lấy thời gian hiện tại theo định dạng
def get_current_timestamp():
    current_time = time.localtime()
    current_time_vn = time.localtime(time.mktime(current_time) + 7 * 3600)
    year_month = f"{current_time_vn[0]}-{current_time_vn[1]:02d}"
    day_hour_minute = f"{current_time_vn[2]:02d}-{current_time_vn[3]:02d}-{current_time_vn[4]:02d}"
    return year_month, day_hour_minute

# Gửi dữ liệu cảm biến lên Firebase
        
def send_sensor_data_to_firebase():
    try:
        year_month, day_hour_minute = get_current_timestamp()
        data_path = f"data/{year_month}/{day_hour_minute}.json"
        json_data = json.dumps(sensor_data)
        print(f"Dữ liệu JSON gửi đi: {json_data}")
        response = requests.put(f"{FIREBASE_HOST}/{data_path}?auth={FIREBASE_AUTH}", data=json_data)
        if response.status_code == 200:
            print(f"Gửi dữ liệu thành công đến: {data_path}")
        else:
            print(f"Lỗi khi gửi dữ liệu: {response.status_code}, {response.text}")
    except Exception as e:
        print(f"Lỗi khi gửi dữ liệu lên Firebase: {e}")
        # Thử lại gửi dữ liệu sau một khoảng thời gian nếu gặp lỗi
        time.sleep(5)
        send_sensor_data_to_firebase()
    finally:
        gc.collect()

# Gửi dữ liệu cảm biến lên Firebase Realtime
def send_sensor_data_to_realtime():
    try:
        json_data = json.dumps(sensor_data)
        print(f"Dữ liệu JSON gửi đi (Realtime): {json_data}")
        response = requests.put(f"{FIREBASE_HOST}/datarealtime.json?auth={FIREBASE_AUTH}", data=json_data)
        if response.status_code == 200:
            print("Gửi dữ liệu thành công đến datarealtime/")
        else:
            print(f"Lỗi khi gửi dữ liệu đến datarealtime/: {response.status_code}, {response.text}")
    except Exception as e:
        print(f"Lỗi khi gửi dữ liệu đến datarealtime/: {e}")

# Nhận dữ liệu từ UART
def receive_data():
    if uart.any():
        data = uart.readline().decode("utf-8").strip()
        print(f"Dữ liệu nhận được: {data}")
        try:
            json_data = json.loads(data)
            data_type = json_data.get("type", None)

            if data_type == "sensor_data":
                handle_sensor_data(json_data)
            elif data_type == "relay_state":
                handle_relay_state(json_data)
            else:
                print("Loại dữ liệu không xác định!")
        except ValueError as e:
            print(f"Lỗi phân tích JSON: {e}")
        finally:
            gc.collect()

def handle_sensor_data(json_data):
    print("Dữ liệu cảm biến:", json_data)
    sensor_data.update({key: auto_round(json_data.get(key, 0.0)) for key in sensor_data.keys()})
    print(sensor_data)
    draw_values()
    if sync_time_ntp():
        send_sensor_data_to_firebase()
    send_sensor_data_to_realtime()

def handle_relay_state(json_data):
    print("Trạng thái Relay:", json_data)
    relay_state.update({key: json_data.get(key, 0) for key in relay_state.keys()})
    print(relay_state)
    send_state_to_firebase()

def send_state_to_firebase():
    try:
        json_data = json.dumps(relay_state)
        print(f"Dữ liệu JSON gửi đi (State): {json_data}")
        response = requests.put(f"{FIREBASE_HOST}/State.json?auth={FIREBASE_AUTH}", data=json_data)
        if response.status_code == 200:
            print("Gửi dữ liệu thành công đến State/")
        else:
            print(f"Lỗi khi gửi dữ liệu đến State/: {response.status_code}, {response.text}")
    except Exception as e:
        print(f"Lỗi khi gửi dữ liệu đến State/: {e}")
        

def send_state_uart():
    '''Ham gui state qua uart'''
    
    try:
        json_string = json.dumps(State)
        uart.write((json_string + "\n").encode('utf-8'))
    except Exception as e:
        print(f"Lỗi gửi State qua UART: {e}")
        
        

def send_threshold_uart(threshold_data, data_name):
    try:
        if not threshold_data:
            print(f"Dữ liệu {data_name} không hợp lệ: {threshold_data}")
            return
        threshold_json = json.dumps(threshold_data)
        uart.write((threshold_json + "\n").encode('utf-8'))  # Giả sử uart.write đã được khai báo
        print(f"Đã gửi {data_name} qua UART: {threshold_json}")
    except Exception as e:
        print(f"Lỗi gửi {data_name} qua UART: {e}")


def receive_data_from_firebase():
    '''Ham lay state tu firebase'''
    global previous_state  
    
    try:
        response = requests.get(f"{FIREBASE_HOST}/State.json?auth={FIREBASE_AUTH}")
        if response.status_code == 200:
            firebase_data = response.json()
            if firebase_data:
                State["Fan"] = firebase_data.get("Fan", 0)
                State["Apump"] = firebase_data.get("AirPump", 0)
                State["fil"] = firebase_data.get("FilterSystem", 0)
                State["Light"] = firebase_data.get("LightingSys", 0)
                State["W"] = firebase_data.get("WaterPump", 0)
                State["Mode"] = firebase_data.get("Mode", 0)
                
                
                if State != previous_state:
                    print("Trạng thái đã thay đổi.")
                    #print("Trạng thái cũ:", previous_state)
                    #print("Trạng thái mới:", State)
                    send_state_uart()
                    previous_state = State.copy()  # Cập nhật trạng thái cũ
                
        else:
            print(f"Lỗi Firebase: {response.status_code}, {response.text}")
    except Exception as e:
        print(f"Lỗi khi nhận dữ liệu từ Firebase: {e}")
    finally:
        gc.collect()
                  

def receive_threshold_from_firebase():
    global previous_thresholds_DO
    global previous_thresholds_pH
    global previous_thresholds_Temp
    global previous_thresholds_Tur
    global previous_thresholds_W
    
    try:
        response_threshold = requests.get(f"{FIREBASE_HOST}/Threshold.json?auth={FIREBASE_AUTH}")
        
        if response_threshold.status_code == 200:
            threshold_data = response_threshold.json()
           # print(threshold_data)
            
            if threshold_data:
                # Cập nhật ngưỡng DO
                threshold_DO["DO_max"] = threshold_data.get("DO", {}).get("max", 0.0)
                threshold_DO["DO_min"] = threshold_data.get("DO", {}).get("min", 0.0)
                
                # Cập nhật ngưỡng nhiệt độ
                threshold_Temp["Temp_max"] = threshold_data.get("Temperature", {}).get("max", 0.0)
                threshold_Temp["Temp_min"] = threshold_data.get("Temperature", {}).get("min", 0.0)
            
                # Cập nhật ngưỡng độ đục
                threshold_Tur["Tur_max"] = threshold_data.get("Turbidity", {}).get("max", 0.0)
                threshold_Tur["Tur_min"] = threshold_data.get("Turbidity", {}).get("min", 0.0)
    
                # Cập nhật ngưỡng mức nước
                threshold_W["W_max"] = threshold_data.get("Water Level", {}).get("max", 0.0)
                threshold_W["W_min"] = threshold_data.get("Water Level", {}).get("min", 0.0)
        
                # Cập nhật ngưỡng pH
                threshold_pH["pH_max"] = threshold_data.get("pH", {}).get("max", 0.0)
                threshold_pH["pH_min"] = threshold_data.get("pH", {}).get("min", 0.0)
                
                 # Kiểm tra và gửi ngưỡng nếu có thay đổi
                if threshold_DO != previous_thresholds_DO:
                    print("Ngưỡng DO thay đổi")
                    send_threshold_uart(threshold_DO, "Threshold_DO")
                    previous_thresholds_DO = threshold_DO.copy()
                    
                if threshold_Temp != previous_thresholds_Temp:
                    print("Ngưỡng Temp thay đổi")
                    send_threshold_uart(threshold_Temp, "Threshold_Temp")
            
                    previous_thresholds_Temp = threshold_Temp.copy()

                if threshold_Tur != previous_thresholds_Tur:
                    print("Ngưỡng Tur thay đổi")
                    send_threshold_uart(threshold_Tur, "Threshold_Tur")
                    
                    previous_thresholds_Tur = threshold_Tur.copy()

                if threshold_W != previous_thresholds_W:
                    print("Ngưỡng W thay đổi")
                    send_threshold_uart(threshold_W, "Threshold_W")
                    previous_thresholds_W = threshold_W.copy()

                if threshold_pH != previous_thresholds_pH:
                    print("Ngưỡng pH thay đổi")
                    send_threshold_uart(threshold_pH, "Threshold_pH")
                    previous_thresholds_pH = threshold_pH.copy()

            else:
                print("Không có dữ liệu ngưỡng từ Firebase.")
        else:
            print(f"Lỗi Firebase: {response_threshold.status_code}, {response_threshold.text}")
    except Exception as e:
        print(f"Lỗi nhận dữ liệu Threshold từ Firebase: {e}")

            
# Hàm làm tròn số
def auto_round(number, decimal_places=1):
    return round(number, decimal_places)

# Vẽ giá trị cảm biến lên màn hình TFT
def draw_values():
    lcd.erase()
    lcd.set_font(tt24)
    lcd.text("SENSOR", 10, 15, color565(0, 0, 255), color565(0, 0, 0))
    lcd.text("VALUE", 170, 15, color565(0, 0, 255), color565(0, 0, 0))
    for idx, (key, value) in enumerate(sensor_data.items()):
        lcd.text(key, 10, 15 + 50 * (idx + 1), color565(0, 0, 255), color565(0, 0, 0))
        lcd.text(str(value), 170, 15 + 50 * (idx + 1), color565(0, 0, 255), color565(0, 0, 0))

# Chương trình chính
def main():
    connect_wifi()
    while True:
        receive_data()
        time.sleep(1)
        receive_data_from_firebase()
        time.sleep(1)
        receive_threshold_from_firebase()
        time.sleep(1)
        gc.collect()
        
        #time.sleep(1)

# Chạy chương trình chính
try:
    main()
except Exception as e:
    print(f"Lỗi chương trình: {e}")



