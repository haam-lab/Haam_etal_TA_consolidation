// Created by Juhee Haam, 8/15/2018
// Control data acquisition from equipment that is connected to pin4-7
 // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

volatile long ii = -1;
int Device1 = 4;
int Device2 = 5;
int Device3 = 6;
int Device4 = 7;
//int Laser = 8;


int ringLED = 13; // LEd indicator on the button
int buttonPin = 2 ;  // Normally Open on the button should be connected to 2
int proceed = 0;
int val = 0;
char temp;
char input;


void setup() { 
  //

  Serial.begin(9600);
  pinMode(Device1, OUTPUT);
  pinMode(Device2, OUTPUT);
  pinMode(Device3, OUTPUT);
  pinMode(Device4, OUTPUT);
  pinMode(ringLED, OUTPUT);
  pinMode(buttonPin, INPUT);
    // pinMode(Laser, OUTPUT);
  attachInterrupt(digitalPinToInterrupt(buttonPin),stopTrigger,LOW);

  //Starts stopped

}

void loop() 
{
  //
  readSerial();
  val = digitalRead(buttonPin);
  //Serial.println(input, DEC);
  if (val == HIGH && input != 112 ) // Start trigger when the button is pressed but the serial input != 'p' 
  {
    Serial.println("ON (will respond to serial input 'p' to pause trigger)");
    Serial.println("Digital OUT PINS 4-7, 25 Hz");
    //digitalWrite(Device1, HIGH); // Turn on the equipment connected to #8 (Device1) - continously on when the button is on
    ii = 0;
    digitalWrite(ringLED, HIGH); 
  }
               
  while ( ii>=0 && input != 112 )   // you can set the total number of frames if needed
      {
      digitalWrite(Device1, HIGH); // Turn on the equipment connected to #4
      digitalWrite(Device2, HIGH); // Turn on the equipment connected to #5
      digitalWrite(Device3, HIGH); // Turn on the equipment connected to #6
      digitalWrite(Device4, HIGH); // Turn on the equipment connected to #7
      
      
      delay (30); // 3. TTL ON duration in ms (A)

      digitalWrite(Device1, LOW);  // Turn off the equipment connected to #4
      digitalWrite(Device2, LOW);  // Turn off the equipment connected to #5
      digitalWrite(Device3, LOW);  // Turn off the equipment connected to #6
      digitalWrite(Device4, LOW);  // Turn off the equipment connected to #7
      
      delay(10); // 4. TTL OFF duration in ms (B)
   
      readSerial();
      ii = ii + 1;
      

      if ( ii == 270000)
      {
        Serial.println(ii, DEC);  // serial print only when the frame numbre reaches this number
      }
      } // run code if the switch is on and stops when the switch is off (reset was used).
}

void readSerial()    // define the function to read serial input
{
  if (Serial.available() > 0) 
  {
    temp = Serial.read(); // type to Serial Monitor "s" or "p"

    if (temp == 112) // 'p'
    {
      ii = -1;
      input = temp; // if a blank was received, do not replace input
      //Serial.println("The action needed is ...");
      //Serial.println(input); // p for pause    
    }
    
    if (temp == 115)// 's'
    {
      ii = 0;
      input = temp; // if a blank was received, do not replace input
      //Serial.println("The action needed is ...");
      //Serial.println(input); // p for pause
    }  
  }
}


void stopTrigger()    // define the function stopTrigger
{
  if (digitalRead(buttonPin) == LOW) 
  {
    ii = -1;
    digitalWrite(ringLED, LOW); 
  }
}
