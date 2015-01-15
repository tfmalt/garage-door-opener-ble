/*

Copyright (c) 2012-2014  RedBearLab
Copyright (c) 2014-2015  Thomas Malt <thomas@malt.no>

Permission is hereby granted, free of charge, to any person obtaining a copy of 
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
IN THE SOFTWARE.

*/

#include <SPI.h>
#include <Nordic_nRF8001.h>
#include <ble_shield.h>
#include <EEPROM.h>

#define DIGITAL_OUT_PIN    2
#define PASSWORD_POSITION   512
#define PASSWORD_MAX_LENGTH 24
#define BLE_NAME_POSITION 544
#define BLE_NAME_MAX_LENGTH 10

String password = "";

void setup()
{
	Serial.begin(57600);
	Serial.println("-------------------------------");
	Serial.println("Starting garage door controller");
	Serial.println("-------------------------------");
	
	password = getStringFromEEPROM(PASSWORD_POSITION);
	
	String str = getStringFromEEPROM(BLE_NAME_POSITION);
	int len = str.length() + 1;
	char name[len];
	str.toCharArray(name, len);
	
	Serial.println("Read password from EEPROM, length: " + password.length());
	Serial.println("Read ble_name from EEPROM: " + String(name));
	
	ble_set_name(name);
	ble_begin();

	pinMode(DIGITAL_OUT_PIN, OUTPUT);
}


String getStringFromEEPROM(int position) 
{
	String str = "";
	int length = EEPROM.read(position);
	
	if (length == 255) return str;
	
	int i   = position + 1;
	int end = i + length;
	
	while (i < end) {
		char c = EEPROM.read(i);
		i++;
		
		str += c;
	}
	
	return str;
}

void writeStringToEEPROM(int position, String p)
{
	int length = p.length();
	
	EEPROM.write(position, length);
	
	int i = position+ 1;
	int j = 0;
	
	int end = i + length;
	
	while (i < end) {
		EEPROM.write(i, p.charAt(j));
		i++;
		j++;
	}
}


String readPassword(int length)
{
	String p = "";
	int i = 0;
	
	while (ble_available()) 
	{
		if (i >= length) break;
		char in = ble_read();
		p += in;
		i++;
	}
	
	Serial.print("read password: No more input: ");
	Serial.println(i);
	
	// p.trim();
	
	return p;
}

void emptyRXBuffer() 
{
	while (ble_available())
	{
		byte data = ble_read();
		Serial.print("extra: ");
		Serial.println(data);
	}
}

void handleBleInput() {
	char command = ble_read();
	
	String input = "";

	Serial.println(String("Received data in rx_buffer: "));
	Serial.println(String("Received command: ") + command);

	if (command == '0') {
		input = readPassword(password.length());
	}
		
	emptyRXBuffer();
		
	if (command = '0' && input.equals(password))
	{
		Serial.println("Password match: Executing command.");
		digitalWrite(DIGITAL_OUT_PIN, HIGH);
		delay(500);
		digitalWrite(DIGITAL_OUT_PIN, LOW);
	}
		
	Serial.println("Done processing incoming data.");
	Serial.println("------------------------------");
}

bool isStringValid(String str, int max_length)
{
	if (str.length() > max_length)
	{
		Serial.println(
			String("String is too Long. Maximum length is: ") + 
			max_length + " characters."
		);
		return false;
	}
	
	return true;
}

void handleSerialInput()
{
	delay(25); // milliseconds to get a full set of input.
	String str = "";
	
	while (Serial.available())
	{
		char c = Serial.read();
		str += c;
	}
	
	if (str.length() > 5 && str.substring(0, 5) == "name=") 
	{
		String name = str.substring(5);
		if (isStringValid(name, BLE_NAME_MAX_LENGTH)) {
			writeStringToEEPROM(BLE_NAME_POSITION, name);
			char new_name[name.length() +1 ];
			name.toCharArray(new_name, name.length() + 1);
			ble_set_name(new_name);
			Serial.println("Set new ble_name = '" + name + "'");
		}
	}
	else if (str.length() > 9 && str.substring(0, 9) == "password=") 
	{
		String newPassword = str.substring(9);
		if (isStringValid(newPassword, PASSWORD_MAX_LENGTH)) {
			writeStringToEEPROM(PASSWORD_POSITION, newPassword);
			password = newPassword;
			Serial.println("Set new password = '" + password + "'");
			
		}
	}
	else {
		Serial.println("Unknown command in: " + str);
		return;
	}
	
	
}

void loop()
{
	
	if (Serial.available()) handleSerialInput();
	if (ble_available()) handleBleInput();

	// Allow BLE Shield to send/receive data
	ble_do_events();
}
