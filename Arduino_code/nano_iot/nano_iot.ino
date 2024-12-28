//ph cao: quat. Suc khi Co2 neu pH cao. Dung Na2Co3 nếu pH thấp.
//oxi: suc oxi
//nhiet do: chay quat
//do duc: hệ thong loc nuoc tuan hoan
//muc nuoc: may bom, may hut. tranh bom nuoc ngoai.
#include <TaskScheduler.h>
#include <OneWire.h>
#include <ArduinoJson.h>


// Cac nguong an toan
/*#define PH_MAX 8.5f
#define PH_MIN 6.5f
#define TEMP_MAX 28.0f
#define TEMP_MIN 24.0f
#define TURBIDITY_MAX 30.0f
#define WATER_LEVEL_MAX 30.0f
#define DO_MIN 6.0f*/

float PH_MAX = 8.5;
float PH_MIN = 6.5;
float TEMP_MAX = 28.0;
float TEMP_MIN = 24.0;
float TURBIDITY_MAX = 30.0;
float WATER_LEVEL_MAX = 30.0;
float DO_MIN = 6.0;

//system mode
uint8_t SMODE = 0; 
uint8_t previousSmode = 0;

bool modeState = false;




//setup cac chan sensor
#define pHSensor A6
#define TemperatureSensor 12 
#define HCSR04Sensor_echo 10
#define HCSR04Sensor_trip 11
#define TurbiditySensor A7

//setup cac chan relay
#define R_oxygen 6
#define R_htcs 4
#define R_waterFlow 5
#define R_pump 2
#define R_fan 3

bool isSendingData = false;


// Trang thai relay
bool DO_State = false;
bool Htcs_State = false;
bool WaterLevelState = false;
bool pumpState = false;
bool fanState = false;


//unsigned long lastSendTime = 0;
//unsigned long sendInterval = 1000;



int lastButtonValue = -1; 
bool buzzerState = false;

//setup button
#define multiButton A0

//setup buzzer
#define buzzer 7

//setup uart arduino-esp32
//#define RX_PIN 1
//#define TX_PIN 0

// doi tuong qonewire de doc nhiet do
OneWire tempSensor(TemperatureSensor);

//Khoi tao TaskScheduler
Scheduler runner;

//Bien luu gia tri cam bien.
float celsius = 0.0f, DO = 0.0f, pH = 0.0f, NTU = 0.0f, distance = 0.0f;


//lu du lieu nhan duoc tu uart
struct StateData {
  uint8_t Apump;
  uint8_t Fan;
  uint8_t fil;
  uint8_t Light;
  uint8_t W;
  uint8_t Mode;
} state;

struct Threshold {
  float max;
  float min;
};

Threshold thresholdDO = {13.0f, 6.0f};
Threshold thresholdTemp = {28.0f, 24.0f};
Threshold thresholdPH = {8.5f, 6.5f};
Threshold thresholdTurbidity = {30.0f, 5.0f};
Threshold thresholdWaterLevel = {30.0f, 20.0f};

// Khai báo biến trạng thái trước đó
bool previousDO_State = false;
bool previousHtcs_State = false;
bool previousWaterLevelState = false;
bool previousPumpState = false;
bool previousFanState = false;

float prevCelsius = 0;
float prevDO = 0;
float prevPH = 0;
float prevNTU = 0;
float prevDistance = 0;


int stateButton1 = 0; 
int stateButton2 = 0;
int stateButton3 = 0;
int stateButton4 = 0;
int stateButton5 = 0;    
int stateButton6 = 0;


int prestateButton1 = 0;
int prestateButton2= 0;
int prestateButton3 = 0;
int prestateButton4 = 0;
int prestateButton5 = 0;
int prestateButton6 = 0;





void readTemperature(){
  //Ham xu ly cam bien nhiet do
  byte i;
  byte present = 0;
  byte type_s; //bien luu gia tri xac dinh loại cam bien
  byte data[9];//bien luu gia tri nhiet do
  byte address[8];//bien luu dia chi cam bien

  //float celsius;
  //float fahrenheit;

  /*Kiem tra tin hieu present co tra ve hay khong
  Khoang thoi gian reset 48us- 640us.
  */

  if(!tempSensor.search(address)){
    unsigned long startMicros = millis();

    //Serial.println("No more address");
    //Serial.println();
    tempSensor.reset_search();
    while (millis() - startMicros<250){} 

    return;
  }
  //In dia chi rom
  //Serial.print("ROM =");
  /*for(i = 0; i < 8; i++){
    Serial.write(' ');
    //Serial.print(address[i], HEX);
  }*/

  if(OneWire::crc8(address, 7) != address[7]){
    //Serial.println("CRC is not valid");
    return;
  }

  tempSensor.reset();
  tempSensor.select(address);
  tempSensor.write(0x44,1); // gui lenh bat dau giao tiep voiws ds18b20
  unsigned long delayMicros = millis();
  while(millis() -delayMicros < 1000){}

  present = tempSensor.reset();
  tempSensor.select(address);
  tempSensor.write(0xBE); // gui lenh doc du lieu toi ds18b20

  //Serial.print("Data = ");
  //Serial.print(present, HEX);
  //Serial.print(" ");

  for(i =0; i< 9; i++){
    data[i] = tempSensor.read();
    //Serial.print(data[i], HEX);
    //Serial.print(" ");

  }

  //Serial.print(" CRC =");
  OneWire::crc8(data, 8);
  //Serial.println();

  int16_t raw = (data[1]<< 8) | data[0];

  if(type_s){
    raw = raw << 3;
    if(data[7] == 0x10){
      raw = (raw & 0xFFF0) +12 -data[6];
    }
  }else{
    byte cfg = (data[4] & 0x60);
    //Tai do phan giai thap cac bit thap khong xac dinh
    if(cfg == 0x00) raw = raw & ~7;
    else if (cfg == 0x20) raw = raw & ~3;
    else if (cfg == 0x40) raw = raw & ~1;

    celsius = (float)raw / 16.0;
   // fahrenheit = celsius * 1.8 + 32.0;

    //Serial.print(" Temperature = ");
    //Serial.print(celsius);
    //Serial.println(" do C");
   // Serial.print(fahrenheit);
    //Serial.println(" do F");
  }

  DO = 13.03f - 0.175f * celsius;  // Dung phuong phap hoi quy tuyen tinh.


}


void readpH(){
  //Ham xu ly cam bien pH
   long measuring = 0;
  for (uint16_t i = 0; i < 800; i++) {
    measuring += analogRead(pHSensor);
  }
  float voltage = (measuring / 800.0f) * 5.0f / 1023.0f;
  pH = 7.0f + ((2.5f - voltage) / 0.18f);
  
}

void readTurbidity(){
  //Ham xu ly cam bien do duc nuoc
  long measuring = 0;
  //float NTU;
   for (uint16_t i = 0; i < 800; i++) {
    measuring += analogRead(TurbiditySensor);
  }
  float voltage = 5.0f / 1023.0f * measuring / 800.0f;
  NTU = (voltage < 2.5f) ? 3000.0f : -1120.4f * sq(voltage) + 5742.3f * voltage - 4353.8f;

}

void readDistance(){
  //Ham doc va xu ly gia tri cam bien hc-sr04
  static unsigned long startmicros = micros();
  //static bool pingSent = fasle;

  digitalWrite(HCSR04Sensor_trip, HIGH);
  while(micros()- startmicros <= 10){}
  digitalWrite(HCSR04Sensor_trip, LOW);

  //do thoi gian tin hieu phan hoi.
  long duration = pulseIn(HCSR04Sensor_echo, HIGH);

  //van toc am thanh trong khong khi: 343,2m/s = 343,2 *100 cm/s.
  // 1us = 1*10^(-6)

  distance = (duration / 2.0f) * 0.0344f;

}
void receiveData() {
  if (Serial.available()) {
    String receivedData = Serial.readStringUntil('\n'); // Đọc dữ liệu tới khi gặp '\n'
    Serial.print("Dữ liệu nhận được: ");
    Serial.println(receivedData);

    // Phân tích dữ liệu JSON
    processJson(receivedData);
  }
}

void processJson(String &data) {
  StaticJsonDocument<500> doc;
  DeserializationError error = deserializeJson(doc, data);

  if (error) {
    Serial.print("Lỗi phân tích JSON: ");
    Serial.println(error.c_str());
    return;
  }

  // Cập nhật State
  if (doc.containsKey("Apump")) {
    state.Apump = doc["Apump"];
    state.Fan = doc["Fan"];
    state.fil = doc["fil"];
    state.Light = doc["Light"];
    state.W = doc["W"];
    state.Mode = doc["Mode"];

   /* Serial.println("Dữ liệu State đã cập nhật:");
    Serial.print("Apump: "); Serial.println(state.Apump);
    Serial.print("Fan: "); Serial.println(state.Fan);
    Serial.print("fil: "); Serial.println(state.fil);
    Serial.print("Light: "); Serial.println(state.Light);
    Serial.print("W: "); Serial.println(state.W);
    Serial.print("Mode: "); Serial.println(state.Mode);*/

    SMODE = state.Mode;
   
    if(state.Mode == 0){
      digitalWrite(R_fan, state.Fan ? LOW : HIGH);
      fanState = state.Fan;

      digitalWrite(R_htcs,state.Light ? LOW : HIGH);
      Htcs_State = state.Light;

      digitalWrite(R_oxygen, state.Apump ? LOW : HIGH);
      DO_State = state.Apump;

      digitalWrite(R_pump, state.W ? LOW : HIGH);
      pumpState = state.W;

      digitalWrite(R_waterFlow,state.fil ? LOW : HIGH);
      WaterLevelState = state.fil;

      StaticJsonDocument<300> jsonRelayState;

      
    }
  }

/*Danh dau phan sua*/

  if (doc.containsKey("DO_max")) {
    thresholdDO.max = doc["DO_max"];
    thresholdDO.min = doc["DO_min"];

    DO_MIN = thresholdDO.min;

    
  }
  if (doc.containsKey("Temp_max")) {
    thresholdTemp.max = doc["Temp_max"];
    thresholdTemp.min = doc["Temp_min"];

    TEMP_MAX = thresholdTemp.max;
    TEMP_MIN = thresholdTemp.min;


    
  }
  if (doc.containsKey("pH_max")) {
    thresholdPH.max = doc["pH_max"];
    thresholdPH.min = doc["pH_min"];

    PH_MAX = thresholdPH.max;
    PH_MIN = thresholdPH.min;

  }
  if (doc.containsKey("Tur_max")) {
    thresholdTurbidity.max = doc["Tur_max"];
    thresholdTurbidity.min = doc["Tur_min"];


    TURBIDITY_MAX = thresholdTurbidity.max;

  }
  if (doc.containsKey("W_max")) {
    thresholdWaterLevel.max = doc["W_max"];
    thresholdWaterLevel.min = doc["W_min"];

    WATER_LEVEL_MAX = thresholdWaterLevel.max;

  }



}

// ========================================================


void sendData() {
  // Kiểm tra dữ liệu có thay đổi hay không
  if (celsius == prevCelsius ||
      DO == prevDO ||
      pH == prevPH ||
      NTU == prevNTU ||
      distance == prevDistance) {
    // Nếu dữ liệu không thay đổi, không gửi
    return;
  }

  // Dữ liệu đã thay đổi, tiến hành gửi
  isSendingData = true;

  // Tạo đối tượng JSON
  StaticJsonDocument<300> jsonData;
  jsonData["type"] = "sensor_data";
  jsonData["Temperature"] = celsius;
  jsonData["DO"] = DO;
  jsonData["pH"] = pH;
  jsonData["Turbidity"] = NTU;
  jsonData["WaterLevel"] = distance;

  // Chuyển đối tượng JSON thành chuỗi
  String jsonString;
  serializeJson(jsonData, jsonString);

  // Gửi chuỗi JSON qua UART
  Serial.println(jsonString);

  isSendingData = false;

  // Lưu lại giá trị dữ liệu hiện tại
  prevCelsius = celsius;
  prevDO = DO;
  prevPH = pH;
  prevNTU = NTU;
  prevDistance = distance;
}

void anlogButtonDevice(int buttonValue){
  //Serial.print(" Button analog = ");
  //Serial.println(buttonValue);
  unsigned long lastDebounceTime = 0;
  unsigned long debounceDelay = 50;
  if (millis() - lastDebounceTime > debounceDelay) {
  // cap nhat thoi gian debounce
  lastDebounceTime = millis();
    if (buttonValue >= 740 && buttonValue <= 760) {
      DO_State = !DO_State;
      digitalWrite(R_oxygen, DO_State ? LOW : HIGH);
      stateButton1 = ! stateButton1;
      
    }
    else if (buttonValue >= 700 && buttonValue <= 720 && SMODE == 0) {
      Htcs_State = !Htcs_State;
      digitalWrite(R_htcs, Htcs_State ? LOW : HIGH);
      stateButton2 = !stateButton2;
    }
    else if (buttonValue >= 650 && buttonValue <= 670 && SMODE == 0) {
      WaterLevelState = !WaterLevelState;
      digitalWrite(R_waterFlow, WaterLevelState ? LOW : HIGH);
      stateButton3 = !stateButton3;
    }
    else if (buttonValue >= 580 && buttonValue <= 600 && SMODE == 0) {
      pumpState = !pumpState;
      digitalWrite(R_pump, pumpState ? LOW : HIGH);
      stateButton4 = !stateButton4;
    }
    else if (buttonValue >= 480 && buttonValue <= 500 && SMODE == 0) {
      fanState = !fanState;
      digitalWrite(R_fan, fanState ? LOW : HIGH);
      stateButton5 = !stateButton5;
    }else if(buttonValue >= 315 && buttonValue <= 335 && SMODE == 0){
      buzzerState = !buzzerState;
      buzzerState ? tone(buzzer, 100) : noTone(buzzer);
    }
  }
}

void controlDevices(){
  // do pH an toan khoang 6.5-8.5
  //pH thấp DO giảm.
  // do duc tot nam trong khoang 30-40
  bool fanControl = (pH > PH_MAX || celsius > TEMP_MAX || celsius < TEMP_MIN);
  digitalWrite(R_fan, fanControl ? LOW : HIGH); // LOW = BẬT relay
  fanState = fanControl;

  bool oxygenControl = (pH < PH_MIN || DO < DO_MIN || celsius > TEMP_MAX || celsius < TEMP_MIN);
  digitalWrite(R_oxygen, oxygenControl ? LOW : HIGH);
  DO_State = oxygenControl;

  bool waterFlowControl = (NTU > TURBIDITY_MAX);
  digitalWrite(R_waterFlow, waterFlowControl ? LOW : HIGH);
  WaterLevelState = waterFlowControl;

  bool pumpControl = (distance > WATER_LEVEL_MAX);
  digitalWrite(R_pump, pumpControl ? LOW : HIGH);
  pumpState = pumpControl;

  bool alarmControl = (pH > PH_MAX || celsius > TEMP_MAX || celsius < TEMP_MIN ||
                       pH < PH_MIN || DO < DO_MIN || NTU > TURBIDITY_MAX || 
                       distance > WATER_LEVEL_MAX);
  if (alarmControl) {
    tone(buzzer, 100); // BẬT còi
  } else {
    noTone(buzzer); // TẮT còi
  }
  buzzerState = alarmControl;

}

 


void controllModeSys(){
  int buttonValue = analogRead(multiButton); 
  unsigned long timeLastDebounce = 0;
  unsigned long delayDebounce = 50;
  if (millis() - timeLastDebounce > delayDebounce) {
  // cap nhat thoi gian debounce
  timeLastDebounce = millis();
    // Chi thay doi trang thai neu gia tri nut bam thay doi de khong bi doi
    if (abs(buttonValue - lastButtonValue) > 20) { // Dam bao gia tri thay doi du lon
      lastButtonValue = buttonValue;
      if (buttonValue >= 0 && buttonValue <= 20) {
        modeState = !modeState;
        SMODE = modeState ? 1 : 0;
        //Serial.print("SMODE: "); 
        //Serial.println(SMODE);
        stateButton6 = ! stateButton6;
        
      }
    }
  }
  if(SMODE == 1){
        controlDevices();
  }else{
        anlogButtonDevice(buttonValue);
  }
  


}



void sendRelayState() {
    // Gửi trạng thái relay
    StaticJsonDocument<300> jsonRelayState;
    jsonRelayState["type"] = "relay_state";
    jsonRelayState["Mode"] = SMODE;
    jsonRelayState["AirPump"] = DO_State ? 1 : 0;
    jsonRelayState["LightingSys"] = Htcs_State ? 1 : 0;
    jsonRelayState["FilterSystem"] = WaterLevelState ? 1 : 0;
    jsonRelayState["WaterPump"] = pumpState ? 1 : 0;
    jsonRelayState["Fan"] = fanState ? 1 : 0;

    // Kiểm tra xem có thay đổi trạng thái không
    if ((DO_State != previousDO_State || 
        Htcs_State != previousHtcs_State || 
        WaterLevelState != previousWaterLevelState || 
        pumpState != previousPumpState || 
        fanState != previousFanState
        || SMODE != previousSmode)
        &&( stateButton1 != prestateButton1
        || stateButton2 != prestateButton2
        || stateButton3 != prestateButton3
        || stateButton4 != prestateButton4
        || stateButton5 != prestateButton5
        || stateButton6 != prestateButton6)) {
        
        // Nếu có thay đổi, gửi dữ liệu
        String jsonStringRelay;
        serializeJson(jsonRelayState, jsonStringRelay);
        Serial.println(jsonStringRelay);
        
        // Cập nhật trạng thái trước đó
        previousDO_State = DO_State;
        previousHtcs_State = Htcs_State;
        previousWaterLevelState = WaterLevelState;
        previousPumpState = pumpState;
        previousFanState = fanState;
        previousSmode = SMODE;
        prestateButton1 = stateButton1;
        prestateButton2 = stateButton2;
        prestateButton3 = stateButton3;
        prestateButton4 = stateButton4;
        prestateButton5 = stateButton5;
        prestateButton6 = stateButton6;


    }
}


// Khai bao cac task
Task taskReadTemperature(1000, TASK_FOREVER, &readTemperature); // Task doc nhiet do
Task taskReadpH(1000, TASK_FOREVER, &readpH);                  // Task doc pH
Task taskReadTurbidity(1000, TASK_FOREVER, &readTurbidity);    // Task doc do duc
Task taskReadDistance(1000, TASK_FOREVER, &readDistance);       // Task doc muc nuoc
Task taskSendData(1000, TASK_FOREVER, &sendData);              // Task gui du lieu
Task taskcontrolMode(1000, TASK_FOREVER, &controllModeSys);
Task tasksendRelayState(1000, TASK_FOREVER, &sendRelayState);
Task taskreceiveData(1000, TASK_FOREVER, &receiveData);


void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);

  //cai dat che do chan cam bien Hcsr04
  pinMode(HCSR04Sensor_trip, OUTPUT);
  pinMode(HCSR04Sensor_echo, INPUT);
  //pinMode(multiButton, INPUT);
  pinMode(buzzer, OUTPUT);

  //Cai dat chan relay
  pinMode(R_oxygen, OUTPUT);
  pinMode(R_htcs, OUTPUT);
  pinMode(R_waterFlow, OUTPUT);
  pinMode(R_pump, OUTPUT);
  pinMode(R_fan, OUTPUT);

  //add task vao runner
  runner.addTask(taskReadTemperature);
  runner.addTask(taskReadpH);
  runner.addTask(taskReadTurbidity);
  runner.addTask(taskReadDistance);
  runner.addTask(taskSendData);
  runner.addTask(taskcontrolMode);
  runner.addTask(tasksendRelayState);
  runner.addTask(taskreceiveData);
  //enble cac tasks
  taskReadTemperature.enable();
  taskReadpH.enable();
  taskReadTurbidity.enable();
  taskReadDistance.enable();
  taskSendData.enable();
  taskcontrolMode.enable();
  tasksendRelayState.enable();
  taskreceiveData.enable();
}

void loop() {
  //Chay cac task
  
  runner.execute();
}
