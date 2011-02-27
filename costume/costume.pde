/*
 * Costume code of hoboness
 */
#ifndef cbi
        #define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
    #endif
    #ifndef sbi
        #define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
    #endif

 #define AUDIOCOUNT 3
 #define AUDIOHIST 4
 #define JUMPCOUNT 3
 #define JUMPHIST 4
 #define SEGMENTCOUNT 4
 int segments[SEGMENTCOUNT] = {0,1,2,3};
// int segments[SEGMENTCOUNT] = {0,1,2,3};
 int audio_channels[AUDIOCOUNT] = {2,3,4};
 int audio_max[AUDIOCOUNT] = {0,0,0};
 int jump_channels[JUMPCOUNT] = {5,6,7};
 int audio_hist[AUDIOCOUNT][AUDIOHIST];
 int jump_hist[JUMPCOUNT][JUMPHIST];
 int jump_decay[JUMPCOUNT];
 int audio_decay[AUDIOCOUNT];
 int js,as;
 int cur_segment;
 unsigned long last_transition;
 unsigned long minimum_interval = 20;
 unsigned long maximum_interval = 2000;
 // turn a given EL wire segment on or off. 'num' is between 0 and 7, corresponding
// to EL segments 'A' through 'H'.  if 'value' is true, the segment will be lit.
// if value is false, the segment will be dark.
void elSegment(byte num, boolean value) {
  digitalWrite(num + 2, value ? HIGH : LOW);
}

 
 void setup() {
  Serial.begin(9600); 
  as = 0;
  js = 0;
  cur_segment = 0;
  for (int i = 0; i < 8; ++i) {
    pinMode(2+i,OUTPUT);
    elSegment(i,false);
  }
  //Start with first wire light up
  elSegment(segments[0],true);
  //ADC drugs for faster reading
  //http://arduinolessons.blogspot.com/2010/10/what-is-maximum-sampling-frequency-for.html
  sbi(ADCSRA,ADPS2) ;
  cbi(ADCSRA,ADPS1) ;
  cbi(ADCSRA,ADPS0) ;
  last_transition = millis();
 }
 
 void loop() {
   bool beat = 0;
   bool jump = 0;
   as = as+1%AUDIOHIST;
   for (int i = 0; i < AUDIOCOUNT ; ++i) {
     // wait 1 milliseconds for the analog-to-digital converter
     // to settle after the last reading:
     delay(1);
     int j = analogRead(audio_channels[i]);
     if (j > audio_max[i]) {
        audio_max[i] = j;
     }
     if (audio_max[i] > 1020 && //Hobo attempt at eliminating disconnected pins
         j > 800 && 
         j > 1.1*audio_decay[i] && //Higher than decayed value
         j > 1.2*audio_hist[i][as%AUDIOHIST] && //Higher than last 3
         j > 1.2*audio_hist[i][as+1%AUDIOHIST] &&
         j > 1.2*audio_hist[i][as+2%AUDIOHIST] 
     ) {
      beat = 1;
     }
     audio_decay[i] = (audio_decay[i]+j)/2;
     audio_hist[i][as] = j;
   }
   js = js+1%JUMPHIST;
   for (int i = 0; i < JUMPCOUNT ; ++i) {
       // wait 1 milliseconds for the analog-to-digital converter
       // to settle after the last reading:
       delay(1);
       int j = analogRead(jump_channels[j]);
       jump_decay[i] = (jump_decay[i]+j)/2;
       jump_hist[i][js] = j;
   }

    //Minimum time before a transition
    if (millis()-last_transition > minimum_interval) {
     //We have a maximum transition length
     if (millis() - last_transition > maximum_interval) {
       transition();
     //If there is a beat & jumping & its been at least minimum interval
     } else if (jump && beat ) {
       do_transition(3);
     //Just a beat
     } else if (beat) {
       transition();
     }
    }
   
 }
 void transition() {
  do_transition(1);
 }
 void do_transition(int i) {
   //Serial.print("Switching to");
   //Serial.println(segments[cur_segment+i%SEGMENTCOUNT]);
   elSegment(segments[cur_segment],false);
   cur_segment+=i;
   cur_segment = cur_segment %SEGMENTCOUNT;
   elSegment(segments[cur_segment],true);
   last_transition = millis();
 }
