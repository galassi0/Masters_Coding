#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

// --- Digital Polling Variables ---
int currentState = LOW;
unsigned long lastPrintTime = 0;
const int INPUT_PIN = 2;
const unsigned long POLLING_INTERVAL_MICROS = 10000; // 10ms update interval

// --- MPU6050 Object ---
Adafruit_MPU6050 mpu;

void setup() {
  // 1. Initialize Serial Communication
  Serial.begin(115200);
  delay(100); // Wait for serial to connect

  // 2. Initialize Digital Pin
  pinMode(INPUT_PIN, INPUT);
  currentState = digitalRead(INPUT_PIN);
  lastPrintTime = micros();

  // 3. Initialize MPU6050 Sensor (I2C)
if (!mpu.begin(0x69)) {  // Use 0x69 for AD0 tied to VCC
  Serial.println(F("--- MPU6050 Initialization Failed! Check Wiring. ---"));
  while (1) delay(10);
}
  
  // Optional: Set gyroscope and accelerometer ranges (defaults are often fine)
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_2000_DEG);

  // 4. Print Header
  // The output format is critical for parsing in MATLAB/Python.
  Serial.println(F("--- Pin 2 + MPU6050 Data Logger Started ---"));
  Serial.println(F("Time_micros | Pin_State | Accel_X | Accel_Y | Accel_Z | Gyro_X | Gyro_Y | Gyro_Z"));
}

void loop() {
  unsigned long currentTime = micros();
  int currentPinState = digitalRead(INPUT_PIN);
  bool dataReady = false;

  // Check for a state change OR a periodic timeout
  if (currentPinState != currentState || (currentTime - lastPrintTime >= POLLING_INTERVAL_MICROS)) {
    
    // If the state changed, update the currentState variable.
    if (currentPinState != currentState) {
      currentState = currentPinState;
    }
    
    dataReady = true;
    lastPrintTime = currentTime;
  }
  
  if (dataReady) {
    // --- Read MPU6050 Data ---
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    // --- Print Combined Data ---
    // 1. Time and Digital State
    Serial.print(currentTime);
    Serial.print(F(" | "));
    Serial.print(currentState == HIGH ? "HIGH" : "LOW");

    // 2. Accelerometer Data (m/s^2)
    Serial.print(F(" | "));
    Serial.print(a.acceleration.x, 3);
    Serial.print(F(" | "));
    Serial.print(a.acceleration.y, 3);
    Serial.print(F(" | "));
    Serial.print(a.acceleration.z, 3);

    // 3. Gyroscope Data (rad/s)
    Serial.print(F(" | "));
    Serial.print(g.gyro.x, 3);
    Serial.print(F(" | "));
    Serial.print(g.gyro.y, 3);
    Serial.print(F(" | "));
    Serial.println(g.gyro.z, 3); // println finishes the line
  }
}
