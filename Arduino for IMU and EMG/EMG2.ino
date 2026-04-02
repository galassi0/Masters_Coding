unsigned long previousMillis = 0;  
const long interval = 1;  // 1 millisecond delay for 1000Hz sampling rate

void setup() {
  Serial.begin(115200);  // Start serial communication
}

void loop() {
  unsigned long currentMillis = millis();  // Get the current time in ms

  // Check if it's time to take a new sample
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;  // Save the last time a sample was taken

    int emgReading = analogRead(A0);  // Read the EMG sensor

    // Print the timestamp and reading to the serial monitor
    Serial.print(currentMillis);  // Send timestamp
    Serial.print(",");            // Separator between timestamp and data
    Serial.println(emgReading);   // Send EMG reading
  }
}
