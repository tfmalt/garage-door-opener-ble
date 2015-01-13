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

#define DIGITAL_OUT_PIN    2

void setup()
{
	ble_set_name("Malt SD60");
	ble_begin();

	Serial.begin(57600);
	Serial.println("-------------------------------");
	Serial.println("Starting garage door controller");
	Serial.println("-------------------------------");
	pinMode(DIGITAL_OUT_PIN, OUTPUT);
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

void loop()
{
	while(ble_available())
	{
		
		char command = ble_read();
		String input = "";
		String password = "Martha";
		
		Serial.println("Received data in rx_buffer.");
		Serial.print("Received command: ");
		Serial.println(command);
		
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

	// Allow BLE Shield to send/receive data
	ble_do_events();
}
