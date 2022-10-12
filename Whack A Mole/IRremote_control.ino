#include <IRremote.h>
#include <LiquidCrystal.h>

const int RECV_PIN = 6;
IRrecv irrecv(RECV_PIN);
decode_results results;
unsigned long key_value = 0;

int led[4] = {7, 8, 9, 10};
int minRandLed = 0;
int maxRandLed = 4;
int selected_led;
unsigned long randDelay;                 // Generated random number
unsigned long minRandDelay = 2000;     // minimum number used to specify the range of random number
unsigned long maxRandDelay = 5000;     // maximum number used to specify the range of random number

LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

unsigned long timefinal, time1, reactiontime;
unsigned long min_response_time = 3000000;

int next_iteration_started = 0;
int takereading = 0;
int printcount = 0;
int react_time = 0;

int score = 0;
int restart = 0;



void setup(){
  Serial.begin(9600);
  
  irrecv.enableIRIn();
  setLEDFeedback(true);

  pinMode(led[0], OUTPUT);
  pinMode(led[1], OUTPUT);
  pinMode(led[2], OUTPUT);
  pinMode(led[3], OUTPUT);

  lcd.begin(16,2);
}

void loop(){
  if ( printcount == 0 && react_time == 0) {
     lcd.clear();
     lcd.setCursor(0, 0);
     lcd.print("Ready");
     delay(500);
     lcd.clear();
     lcd.setCursor(0, 0);
     lcd.print("Set");
     delay(500);
     lcd.clear();
     lcd.setCursor(0, 0);
     lcd.print("Go");
     printcount = 1;
     next_iteration_started = 1;
  }
  if ( next_iteration_started ) {
     selected_led = random(minRandLed, maxRandLed);
     randDelay = random(minRandDelay, maxRandDelay);
     Serial.print("Selected led is:");
     Serial.print(selected_led);
     Serial.println("\nSelected pin is:");
     Serial.print(led[selected_led]);
     delay(randDelay);
     digitalWrite(led[selected_led], !digitalRead(led[selected_led]));
     time1 = micros();
     next_iteration_started = 0;
     takereading = 1;
  }  
     
  if ( ((micros() - time1) > min_response_time) || restart ) {
     if (! restart) {
     lcd.clear();
     lcd.setCursor(0,0);
     lcd.print("Timeout!!");
     delay(3000);
     }

     if (! react_time) {
     lcd.clear();
     lcd.setCursor(0, 0);
     lcd.print("Your score was:");
     lcd.setCursor(0,1);
     lcd.print(score);
     delay(5000);
     }
     lcd.print("Restarting...");
     delay(2000);
     digitalWrite(led[0], 0);
     digitalWrite(led[1], 0);
     digitalWrite(led[2], 0);
     digitalWrite(led[3], 0);
     printcount = 0;
     takereading = 0;
     next_iteration_started = 0;
     score = 0;
     restart = 0;
     react_time = 0;
  }
  if (takereading) {
    if (IrReceiver.decode()){
  
          results.value = IrReceiver.decodedIRData.decodedRawData;
          uint32_t reversed = 0;
          for(int i=0;i<=31;i++) {
             reversed = reversed << 1;
             reversed += (results.value >> (i))& 1;
          }
        
          if (reversed == 0XFFFFFFFF)
            reversed = key_value;
  
          switch(reversed){
            case 0xFFA25D:
            Serial.println("CH-");
            break;
            case 0xFF629D:
            Serial.println("CH");
            break;
            case 0xFFE21D:
            Serial.println("CH+");
            break;
            case 0xFF22DD:
            Serial.println("|<<");
            break;
            case 0xFF02FD:
            Serial.println(">>|");
            break ;  
            case 0xFFC23D:
            Serial.println(">|");
            break ;               
            case 0xFFE01F:
            Serial.println("-");
            break ;  
            case 0xFFA857:
            Serial.println("+");
            break ;  
            case 0xFF906F:
            Serial.println("EQ");
            break ;  
            case 0xFF6897:
            Serial.println("0");
            takereading = 0;
            printcount = 0;
            restart = 1;
            timefinal = micros();
            //if ((micros() - timefinal) > debounceDelay) {
               reactiontime = timefinal - time1;
               Serial.println(reactiontime);
               lcd.clear();
               lcd.print("Reaction time is:");
               lcd.setCursor(0, 1);
               lcd.print(reactiontime);
               restart = 1;
               react_time = 1;
            delay(5000);
            break ;  
            case 0xFF9867:
            Serial.println("100+");
            break ;
            case 0xFFB04F:
            Serial.println("200+");
            break ;
            case 0xFF30CF:
            Serial.println("1");
            takereading = 0;
            if ( selected_led == 0 ) {
               digitalWrite(led[selected_led], !digitalRead(led[selected_led]));
               score += 1;
               next_iteration_started = 1;
            } else {
               lcd.clear();
               lcd.setCursor(0, 0);
               lcd.print("Incorrect");
               lcd.setCursor(0, 1);
               lcd.print("Selection!!");
               delay(3000);
               restart = 1;
            }
            break ;
            case 0xFF18E7:
            Serial.println("2");
            takereading = 0;
            if ( selected_led == 1 ) {
               digitalWrite(led[selected_led], !digitalRead(led[selected_led]));
               score += 1;
               next_iteration_started = 1;
            } else {
               lcd.clear();
               lcd.setCursor(0, 0);
               lcd.print("Incorrect");
               lcd.setCursor(0, 1);
               lcd.print("Selection!!");
               delay(3000);
               restart = 1;
            }
            break ;
            case 0xFF7A85:
            Serial.println("3");
            takereading = 0;
            if ( selected_led == 2 ) {
               digitalWrite(led[selected_led], !digitalRead(led[selected_led]));
               score += 1;
               next_iteration_started = 1;
            } else {
               lcd.clear();
               lcd.setCursor(0, 0);
               lcd.print("Incorrect");
               lcd.setCursor(0, 1);
               lcd.print("Selection!!");
               delay(3000);
               restart = 1;
            }
            break ;
            case 0xFF10EF:
            Serial.println("4");
            takereading = 0;
            if ( selected_led == 3 ) {
               digitalWrite(led[selected_led], !digitalRead(led[selected_led]));
               score += 1;
               next_iteration_started = 1;
            } else {
               lcd.clear();
               lcd.setCursor(0, 0);
               lcd.print("Incorrect");
               lcd.setCursor(0, 1);
               lcd.print("Selection!!");
               delay(3000);
               restart = 1;
            }
            break ;
            case 0xFF38C7:
            Serial.println("5");
            break ;
            case 0xFF5AA5:
            Serial.println("6");
            break ;
            case 0xFF42BD:
            Serial.println("7");
            break ;
            case 0xFF4AB5:
            Serial.println("8");
            break ;
            case 0xFF52AD:
            Serial.println("9");
            break ;      
          }
          key_value = reversed;
          irrecv.resume(); 
    }
  }
}
