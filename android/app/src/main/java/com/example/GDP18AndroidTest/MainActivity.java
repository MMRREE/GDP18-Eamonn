package com.example.GDP18AndroidTest;

import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.os.Build.VERSION;
import android.os.Build.VERSION_CODES;

import androidx.annotation.NonNull;

import java.util.ArrayList;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    // Flutter setup for audio output
    private static final String CHANNEL = "GDP18Androidtest.example.com/oscilloscope";

    // Settings and setup for audio output
    private static final double duration = 0.1; // seconds
    private static final int sampleRate = 44100; // hz
    private final int numSamples = (int) (duration * sampleRate);
    private final short[] outputSoundBuffer = new short[numSamples*2];

    // Right audio settings
    private double rightAmplitude = 1; // 0-1 scale
    private double rightFrequency = 42000; // hz
    private String rightWaveType = "sine"; // name of wave type {"sine", "square", "triangle"}
    private double rightPhaseOffset = 0; // phase offset of graph
    private boolean leftTurnedOn = true;
    private final ArrayList<Double> leftBufferChannel = new ArrayList<>();

    // Left audio settings
    private double leftAmplitude = 1; // 0-1 scale
    private double leftFrequency = 4000; // hz
    private String leftWaveType = "sine"; // name of wave type {"sine", "square", "triangle"}
    private double leftPhaseOffset = 0; // phase offset of graph
    private boolean rightTurnedOn = true;
    private final ArrayList<Double> rightBufferChannel = new ArrayList<>();

    // Thread stuff so that sound can be played in the background
    private AudioTrack audioTrack = null;
    private boolean isPlaying = true;

    private Thread playSoundRunnable = new Thread(new Runnable(){
        public void run(){
            while (isPlaying) {
                playAudioTrack();
                try {
                    Thread.sleep(1);
                } catch (InterruptedException e) {
                    return;
                }
            }
        }
    });

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
  super.configureFlutterEngine(flutterEngine);
  genTone();
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
        .setMethodCallHandler(
          (call, result) -> {
              final Boolean leftChannel = call.argument("left");

            switch(call.method){
              case "updateType":
                  if(leftChannel) leftWaveType = call.argument("value");
                  else rightWaveType = call.argument("value");
                  genTone();
                  result.success(leftChannel ? leftBufferChannel : rightBufferChannel);
              break;

              case "updateFrequency":
                if(leftChannel) leftFrequency = call.argument("value");
                else rightFrequency = call.argument("value");
                genTone();
                  result.success(true);
              break;

              case "updateAmplitude":
                if(leftChannel) leftAmplitude = call.argument("value");
                else rightAmplitude = call.argument("value");
                genTone();
                  result.success(true);
              break;

                case "updateOffset":
                    if(leftChannel) leftPhaseOffset = call.argument("value");
                    else rightPhaseOffset = call.argument("value");
                    genTone();
                    result.success(true);
                    break;

                case "updateChannelSwitch":
                    if(leftChannel) leftTurnedOn = call.argument("value");
                    else rightTurnedOn = call.argument("value");
                    genTone();
                    result.success(leftChannel ? leftBufferChannel : rightBufferChannel);
                    break;

              case "playSound":
                  isPlaying = true;
                  playSoundRunnable = new Thread(new Runnable(){
                      public void run(){
                          while (isPlaying) {
                              playAudioTrack();
                              try {
                                  Thread.sleep(1);
                              } catch (InterruptedException e) {
                                  return;
                              }
                          }
                      }
                  });

                  playSoundRunnable.start();

                  result.success(true);
                  break;

              case "pauseSound":
                  isPlaying = false;
                  try {
                      playSoundRunnable.interrupt();

                      // pause() appears to be more snappy in audio cutoff than stop()
                      if(audioTrack != null){
                          audioTrack.pause();
                          audioTrack.flush();
                          audioTrack.release();
                          audioTrack = null;
                      }
                  } catch (IllegalStateException e) {
                      // An irrelevant exception
                  }

                  result.success(true);
                  break;

                case "updateChannel":
                    result.success(leftChannel ? leftBufferChannel : rightBufferChannel);
                    break;

              default:
                result.notImplemented();
            }
          }
        );
  }

  void genTone(){
      leftBufferChannel.clear();
      rightBufferChannel.clear();

      int ramp = numSamples / 100;

      for (int i = 0; i < numSamples; i++) {
          short tempCalculation;

          if(leftTurnedOn){
              switch(leftWaveType){
                  case "sine":
                      tempCalculation = (short) (Math.sin(2 * Math.PI * i * leftFrequency / sampleRate - 2 * Math.PI * leftPhaseOffset) * (0x7FFF * leftAmplitude));
                      break;

                  case "triangle":
                      tempCalculation = (short) ((2 / Math.PI) * Math.asin(Math.sin(2 * Math.PI * i * leftFrequency / sampleRate - 2 * Math.PI * leftPhaseOffset)) * (0x7FFF * leftAmplitude));
                      break;

                  case "square":
                      tempCalculation = (short) (Math.signum(Math.sin(2 * Math.PI * i * leftFrequency / sampleRate - 2 * Math.PI * leftPhaseOffset)) * (0x7FFF * leftAmplitude));
                      break;

                  default:
                      tempCalculation = (short) 0;
              }
          } else {
              tempCalculation = (short) 0;
          }

          //if(i < ramp) tempCalculation = (short) (tempCalculation * i / ramp);
          //if(i > numSamples - ramp) tempCalculation = (short) (tempCalculation * (numSamples - i) / ramp);

          leftBufferChannel.add((double) tempCalculation);
          outputSoundBuffer[2 * i] = tempCalculation;

          if(rightTurnedOn){
              switch(rightWaveType){
                  case "sine":
                      tempCalculation = (short) (Math.sin(2 * Math.PI * i * rightFrequency / sampleRate - 2 * Math.PI * rightPhaseOffset) * (0x7FFF * rightAmplitude));
                      break;

                  case "triangle":
                      tempCalculation = (short) ((2 / Math.PI) * Math.asin(Math.sin(2 * Math.PI * i * rightFrequency / sampleRate - 2 * Math.PI * rightPhaseOffset)) * (0x7FFF * rightAmplitude));
                      break;

                  case "square":
                      tempCalculation = (short) (Math.signum(Math.sin(2 * Math.PI * i * rightFrequency / sampleRate - 2 * Math.PI * rightPhaseOffset)) * (0x7FFF * rightAmplitude));
                      break;

                  default:
                      tempCalculation = 0;
              }
          } else {
              tempCalculation = 0;
          }

          //if(i < ramp) tempCalculation = (short) (tempCalculation * i / ramp);
          //if(i > numSamples - ramp) tempCalculation = (short) (tempCalculation * (numSamples - i) / ramp);

          rightBufferChannel.add((double) tempCalculation);
          outputSoundBuffer[2 * i + 1] = tempCalculation;
      }
  }

  void playAudioTrack(){
    if(VERSION.SDK_INT >= VERSION_CODES.O && audioTrack == null){
        AudioAttributes attributes = new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build();
        AudioFormat format = new AudioFormat.Builder()
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setSampleRate(sampleRate)
                .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                .build();
        audioTrack = new AudioTrack(attributes,
                format,
                outputSoundBuffer.length,
                AudioTrack.MODE_STREAM,
                AudioManager.AUDIO_SESSION_ID_GENERATE);
    } else if(audioTrack == null) {
      audioTrack = new AudioTrack(AudioManager.STREAM_MUSIC,
              sampleRate,
              AudioFormat.CHANNEL_OUT_STEREO,
              AudioFormat.ENCODING_PCM_16BIT,
              outputSoundBuffer.length,
              AudioTrack.MODE_STREAM);
    }

      audioTrack.play();
      audioTrack.write(outputSoundBuffer, 0, outputSoundBuffer.length);
  }
}
