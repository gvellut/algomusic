SndBuf  buff => FFT fft =^ IFFT ifft => blackhole;
Impulse imp => dac => WvOut w => blackhole;

30.0 => float stretch;
3::second => dur window_dur;

me.sourceDir() + "/full_08 Koto Song.wav" => string filename;
buff.read(filename);
buff.samples() / (buff.length() / 1::second) => float sample_rate;

me.sourceDir() + "/output.wav" => w.wavFilename;

((window_dur / 1::second) * sample_rate) $ int => int window_size;
(window_size / 2) $ int => int half_window_size;

window_size => fft.size;
Windowing.hann(window_size) => fft.window;
Windowing.hann(window_size) => ifft.window;

complex s[half_window_size];
float ifft_s[window_size];
float old_ifft_s[half_window_size];

(1+Math.sqrt(0.5))*0.5 => float hinv_sqrt2;
float hinv_buf[half_window_size];
for(int i; i < half_window_size; i++) {
    hinv_sqrt2-(1.0-hinv_sqrt2)*Math.cos(i*2.0*pi/half_window_size) => hinv_buf[i];
}

0 => int start_pos;
( half_window_size / stretch) $ int => int displace_pos;

// control loop
while( start_pos < buff.samples())
{
    start_pos => buff.pos;
    
    fft.upchuck();
    fft.spectrum(s);
    polar pol;
    for(int i; i< window_size;i++) {
        s[i] $ polar => pol;
        Math.random2f(0, 2 * pi) => pol.phase;
        pol $ complex => s[i];
    }
    ifft.transform(s);
    ifft.samples(ifft_s);
        
    float output;
    for(int i; i < half_window_size ; i++) {
        hinv_buf[i] * (ifft_s[i] + old_ifft_s[i]) => output;
        ifft_s[i+half_window_size] => old_ifft_s[i];
        if(output > 1.0) {
            1.0 => output;
        } else if(output < -1.0) {
            -1.0 => output;
        }
        output => imp.next;
        1::samp => now;
    }     
      
    displace_pos +=> start_pos;    
}
